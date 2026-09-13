{
  config,
  lib,
  pkgs,
  userConfig,
  ...
}: let
  cfg = config.mySystem.core.vfio;
in {
  options.mySystem.core.vfio = {
    enable = lib.mkEnableOption "Bind a GPU to vfio-pci for VM passthrough";

    gpuIDs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["10de:2d04" "10de:22eb"];
      description = ''
        PCI vendor:device IDs claimed by vfio-pci at boot. Must include every
        function of the card (video and audio), because the whole IOMMU group
        is handed to the guest.
      '';
    };

    hostVideoDrivers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["amdgpu" "modesetting"];
      description = "Video drivers the host falls back to once the GPU is gone.";
    };

    kernelPackages = lib.mkOption {
      type = lib.types.nullOr lib.types.raw;
      default = null;
      example = lib.literalExpression "pkgs.linuxPackages_6_18";
      description = ''
        Kernel to use instead of the host default. Useful when the integrated
        GPU that takes over the display misbehaves on the newest kernel: this
        configuration only has to host a VM, so it does not need the gaming
        kernel's tuning and can run a stock, better-tested build.
      '';
    };

    lookingGlass = {
      enable = lib.mkEnableOption "kvmfr shared-memory device for Looking Glass";

      sizeMB = lib.mkOption {
        type = lib.types.int;
        default = 128;
        description = ''
          Size of the kvmfr staging buffer. 128 MiB covers 4K at 32-bit colour
          with double buffering; see the Looking Glass documentation for the
          exact formula.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.gpuIDs != [];
        message = "mySystem.core.vfio.gpuIDs must list the passthrough GPU's PCI IDs.";
      }
    ];

    boot = {
      kernelPackages = lib.mkIf (cfg.kernelPackages != null) (lib.mkOverride 40 cfg.kernelPackages);

      # A wedged display engine leaves the machine running but blind, and a hard
      # reset on LUKS+ext4 risks the filesystem. SysRq makes a clean
      # sync-and-reboot reachable from the keyboard in that state:
      # Alt+SysRq+R E I S U B.
      kernel.sysctl."kernel.sysrq" = lib.mkForce 1;

      # vfio-pci has to claim the card before any real driver binds to it, so
      # the modules and the ID list both belong in the initrd.
      initrd.kernelModules = [
        "vfio_pci"
        "vfio_iommu_type1"
        "vfio"
      ];

      kernelParams = [
        "amd_iommu=on"
        "iommu=pt"
        "vfio-pci.ids=${lib.concatStringsSep "," cfg.gpuIDs}"
      ];

      blacklistedKernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_drm"
        "nvidia_uvm"
        "nouveau"
      ];

      extraModulePackages = lib.optional cfg.lookingGlass.enable config.boot.kernelPackages.kvmfr;
      kernelModules = lib.optional cfg.lookingGlass.enable "kvmfr";
      extraModprobeConfig = lib.optionalString cfg.lookingGlass.enable ''
        options kvmfr static_size_mb=${toString cfg.lookingGlass.sizeMB}
      '';
    };

    # The NVIDIA stack must not be built into this configuration at all,
    # otherwise its modules and services race vfio-pci for the card. Turning the
    # shared flag off also drops the host's NVIDIA kernel parameters and the
    # clock-capping service.
    mySystem.desktop.nvidia.enable = lib.mkForce false;
    services.xserver.videoDrivers = lib.mkForce cfg.hostVideoDrivers;
    hardware.nvidia-container-toolkit.enable = lib.mkForce false;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    # Disable Delta Color Compression in Mesa (radeonsi/RADV) to prevent
    # rendering corruption / artifacting in GPU-accelerated windows (e.g. Kitty)
    # on Raphael RDNA2 iGPU.
    environment.sessionVariables = {
      AMD_DEBUG = "nodcc";
      RADV_DEBUG = "nodcc";
    };

    services.udev.extraRules = lib.mkIf cfg.lookingGlass.enable ''
      SUBSYSTEM=="kvmfr", OWNER="${userConfig.username}", GROUP="kvm", MODE="0660"
    '';

    environment.systemPackages = lib.mkIf cfg.lookingGlass.enable [
      pkgs.looking-glass-client
    ];
  };
}
