# plex: Intel N100 Mini PC (Headless Plex media server + home server).
{
  config,
  lib,
  pkgs,
  inputs,
  userConfig,
  ...
}: let
  # Transcode scratch, deliberately on disk rather than under /tmp. See the
  # plex-preferences service below for why.
  transcodeDir = "${config.services.plex.dataDir}/Transcode";

  # Plex's butler maintenance window, 24h clock. Plex's own default is 02:00 to
  # 05:00; this is shifted into the afternoon while the overnight hangs are
  # being diagnosed, so the load lands when someone is awake to watch it.
  butlerStartHour = 12;
  butlerEndHour = 15;
in {
  imports = [
    ../common.nix
    ./disko.nix
    ./ssh.nix
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  networking = {
    hostName = "plex";
    wireless.enable = false;
  };

  # Passwordless sudo matching ninja and windy
  security.sudo-rs.wheelNeedsPassword = false;

  # Lock the local password. Access is ssh key only and sudo is passwordless,
  # so no console login path remains. Applied on every switch, overriding the
  # password set by hand during installation (users.mutableUsers stays on).
  users.users.${userConfig.username}.hashedPassword = "!";

  # Blacklist the RTL8822CE WiFi driver to keep a pure wired headless setup
  boot.blacklistedKernelModules = ["rtw88_8822ce"];

  # Overnight hangs at 03:31 (08-31), 03:32 (09-03), 04:14 (09-05).
  #
  # The first oopsed in __alloc_tagging_slab_alloc_hook, the memory allocation
  # profiling instrumentation. It is a debugging aid with no use here, so the
  # code path is switched off.
  boot.kernelParams = ["sysctl.vm.mem_profiling=0"];

  # The later two logged nothing and hit while idle, so they are a different,
  # still unexplained fault. Suspected deep C-state wedge (C10 is ~87% of idle
  # residency, BIOS 100E_P is stock), left unmasked so it can recur and be
  # identified.
  #
  # Recover automatically instead. The sysctls cover a kernel alive enough to
  # panic (the default of 0 halts forever, which cost 6.5h and 3.4h); the
  # watchdog covers a wedged CPU, which only silicon can reset.
  # 8G of RAM, unlike ninja. The shared performance module tunes for a desktop
  # with memory to spare, which is actively harmful here: Plex's overnight
  # butler work (see docs/plex.md) transcodes into tmpfs while rclone streams
  # the media mount through its VFS cache, and every escape valve on this box
  # was also RAM.
  #
  # zram is compressed swap living *in* RAM, so at 100% it cannot relieve real
  # pressure, it only trades uncompressed pages for compressed ones. Halved,
  # and paired with a genuine on-disk swapfile so the kernel has somewhere to
  # actually evict to. swappiness drops from the desktop's 180 because
  # thrashing pages into RAM-backed swap is what makes the stall worse.
  zramSwap.memoryPercent = lib.mkForce 50;

  swapDevices = [
    {
      device = "/var/swapfile";
      size = 8192; # MiB, matched to RAM
    }
  ];

  boot.kernel.sysctl = {
    "kernel.panic" = 30;
    "kernel.panic_on_oops" = 1;
    "kernel.hardlockup_panic" = 1;

    # Prefer reclaiming page cache over swapping anonymous pages.
    "vm.swappiness" = lib.mkForce 60;

    # Percentages of RAM: the shared 10/5 is 750M/375M of dirty pages on 8G,
    # which is a long stall to flush through one SATA SSD while rclone is
    # writing its cache. Lower caps keep writeback incremental.
    "vm.dirty_ratio" = lib.mkForce 5;
    "vm.dirty_background_ratio" = lib.mkForce 2;
  };

  # /dev/watchdog is intel_oc_wdt. systemd pings at half the interval, so 60s
  # tolerates a 30s stall before the board resets itself.
  systemd.settings.Manager.RuntimeWatchdogSec = "60s";

  # Hardware acceleration for Intel N100 QuickSync transcoding
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
      vpl-gpu-rt
    ];
  };

  # Host overrides: headless server profile
  mySystem = {
    desktop.enable = false;
    gaming.enable = false;
    core = {
      tailscale.enable = true;
      virtualization.enable = false;
      printing.enable = false;
      sops.enable = false;
    };
  };

  # Disable flatpak on headless server
  services.flatpak.enable = false;

  # Server duty: make sleep impossible instead of managing inhibitor locks.
  # Background jobs no longer need polkit-based sleep inhibition.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "no";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # Enable Plex Media Server
  #
  # Pinned to izaac/nix-packages, which tracks the newest build on plex.tv.
  # nixpkgs trails upstream by weeks, and this box is internet-facing through
  # plex.tv relay, so server-side security fixes should not wait on a channel
  # bump. Drop the override once nixpkgs catches up and stays current.
  services.plex = {
    enable = true;
    openFirewall = true;
    user = userConfig.username;
    package = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system}.plex;
  };

  # Disk management daemon
  services.udisks2.enable = true;

  # Allow wheel users to manage disks with udisks2 without password prompts (needed for headless/SSH)
  security.polkit.extraConfig = ''
    polkit.addRule(function(action, subject) {
      if (action.id.indexOf("org.freedesktop.udisks2.") === 0 && subject.isInGroup("wheel")) {
        return polkit.Result.YES;
      }
    });
  '';

  # Fuse support for rclone mounts
  programs.fuse.userAllowOther = true;

  # Create mount directory for rclone media (/srv/media)
  systemd.tmpfiles.rules = [
    "d /srv/media 0775 ${userConfig.username} users -"
    "d ${transcodeDir} 0755 ${config.services.plex.user} ${config.services.plex.group} -"
  ];

  # Plex settings live in a Preferences.xml that Plex itself rewrites (tokens,
  # machine identifier, anything changed in the UI), so the file cannot be a
  # store symlink. Instead, stamp only the keys that must not drift, before
  # each start. Everything else is left to Plex.
  #
  # TranscoderTempDirectory is the important one. It defaulted to
  # /tmp/plex-transcode, and because the unit runs with PrivateTmp=true that
  # was a systemd-provided tmpfs, i.e. RAM, on a host with 8G of it. Overnight
  # butler transcodes (loudness analysis decodes audio out to FLAC, which is
  # lossless and therefore larger than the source) wrote into that tmpfs while
  # rclone held 64M buffers and flushed its VFS cache to disk. tmpfs pages can
  # only be evicted to swap, and swap was zram, which is also RAM. The result
  # was a reclaim stall that took the whole box down with no trace: journald
  # could not write, and the NMI watchdog stayed quiet because tasks were
  # blocked in D-state rather than spinning. Only the hardware watchdog
  # recovered it. Pointing this at the data directory puts transcode scratch on
  # the 123G of free disk instead.
  #
  # The old value also carried a trailing space, which is why it reads oddly in
  # any dump of the file.
  systemd.services.plex-preferences = {
    description = "Stamp declarative settings into Plex Preferences.xml";
    before = ["plex.service"];
    requiredBy = ["plex.service"];
    serviceConfig = {
      Type = "oneshot";
      User = config.services.plex.user;
      Group = config.services.plex.group;
    };
    script = let
      prefs = "${config.services.plex.dataDir}/Plex Media Server/Preferences.xml";
    in ''
      # First run: Plex has not created the file yet, so there is nothing to
      # stamp. Plex writes its own defaults and the next start will fix them up.
      if [ ! -f "${prefs}" ]; then
        echo "Preferences.xml not present yet, skipping"
        exit 0
      fi

      set_pref() {
        ${lib.getExe pkgs.xmlstarlet} edit --inplace \
          --insert "/Preferences[not(@$1)]" --type attr --name "$1" --value "$2" \
          --update "/Preferences/@$1" --value "$2" \
          "${prefs}"
      }

      # Transcode scratch on disk, not the PrivateTmp tmpfs.
      set_pref TranscoderTempDirectory "${transcodeDir}"

      # Butler maintenance window. Plex defaults to 02:00-05:00 when these keys
      # are absent, which is where every hang so far has landed. Held during
      # waking hours so the load is observable rather than discovered at
      # breakfast.
      set_pref ButlerStartHour "${toString butlerStartHour}"
      set_pref ButlerEndHour "${toString butlerEndHour}"
    '';
  };

  # Systemd service to auto-mount rclone ul-crypt drive on boot
  systemd.services.rclone-ul-crypt = {
    description = "Rclone mount for ul-crypt media drive";
    after = ["network-online.target"];
    wants = ["network-online.target"];
    wantedBy = ["multi-user.target"];
    path = [
      "/run/wrappers"
      pkgs.fuse3
      pkgs.rclone
    ];
    serviceConfig = {
      Type = "notify";
      ExecStart = let
        flags = [
          "--config /home/${userConfig.username}/.config/rclone/rclone.conf"
          "--allow-other"

          # Content cache. Sized to leave room on the 233G root; entries also
          # expire after a week so a one-off binge does not pin the cache.
          "--vfs-cache-mode full"
          "--vfs-cache-max-size 50G"
          "--vfs-cache-max-age 168h"

          # Directory listings. The default is 5 minutes, which meant rclone
          # re-fetched the movies listing (6300+ entries) from the provider over the
          # network every 5 minutes, and continuously during a library scan.
          # Matches the 72h used for the Google Drive mount in home/rclone.nix.
          #
          # The backend reports ChangeNotify=false, so --poll-interval cannot
          # pick up changes made outside the mount. Writes through /srv/media
          # invalidate the cache immediately; uploads made straight to the
          # remote (`rclone move ... ul-crypt:movies/`) do not, so those need
          # `rclone rc vfs/refresh dir=movies` afterwards. See docs/plex.md.
          "--dir-cache-time 72h"

          # FUSE attribute cache, default 1s. Plex stats every file it scans,
          # and each miss is a round trip. Kept well under dir-cache-time.
          "--attr-timeout 1h"

          # Sequential streaming: start small so playback begins quickly, then
          # ramp up rather than issuing many small ranged reads.
          "--buffer-size 64M"
          "--vfs-read-chunk-size 32M"
          "--vfs-read-chunk-size-limit 2G"

          # Loopback-only control socket, so vfs/refresh can be triggered after
          # an out-of-band upload. Not reachable off the box; the firewall does
          # not open this port either.
          "--rc"
          "--rc-addr 127.0.0.1:5572"
          "--rc-no-auth"
        ];
      in "${pkgs.rclone}/bin/rclone mount ul-crypt: /srv/media ${lib.concatStringsSep " " flags}";
      ExecStop = "/run/current-system/sw/bin/umount -l /srv/media";
      Restart = "on-failure";
      RestartSec = "10s";
      User = userConfig.username;
      Group = "users";
    };
  };

  environment.systemPackages = with pkgs; [
    ffmpeg
    pciutils
    usbutils
    htop
    btop
    rclone
    fuse3
  ];
}
