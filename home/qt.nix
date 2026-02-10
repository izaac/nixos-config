{ pkgs, config, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "Breeze";
  };

  # Ensure GTK apps (Libadwaita, etc.) use dark theme for consistency in KDE
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };

  # Ensure GTK apps use dark theme in KDE/Wayland
  home.sessionVariables = {
    GTK_THEME = "Breeze-Dark";
  };
}