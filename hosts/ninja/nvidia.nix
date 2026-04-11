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
    # To update: bump version + set all sha256 fields to lib.fakeHash,
    # then rebuild to get correct hashes from the error messages.
    # Releases: https://www.nvidia.com/en-us/drivers/unix/
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "595.58.03";
      sha256_64bit = "sha256-jA1Plnt5MsSrVxQnKu6BAzkrCnAskq+lVRdtNiBYKfk=";
      sha256_aarch64 = "sha256-hzzIKY1Te8QkCBWR+H5k1FB/HK1UgGhai6cl3wEaPT8="; # Placeholder
      openSha256 = "sha256-6LvJyT0cMXGS290Dh8hd9rc+nYZqBzDIlItOFk8S4n8=";
      settingsSha256 = "sha256-2vLF5Evl2D6tRQJo0uUyY3tpWqjvJQ0/Rpxan3NOD3c=";
      persistencedSha256 = "sha256-AtjM/ml/ngZil8DMYNH+P111ohuk9mWw5t4z7CHjPWw=";
    };
    nvidiaPersistenced = true;
  };

  # 3. Kernel Modules & Wayland Environment
  boot.initrd.kernelModules = [];
  boot.kernelParams = [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Explicitly added since powerManagement is disabled
    "nvidia.NVreg_UseKernelSuspendNotifiers=1" # Required for improved memory preservation on Open Modules
    # High-performance PowerMizer (avoid clock dips during presentation)
    "nvidia.NVreg_RegistryDwords=\"PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x1; RMIntrLockingMode=1; RMConnectToDevice=0\""
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
    after = ["display-manager.service" "nvidia-persistenced.service"];
    wantedBy = ["multi-user.target"];
    serviceConfig = {
      Type = "oneshot";
      # Set Power Limit to 250W (hardware minimum) and Lock Clocks to 210-2100MHz (summer-friendly ceiling)
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 250 && ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -lgc 210,2100'";
      RemainAfterExit = true;
    };
  };
}
