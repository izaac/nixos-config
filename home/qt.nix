{ pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "adwaita";
    style.name = "adwaita-dark";
  };

  # Ensure GTK apps (Libadwaita, etc.) use dark theme
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}