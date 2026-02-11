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
  boot.kernelParams = [ ]; 
  
  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";
  };

  # 4. Unlock Overclocking/Undervolting (Coolbits)
  services.xserver.deviceSection = ''
    Option "Coolbits" "28"
  '';

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

  # 5. The Undervolt Service (Clock Locking)
  systemd.services.nvidia-lock-clocks = {
    enable = true; 
    description = "Lock NVIDIA GPU Clocks for stability and undervolting";
    after = [ "display-manager.service" "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${config.boot.kernelPackages.nvidiaPackages.beta.bin}/bin/nvidia-smi -lgc 210,2500";
      RemainAfterExit = true;
    };
  };
}
