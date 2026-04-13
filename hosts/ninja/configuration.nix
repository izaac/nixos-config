{
  pkgs,
  lib,
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
  ];

  # --- CORE FEATURES ---
  # Enabling the modular components that make up this system's identity.
  mySystem = {
    gaming.enable = true;
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
    "x-scheme-handler/http" = "brave-origin.desktop";
    "x-scheme-handler/https" = "brave-origin.desktop";
    "text/html" = "brave-origin.desktop";
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
