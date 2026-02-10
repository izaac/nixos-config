{ pkgs, ... }:

{
  # 1. Controller & Hardware Support
  # Provides udev rules for Steam Deck, DualSense, and other controllers.
  hardware.steam-hardware.enable = true;

  # 2. Host Steam Configuration
  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    extraCompatPackages = [ pkgs.steamtinkerlaunch ];
    extraPackages = with pkgs; [
      mangohud
      protonup-qt
    ];
  };

  # 3. Ananicy-cpp (CachyOS-style auto-nice daemon)
  services.ananicy = {
    enable = true;
    package = pkgs.ananicy-cpp;
    rulesProvider = pkgs.ananicy-rules-cachyos;
  };

  # 4. Sched-ext (Dynamic Schedulers)
  # Linux 6.12+ supports this natively. scx_lavd is excellent for gaming latency.
  services.scx = {
    enable = true;
    scheduler = "scx_lavd";
  };

  # 5. Controller & Hardware Support (The "Maximized" List)
  hardware.xpadneo.enable = true; # Xbox Bluetooth
  services.joycond.enable = false; # Nintendo Switch JoyCons (Merge L+R)
  hardware.uinput.enable = true;  # Virtual Input (Critical for remapping tools)
  services.input-remapper.enable = true; # Easy input remapping daemon
  
  services.udev.packages = with pkgs; [
    game-devices-udev-rules # The big community list
    logitech-udev-rules
    openrgb                 # RGB Control access
  ];

  # 6. Environment Tweaks
  environment.sessionVariables = {
    # Force NVIDIA for Steam (fixes the iGPU vs dGPU conflict)
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __NV_PRIME_RENDER_OFFLOAD_SET_AS_ID = "0";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # G-Sync / VRR support
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";

    # NVIDIA-specific DLSS/NGX
    PROTON_ENABLE_NGX_UPDATER = "1";

    # Fast Synchronization (ntsync / fsync)
    # ntsync is the modern NT synchronization driver (XanMod 6.13+ or 6.14 mainline)
    # WINE_FSYNC is the standard high-performance sync method
    WINE_FSYNC = "1";

    # Wayland Fixes for NVIDIA
    DISABLE_RT_CHECK = "1"; # Helps with some Raytracing titles on Wayland
    
    # Steam UI Performance & Stability Fixes
    # NOTE: Steam doesn't read STEAM_EXTRA_ARGS natively. 
    # Use these in per-game launch options or custom wrappers if needed.
    STEAM_EXTRA_ARGS = "-no-cef-sandbox -disable-gpu-compositing -disable-smooth-scrolling";
    
    # Fix for X11 BadWindow errors on NVIDIA
    STEAM_DISABLE_PH_CLIPPED_VIDEO = "1";
    
    # Force SDL to use X11 (Fixes many Native/Proton game launch issues on NVIDIA)
    SDL_VIDEODRIVER = "x11";
  };
}
