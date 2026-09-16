# hosts/ninja/hardware.nix
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot = {
    initrd = {
      availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "uas" "usb_storage" "sd_mod" "sr_mod"];
      kernelModules = [];
    };
    kernelModules = ["kvm-amd" "nct6775" "ntsync"];
    extraModulePackages = [];

    # Workaround for Intel I225-V (igc) dropping connections after a few hours
    # Prevents PCIe power management from putting the NIC into a state it can't recover from
    # Note: pcie_aspm=off is already set in boot.nix (pcie_aspm.policy is not a valid param)
    kernelParams = ["pcie_port_pm=off"];
  };

  # disko does not set neededForBoot for root — without this the initrd
  # has no /etc/fstab entry, so systemd never mounts /sysroot after LUKS.
  fileSystems."/".neededForBoot = true;

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
