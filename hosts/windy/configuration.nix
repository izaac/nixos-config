{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./nvidia.nix
    ./network.nix
    ../../modules/core
    ../../modules/gaming
    ../../modules/desktop
    ../../users/izaac
    # nixos-hardware: Intel CPU, NVIDIA Prime offload, laptop power, SSD trim
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Custom Feature Flags
  mySystem = {
    gaming.enable = true;
    desktop.enable = true;
    core = {
      audio.enable = true;
      bluetooth.enable = true;
      codecs.enable = true;
      virtualization.enable = true;
      nfs.enable = false;
      maintenance.enable = true;
      performance.enable = true;
      sops.enable = true;
      system.enable = true;
      usb-fixes.enable = true;
      user.enable = true;
      home-manager.enable = true;
      theme.enable = true;
      nix-ld.enable = true;
    };
  };

  # Bootloader
  boot = {
    loader = {
      systemd-boot = {
        enable = true;
        configurationLimit = 10;
      };
      efi.canTouchEfiVariables = true;
    };

    # File Systems
    supportedFilesystems = ["exfat"];

    # --- KERNEL ---
    kernelPackages = pkgs.linuxPackages_latest;

    tmp.useTmpfs = true;

    # --- CORE HARDWARE TWEAKS ---
    kernelParams = [
      "boot.shell_on_fail"
      "iommu=pt"
      "usbcore.autosuspend=-1"
      # Fix for some Intel/NVIDIA laptop backlight issues
      "acpi_backlight=vendor"
    ];
  };

  # System-level Flatpak (required by nix-flatpak home module)
  services.flatpak.enable = true;

  # Laptop-specific Power Management
  services = {
    thermald.enable = true;
    tlp = {
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
    # Disable unnecessary services
    colord.enable = false;
  };

  # Hardware Firmware
  hardware.enableAllFirmware = true;
  # System Packages
  environment.systemPackages = with pkgs; [
    powertop # Monitor laptop power usage
    brightnessctl # Control screen brightness
    acpi # Battery/Thermal info
    libnotify # For OSD notifications
  ];

  systemd.services.ModemManager.enable = false;

  system.stateVersion = "25.11";
}
