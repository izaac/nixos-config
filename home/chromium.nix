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

      # --- Security & Debloat ---
      "--disable-sync"
      "--disable-signin"
      "--no-first-run"
      "--no-pings"
      "--no-default-browser-check"
      "--disable-breakpad" # Disable crash reporting
      "--disable-component-update" # Don't update components in background
      "--disable-domain-reliability"
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

      # --- Security & Debloat ---
      "--disable-sync"
      "--disable-signin"
      "--no-first-run"
      "--no-pings"
      "--no-default-browser-check"
      "--disable-breakpad"
      "--disable-component-update"
      "--disable-domain-reliability"
    ];
  };
}
