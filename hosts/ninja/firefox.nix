_: {
  programs.firefox = {
    enable = true;
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
      DisplayBookmarksToolbar = "never";
      DisplayMenuBar = "default-off";
      SearchBar = "unified";
      HardwareAcceleration = true;
      Preferences = {
        "privacy.resistFingerprinting" = false;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "dom.security.https_only_mode" = true;
        "browser.contentblocking.category" = "strict";
        "browser.ping-centre.telemetry" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.unified" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.server" = "data:,";
        "toolkit.telemetry.archive.enabled" = false;
        "app.normandy.enabled" = false;
        "app.normandy.api_url" = "";
        "browser.discovery.enabled" = false;
        "browser.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionPolicyAccepted" = false;
        "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;
        "beacon.enabled" = false;
        "network.http.max-connections" = 1800;
        "network.http.max-persistent-connections-per-server" = 10;
        "network.trr.mode" = 5;
        "network.captive-portal-service.enabled" = false;
        "browser.cache.disk.enable" = false;
        "browser.cache.memory.capacity" = 1048576;
        "browser.sessionstore.interval" = 600000;
        "ui.systemUsesDarkTheme" = 1;

        "media.resampling.enabled" = false;
        "media.audio_max_channels" = 8;
        "media.mediasource.webm.enabled" = true;
        "media.mediasource.webm.audio.enabled" = true;
        "media.webm.enabled" = true;
        "media.opus.enabled" = true;
        "media.setsinkid.enabled" = true;
        "media.track.enabled" = true;
        "media.getusermedia.audio.processing.agc.enabled" = false;
        "media.getusermedia.audio.processing.noise_suppression" = false;

        "media.ffmpeg.vaapi.enabled" = true;
        "media.hardware-video-decoding.force-enabled" = true;
        "media.rdd-ffmpeg.enabled" = true;
        "gfx.webrender.all" = true;
        "widget.dmabuf.force-enabled" = false;
      };
    };
  };
}
