{
  config,
  pkgs,
  ...
}: {
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
    # Note: On 595+ with open modules, NixOS automatically enables 'kernelSuspendNotifier'.
    # We must explicitly disable NixOS powerManagement to prevent the creation of legacy
    # nvidia-suspend/resume systemd services which conflict with the kernel notifiers.
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = true; # Open modules required for RTX 50-series (Blackwell)
    nvidiaSettings = true;
    # Track nixpkgs production branch. Switched from a custom mkDriver pin on
    # 2026-04-30 once the channel default caught up. Verify
    # `nvidiaPackages.production.version` is at least the previously running
    # driver before bumping nixpkgs.
    package = config.boot.kernelPackages.nvidiaPackages.production;
    nvidiaPersistenced = true;
  };

  # 3. Kernel Modules & Wayland Environment
  # nvidia modules load post-initrd — keeps LUKS prompt input clean.
  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Explicitly added since powerManagement is disabled
    "nvidia.NVreg_UseKernelSuspendNotifiers=1" # Required for improved memory preservation on Open Modules
    # Adaptive PowerMizer — GPU clocks down at idle, ramps for load
    "nvidia.NVreg_RegistryDwords=\"PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x2; RMIntrLockingMode=1; RMConnectToDevice=0\""
  ];

  environment.sessionVariables = {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";
    GBM_BACKEND = "nvidia-drm";

    # Enable G-Sync/VRR (for GNOME/KDE Wayland)
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };

  environment.systemPackages = with pkgs; [
    nvtopPackages.nvidia
  ];

  # 5. The Undervolt Service (Clock Locking & Power Limit)
  systemd.services.nvidia-lock-clocks = {
    enable = true;
    description = "Lock NVIDIA GPU Clocks and Power Limit for stability and undervolting";
    after = ["display-manager.service" "nvidia-persistenced.service"];
    wantedBy = ["graphical.target"];
    serviceConfig = {
      Type = "oneshot";
      # Set Power Limit to 250W (hardware minimum) and Lock Clocks to 210-2100MHz (summer-friendly ceiling)
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 250 && ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -lgc 210,2100'";
      RemainAfterExit = true;
    };
  };
}
