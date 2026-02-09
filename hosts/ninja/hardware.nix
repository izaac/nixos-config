# hosts/ninja/hardware.nix
{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [ "nvme" "xhci_pci" "ahci" "usbhid" "uas" "usb_storage" "sd_mod" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    { device = "/dev/mapper/luks-782b8c84-7a71-4244-8a98-c884f7678b96";
      fsType = "ext4";
      options = [ "noatime" "nodiratime" "lazytime" "commit=60" ];
    };

  boot.initrd.luks.devices."luks-782b8c84-7a71-4244-8a98-c884f7678b96".device = "/dev/disk/by-uuid/782b8c84-7a71-4244-8a98-c884f7678b96";

  fileSystems."/boot" = { 
    device = "/dev/disk/by-uuid/48E1-0BDF";
    fsType = "vfat";
    options = [ "fmask=0077" "dmask=0077" ];
  };

  # --- GAME DRIVE (NVMe) ---
  fileSystems."/mnt/data" = { 
    device = "/dev/disk/by-uuid/7f69bc73-1ebb-4883-851a-f08d8101da9e";
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

  fileSystems."/mnt/storage" = {
    device = "//192.168.0.173/storage";
    fsType = "cifs";
    options = [
      "credentials=/etc/nixos/samba-creds"
      "uid=1000"
      "gid=100"
      "vers=3.0"
      "x-systemd.automount"
      "noauto"
      "x-systemd.idle-timeout=60"
      "x-systemd.mount-timeout=5s"
    ];
  };

  swapDevices = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}