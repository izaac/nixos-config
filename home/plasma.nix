{ pkgs, ... }:

{
  programs.plasma = {
    enable = true;
    
    shortcuts = {
      "kwin" = {
        "Window Close" = "Meta+Q";
        "Window Maximize" = "Meta+M";
        "Window Fullscreen" = "Meta+F";
        "Window Operations Menu" = "Alt+F3";
        
        # Desktop Switching
        "Switch to Desktop 1" = "Meta+1";
        "Switch to Desktop 2" = "Meta+2";
        "Switch to Desktop 3" = "Meta+3";
        "Switch to Desktop 4" = "Meta+4";
        "Switch to Desktop 5" = "Meta+5";
        "Switch to Desktop 6" = "Meta+6";
        "Switch to Desktop 7" = "Meta+7";
        "Switch to Desktop 8" = "Meta+8";
        "Switch to Desktop 9" = "Meta+9";
        
        # Moving Windows to Desktops
        "Window to Desktop 1" = "Meta+Shift+1";
        "Window to Desktop 2" = "Meta+Shift+2";
        "Window to Desktop 3" = "Meta+Shift+3";
        "Window to Desktop 4" = "Meta+Shift+4";
        "Window to Desktop 5" = "Meta+Shift+5";
        "Window to Desktop 6" = "Meta+Shift+6";
        "Window to Desktop 7" = "Meta+Shift+7";
        "Window to Desktop 8" = "Meta+Shift+8";
        "Window to Desktop 9" = "Meta+Shift+9";
        
        # Focus / Movement (Tiling-like)
        "Switch Window Left" = "Meta+Left";
        "Switch Window Right" = "Meta+Right";
        "Switch Window Up" = "Meta+Up";
        "Switch Window Down" = "Meta+Down";

        # Disable conflicting defaults
        "Window Quick Tile Left" = "none";
        "Window Quick Tile Right" = "none";
        "Window Quick Tile Top" = "none";
        "Window Quick Tile Bottom" = "none";
        "Window Minimize" = "none";
        "Window Restore" = "none";

        # Relative Desktop Switching
        "Switch One Desktop to the Left" = "Meta+Ctrl+Left";
        "Switch One Desktop to the Right" = "Meta+Ctrl+Right";
        "Switch One Desktop Up" = "Meta+Ctrl+Up";
        "Switch One Desktop Down" = "Meta+Ctrl+Down";

        "Window One Desktop to the Left" = "Meta+Shift+Left";
        "Window One Desktop to the Right" = "Meta+Shift+Right";
        "Window One Desktop Up" = "Meta+Shift+Up";
        "Window One Desktop Down" = "Meta+Shift+Down";

        # Overview / Workspaces
        "Overview" = "Meta+Tab";
      };

      "org.kde.krunner.desktop" = {
        "_launch" = "Meta+Space";
      };

      "services/org.kde.dolphin.desktop" = {
        "_launch" = "Meta+E";
      };

      "ksmserver" = {
        "Lock Session" = "Meta+L";
      };
    };

    hotkeys.commands = {
      "launch-kitty" = {
        name = "Launch Kitty";
        key = "Meta+Return";
        command = "kitty";
      };
    };

    kwin = {
      virtualDesktops = {
        number = 9;
        rows = 3;
      };
    };
    
    # Optional: Configure some workspace settings to feel more like a WM
    workspace = {
      clickItemTo = "select"; # Single click to select, double click to open (more standard)
      lookAndFeel = "org.kde.breezedark.desktop";
      colorScheme = "BreezeDark";
      cursor.theme = "Breeze_Snow";
    };
  };
}
