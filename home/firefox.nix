{ pkgs, lib, latestPkgs, ... }:

{
  catppuccin.firefox.enable = true;
  catppuccin.firefox.profiles.default.enable = true;

  # Configure the standard firefox package (home-manager's module will handle it)
  programs.firefox = {
    enable = true;
    package = lib.makeOverridable (args: pkgs.symlinkJoin {
      name = "firefox-vip";
      paths = [ latestPkgs.firefox ];
      postBuild = ''
        # Replace the desktop file with a patched version
        rm -rf $out/share/applications
        mkdir -p $out/share/applications
        cp ${latestPkgs.firefox}/share/applications/firefox.desktop $out/share/applications/firefox.desktop
        substituteInPlace $out/share/applications/firefox.desktop \
          --replace "Exec=firefox" "Exec=/run/wrappers/bin/firefox-vip"

        # Also provide a 'firefox' binary that calls the wrapper
        # This fixes terminal launches as well
        rm $out/bin/firefox
        echo "#!/bin/sh" > $out/bin/firefox
        echo "exec /run/wrappers/bin/firefox-vip \"\$@\"" >> $out/bin/firefox
        chmod +x $out/bin/firefox
      '';
    }) {};
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

        # --- AI & DEBLOAT (NEW) ---
        "browser.ml.enable" = false; # Disable internal AI/ML model loading
        "browser.ml.chat.enabled" = false; # Disable Firefox Chat/AI Sidebar
        "browser.tabs.tab-grouping.enabled" = false; # Disable AI-assisted tab grouping
        "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
        "browser.urlbar.suggest.quicksuggest.sponsored" = false;
        "browser.urlbar.trending.featureGate" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false; # Pocket/Top Stories
        "extensions.htmlaboutaddons.recommendations.enabled" = false;
        "services.sync.telemetry" = false;

        # --- FASTFOX / ZEN BROWSER OPTIMIZATIONS ---
        # 1. Memory Cache Aggressiveness (Disables disk cache, forces RAM)
        "browser.cache.memory.max_entry_size" = 51200; # 50 MB max entry (up from 5MB)
        "image.mem.decode_bytes_at_a_time" = 65536; # Chunk size for image decoders
        "image.cache.size" = 10485760; # Cache images up to 10MiB
        "media.memory_cache_max_size" = 262144; # 256 MB for media cache
        "media.memory_caches_combined_limit_kb" = 1048576; # 1GB combined media limit

        # 2. Network & DNS Tuning (Parallelism)
        "network.http.max-connections" = 1800; # Default is 900
        "network.http.max-persistent-connections-per-server" = 10;
        "network.http.pacing.requests.enabled" = false;
        "network.dnsCacheEntries" = 10000;
        "network.dnsCacheExpiration" = 60; # Reduced from 3600 so DNS changes take effect faster
        "network.trr.mode" = 5; # Explicitly disable DNS-over-HTTPS (DoH) and use system DNS
        "network.ssl_tokens_cache_capacity" = 10240; # Faster TLS reconnects
        
        # 3. Graphics & UI Responsiveness (Skia/Canvas acceleration)
        "gfx.content.skia-font-cache-size" = 32; # Font rendering cache (32MB)
        "gfx.canvas.accelerated.cache-items" = 32768;
        "gfx.canvas.accelerated.cache-size" = 4096;
        "nglayout.initialpaint.delay" = 5; # How long FF waits before rendering the page (ms)
        "content.notify.interval" = 100000;
        "browser.sessionhistory.max_total_viewers" = 4; # Keep up to 4 pages in memory for instant back/forward

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
        "media.hardware-video-decoding.force-enabled" = { Value = true; Status = "locked"; }; # Forces NVDEC/VAAPI on newer FF versions
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
