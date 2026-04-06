{pkgs, ...}: {
  # Bootloader and startup UX
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;
  boot.loader.systemd-boot.editor = false;
  boot.loader.systemd-boot.consoleMode = "max";

  boot.plymouth = {
    enable = true;
    theme = "bgrt";
  };
  catppuccin.plymouth.enable = false;

  boot.consoleLogLevel = 0;
  boot.initrd.verbose = false;
  boot.initrd.systemd.enable = true;
  boot.initrd.systemd.tpm2.enable = false;

  boot.supportedFilesystems = ["exfat"];
  programs.fuse.enable = true;

  # Keep latest kernel for current hardware support
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.blacklistedKernelModules = [
    "sp5100_tco"
    "eeepc_wmi"
    "joydev"
    "pcspkr"
  ];

  boot.kernelParams = [
    "quiet"
    "splash"
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
    "split_lock_detect=off"
  ];
}
