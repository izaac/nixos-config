{ pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "kvantum";
    style.name = "kvantum";
  };

  catppuccin.kvantum.enable = true;

  # Ensure GTK apps (Libadwaita, etc.) use dark theme
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
  };
}