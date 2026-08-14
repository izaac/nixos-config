{
  lib,
  osConfig ? {},
  ...
}:
# Follow the system-level switch rather than naming hosts: the nix-flatpak home
# module needs services.flatpak on the host, and its weekly update timer is
# pointless where flatpak is not installed at all.
lib.mkIf (osConfig.services.flatpak.enable or false) {
  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}
