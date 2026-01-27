# hosts/ninja/hardware.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "uas" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = { 
    device = "/dev/disk/by-uuid/4d34b1f8-2252-429d-859e-4d61bc0d6290";
    fsType = "ext4";
  };

  fileSystems."/boot" = { 
    device = "/dev/disk/by-uuid/D09D-4904";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # --- GAME DRIVE (NVMe) ---
  fileSystems."/mnt/data" = { 
    device = "/dev/disk/by-uuid/e76c3d51-616c-446a-89ae-f7083290e290";
    fsType = "ext4";
    options = [ 
      "rw"
      "noatime"
      "nofail"
      # We removed 'users' because it was forcing 'noexec'
      # We removed 'uid/gid' because EXT4 doesn't use them (permissions are on-disk)
      "exec" 
      "x-systemd.automount" 
    ];
  };

  swapDevices = [ { device = "/dev/disk/by-uuid/3f12ad87-1c08-4366-a556-535bce1b9476"; } ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
