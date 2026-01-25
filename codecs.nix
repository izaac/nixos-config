{ config, pkgs, ... }:

{
  # 1. License Freedom (Required for AAC, H.264, etc.)
  nixpkgs.config.allowUnfree = true;

  # 2. Hardware Acceleration (Nvidia Specific)
  # This allows your GPU to do the heavy lifting for video decoding
  hardware.graphics = {
    enable = true;
    enable32Bit = true; # Needed for Steam/Wine
    
    extraPackages = with pkgs; [
      # The bridge between Nvidia and standard Linux video apps
      nvidia-vaapi-driver 
      
      # Legacy support
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # 3. System Packages
  environment.systemPackages = with pkgs; [
    # --- The Swiss Army Knife ---
    # Standard ffmpeg is usually enough. 'ffmpeg-full' forces a massive 
    # compile from source. Stick to this unless you have a specific reason.
    ffmpeg 
    
    # --- DVD Support ---
    libdvdcss       # Decrypts standard DVDs
    libdvdread
    libdvdnav

    # --- GNOME / GStreamer ---
    # GNOME apps (Totem, Web, File Manager previews) depend heavily on these.
    gst_all_1.gstreamer
    
    # The "Good" (Open source, standard quality)
    gst_all_1.gst-plugins-good
    
    # The "Bad" (Not fully up to spec, but often needed)
    gst_all_1.gst-plugins-bad
    
    # The "Ugly" (Proprietary: H.264, AAC, MP3, etc.)
    gst_all_1.gst-plugins-ugly
    
    # The Bridge (Allows GStreamer to use FFmpeg codecs)
    gst_all_1.gst-libav
  ];
  
  # 4. Environment Variables for Firefox/Chrome
  # Forces browsers to look for the Nvidia VAAPI driver
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; # Hint for Electron apps to use Wayland
    MOZ_DISABLE_RDD_SANDBOX = "1"; # Sometimes needed for Firefox VAAPI
    LIBVA_DRIVER_NAME = "nvidia"; 
  };
}
