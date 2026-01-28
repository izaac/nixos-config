{ pkgs, ... }:

{
  # 1. Steam Hardware Support
  # Explicitly enables udev rules for Valve hardware
  hardware.steam-hardware.enable = true;

  programs.steam = {
    enable = true;
    remotePlay.openFirewall = true;
    dedicatedServer.openFirewall = true;
    localNetworkGameTransfers.openFirewall = true;
    gamescopeSession.enable = true; # Adds "Steam Deck" session support
    extraCompatPackages = [ pkgs.steamtinkerlaunch ];
    extraPackages = with pkgs; [
      libvdpau
      libva
      mangohud
      protonup-qt
    ];
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true; # Required for performance
  };

  programs.corectrl = {
    enable = true;
  };

  # 2. GameMode
  programs.gamemode = {
    enable = true;
    enableRenice = true;
    settings = {
      general = {
        renice = 10;
      };
    };
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
  services.joycond.enable = true; # Nintendo Switch JoyCons (Merge L+R)
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

    # Wayland Fixes for NVIDIA
    DISABLE_RT_CHECK = "1"; # Helps with some Raytracing titles on Wayland
  };
}
