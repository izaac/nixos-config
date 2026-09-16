# Shared baseline for headless server hosts (e.g. plex).
# Sets conservative server defaults: no desktop, no gaming, no audio, no bluetooth,
# no codecs, no yubikey, no desktop usb quirks, no stylix desktop theming.
{lib, ...}: {
  mySystem = {
    core = {
      audio.enable = lib.mkDefault false;
      bluetooth.enable = lib.mkDefault false;
      codecs.enable = lib.mkDefault false;
      printing = {
        enable = lib.mkDefault false;
        networkPrinter.enable = lib.mkDefault false;
      };
      virtualization.enable = lib.mkDefault false;
      nfs.enable = lib.mkDefault false;
      maintenance.enable = lib.mkDefault true;
      performance.enable = lib.mkDefault true;
      sops.enable = lib.mkDefault false;
      system.enable = lib.mkDefault true;
      usb-fixes.enable = lib.mkDefault false;
      user.enable = lib.mkDefault true;
      theme.enable = lib.mkDefault false;
      home-manager.enable = lib.mkDefault true;
      nix-ld.enable = lib.mkDefault false;
      yubikey.enable = lib.mkDefault false;
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

  # Disable flatpak on headless server
  services.flatpak.enable = lib.mkDefault false;

  # Server duty: disable sleep/suspend
  systemd.sleep.settings.Sleep = {
    AllowSuspend = lib.mkDefault "no";
    AllowHibernation = lib.mkDefault "no";
    AllowHybridSleep = lib.mkDefault "no";
    AllowSuspendThenHibernate = lib.mkDefault "no";
  };

  # No WWAN hardware in servers.
  systemd.services.ModemManager.enable = lib.mkDefault false;
}
