{
  pkgs,
  modulesPath,
  userConfig,
  ...
}: {
  imports = [(modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix")];

  networking = {
    hostName = "canoe";
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  hardware.enableRedistributableFirmware = true;

  # Adopt 26.11 default early; ISO doesn't use ZFS root.
  boot.zfs.forceImportRoot = false;

  users.users.${userConfig.username} = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
  };

  environment.systemPackages = with pkgs; [
    helix
    git
    neovim
    usbutils
    pciutils
    parted
    cryptsetup
  ];

  system.stateVersion = "25.11";
}
