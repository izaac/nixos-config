{
  config,
  pkgs,
  lib,
  ...
}: let
  # Everything below is inert once the GPU is handed to vfio-pci, and the
  # clock-capping service would fight the passthrough binding. Gate it all on
  # the shared NVIDIA flag so the vfio specialisation drops it by forcing that
  # flag off.
  nvidiaEnabled = config.mySystem.desktop.nvidia.enable;
in {
  # Shared NVIDIA baseline (graphics, open module, VAAPI/VDPAU) lives in
  # modules/desktop/nvidia.nix. This file overrides only ninja-specific bits.
  mySystem.desktop.nvidia.enable = true;

  hardware.nvidia = lib.mkIf nvidiaEnabled {
    # Note: On 595+ with open modules, NixOS automatically enables 'kernelSuspendNotifier'.
    # We must explicitly disable NixOS powerManagement to prevent the creation of legacy
    # nvidia-suspend/resume systemd services which conflict with the kernel notifiers.
    powerManagement.enable = false;
    powerManagement.finegrained = false;

    # Hand-pinned to NVIDIA's New Feature Branch, which is ahead of every
    # attribute nixpkgs currently ships (production 595.71.05, new_feature
    # 590.48.01). This is deliberately not the production branch: NFB carries
    # the current Blackwell fixes for the RTX 5060 Ti, at the cost of a shorter
    # support window and faster churn.
    #
    # Nothing updates these hashes automatically, so this pin holds the driver
    # back once nixpkgs catches up. Drop the whole mkDriver block and go back to
    # nvidiaPackages.production as soon as it reaches 610 or newer.
    #
    # To bump by hand: take the version from
    # https://www.nvidia.com/en-us/drivers/unix/ and refresh all four hashes
    # (aarch64 is intentionally omitted, ninja is x86_64 only).
    package = config.boot.kernelPackages.nvidiaPackages.mkDriver {
      version = "615.71.09";
      sha256_64bit = "sha256-zc7tIrvrYSSNGm3qvCWWZz46ZQFpjucayNL9wo87cP4=";
      openSha256 = "sha256-3gByMYIwFzRaLdDG+roCEOuKRRJDrljG9AlLnRZTirM=";
      settingsSha256 = "sha256-LK1LU8mDkM/XVRKPBtuOZh9nIP/lGFLAJnmasEX8jhg=";
      persistencedSha256 = "sha256-qPRb+3d88+2RcpUkoBTbjIaImnQ+jX+/6p1vXcJ5geE=";
    };
    nvidiaPersistenced = true;
  };

  # 3. Kernel Modules & Wayland Environment
  # nvidia modules load post-initrd - keeps LUKS prompt input clean.
  boot.kernelParams = lib.mkIf nvidiaEnabled [
    "nvidia.NVreg_PreserveVideoMemoryAllocations=1" # Explicitly added since powerManagement is disabled
    "nvidia.NVreg_UseKernelSuspendNotifiers=1" # Required for improved memory preservation on Open Modules
    # Adaptive PowerMizer - GPU clocks down at idle, ramps for load
    "nvidia.NVreg_RegistryDwords=\"PowerMizerEnable=0x1; PerfLevelSrc=0x2222; PowerMizerDefaultAC=0x2; RMIntrLockingMode=1; RMConnectToDevice=0\""
  ];

  environment.sessionVariables = lib.mkIf nvidiaEnabled {
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";
    LIBVA_DRIVER_NAME = "nvidia";
    NVD_BACKEND = "direct";

    # Enable G-Sync/VRR (for GNOME/KDE Wayland)
    __GL_GSYNC_ALLOWED = "1";
    __GL_VRR_ALLOWED = "1";
  };

  # 5. The Power-Cap & Clock-Ceiling Service
  # Tuned for RTX 5060 Ti 16GB (Ventus 2X). Card limits: power 150-180W
  # (default 180W), max graphics clock 3090MHz.
  #
  # Strategy: the 150W power floor is the real thermal guard - the card
  # physically cannot run hot at 150W. The clock ceiling is raised to 2700MHz
  # so the GPU is free to boost on light loads while the power cap throttles it
  # under heavy load. Validated with real in-game benchmarking: ~2610MHz @
  # ~142W @ 74C at 99% utilization (vs the old 2000MHz lock which wasted ~58W
  # of budget and clock headroom at only 63C).
  systemd.services.nvidia-lock-clocks = lib.mkIf nvidiaEnabled {
    enable = true;
    description = "Cap NVIDIA GPU power and clock ceiling for cool, efficient performance";
    after = ["display-manager.service" "nvidia-persistenced.service"];
    wantedBy = ["graphical.target"];
    serviceConfig = {
      Type = "oneshot";
      # Set Power Limit to 150W (hardware minimum) and cap Clocks at 210-2700MHz;
      # the 150W power cap is the active limiter under load, keeping temps ~74C.
      ExecStart = "${pkgs.bash}/bin/bash -c '${config.hardware.nvidia.package.bin}/bin/nvidia-smi -pl 150 && ${config.hardware.nvidia.package.bin}/bin/nvidia-smi -lgc 210,2700'";
      RemainAfterExit = true;
      NoNewPrivileges = true;
      ProtectHome = true;
      ProtectControlGroups = true;
      RestrictRealtime = true;
    };
  };
}
