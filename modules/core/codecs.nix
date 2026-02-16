{ pkgs, ... }:

{
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
  environment.sessionVariables = {
    MOZ_DISABLE_RDD_SANDBOX = "1";
  };
}
