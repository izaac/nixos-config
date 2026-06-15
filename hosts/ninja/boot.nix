{lib, ...}: {
  boot = {
    # EFI vars come from the workstation profile. systemd-boot is replaced by
    # Limine to gain Secure Boot (sbctl-signed) support; the profile enables
    # systemd-boot at mkDefault, so disable it with mkForce here.
    loader = {
      systemd-boot.enable = lib.mkForce false;
      grub.enable = false;
      limine = {
        enable = true;
        efiSupport = true;
        # Boot-entry editor allows `init=/bin/sh` -> root. Must stay false for
        # Secure Boot to be meaningful.
        enableEditor = false;
        maxGenerations = 10;
        # Keys created + enrolled (sbctl, PK/KEK/db present). This signs the
        # Limine EFI binary at install time. Enforce Secure Boot in BIOS
        # (OS Type -> Windows UEFI) only after this builds and `sbctl verify`
        # is clean.
        secureBoot.enable = true;
      };
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
