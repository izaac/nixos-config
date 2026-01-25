{ pkgs, lib, ... }:

{
  # 1. Install the Extensions
  home.packages = with pkgs.gnomeExtensions; [
    appindicator           # Tray icons (Steam, Discord, etc.)
    dash-to-dock           # Persistent dock
    clipboard-indicator    # QA history tool
    caffeine               # Prevent sleep toggle
    blur-my-shell          # Aesthetics
    vitals                 # System Monitor
    alphabetical-app-grid  # Automatically sorts your app grid
  ];

  # 2. Configure & Enable
  dconf.settings = {
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "dash-to-dock@micxgx.gmail.com"
        "clipboard-indicator@tudmotu.com"
        "caffeine@patapon.info"
        "blur-my-shell@aunetx"
        "vitals@corecoding.com"
        "AlphabeticalAppGrid@stuarthayhurst"
      ];
    };

    # Dock Settings
    "org/gnome/shell/extensions/dash-to-dock" = {
      dock-position = "BOTTOM";
      dock-fixed = false;      # Intelli-hide
      dash-max-icon-size = 48;
      background-opacity = 0.8;
      custom-theme-shrink = true;
    };

    # Clipboard Settings
    "org/gnome/shell/extensions/clipboard-indicator" = {
      history-size = 50;
      display-mode = 0; 
    };

    # System Monitor Settings
    "org/gnome/shell/extensions/vitals" = {
      update-time = 5;
      show-temperature = true;
      show-memory = true;
      show-cpu = true;
    };

    # Alphabetical App Grid Settings
    "org/gnome/shell/extensions/alphabetical-app-grid" = {
      sort-folders-first = true;
    };
  };
}
