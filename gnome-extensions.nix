{ pkgs, lib, ... }:

{
  # 1. Install the Extensions
  home.packages = with pkgs.gnomeExtensions; [
    appindicator         # Tray icons (Steam, Discord, etc.)
    dash-to-dock         # A proper dock
    clipboard-indicator  # QA Requirement: Clipboard history
    caffeine             # Prevent sleep
    blur-my-shell        # Aesthetics
    vitals               # System Monitor
  ];

  # 2. Configure them
  dconf.settings = {
    # Enable them automatically
    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "appindicatorsupport@rgcjonas.gmail.com"
        "dash-to-dock@micxgx.gmail.com"
        "clipboard-indicator@tudmotu.com"
        "caffeine@patapon.info"
        "blur-my-shell@aunetx"
        "vitals@corecoding.com"
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

    # Clipboard History (50 items)
    "org/gnome/shell/extensions/clipboard-indicator" = {
      history-size = 50;
      display-mode = 0; 
    };

    # System Monitor
    "org/gnome/shell/extensions/vitals" = {
      update-time = 5;
      show-temperature = true;
      show-memory = true;
    };
  };
}
