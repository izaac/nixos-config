{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    ffmpeg
    libdvdcss
    
    # GStreamer (The "Good, Bad, and Ugly")
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-good
    gst_all_1.gst-plugins-bad
    gst_all_1.gst-plugins-ugly
    gst_all_1.gst-libav
  ];
  
  # Browser Acceleration Hints
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1";
    MOZ_DISABLE_RDD_SANDBOX = "1";
    LIBVA_DRIVER_NAME = "nvidia"; 
  };
}
