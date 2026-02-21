{ config, pkgs, ... }:

{
  # 1. Graphics / OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # 2. NVIDIA Driver Config
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # Disabled to fix slow wake-up/EGL context loss on DPMS
    powerManagement.finegrained = false;
    open = true; # Open modules required for RTX 50-series (Blackwell)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.beta;
    nvidiaPersistenced = true;
  };

  # 3. Kernel Modules & Wayland Environment
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ 
    "nvidia_drm.fbdev=1" 
    # High-performance PowerMizer (avoid clock dips during presentation)
    "nvidia.NVreg_RegistryDwords=\"PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x1\""
  ]; 
  
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";

    # Enable G-Sync/VRR (for GNOME/KDE Wayland)
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";

    # Native Wayland for Electron apps (Discord, VSCode, etc.)
    NIXOS_OZONE_WL = "1";
  };

  # 4. Unlock Overclocking/Undervolting (Coolbits)
  services.xserver.deviceSection = ''
    Option "Coolbits" "28"
  '';

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

  # 5. The Undervolt Service (Clock Locking & Power Limit)
  systemd.services.nvidia-lock-clocks = {
    enable = true; 
    description = "Lock NVIDIA GPU Clocks and Power Limit for stability and undervolting";
    after = [ "display-manager.service" "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      # Set Power Limit to 250W (Safe undervolt) and Lock Clocks to 210-2575MHz
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.boot.kernelPackages.nvidiaPackages.beta.bin}/bin/nvidia-smi -pl 250 && ${config.boot.kernelPackages.nvidiaPackages.beta.bin}/bin/nvidia-smi -lgc 210,2575'";
      RemainAfterExit = true;
    };
  };
}
