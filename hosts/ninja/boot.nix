{pkgs, ...}: {
  boot = {
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

    # No Plymouth, no quiet — plain systemd-initrd handles the LUKS prompt.
    consoleLogLevel = 3;
    initrd = {
      verbose = false;
      systemd = {
        enable = true;
        tpm2.enable = false;
      };
    };

    supportedFilesystems = ["exfat"];

    kernelPackages = pkgs.linuxPackages_latest;
    blacklistedKernelModules = [
      "sp5100_tco"
      "eeepc_wmi"
      "joydev"
      "pcspkr"
    ];

    kernelParams = [
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
