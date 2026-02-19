{ config, pkgs, lib, ... }:

{
  # 1. Graphics / OpenGL
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver # For Intel QuickSync / Video acceleration
      nvidia-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
    ];
  };

  # 2. NVIDIA Driver Config
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = true; # Recommended for laptops to help with battery
    powerManagement.finegrained = true; # Better power savings for hybrid
    open = true; 
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    # Prime / Hybrid Configuration
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      intelBusId = "PCI:0:2:0";
      nvidiaBusId = "PCI:1:0:0";
    };
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.full
  ];

  # Intel-specific env vars for better performance
  environment.sessionVariables = {
    VDPAU_DRIVER = "va_gl";
  };
}