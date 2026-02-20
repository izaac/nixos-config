{ pkgs, ... }:

let
  catppuccin-papirus = pkgs.catppuccin-papirus-folders.override {
    flavor = "mocha";
    accent = "mauve";
  };
  catppuccin-gtk-overridden = pkgs.catppuccin-gtk.override {
    accents = [ "mauve" ];
    size = "standard";
    tweaks = [ "rimless" ];
    variant = "mocha";
  };
in
{
  catppuccin.enable = true;
  catppuccin.flavor = "mocha";
  catppuccin.accent = "mauve";

  # Enable specific integrations
  catppuccin.cursors.enable = true;

  home.packages = with pkgs; [
    catppuccin-papirus
    gnome-themes-extra
    gnomeExtensions.user-themes
    gnomeExtensions.appindicator
    gnomeExtensions.blur-my-shell
    gnomeExtensions.just-perfection
    gnomeExtensions.dash-to-dock
    gnomeExtensions.paperwm
  ];

  gtk = {
    enable = true;
    theme = {
      name = "catppuccin-mocha-mauve-standard";
      package = catppuccin-gtk-overridden;
    };
  };

  # Theme Libadwaita
  home.sessionVariables.GTK_THEME = "catppuccin-mocha-mauve-standard";

  # GTK 4 settings
  xdg.configFile."gtk-4.0/gtk.css".source = "${catppuccin-gtk-overridden}/share/themes/catppuccin-mocha-mauve-standard/gtk-4.0/gtk.css";
  xdg.configFile."gtk-4.0/gtk-dark.css".source = "${catppuccin-gtk-overridden}/share/themes/catppuccin-mocha-mauve-standard/gtk-4.0/gtk-dark.css";
  xdg.configFile."gtk-4.0/assets".source = "${catppuccin-gtk-overridden}/share/themes/catppuccin-mocha-mauve-standard/gtk-4.0/assets";

  dconf.settings = {
    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    
    # GNOME Shell theme (requires User Themes extension)
    "org/gnome/shell/extensions/user-theme" = {
      name = "catppuccin-mocha-mauve-standard";
    };

    "org/gnome/shell" = {
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "blur-my-shell@aunetx"
        "just-perfection-desktop@just-perfection"
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "paperwm@paperwm.github.com"
      ];
    };
  };
}
