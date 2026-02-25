{ pkgs, userConfig, config, ... }:

{
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
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-full-gtk-1.1.07"
    "ventoy-gtk3-1.1.07"
  ];
}
