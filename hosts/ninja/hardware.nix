# hosts/ninja/hardware.nix
{
  config,
  lib,
  modulesPath,
  ...
}: {
  imports = [(modulesPath + "/installer/scan/not-detected.nix")];

  boot.initrd.availableKernelModules = ["nvme" "xhci_pci" "ahci" "usbhid" "uas" "usb_storage" "sd_mod" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = ["kvm-amd" "nct6775" "ntsync"];
  boot.extraModulePackages = [];

  # Workaround for Intel I225-V (igc) dropping connections after a few hours
  # Prevents PCIe power management from putting the NIC into a state it can't recover from
  boot.kernelParams = ["pcie_port_pm=off" "pcie_aspm.policy=performance"];

  # NFS mount — not managed by disko, always present
  fileSystems."/mnt/storage" = {
    device = "192.168.0.173:/storage";
    fsType = "nfs4";
    options = [
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=900"
      "x-systemd.mount-timeout=5s"
      "x-systemd.device-timeout=5s"
      "nconnect=4"
      "rsize=1048576"
      "wsize=1048576"
      "actimeo=60"
      "noatime"
      "nodiratime"
      "hard"
      "timeo=14"
    ];
  };

  swapDevices = [];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
