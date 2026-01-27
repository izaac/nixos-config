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
    powerManagement.enable = true; # Better for 50-series power state switching
    open = true; # Using the open kernel modules for the 5070 Ti
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    nvidiaPersistenced = true;
  };

  # 3. Kernel Modules & Wayland Environment
  boot.initrd.kernelModules = [ "nvidia" "nvidia_modeset" "nvidia_uvm" "nvidia_drm" ];
  
  environment.sessionVariables = {
    WLR_NO_HARDWARE_CURSORS = "1";
    NIXOS_OZONE_WL = "1";
    GBM_BACKEND = "nvidia-drm";
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
  };

  # 4. Unlock Overclocking/Undervolting (Coolbits)
  services.xserver.deviceSection = ''
    Option "Coolbits" "28"
  '';

  # 5. The Undervolt Service (Clock Locking)
  systemd.services.nvidia-lock-clocks = {
    description = "Lock NVIDIA GPU Clocks for stability and undervolting";
    after = [ "display-manager.service" "nvidia-persistenced.service" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      # Lock to 2500MHz. Adjust as needed for your specific silicon lottery.
      ExecStart = "${config.boot.kernelPackages.nvidiaPackages.stable.bin}/bin/nvidia-smi -lgc 210,2500";
      RemainAfterExit = true;
    };
  };
}
