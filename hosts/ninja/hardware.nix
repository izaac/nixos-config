# hosts/ninja/hardware.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "uas" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "ntsync" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = { 
    device = "/dev/disk/by-uuid/4d34b1f8-2252-429d-859e-4d61bc0d6290";
    fsType = "ext4";
    options = [ "noatime" "commit=60" "lazytime" ];
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
      "commit=60"
      "nofail"
      "lazytime"
      # Removed 'users' to avoid forcing 'noexec'
      # Removed 'uid/gid' as EXT4 handles permissions on-disk
      "exec" 
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
