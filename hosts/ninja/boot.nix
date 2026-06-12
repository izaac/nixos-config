_: {
  boot = {
    # systemd-boot enable/limit + EFI vars come from the workstation profile.
    loader = {
      systemd-boot = {
        editor = false;
        consoleMode = "max";
      };
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

    blacklistedKernelModules = [
      "sp5100_tco"
      "eeepc_wmi"
      "pcspkr"
    ];

    kernelParams = [
      "boot.shell_on_fail"
      "pci=realloc,pcie_bus_safe"
      "pcie_aspm=off"
      "iommu=pt"
      "pcie_ports=native"
      "amd_pstate=active"
      # Silence split-lock dmesg spam from Steam/Wine games. The mitigation
      # itself is already disabled via kernel.split_lock_mitigate=0 in
      # performance.nix; this just stops the kernel from logging traps.
      "split_lock_detect=off"
    ];
  };
  programs.fuse = {
    enable = true;
    userAllowOther = true;
  };
}
