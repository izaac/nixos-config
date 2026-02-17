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
      libvdpau
      libva
      mangohud
      protonplus
      gamemode
    ];
  };

  # 3. GameMode (Automatic Optimizations)
  programs.gamemode.enable = true;

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
    # G-Sync / VRR support
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";

    # NVIDIA-specific DLSS/NGX
    PROTON_ENABLE_NGX_UPDATER = "1";

    # Fast Synchronization (ntsync / fsync)
    # ntsync is the modern NT synchronization driver (XanMod 6.13+)
    # fsync is the standard high-performance sync method
    PROTON_USE_NTSYNC = "1";
    PROTON_ENABLE_NTSYNC = "1";
    WINE_NTSYNC = "1";
    WINE_FSYNC = "1";

    # NVIDIA & DX12 Performance Fixes
    # - no_upload_hlist: Fixes 'Invalid resource alignment' stutters in Elden Ring
    # - Shader Cache: Increased to 10GB to prevent re-compilation hitches
    VKD3D_CONFIG = "no_upload_hlist";
    __GL_SHADER_DISK_CACHE_SKIP_CLEANUP = "1";
    __GL_SHADER_DISK_CACHE_SIZE = "10737418240";
    
    # Wayland Fixes for NVIDIA
    DISABLE_RT_CHECK = "1"; # Helps with some Raytracing titles on Wayland
    
    # Steam UI Performance & Stability Fixes
    # -no-cef-sandbox: Fixes web helper crashes
    # -disable-gpu-compositing: Prevents UI flickering/lag
    # -disable-smooth-scrolling: Reduces rendering load
    STEAM_EXTRA_ARGS = "-no-cef-sandbox -disable-gpu-compositing -disable-smooth-scrolling";
    
    # Fix for X11 BadWindow errors on NVIDIA
    STEAM_DISABLE_PH_CLIPPED_VIDEO = "1";
  };
}
