# hosts/windy/hardware.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "thunderbolt" "vmd" "nvme" "usb_storage" "sd_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  # --- PLACEHOLDER FILESYSTEMS ---
  # Replace UUIDs after running 'nixos-generate-config' or 'lsblk -f' on the target
  fileSystems."/" =
    { device = "/dev/disk/by-uuid/REPLACE_ME_ROOT_UUID";
      fsType = "ext4";
      options = [ "noatime" "nodiratime" "lazytime" "commit=60" ];
    };

  fileSystems."/boot" =
    { device = "/dev/disk/by-uuid/REPLACE_ME_BOOT_UUID";
      fsType = "vfat";
      options = [ "fmask=0077" "dmask=0077" ];
    };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.intel.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
