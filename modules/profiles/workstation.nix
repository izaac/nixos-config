# Shared baseline for the interactive hosts (ninja, windy). Everything is
# mkDefault so hosts override freely. The canoe ISOs do NOT import this.
{lib, ...}: {
  mySystem = {
    desktop.enable = lib.mkDefault true;
    gaming.enable = lib.mkDefault true;
    core = {
      audio.enable = lib.mkDefault true;
      bluetooth.enable = lib.mkDefault true;
      codecs.enable = lib.mkDefault true;
      virtualization.enable = lib.mkDefault true;
      nfs.enable = lib.mkDefault false;
      maintenance.enable = lib.mkDefault true;
      performance.enable = lib.mkDefault true;
      sops.enable = lib.mkDefault true;
      system.enable = lib.mkDefault true;
      usb-fixes.enable = lib.mkDefault true;
      user.enable = lib.mkDefault true;
      theme.enable = lib.mkDefault true;
      home-manager.enable = lib.mkDefault true;
      nix-ld.enable = lib.mkDefault true;
      yubikey.enable = lib.mkDefault true;
      "sudo-readonly".enable = lib.mkDefault true;
      "known-hosts".enable = lib.mkDefault true;
    };
  };

  boot = {
    loader = {
      systemd-boot = {
        enable = lib.mkDefault true;
        configurationLimit = lib.mkDefault 10;
      };
      efi.canTouchEfiVariables = lib.mkDefault true;
    };
    supportedFilesystems = ["exfat"];
    tmp.useTmpfs = lib.mkDefault true;
  };

  # System-level Flatpak (required by the nix-flatpak home module).
  services.flatpak.enable = lib.mkDefault true;

  hardware.enableAllFirmware = lib.mkDefault true;

  # No WWAN hardware in either machine.
  systemd.services.ModemManager.enable = lib.mkDefault false;
}
