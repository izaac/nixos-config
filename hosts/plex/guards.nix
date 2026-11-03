# plex: runtime guard rails for the two failure modes that took the host down
# on 2026-11-02.
#
# DNS. dhcpcd's IPv6 router advertisement expired, resolvconf rewrote
# /etc/resolv.conf empty, and every lookup on the box failed. The rclone
# backend host apis.uloz.to was among them, so the mount went dead and
# media-mover could not upload. Static nameservers (see configuration.nix) are
# the fix; dns-watchdog is the alarm that says whether they actually arrived.
#
# Disk. With the mover stuck, nothing drained /var/lib/media-staging while
# qBittorrent, Sonarr and Radarr kept writing, and the root filesystem filled
# completely, which breaks far more than media. media-disk-guard stops the
# writers before that point and resumes them once space comes back.
#
# Both are timers rather than daemons: the condition they check is cheap and
# the failure they watch for is not worth a long-lived process.
{
  lib,
  pkgs,
  ...
}: let
  # Root filesystem thresholds, in bytes. 30 GiB is roughly where a full
  # staging tree plus Plex's and rclone's caches stop leaving room to work;
  # 8 GiB is the last chance to keep the box usable for logins and systemd
  # itself. Resuming only above 45 GiB keeps the guard from flapping when an
  # upload frees exactly enough space to trip it again.
  lowBytes = 30 * 1024 * 1024 * 1024;
  critBytes = 8 * 1024 * 1024 * 1024;
  resumeBytes = 45 * 1024 * 1024 * 1024;

  # Units the guard may stop, in the order it stops them. rclone-ul-crypt is
  # deliberately absent: stopping the mount would not free space, and it would
  # take the library offline on top of everything else.
  writerUnits = [
    "podman-qbittorrent.service"
    "sonarr.service"
    "radarr.service"
  ];
  critUnits = ["prowlarr.service"];

  dnsWatchdog = pkgs.writeShellApplication {
    name = "plex-dns-watchdog";
    runtimeInputs = with pkgs; [glibc systemd util-linux openresolv gnugrep coreutils];
    text = ''
      # The rclone backend host. If this does not resolve, the media mount and
      # the mover are both dead, which is exactly the 2026-11-02 state.
      host=apis.uloz.to

      if getent hosts "$host" > /dev/null 2>&1; then
        exit 0
      fi

      # Empty resolv.conf is the known cause, so give resolvconf one chance to
      # rebuild it from the submitted nameservers. Best effort: a rebuild is
      # not guaranteed to help if the resolver itself is down.
      if ! grep -qE '^[[:space:]]*nameserver[[:space:]]' /etc/resolv.conf; then
        resolvconf -u || true
        if getent hosts "$host" > /dev/null 2>&1; then
          logger -p user.crit "dns-watchdog: $host failed to resolve, recovered after resolvconf -u"
          exit 0
        fi
      fi

      logger -p user.crit "dns-watchdog: $host does not resolve, /etc/resolv.conf is: $(tr '\n' ' ' < /etc/resolv.conf)"
      exit 1
    '';
  };

  mediaDiskGuard = pkgs.writeShellApplication {
    name = "plex-media-disk-guard";
    runtimeInputs = with pkgs; [systemd coreutils gnugrep util-linux];
    text = ''
      state=/run/media-disk-guard
      tripped="$state/tripped"
      stopped="$state/stopped"

      mkdir -p "$state"

      # Available bytes, not used bytes or a percentage: the root device is a
      # fixed 233G, so an absolute floor is what actually bounds the staging
      # burst that caused the incident.
      avail=$(df --output=avail -B1 / | tail -n 1 | tr -d ' ')
      human=$(numfmt --to=iec "$avail")

      # Stops a writer and remembers that it did, so the resume path never
      # starts a unit that was already down for its own reasons.
      stop_unit() {
        unit=$1
        if ! systemctl cat "$unit" > /dev/null 2>&1; then
          echo "media-disk-guard: $unit is not installed, skipping"
          return 0
        fi
        if ! systemctl is-active --quiet "$unit"; then
          echo "media-disk-guard: $unit already inactive, leaving it alone"
          return 0
        fi
        if grep -qx "$unit" "$stopped" 2> /dev/null; then
          return 0
        fi
        # Only record what actually stopped. A unit left running must not be
        # remembered, or the resume path would report success for a writer that
        # this guard never took down.
        if systemctl stop "$unit"; then
          echo "$unit" >> "$stopped"
        else
          echo "media-disk-guard: failed to stop $unit" >&2
        fi
      }

      # A writer that did not come back is still down, so it stays on the stopped
      # list and $tripped stays set: the next pass retries it instead of logging
      # a recovery that never happened.
      resume_units() {
        failed=""
        while IFS= read -r unit; do
          [ -n "$unit" ] || continue
          if ! systemctl start "$unit"; then
            echo "media-disk-guard: failed to start $unit" >&2
            failed="$failed $unit"
          fi
        done < "$stopped"

        if [ -n "$failed" ]; then
          : > "$stopped"
          for unit in $failed; do
            echo "$unit" >> "$stopped"
          done
          logger -p user.crit "media-disk-guard: root has $human free, failed to restart:$failed"
          return 0
        fi

        rm -f "$stopped" "$tripped"
        logger -p user.crit "media-disk-guard: root has $human free, restarting the units it stopped"
      }

      if [ "$avail" -lt ${toString lowBytes} ]; then
        # The stopped list is created here so the resume path always has a file
        # to read, even when every writer was already down.
        touch "$tripped" "$stopped"
        logger -p user.crit "media-disk-guard: root has only $human free, stopping media writers"

        for unit in ${pkgs.lib.concatStringsSep " " (map (u: "\"${u}\"") writerUnits)}; do
          stop_unit "$unit"
        done

        # One immediate attempt to drain staging. --no-block because the mover
        # is a long oneshot and this guard must not wait behind it.
        systemctl start --no-block media-mover.service \
          || echo "media-disk-guard: failed to queue media-mover.service" >&2

        if [ "$avail" -lt ${toString critBytes} ]; then
          logger -p user.crit "media-disk-guard: root has only $human free, below the critical floor"
          ${lib.concatMapStringsSep "\n          " (u: ''stop_unit "${u}"'') critUnits}
        fi

        exit 0
      fi

      if [ -e "$tripped" ] && [ "$avail" -gt ${toString resumeBytes} ]; then
        resume_units
      fi
    '';
  };
in {
  systemd = {
    # Generic failure logger. systemd starts this for any unit whose OnFailure
    # names it, so a crashed timer job leaves a critical line in the journal
    # instead of failing silently. %i is the instance, i.e. the failed unit.
    services = {
      "alert@" = {
        description = "Record a critical journal alert for failed unit %i";
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/logger -p user.crit \"unit %i failed\"";
        };
      };

      dns-watchdog = {
        description = "Check that the media backend host resolves";
        after = ["network-online.target"];
        wants = ["network-online.target"];
        unitConfig.OnFailure = ["alert@%n.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe dnsWatchdog;
          SyslogIdentifier = "dns-watchdog";
        };
      };

      media-disk-guard = {
        description = "Stop media writers before the root filesystem fills";
        unitConfig.OnFailure = ["alert@%n.service"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = lib.getExe mediaDiskGuard;
          SyslogIdentifier = "media-disk-guard";
        };
      };
    };

    timers = {
      dns-watchdog = {
        description = "Minutely DNS check for apis.uloz.to";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "1min";
          OnUnitActiveSec = "1min";
          AccuracySec = "15s";
        };
      };

      media-disk-guard = {
        description = "Check root filesystem free space every two minutes";
        wantedBy = ["timers.target"];
        timerConfig = {
          OnBootSec = "2min";
          OnUnitActiveSec = "2min";
          AccuracySec = "15s";
        };
      };
    };

    # The guard keeps its trip state here. /run so a reboot clears it: after a
    # reboot the guard re-evaluates from scratch rather than trusting state
    # from the previous boot.
    tmpfiles.rules = [
      "d /run/media-disk-guard 0755 root root -"
    ];
  };
}
