{pkgs, ...}: {
  boot = {
    # Bootloader and startup UX
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
        editor = false;
        consoleMode = "max";
      };
      efi.canTouchEfiVariables = true;
      grub.enable = false;
    };

    # Plymouth disabled — causes DRM warnings during simpledrm→nvidia-drm
    # handoff (connector Unknown-1 leaked, drm_gem_shmem_release warnings).
    # Boot is fast enough without it (~10s to greeter).

    consoleLogLevel = 0;
    initrd = {
      verbose = false;
      systemd = {
        enable = true;
        tpm2.enable = false;
      };
    };

    supportedFilesystems = ["exfat"];

    # Keep latest kernel for current hardware support
    kernelPackages = pkgs.linuxPackages_latest;
    blacklistedKernelModules = [
      "sp5100_tco"
      "eeepc_wmi"
      "joydev"
      "pcspkr"
    ];

    kernelParams = [
      "quiet"
      "loglevel=3"
      "rd.systemd.show_status=false"
      "rd.udev.log_level=3"
      "udev.log_priority=3"
      "boot.shell_on_fail"
      "pci=realloc,pcie_bus_safe"
      "pcie_aspm=off"
      "iommu=pt"
      "pcie_ports=native"
      "amd_pstate=active"
      "preempt=full"
      # split_lock_mitigate is handled via sysctl in performance.nix
    ];
  };
  programs.fuse.enable = true;
}
