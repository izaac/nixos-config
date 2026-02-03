# hosts/ninja/hardware.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "uas" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "ntsync" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = { 
    device = "/dev/disk/by-uuid/522b2e41-a6da-40eb-a666-84c80503afdc";
    fsType = "ext4";
    options = [ "noatime" "commit=60" "lazytime" ];
  };

  fileSystems."/boot" = { 
    device = "/dev/disk/by-uuid/F1EC-8130";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # --- GAME DRIVE (NVMe) ---
  fileSystems."/mnt/data" = { 
    device = "/dev/disk/by-uuid/ebde3930-7313-4fe2-aee8-a15b7a96ae2e";
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
