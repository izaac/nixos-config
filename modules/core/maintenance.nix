{
  config,
  pkgs,
  lib,
  userConfig,
  ...
}:
with lib; let
  cfg = config.mySystem.core.maintenance;
in {
  options.mySystem.core.maintenance = {
    enable = mkEnableOption "System maintenance tools and scripts";
  };

  config = mkIf cfg.enable {
    programs.nh = {
      enable = true;
      clean.enable = true;
      clean.extraArgs = "--keep 10 --keep-since 7d";
      flake = userConfig.dotfilesDir;
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
      wget
      curl
      tree
      file
      iotop
      iftop
      strace
      lsof
      lm_sensors
      ethtool
      dnsutils

      # TTY rescue tools (root accessible)
      neovim
      git
      tmux
      ripgrep
      fd
      htop
      btop
    ];

    nixpkgs.config.permittedInsecurePackages = [
      "ventoy-full-gtk-1.1.10"
      "ventoy-gtk3-1.1.10"
      "ventoy-bin-1.1.10"
    ];
  };
}
