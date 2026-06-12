{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}: let
  cfg = config.mySystem.core.maintenance;
in {
  options.mySystem.core.maintenance = {
    enable = lib.mkEnableOption "System maintenance tools and scripts";
  };

  config = lib.mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep 10 --keep-since 7d";
      flake = userConfig.dotfilesDirFor pkgs;
    };

    environment.systemPackages = with pkgs; [
      gparted
      exfatprogs
      atop # For historical system monitoring

      # System Diagnostics & Hardware Probes
      usbutils
      pciutils
      lshw
      dmidecode
      smartmontools
      nvme-cli
      curl
      file
      iotop
      iftop
      strace
      lsof
      lm_sensors
      ethtool
      dnsutils

      # TTY rescue tools (root accessible)
      vim
      git
      tmux
      ripgrep
      fd
      btop
    ];
  };
}
