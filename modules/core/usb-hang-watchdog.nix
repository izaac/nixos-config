# Early warning for USB subsystem lockups.
#
# The kernel processes every hub event (enumeration, reset, disconnect) on a
# single global workqueue, `usb_hub_wq`. There is no per-controller or
# per-port isolation: if one misbehaving device stalls inside
# `hub_event` -> `hub_port_init` -> `xhci_setup_device`, that worker blocks in
# uninterruptible sleep and *all* USB hotplug across every controller stops.
# Keyboards and mice plugged in afterwards never enumerate, udev workers pile
# up until they are SIGKILLed, and the machine can end up effectively frozen.
#
# That failure mode is silent: the only evidence is a kernel hung-task dump in
# the journal, which nobody reads while the desktop is still (briefly)
# responsive. This watchdog tails the kernel journal and surfaces those dumps
# as a desktop notification, so there is a chance to unplug the offending
# device before the pile-up becomes fatal.
#
# It deliberately does NOT try to repair anything. Recovering a wedged xHCI
# controller means removing and rescanning it on the PCI bus, which tears down
# every device on that controller (including the keyboard used to react), and
# it cannot cancel a worker already stuck in D state anyway. Warning early is
# the useful part; the fix is physical.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.mySystem.core.usb-hang-watchdog;

  watchdog = pkgs.writeShellApplication {
    name = "usb-hang-watchdog";
    runtimeInputs = with pkgs; [systemd libnotify util-linux coreutils gnugrep];
    text = ''
      cooldown=${toString cfg.cooldownSeconds}

      # Epoch of the last alert per category, so a hung task that re-reports
      # every 120s does not turn into a notification storm.
      declare -A last_alert

      # systemd reads these prefixes off stdout and maps them to journal
      # priorities (2 = crit, 4 = warning).
      log() { printf '<%s>%s\n' "$1" "$2"; }

      notify_all_sessions() {
        urgency=$1
        expire=$2
        title=$3
        body=$4
        for bus in /run/user/*/bus; do
          [ -S "$bus" ] || continue
          uid=$(stat -c '%u' "$bus")
          gid=$(stat -c '%g' "$bus")
          DBUS_SESSION_BUS_ADDRESS="unix:path=$bus" \
          XDG_RUNTIME_DIR="/run/user/$uid" \
            setpriv --reuid="$uid" --regid="$gid" --init-groups \
              notify-send -a "USB watchdog" -u "$urgency" -t "$expire" "$title" "$body" || true
        done
      }

      # Names the device that was mid-enumeration when the worker stalled.
      # Restricted to identity and failure lines: plain traffic messages
      # (mixer probes and the like) would just bury the useful ones.
      recent_usb_context() {
        journalctl -k -n 500 -o cat 2>/dev/null \
          | grep -Eo 'usb [0-9]+-[0-9.]+: (new .*|Product: .*|Manufacturer: .*|USB disconnect.*|Device not responding.*|device descriptor read.*|unable to enumerate.*)' \
          | tail -4 \
          || true
      }

      # notify=1 raises a desktop popup; notify=0 records it in the journal
      # only, for categories that are too chatty to interrupt over.
      alert() {
        key=$1
        priority=$2
        notify=$3
        urgency=$4
        expire=$5
        title=$6
        body=$7

        now=$(date +%s)
        previous=''${last_alert[$key]:-0}
        if [ $((now - previous)) -lt "$cooldown" ]; then
          return
        fi
        last_alert[$key]=$now

        log "$priority" "$title: $body"
        [ "$notify" = 1 ] && notify_all_sessions "$urgency" "$expire" "$title" "$body"
        return 0
      }

      log 5 "watching kernel log for USB hub lockups"

      # -n 0 starts at the tail so old dumps from a previous boot-up burst do
      # not fire an alert on every service restart. Process substitution keeps
      # the loop in the main shell, so the cooldown map survives across lines.
      while IFS= read -r line; do
        case "$line" in
          # The stall itself. This line only appears in a stack dump, so a
          # match means a hub worker is parked in uninterruptible sleep and
          # no USB device will enumerate anywhere until it is freed.
          *"Workqueue: usb_hub_wq hub_event"*)
            body="A hub worker is stuck in hub_event."
            body="$body Hotplug is dead on every USB controller until the device is unplugged."
            context=$(recent_usb_context)
            if [ -n "$context" ]; then
              body="$body"$'\n\n'"Last USB activity:"$'\n'"$context"
            fi
            alert hub 2 1 critical 0 "USB subsystem wedged" "$body"
            ;;

          # Immediate precursor: the device answered the port reset but not
          # the address assignment, which is where xhci_setup_device blocks.
          *"Device not responding to setup address"* \
          | *"unable to enumerate USB device"* \
          | *"device descriptor read"*)
            alert enumerate 4 1 critical 15000 \
              "USB device failing to enumerate" \
              "$line"$'\n\n'"Unplug it now: a retry loop here can wedge USB system-wide."
            ;;

          # Control transfers timing out (-110 is ETIMEDOUT). Usually the
          # earliest sign that a device or its port is going bad.
          *"-110 (exp."* | *"error -110"* | *"status -110"*)
            alert timeout 4 1 normal 10000 \
              "USB device timing out" \
              "$line"
            ;;

          # Host-controller bookkeeping errors. Real, but they also show up
          # transiently on healthy hardware, so journal only.
          *"ERROR Transfer event for disabled endpoint"* \
          | *"ERROR mismatched command completion event"* \
          | *"ERROR unknown event type"*)
            alert xhci 4 0 normal 0 \
              "xHCI controller errors" \
              "$line"
            ;;
        esac
      done < <(journalctl -k -n 0 -f -o cat)
    '';
  };
in {
  options.mySystem.core.usb-hang-watchdog = {
    enable = lib.mkEnableOption "desktop warnings when the USB hub workqueue stalls";

    cooldownSeconds = lib.mkOption {
      type = lib.types.ints.positive;
      default = 600;
      description = ''
        Minimum seconds between two alerts of the same category. The kernel
        re-reports a hung task every `kernel.hung_task_timeout_secs`, so
        without a cooldown a single stall produces an alert every 2 minutes.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services.usb-hang-watchdog = {
      description = "Warn when the USB hub workqueue stalls";
      wantedBy = ["multi-user.target"];
      after = ["systemd-journald.service"];

      serviceConfig = {
        ExecStart = lib.getExe watchdog;
        Restart = "always";
        RestartSec = 5;

        # Dropping to the session user is done with setpriv, which needs no
        # new privileges, so the usual hardening still applies.
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "full";
        ProtectKernelModules = true;
        RestrictRealtime = true;
        MemoryMax = "64M";
      };
    };
  };
}
