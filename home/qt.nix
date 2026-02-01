{ pkgs, ... }:

{
  qt = {
    enable = true;
    platformTheme.name = "kde";
    style.name = "breeze-dark";
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

  # Plasma Configuration via home-manager (using plain config files for now)
  # Disabling animations and effects for raw speed
  home.file.".config/kwinrc".text = ''
    [org.kde.kdecoration2]
    ButtonsOnLeft=
    ButtonsOnRight=IAX
    CloseButtonOnLeft=false
    ThemeName=Breeze

    [Compositing]
    AnimationSpeedFactor=0
    LatencyPolicy=LowLatency
    
    [Effect-Slide]
    Duration=0

    [Effect-Fade]
    Duration=0
    
    [Effect-Scale]
    Duration=0
  '';
  
  home.file.".config/kdeglobals".text = ''
    [KDE]
    AnimationDurationFactor=0
    LookAndFeelPackage=org.kde.breezedark.desktop

    [General]
    ColorScheme=BreezeDark
    Name=Breeze Dark
    
    [Icons]
    Theme=breeze-dark

    [WM]
    activeBackground=49,54,59
    activeForeground=239,240,241
    inactiveBackground=42,46,50
    inactiveForeground=189,195,199

    [Colors:Window]
    BackgroundNormal=49,54,59
    ForegroundNormal=239,240,241
    
    [Colors:View]
    BackgroundNormal=35,38,41
    ForegroundNormal=239,240,241
    
    [Colors:Button]
    BackgroundNormal=49,54,59
    ForegroundNormal=239,240,241

    [Colors:Selection]
    BackgroundNormal=61,174,233
    ForegroundNormal=239,240,241
  '';
  
  home.file.".config/plasmarc".text = ''
    [Theme]
    name=breeze-dark
  '';

  # Ensure GTK apps use dark theme in KDE/Wayland
  home.sessionVariables = {
    GTK_THEME = "Breeze-Dark";
  };
}
