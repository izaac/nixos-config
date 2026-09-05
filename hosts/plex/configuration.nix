# plex: Intel N100 Mini PC (Headless Plex media server + home server).
{
  pkgs,
  inputs,
  userConfig,
  ...
}: {
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
  boot.kernel.sysctl = {
    "kernel.panic" = 30;
    "kernel.panic_on_oops" = 1;
    "kernel.hardlockup_panic" = 1;
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

  # Fuse support for rclone mounts
  programs.fuse.userAllowOther = true;

  # Create mount directory for rclone media (/srv/media) and RAM transcode path (/tmp/plex-transcode)
  systemd.tmpfiles.rules = [
    "d /srv/media 0775 ${userConfig.username} users -"
    "d /tmp/plex-transcode 0775 ${userConfig.username} users -"
  ];

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
      ExecStart = "${pkgs.rclone}/bin/rclone mount ul-crypt: /srv/media --config /home/${userConfig.username}/.config/rclone/rclone.conf --allow-other --vfs-cache-mode full --vfs-cache-max-size 50G --vfs-cache-max-age 168h --buffer-size 64M";
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
