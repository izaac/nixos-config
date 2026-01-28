{ pkgs, ... }:

{
  programs.firefox = {
    enable = true;
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
        "gfx.webrender.all" = { Value = true; Status = "locked"; };
        "layers.acceleration.force-enabled" = { Value = true; Status = "locked"; };
        "media.ffmpeg.vaapi.enabled" = { Value = true; Status = "locked"; };
        "media.rdd-ffmpeg.enabled" = { Value = true; Status = "locked"; };
        "media.av1.enabled" = { Value = true; Status = "locked"; };
        "gfx.x11-egl.force-enabled" = { Value = true; Status = "locked"; };
        "widget.dmabuf.force-enabled" = { Value = true; Status = "locked"; };
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
