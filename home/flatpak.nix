_: {
  # Declarative user-level Flatpak configuration via nix-flatpak.
  # Note: services.flatpak.enable = true must be set in the system configuration.

  services.flatpak = {
    enable = true;
    remotes = [
      {
        name = "flathub";
        location = "https://dl.flathub.org/repo/flathub.flatpakrepo";
      }
    ];
    packages = [
      # Add user-level flatpaks here, e.g.:
      # "com.spotify.Client"
      # "com.discordapp.Discord"
    ];
    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };
  };
}
