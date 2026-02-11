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
        
        # Moving Windows to Desktops
        "Window to Desktop 1" = "Meta+Shift+1";
        "Window to Desktop 2" = "Meta+Shift+2";
        "Window to Desktop 3" = "Meta+Shift+3";
        "Window to Desktop 4" = "Meta+Shift+4";
        
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
        "_launch" = "none";
      };

      "services/org.kde.dolphin.desktop" = {
        "_launch" = "Meta+E";
      };

      "ksmserver" = {
        "Lock Session" = "Meta+L";
      };

      "klipper" = {
        "clipboard_action" = "none";
      };
    };

    hotkeys.commands = {
      "launch-kitty" = {
        name = "Launch Kitty";
        key = "Meta+Return";
        command = "kitty";
      };
      "launch-fuzzel" = {
        name = "Launch Fuzzel";
        key = "Meta+Space";
        command = "fuzzel";
      };
    };

    kwin = {
      virtualDesktops = {
        number = 4;
        rows = 2;
        names = [ "Main" "Dev" "Web" "Media" ];
      };
    };

    session = {
      sessionRestore.restoreOpenApplicationsOnLogin = "startWithEmptySession";
    };

    configFile = {
      "krunnerrc"."Plugins"."breezeEnabled" = false;
      "krunnerrc"."Plugins"."fileEnabled" = false;
      "krunnerrc"."Plugins"."krunner_appstreamEnabled" = false;
      "krunnerrc"."Plugins"."krunner_bookmarksrunnerEnabled" = false;
      "krunnerrc"."Plugins"."krunner_calculatorEnabled" = false;
      "krunnerrc"."Plugins"."krunner_charrunnerEnabled" = false;
      "krunnerrc"."Plugins"."krunner_consoleEnabled" = false;
      "krunnerrc"."Plugins"."krunner_converterEnabled" = false;
      "krunnerrc"."Plugins"."krunner_datetimeEnabled" = false;
      "krunnerrc"."Plugins"."krunner_dictionaryEnabled" = false;
      "krunnerrc"."Plugins"."krunner_katesessionsEnabled" = false;
      "krunnerrc"."Plugins"."krunner_konsoleprofilesEnabled" = false;
      "krunnerrc"."Plugins"."krunner_killEnabled" = false;
      "krunnerrc"."Plugins"."krunner_locationsEnabled" = false;
      "krunnerrc"."Plugins"."krunner_placesrunnerEnabled" = false;
      "krunnerrc"."Plugins"."krunner_powerdevilEnabled" = false;
      "krunnerrc"."Plugins"."krunner_recentdocumentsEnabled" = false;
      "krunnerrc"."Plugins"."krunner_sessionsEnabled" = false; # System settings handles logout/etc
      "krunnerrc"."Plugins"."krunner_shellEnabled" = false;
      "krunnerrc"."Plugins"."krunner_spellcheckEnabled" = false;
      "krunnerrc"."Plugins"."krunner_systemdEnabled" = false;
      "krunnerrc"."Plugins"."krunner_webshortcutsEnabled" = false;
      "krunnerrc"."Plugins"."windowsEnabled" = false;
      "krunnerrc"."Plugins"."baloosearchEnabled" = false; # Files search
      
      "baloofilerc"."Basic Settings"."Indexing-Enabled" = false;

      # Keep ONLY these enabled:
      "krunnerrc"."Plugins"."krunner_servicesEnabled" = true; # Applications
      "krunnerrc"."Plugins"."krunner_systemsettingsEnabled" = true; # System Settings

      # ========================================
      # COMPOSITOR - GAMING OPTIMIZED
      # ========================================
      "kwinrc"."Compositing"."Backend" = "OpenGL";
      "kwinrc"."Compositing"."GLCore" = true;
      "kwinrc"."Compositing"."GLPlatformInterface" = "egl";
      "kwinrc"."Compositing"."LatencyPolicy" = "Low";
      "kwinrc"."Compositing"."MaxFPS" = 144;
      "kwinrc"."Compositing"."RefreshRate" = 144;
      "kwinrc"."Compositing"."AnimationSpeed" = 1;  # Fast animations (0=instant, 1=fast, 2=normal)

      # CRITICAL FOR GAMING - Bypass compositor in fullscreen games
      "kwinrc"."Compositing"."UnredirectFullscreen" = true;

      # Works WITH VRR for better frame pacing
      "kwinrc"."Compositing"."AllowTearing" = true;

      # ========================================
      # EFFECTS - DISABLED FOR SPEED
      # Steam overlay works without these
      # ========================================
      "kwinrc"."Plugins"."blurEnabled" = false;
      "kwinrc"."Plugins"."contrastEnabled" = false;
      "kwinrc"."Plugins"."dimscreenEnabled" = false;
      "kwinrc"."Plugins"."diminactiveEnabled" = false;
      "kwinrc"."Plugins"."fadeEnabled" = false;
      "kwinrc"."Plugins"."fadedesktopEnabled" = false;
      "kwinrc"."Plugins"."highlightwindowEnabled" = false;
      "kwinrc"."Plugins"."magiclampEnabled" = false;
      "kwinrc"."Plugins"."morphingpopupsEnabled" = false;
      "kwinrc"."Plugins"."scaleinEnabled" = false;
      "kwinrc"."Plugins"."slideEnabled" = false;
      "kwinrc"."Plugins"."slidingpopupsEnabled" = false;
      "kwinrc"."Plugins"."squashEnabled" = false;
      "kwinrc"."Plugins"."translucencyEnabled" = false;
      "kwinrc"."Plugins"."windowapertureEnabled" = false;
      "kwinrc"."Plugins"."zoomEnabled" = false;

      # Keep overview for Meta+Tab workspace switching
      "kwinrc"."Plugins"."overviewEnabled" = true;

      # ========================================
      # WINDOW MANAGEMENT - GAMING SAFE
      # ========================================
      "kwinrc"."Windows"."RollOverDesktops" = true;
      "kwinrc"."Windows"."DelayFocusInterval" = 0;
      "kwinrc"."Windows"."BorderlessMaximizedWindows" = true;

      "kwinrc"."Plugins"."logoutEffectEnabled" = false;
      "kwinrc"."Plugins"."screenedgeEnabled" = false;
      "kwinrc"."Windows"."ElectricBorderMaximize" = false;
      "kwinrc"."Windows"."ElectricBorderTiling" = false;
      "kwinrc"."Xwayland"."Scale" = 1;
      "kwinrc"."ScreenEdges"."Top" = 0;
      "kwinrc"."ScreenEdges"."Bottom" = 0;
      "kwinrc"."ScreenEdges"."Left" = 0;
      "kwinrc"."ScreenEdges"."Right" = 0;
      "kwinrc"."ScreenEdges"."TopLeft" = 0;
      "kwinrc"."ScreenEdges"."TopRight" = 0;
      "kwinrc"."ScreenEdges"."BottomLeft" = 0;
      "kwinrc"."ScreenEdges"."BottomRight" = 0;
      "kwinrc"."TouchEdges"."Top" = 0;
      "kwinrc"."TouchEdges"."Bottom" = 0;
      "kwinrc"."TouchEdges"."Left" = 0;
      "kwinrc"."TouchEdges"."Right" = 0;
      "kwinrc"."EdgeBarrier"."EdgeBarrier" = 0;
      "kwinrc"."EdgeBarrier"."CornerBarrier" = false;
      "kwinrc"."Effect-overview"."BorderActivate" = 9;
      "kwinrc"."Effect-overview"."TouchBorderActivate" = 0;
      "kwinrc"."Effect-presentwindows"."BorderActivate" = 0;
      "kwinrc"."Effect-presentwindows"."TouchBorderActivate" = 0;
      "kwinrc"."Effect-desktopgrid"."BorderActivate" = 0;
      "kwinrc"."Effect-desktopgrid"."TouchBorderActivate" = 0;
    };

    startup.startupScript."set_monitor_config" = {
      text = "kscreen-doctor output.DP-1.mode.3440x1440@144 output.DP-1.scale.0.9 output.DP-1.rotation.none output.DP-1.vrrpolicy.always output.DP-1.hdr.enable output.DP-1.wcg.enable";
      priority = 1;
      runAlways = true;
    };

    startup.startupScript."ensure_krunner_running" = {
      text = "systemctl --user start plasma-krunner.service";
      priority = 2;
      runAlways = true;
    };
    
    # Optional: Configure some workspace settings to feel more like a WM
    workspace = {
      clickItemTo = "select"; # Single click to select, double click to open (more standard)
      theme = "breeze-dark";
      colorScheme = "BreezeDark";
      iconTheme = "breeze-dark";
      cursor.theme = "Breeze_Snow";
      splashScreen.theme = "None";
    };

    panels = [
      {
        location = "left";
        height = 64;
        floating = true;
        alignment = "center";
        lengthMode = "fit"; # Automatically expand/shrink based on widgets
        hiding = "none"; # Always visible
        widgets = [
          "org.kde.plasma.kickoff"
          "org.kde.plasma.pager"
          {
            iconTasks = {
              launchers = [
                "applications:systemsettings.desktop"
                "preferred://filemanager"
                "preferred://browser"
                "applications:kitty.desktop"
              ];
            };
          }
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items = {
              shown = [
                "org.kde.plasma.notifications"
                "org.kde.plasma.volume"
                "org.kde.plasma.bluetooth"
                "org.kde.plasma.networkmanagement"
              ];
              hidden = [
                "org.kde.plasma.cameraindicator"
                "org.kde.plasma.clipboard"
                "org.kde.plasma.manage-inputmethod"
                "org.kde.plasma.keyboardlayout"
                "org.kde.plasma.devicenotifier"
                "org.kde.plasma.mediacontroller"
                "org.kde.plasma.keyboardindicator"
                "org.kde.plasma.battery"
                "org.kde.plasma.weather"
                "org.kde.plasma.brightness"
                "org.kde.kscreen"
              ];
            };
          }
          "org.kde.plasma.digitalclock"
        ];
      }
    ];
  };
}
