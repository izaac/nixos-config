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
  security.sudo.wheelNeedsPassword = false;

  # Blacklist WiFi drivers to keep pure wired headless setup
  boot.blacklistedKernelModules = [
    "iwlwifi"
    "iwlmvm"
  ];

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

  # Enable Plex Media Server
  services.plex = {
    enable = true;
    openFirewall = true;
    user = userConfig.username;
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
      ExecStart = "${pkgs.rclone}/bin/rclone mount ul-crypt: /srv/media --config /home/${userConfig.username}/.config/rclone/rclone.conf --allow-other --vfs-cache-mode full --vfs-cache-max-size 50G --buffer-size 64M";
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
