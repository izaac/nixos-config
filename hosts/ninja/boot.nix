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
      # Fragnesia mitigation (CVE-2026-46300) — disable XFRM ESP-in-TCP until
      # nixpkgs ships a kernel >= 7.0.8 / 6.18.31 with the upstream fix.
      "esp4"
      "esp6"
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
  programs.fuse = {
    enable = true;
    userAllowOther = true;
  };
}
