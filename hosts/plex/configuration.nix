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

  # Plex's butler maintenance window, 24h clock. Matches Plex's own default of
  # 02:00 to 05:00: the box is idle then, and the overnight load has been cut
  # substantially by the analysis settings below. Pinned explicitly rather than
  # left to Plex's default so the window is visible and version controlled.
  butlerStartHour = 2;
  butlerEndHour = 5;

  # Analysis tasks, all of which read file *content* over the network mount and
  # so are far more expensive here than on a local disk. Values are Plex's
  # "behavior" enum: never | scheduled | asap.
  #
  # `never` for the three that produce nothing on this server: there is no
  # music library (loudness, sonic) and no DVR tuner (ad markers). Preview
  # thumbnails are also off, which is Plex's own default; they read every file
  # end to end and store the images in the database. Plex's docs warn against
  # enabling them on a large existing library for exactly this reason.
  #
  # `scheduled` for the rest, so they run inside the butler window instead of
  # firing on import. Skip Intro, Skip Credits and chapter thumbnails all keep
  # working, they are just deferred.
  analysisBehavior = {
    GenerateBIFBehavior = "never";
    LoudnessAnalysisBehavior = "never";
    MusicAnalysisBehavior = "never";
    GenerateAdMarkerBehavior = "never";
    GenerateChapterThumbBehavior = "scheduled";
    GenerateIntroMarkerBehavior = "scheduled";
    GenerateCreditsMarkerBehavior = "scheduled";
  };

  # Transcoding. This host almost only serves the LAN. The library is entirely
  # 1080p or lower (sampled 120 items: nothing above 1920 wide) and QuickSync
  # encodes 1080p h264 at roughly 6x realtime here, so a playback transcode is
  # a bounded, on-demand load rather than a threat.
  #
  # Video transcoding is deliberately allowed. It was disabled for a while on
  # the assumption that transcodes were implicated in the overnight hangs, but
  # those turned out to be unattended butler analysis walking the whole library
  # for hours, which is a different shape of load entirely and is now off.
  #
  # The practical reason to allow it is subtitles. Plex has no "transcode only
  # for subtitles" option, and burning in a subtitle requires a full video
  # transcode. The library carries `ass` and `pgs` (bitmap) tracks that many
  # clients cannot render; with transcoding refused those subtitles simply
  # never appear.
  #
  # TranscoderVideoResolutionLimit caps output at 1080p. Nothing in the library
  # exceeds that today, so it changes nothing now and prevents a future 4K file
  # from starting a transcode this box cannot sustain.
  #
  # TranscoderQuality stays at Plex's default of 0 (automatic). LAN bitrate
  # limits are deliberately left unset, since a quality cap is a common way to
  # force transcodes on otherwise direct-playable files.
  transcoderSettings = {
    TranscoderCanOnlyRemuxVideo = "0";
    TranscoderVideoResolutionLimit = "1920x1080";
    TranscoderQuality = "0";

    # Tone mapping now actually applies, since it is the transcoder that does
    # it: HDR sources will not look washed out on an SDR client.
    TranscoderToneMapping = "1";

    # QuickSync does the work instead of the CPU. Without these the same
    # transcode would be software and would not keep up.
    HardwareAcceleratedCodecs = "1";
    HardwareAcceleratedEncoders = "1";
  };

  # Individual butler tasks, on ("1") or off ("0"). These are the Scheduled
  # Tasks checkboxes in the UI, separate from the analysis behaviours above.
  #
  # The three disabled ones each walk the whole library reading file content
  # over the network. DeepMediaAnalysis is the task that was running during the
  # 2026-09-06 13:39 hang, working through a backlog thousands of items deep.
  # UpgradeMediaAnalysis repeats that whole pass whenever Plex bumps its
  # analysis version, and EPG guide refresh does nothing without a tuner.
  #
  # Everything left enabled is local and cheap: database backup and optimise,
  # bundle and cache cleanup, blob garbage collection, and metadata refresh.
  # RefreshLibraries stays off, which is also Plex's default; scanning is
  # driven by ScheduledLibraryUpdateInterval instead.
  butlerTasks = {
    ButlerTaskDeepMediaAnalysis = "0";
    ButlerTaskUpgradeMediaAnalysis = "0";
    ButlerTaskRefreshEpgGuides = "0";

    ButlerTaskBackupDatabase = "1";
    ButlerTaskOptimizeDatabase = "1";
    ButlerTaskCleanOldBundles = "1";
    ButlerTaskCleanOldCacheFiles = "1";
    ButlerTaskGarbageCollectBlobs = "1";
    ButlerTaskRefreshLocalMedia = "1";
    ButlerTaskRefreshPeriodicMetadata = "1";
    ButlerTaskRefreshLibraries = "0";
  };

  # Seconds between library scans. Plex cannot get change notifications from a
  # network mount, so periodic scanning is how new media is discovered. Hourly
  # was re-queueing analysis work far more often than the library actually
  # changes; 6h still finds new files the same day.
  scheduledLibraryUpdateInterval = 6 * 60 * 60;
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

  # Recurring hangs, seven so far, under load and at idle. Nothing reaches the
  # journal, but the kernel dumps to EFI pstore and systemd-pstore archives it
  # to /var/lib/systemd/pstore. Those dumps show control-flow corruption in a
  # different kernel function every time, which points at the hardware; the RAM
  # is non-ECC so nothing else would catch it. See docs/plex.md.
  #
  # mem_profiling: the first hang oopsed in the allocation profiling
  # instrumentation, a debugging aid with no use here.
  #
  # intel_idle.max_cstate=4 blocks C10 and keeps the rest. Do not lower it: on
  # this CPU max_cstate=1 leaves no usable state at all ("max_cstate 1 reached",
  # POLL the only entry in sysfs), and busy-looping raised the idle package
  # temperature from 50 to 70 C. Heat shortens DRAM retention, so that trade
  # works against the actual fault. The index counts the driver's own table
  # (C1, C1E, C6, C8, C10 on Gracemont), so recheck after a kernel upgrade:
  #
  #   grep . /sys/devices/system/cpu/cpu0/cpuidle/state*/name
  boot.kernelParams = [
    "sysctl.vm.mem_profiling=0"
    "intel_idle.max_cstate=4"
  ];

  # These four overrides existed to survive 8G. On 16G the box idles at 1.3G
  # used with zero memory pressure, so they are no longer about capacity. Two
  # of them are still right for other reasons, noted at each; the zram split
  # and the swapfile are kept as cheap conservative defaults for a server.
  zramSwap.memoryPercent = lib.mkForce 50;

  swapDevices = [
    {
      device = "/var/swapfile";
      size = 8192; # MiB
    }
  ];

  # Recovery. The sysctls cover a kernel alive enough to panic; the default of
  # 0 halts forever, which cost 6.5h and 3.4h.
  boot.kernel.sysctl = {
    "kernel.panic" = 30;
    "kernel.panic_on_oops" = 1;
    "kernel.hardlockup_panic" = 1;

    # The shared 180 is desktop tuning that assumes swap is zram and therefore
    # fast. This host also has a swapfile on the same SATA SSD that serves
    # media, so evicting anonymous pages there costs playback latency.
    "vm.swappiness" = lib.mkForce 60;

    # Percentages of RAM, so more RAM means a bigger writeback burst, not a
    # smaller one: the shared 10/5 is 1.6G/800M of dirty pages on 16G, flushed
    # through the one SATA SSD that rclone is already writing its cache to.
    # This is about the disk, not the memory, and did not stop mattering when
    # the DIMM was replaced.
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
  # /tmp/plex-transcode, and because the unit runs with PrivateTmp=true that was
  # a systemd-provided tmpfs, i.e. RAM, on a host with 8G of it. Pointing it at
  # the data directory puts transcode scratch on disk instead. See docs/plex.md.
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

      # Butler maintenance window. Plex falls back to 02:00-05:00 when these
      # keys are absent; pinned so the window is explicit rather than implied.
      set_pref ButlerStartHour "${toString butlerStartHour}"
      set_pref ButlerEndHour "${toString butlerEndHour}"

      # Library scan interval, in seconds.
      set_pref ScheduledLibraryUpdateInterval "${toString scheduledLibraryUpdateInterval}"

      # Analysis behaviours: keep the expensive ones off or deferred.
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: ''set_pref ${k} "${v}"'') analysisBehavior
      )}

      # Individual butler tasks.
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: ''set_pref ${k} "${v}"'') butlerTasks
      )}

      # Transcoding: never touch the video stream.
      ${lib.concatStringsSep "\n" (
        lib.mapAttrsToList (k: v: ''set_pref ${k} "${v}"'') transcoderSettings
      )}
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
