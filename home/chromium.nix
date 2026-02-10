{ pkgs, ... }:

{
  # Chromium Configuration
  programs.chromium = {
    enable = true;
    commandLineArgs = [
      # --- Dark Mode ---
      "--force-dark-mode"
      "--enable-features=WebUIDarkMode"

      # --- Performance & GPU (Hardware Acceleration) ---
      "--ignore-gpu-blocklist"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"
      
      # --- Wayland/Video/Compatibility ---
      "--ozone-platform=x11"
      "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
    ];
  };

  # Google Chrome Configuration
  programs.google-chrome = {
    enable = true;
    commandLineArgs = [
      # --- Dark Mode ---
      "--force-dark-mode"
      "--enable-features=WebUIDarkMode"

      # --- Performance & GPU (Hardware Acceleration) ---
      "--ignore-gpu-blocklist"
      "--enable-gpu-rasterization"
      "--enable-zero-copy"

      # --- Wayland/Video/Compatibility ---
      "--ozone-platform=x11"
      "--enable-features=VaapiVideoDecoder,VaapiVideoEncoder"
    ];
  };
}
