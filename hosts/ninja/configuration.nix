{
  pkgs,
  lib,
  inputs,
  ...
}: {
  # --- VIRTUALIZATION VARIANT ---
  virtualisation.vmVariant = {
    # Disable NVIDIA in the VM
    services.xserver.videoDrivers = lib.mkForce ["modesetting"];
    hardware = {
      nvidia.package = lib.mkForce pkgs.hello;
      graphics.extraPackages = lib.mkForce [];
      # Disable NVIDIA toolkit in VM
      nvidia-container-toolkit.enable = lib.mkForce false;
    };
    systemd.services.nvidia-lock-clocks.enable = lib.mkForce false;
    # No sops secrets needed in the VM
    sops.gnupg.home = lib.mkForce "/tmp/gnupg";
  };

  # This is 'ninja' — a high-performance workstation built around the Ryzen 9 9950X3D and NVIDIA.
  # It's optimized for zero-latency desktop feel, high-fidelity audio, and maximum gaming throughput.

  imports = [
    ./hardware.nix
    ./disko.nix
    ./nvidia.nix
    ./network.nix
    ./udev-igc-fix.nix
    ./boot.nix
    ./performance.nix
    ./audio.nix
    ./chromium.nix
    ../../modules/core
    ../../modules/gaming
    ../../modules/desktop
    ../../users/izaac
    # nixos-hardware: AMD pstate, NVIDIA (nonprime/desktop), SSD trim
    inputs.nixos-hardware.nixosModules.common-cpu-amd-pstate
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia-nonprime
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # --- CORE FEATURES ---
  # Enabling the modular components that make up this system's identity.
  mySystem = {
    gaming = {
      enable = true;
      cpuBoostFreq = 5756452; # 5.7 GHz
      cpuBaseFreq = 4500000; # 4.5 GHz
      gpuBoostClock = 2475; # RTX 5070 Ti gaming
      gpuBaseClock = 2100; # RTX 5070 Ti efficiency
      thermalGuard = {
        enable = true;
        throttleTemp = 90;
        recoverTemp = 80;
      };
    };
    desktop.enable = true;
    core = {
      audio.enable = true;
      bluetooth.enable = true;
      codecs.enable = true;
      virtualization.enable = true;
      nfs.enable = true;
      maintenance.enable = true;
      performance.enable = true;
      sops.enable = true;
      system.enable = true;
      usb-fixes.enable = true;
      user.enable = true;
      theme.enable = true;
      home-manager.enable = true;
      nix-ld.enable = true;
    };
  };

  # --- DRIVERS & FIRMWARE ---
  # Including all firmware to ensure the 9950X3D and NVIDIA GPU have everything they need.
  hardware.enableAllFirmware = true;

  # --- TOOLS OF THE TRADE ---
  # Essential CLI utilities for system management and audio debugging.
  environment.systemPackages = with pkgs; [
    libglvnd
    parted
    nmap
    alsa-utils # CLI audio tools (aplay, amixer)
    libpulseaudio # Compatibility library
    ddcutil # Monitor brightness control via DDC/CI
    btop
  ];

  # Allow ddcutil to access I2C devices
  hardware.i2c.enable = true;

  # --- SLIMMING THE SYSTEM ---
  # Keep man pages for offline reference; skip NixOS module docs and info pages.
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    info.enable = false;
  };

  # MIME defaults centralized in home/desktop.nix (user-level takes precedence)

  system.stateVersion = "25.11";
}
