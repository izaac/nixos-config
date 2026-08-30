{
  pkgs,
  userConfig,
  ...
}: {
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

  services.openssh = {
    enable = true;
    openFirewall = true;
    settings = {
      PermitRootLogin = "prohibit-password";
      PasswordAuthentication = true;
    };
  };

  users.users.${userConfig.username} = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager"];
    initialHashedPassword = "";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVatwgVrpfaElZ8yZjQqx9irakwJ6xdgE14P8nuPaja izaac@ninja"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKReCEJbKJZa0tS2D9owU5+YdXbl1pKpiRBOPlKGbQFh izaac@mac"
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJVatwgVrpfaElZ8yZjQqx9irakwJ6xdgE14P8nuPaja izaac@ninja"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKReCEJbKJZa0tS2D9owU5+YdXbl1pKpiRBOPlKGbQFh izaac@mac"
  ];

  security.sudo-rs.wheelNeedsPassword = false;

  environment.systemPackages = with pkgs; [
    git
    neovim
    usbutils
    pciutils
    parted
    cryptsetup
    disko
  ];

  system.stateVersion = "25.11";
}
