{config, ...}: {
  stylix.targets.firefox.enable = false;

  home.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";
  };

  # Override desktop entry so launcher runs Firefox under native Wayland
  xdg.desktopEntries.firefox = {
    name = "Firefox Web Browser";
    exec = "firefox %U";
    icon = "firefox";
    type = "Application";
    categories = ["Network" "WebBrowser"];
    terminal = false;
    mimeType = [
      "text/html"
      "text/xml"
      "application/xhtml+xml"
      "application/vnd.mozilla.xul+xml"
      "x-scheme-handler/http"
      "x-scheme-handler/https"
    ];
    actions = {
      "new-window" = {
        name = "Open a New Window";
        exec = "firefox --new-window %U";
      };
      "new-private-window" = {
        name = "Open a New Private Window";
        exec = "firefox --private-window %U";
      };
    };
  };

  programs.firefox = {
    enable = true;
    configPath = "${config.xdg.configHome}/mozilla/firefox";
    profiles.default = {
      id = 0;
      name = "default";
      isDefault = true;
      extensions.force = true;
      settings = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };
    # Policies apply globally to all profiles and won't delete your history/extensions
    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      EnableTrackingProtection = {
        Value = true;
        Locked = false;
        Cryptomining = true;
        Fingerprinting = true;
      };
      DisablePocket = true;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";
      DontCheckDefaultBrowser = true;
      DisplayBookmarksToolbar = "never"; # or "always"
      DisplayMenuBar = "default-off";
      SearchBar = "unified";

      # Hardware Acceleration & Performance
      HardwareAcceleration = true;
      # Preferences allow setting any about:config value
      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = {
          Value = true;
          Status = "locked";
        };
        "gfx.webrender.all" = {
          Value = true;
          Status = "locked";
        };
        "gfx.webrender.compositor" = {
          Value = false;
          Status = "locked";
        };
        "widget.wayland.opaque-region.enabled" = {
          Value = false;
          Status = "locked";
        };
        "media.ffmpeg.vaapi.enabled" = {
          Value = true;
          Status = "locked";
        };
        "media.rdd-ffmpeg.enabled" = {
          Value = true;
          Status = "locked";
        };
        "media.av1.enabled" = {
          Value = true;
          Status = "locked";
        };
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.capacity" = 1048576;
        "browser.sessionstore.interval" = 600000;
        "privacy.donottrackheader.enabled" = true;
        "browser.tabs.firefox-view" = false;
        "browser.compactmode.show" = true;
        "browser.uidensity" = 1;
      };
    };
  };
}
