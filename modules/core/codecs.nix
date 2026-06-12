{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.mySystem.core.codecs;
in {
  options.mySystem.core.codecs = {
    enable = lib.mkEnableOption "Core system video and audio codecs";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      ffmpeg
      libdvdcss

      # GStreamer (The "Good, Bad, and Ugly")
      gst_all_1.gstreamer
      gst_all_1.gst-plugins-base
      gst_all_1.gst-plugins-good
      gst_all_1.gst-plugins-bad
      gst_all_1.gst-plugins-ugly
      gst_all_1.gst-libav
      gst_all_1.gst-vaapi
    ];

    # Browser Acceleration Hints
    # MOZ_DISABLE_RDD_SANDBOX was previously set here to force Firefox HW
    # decode, but it weakens the media sandbox for every user. Brave/Chromium
    # are the primary browsers and get VA-API via nvidia-vaapi-driver, so the
    # sandbox stays intact.
  };
}
