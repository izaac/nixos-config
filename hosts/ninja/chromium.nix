_: {
  programs.chromium = {
    enable = true;
    extraOpts = {
      # Privacy
      MetricsReportingEnabled = false;
      SpellCheckServiceEnabled = false;
      # Performance
      BackgroundModeEnabled = false;
      HardwareAccelerationModeEnabled = true;
      # Keep Manifest V2 extensions (uBlock Origin)
      ExtensionManifestV2Availability = 2;
    };
  };
}
