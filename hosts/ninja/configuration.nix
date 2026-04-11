{
  pkgs,
  lib,
  ...
}: {
  # --- VIRTUALIZATION VARIANT ---
  virtualisation.vmVariant = {
    # Disable NVIDIA in the VM
    services.xserver.videoDrivers = lib.mkForce ["modesetting"];
    hardware.nvidia.package = lib.mkForce pkgs.hello;
    systemd.services.nvidia-lock-clocks.enable = lib.mkForce false;
    hardware.graphics.extraPackages = lib.mkForce [];
    # No sops secrets needed in the VM
    sops.gnupg.home = lib.mkForce "/tmp/gnupg";
    # Disable NVIDIA toolkit in VM
    hardware.nvidia-container-toolkit.enable = lib.mkForce false;
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
    ddcutil # Monitor brightness control via DDC/CI
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

  # --- DEFAULT APPLICATIONS ---
  # Override COSMIC's system-level cosmic-mimeapps.list so the Settings panel
  # and xdg-mime both resolve to the correct apps.
  xdg.mime.defaultApplications = {
    "x-scheme-handler/http" = "chromium-browser.desktop";
    "x-scheme-handler/https" = "chromium-browser.desktop";
    "text/html" = "chromium-browser.desktop";
    "audio/mpeg" = "com.galacticpirateradio.ethereal-waves.desktop";
    "audio/flac" = "com.galacticpirateradio.ethereal-waves.desktop";
    "audio/x-wav" = "com.galacticpirateradio.ethereal-waves.desktop";
    "audio/ogg" = "com.galacticpirateradio.ethereal-waves.desktop";
    "audio/x-vorbis+ogg" = "com.galacticpirateradio.ethereal-waves.desktop";
    "audio/mp4" = "com.galacticpirateradio.ethereal-waves.desktop";
    "audio/x-flac" = "com.galacticpirateradio.ethereal-waves.desktop";
    "audio/x-mp3" = "com.galacticpirateradio.ethereal-waves.desktop";
    "video/mp4" = "net.base_art.Glide.desktop";
    "video/x-matroska" = "net.base_art.Glide.desktop";
    "video/webm" = "net.base_art.Glide.desktop";
    "video/quicktime" = "net.base_art.Glide.desktop";
    "video/x-msvideo" = "net.base_art.Glide.desktop";
    "video/mpeg" = "net.base_art.Glide.desktop";
    "video/ogg" = "net.base_art.Glide.desktop";
    "video/x-flv" = "net.base_art.Glide.desktop";
    "video/x-ms-wmv" = "net.base_art.Glide.desktop";
  };

  system.stateVersion = "25.11";
}
