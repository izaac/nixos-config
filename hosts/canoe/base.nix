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
      userConfig.sshKeys.ninja
      userConfig.sshKeys.mac
    ];
  };

  users.users.root.openssh.authorizedKeys.keys = [
    userConfig.sshKeys.ninja
    userConfig.sshKeys.mac
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
