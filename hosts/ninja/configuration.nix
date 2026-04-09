{pkgs, ...}: {
  # This is 'ninja' — a high-performance workstation built around the Ryzen 9 9950X3D and NVIDIA.
  # It's optimized for zero-latency desktop feel, high-fidelity audio, and maximum gaming throughput.

  imports = [
    ./hardware.nix
    ./nvidia.nix
    ./network.nix
    ./udev-igc-fix.nix
    ./boot.nix
    ./performance.nix
    ./audio.nix
    ./firefox.nix
    ./chromium.nix
    ../../modules/core
    ../../modules/gaming
    ../../modules/desktop
    ../../users/izaac
  ];

  # --- CORE FEATURES ---
  # Enabling the modular components that make up this system's identity.
  mySystem.gaming.enable = true;
  mySystem.desktop.enable = true;
  mySystem.core.audio.enable = true;
  mySystem.core.bluetooth.enable = true;
  mySystem.core.codecs.enable = true;
  mySystem.core.virtualization.enable = true;
  mySystem.core.nfs.enable = true;
  mySystem.core.maintenance.enable = true;
  mySystem.core.performance.enable = true;
  mySystem.core.sops.enable = true;
  mySystem.core.system.enable = true;
  mySystem.core.usb-fixes.enable = true;
  mySystem.core.user.enable = true;
  mySystem.core.home-manager.enable = true;
  mySystem.core.nix-ld.enable = true;

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
  ];

  # --- SLIMMING THE SYSTEM ---
  # Keep man pages for offline reference; skip NixOS module docs and info pages.
  documentation = {
    enable = true;
    doc.enable = false;
    man.enable = true;
    info.enable = false;
  };

  system.stateVersion = "25.11";
}
