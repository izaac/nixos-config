{ config, pkgs, inputs, lib, userConfig, ... }:

{
  imports =
    [ 
      ./hardware.nix
      ./nvidia.nix
      ./network.nix
      ../../modules/core
      ../../modules/gaming
      ../../modules/desktop
    ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  # Laptop-specific Power Management
  services.thermald.enable = true;
  services.tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      # Helps with Intel-specific power savings
      INTEL_GPU_MIN_FREQ_ON_AC = 800;
      INTEL_GPU_MIN_FREQ_ON_BAT = 300;
      INTEL_GPU_BOOST_FREQ_ON_AC = 1300;
      INTEL_GPU_BOOST_FREQ_ON_BAT = 800;
    };
  };

  # File Systems
  boot.supportedFilesystems = [ "exfat" ];

  # --- KERNEL ---
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  
  boot.tmp.useTmpfs = true;

  # --- CORE HARDWARE TWEAKS ---
  boot.kernelParams = [
    "boot.shell_on_fail"
    "iommu=pt"
    "usbcore.autosuspend=-1"
    # Fix for some Intel/NVIDIA laptop backlight issues
    "acpi_backlight=vendor" 
  ];

  programs.light.enable = true;

  # Hardware Firmware
  hardware.enableAllFirmware = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    powertop     # Monitor laptop power usage
    brightnessctl # Control screen brightness
    acpi          # Battery/Thermal info
    libnotify     # For OSD notifications
  ];

  # Windy-specific SSH overrides (Password Auth allowed for easier remote setup)
  services.openssh.settings = {
    PasswordAuthentication = lib.mkForce true;
    KbdInteractiveAuthentication = lib.mkForce true;
  };
  
  # Disable unnecessary services
  services.colord.enable = false;
  systemd.services.ModemManager.enable = false;

  system.stateVersion = "25.11";
}
