{ pkgs, lib, ... }:

{
  catppuccin.firefox.enable = true;
  catppuccin.firefox.profiles.default.enable = true;

  # Configure the standard firefox package (home-manager's module will handle it)
  programs.firefox = {
    enable = true;
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
        # --- PRIVACY & SECURITY ---
        "privacy.resistFingerprinting" = false; # Set to false to prevent breaking Google Meet/Layouts
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "privacy.partition.network_state.ocsp_cache" = true;
        "dom.security.https_only_mode" = true;
        "browser.contentblocking.category" = "strict";
        
        # --- DEBLOAT & PERFORMANCE ---
        "browser.newtabpage.activity-stream.feeds.telemetry" = false;
        "browser.newtabpage.activity-stream.telemetry" = false;
        "browser.ping-centre.telemetry" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "toolkit.telemetry.newProfilePreclockSample" = false;
        "toolkit.telemetry.shutdownPingSender.enabled" = false;
        "toolkit.telemetry.updatePing.enabled" = false;
        "toolkit.telemetry.bhrPing.enabled" = false;
        "toolkit.telemetry.firstShutdownPing.enabled" = false;

        # --- VIDEO CALLS & MEDIA ---
        "media.peerconnection.enabled" = true; # Essential for Google Meet/WebRTC
        "media.navigator.enabled" = true;
        "media.getusermedia.screensharing.enabled" = true;
        "media.autoplay.default" = 5; # Block audio and video autoplay
        "media.autoplay.blocking_policy" = 2;

        # --- EXISTING HARDWARE ACCEL ---
        "toolkit.legacyUserProfileCustomizations.stylesheets" = { Value = true; Status = "locked"; };
        "gfx.webrender.all" = { Value = true; Status = "locked"; };
        "media.cubeb.backend" = { Value = "pulse"; Status = "locked"; };
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
        "ui.systemUsesDarkTheme" = 1;
      };
    };
  };


}
