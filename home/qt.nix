{ pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze";
  };

  gtk = {
    enable = true;
    theme = {
      name = "Breeze-Dark";
      package = pkgs.kdePackages.breeze-gtk;
    };
    iconTheme = {
      name = "breeze-dark";
      package = pkgs.kdePackages.breeze-icons;
    };
    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
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