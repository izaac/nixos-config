{ pkgs, config, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  # Modern GTK apps (Libadwaita, etc.) look at dconf for color scheme
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