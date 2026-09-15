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
    enable = lib.mkEnableOption "GPU binding to vfio-pci for VM passthrough";

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

    hostCPUs = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "8-15,24-31";
      description = ''
        CPU list that host userspace is confined to while the GPU is passed
        through, as an `AllowedCPUs` cpuset on `system.slice` and `user.slice`.

        Pinning a guest's vCPUs says where they run, not that nothing else may
        run there. Host processes keep being scheduled onto the same cores and
        evict the cache lines the guest is using, which matters most when the
        guest is pinned to a die with stacked cache.

        libvirt places guests in `machine.slice`, which is left alone, so the
        guest keeps the whole machine available and its own pinning decides
        where it lands. Confining the host with a cpuset rather than
        `isolcpus` also keeps the cores ordinary: nothing is removed from the
        scheduler, and the restriction disappears with this module, so the
        native gaming entry still has every thread.
      '';
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

          The guest cannot reach this through `<shmem>`: libvirt always resolves
          a shmem name to `/dev/shm/<name>`, so the device has to be attached
          with a raw `<qemu:commandline>` `memory-backend-file` pointing at
          `/dev/kvmfr0`.
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
        # If the guest touches a register before the card is back in D0 the MMIO
        # read never completes and the CPU spins uninterruptibly, which is what
        # a hard lockup with no oops and a journal stopping mid-line looks like.
        # Set here for the initrd load and in modprobe.d below for any later one.
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
        + ''
          options vfio-pci disable_idle_d3=1
        '';
    };

    # The NVIDIA stack must not be built into this configuration at all,
    # otherwise its modules and services race vfio-pci for the card. Turning the
    # shared flag off also drops the host's NVIDIA kernel parameters and the
    # clock-capping service.
    #
    # This writes an option declared in modules/desktop, which lib.mkIf does not
    # shield: an undeclared path is an eval error even in a disabled branch.
    # hosts/common.nix always imports both trees, so the coupling holds.
    mySystem.desktop.nvidia.enable = lib.mkForce false;

    # nvidia-container-toolkit follows videoDrivers in modules/core/virtualization.nix,
    # so forcing the list above is enough to switch it off.
    services.xserver.videoDrivers = lib.mkForce cfg.hostVideoDrivers;

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    services.udev.extraRules = lib.optionalString cfg.lookingGlass.kvmfr ''
      SUBSYSTEM=="kvmfr", OWNER="${userConfig.username}", GROUP="kvm", MODE="0660"
    '';

    systemd.slices = lib.mkIf (cfg.hostCPUs != null) {
      system.sliceConfig.AllowedCPUs = cfg.hostCPUs;
      user.sliceConfig.AllowedCPUs = cfg.hostCPUs;
    };

    environment.systemPackages = lib.optionals cfg.lookingGlass.enable [
      pkgs.looking-glass-client
    ];
  };
}
