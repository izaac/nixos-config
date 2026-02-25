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
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "590.44.01";
      sha256_64bit = "sha256-VbkVaKwElaazojfxkHnz/nN/5olk13ezkw/EQjhKPms=";
      sha256_aarch64 = "sha256-gpqz07aFx+lBBOGPMCkbl5X8KBMPwDqsS+knPHpL/5g=";
      openSha256 = "sha256-ft8FEnBotC9Bl+o4vQA1rWFuRe7gviD/j1B8t0MRL/o=";
      settingsSha256 = "sha256-wVf1hku1l5OACiBeIePUMeZTWDQ4ueNvIk6BsW/RmF4=";
      persistencedSha256 = "sha256-nHzD32EN77PG75hH9W8ArjKNY/7KY6kPKSAhxAWcuS4=";
    };
    nvidiaPersistenced = true;
  };

  # 3. Kernel Modules & Wayland Environment
  boot.initrd.kernelModules = [ ];
  boot.kernelParams = [ 
    "nvidia_drm.fbdev=1" 
    # High-performance PowerMizer (avoid clock dips during presentation)
    "nvidia.NVreg_RegistryDwords=\"PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x1; RMIntrLockingMode=1\""
  ]; 
  
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
    MOZ_DISABLE_RDD_SANDBOX = "1"; # Fixes Firefox slow-motion video stutter at start on NVIDIA Wayland

    # Enable G-Sync/VRR (for GNOME/KDE Wayland)
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";

    # Native Wayland for Electron apps (Discord, VSCode, etc.)
    NIXOS_OZONE_WL = "1";
    ELECTRON_OZONE_PLATFORM_HINT = "auto";
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
      # Set Power Limit to 250W (Safe undervolt) and Lock Clocks to 210-2475MHz
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 250 && ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -lgc 210,2475'";
      RemainAfterExit = true;
    };
  };
}
