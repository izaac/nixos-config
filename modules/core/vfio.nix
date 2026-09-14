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

    lookingGlass = {
      enable = lib.mkEnableOption "the Looking Glass client";

      kvmfr = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Load the out-of-tree kvmfr module, which exposes the guest's
          framebuffer as `/dev/kvmfr0` and saves one copy compared with a plain
          `/dev/shm` file.

          The guest must reference the device rather than a `/dev/shm` file:

          ```xml
          <shmem name='kvmfr0'>
            <model type='ivshmem-plain'/>
            <size unit='M'>128</size>
          </shmem>
          ```

          This was disabled for a while during the lockup investigation, because
          an early-boot freeze left the kernel log ending on the line right
          after kvmfr finished loading. That turned out to be the Raphael iGPU
          rather than this module, and the machine has been stable since the
          RX 550 replaced it.
        '';
      };

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
        # vfio-pci parks an assigned device in D3cold while nothing has it open.
        # If the guest touches a register before the card is fully back in D0,
        # the MMIO read never completes and the CPU spins uninterruptibly.
        "vfio-pci.disable_idle_d3=1"
      ];

      blacklistedKernelModules = [
        "nvidia"
        "nvidia_modeset"
        "nvidia_drm"
        "nvidia_uvm"
        "nouveau"
      ];

      extraModulePackages = lib.optional cfg.lookingGlass.kvmfr config.boot.kernelPackages.kvmfr;
      kernelModules = lib.optional cfg.lookingGlass.kvmfr "kvmfr";
      extraModprobeConfig =
        lib.optionalString cfg.lookingGlass.kvmfr ''
          options kvmfr static_size_mb=${toString cfg.lookingGlass.sizeMB}
        ''
        # vfio-pci parks an assigned device in D3cold while nothing has it open.
        # If the guest touches a register before the card is fully back in D0,
        # the MMIO read never completes and the CPU spins in an uninterruptible
        # state, which is exactly what a hard lockup with no oops and a journal
        # that stops mid-line looks like.
        + ''
          options vfio-pci disable_idle_d3=1
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

    services.udev.extraRules = lib.mkIf cfg.lookingGlass.kvmfr ''
      SUBSYSTEM=="kvmfr", OWNER="${userConfig.username}", GROUP="kvm", MODE="0660"
    '';

    environment.systemPackages = lib.mkIf cfg.lookingGlass.enable [
      pkgs.looking-glass-client
    ];
  };
}
