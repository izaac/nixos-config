{ config, pkgs, inputs, lib, userConfig, ... }:

{
  imports =
    [ 
      ./hardware.nix
      ./nvidia.nix
      ./network.nix
      ../../modules/core/nix-ld.nix
      ../../modules/core/codecs.nix
      ../../modules/core/bluetooth-audio.nix
      ../../modules/core/virtualization.nix
      ../../modules/core/usb-fixes.nix
      ../../modules/core/maintenance.nix
      ../../modules/core/performance.nix
      ../../modules/gaming/default.nix
      ../../modules/desktop/default.nix
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
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
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
  # Pin to Linux 6.18 for stability/compatibility parity
  boot.kernelPackages = pkgs.linuxPackages_6_18;
  
  # ZRAM (Compressed RAM Swap) - Essential for laptops to reduce SSD wear
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 100;
    priority = 100;
  };
  boot.tmp.useTmpfs = true;

  # --- CORE HARDWARE TWEAKS ---
  boot.kernelParams = [
    "boot.shell_on_fail"
    "iommu=pt"
    "usbcore.autosuspend=-1"
  ];

  programs.light.enable = true;

  time.timeZone = "America/Phoenix";
  i18n.defaultLocale = "en_US.UTF-8";

  # Audio (Pipewire)
  services.pulseaudio.enable = false;
  # This is often needed for Fn keys to be recognized as audio controls
  sound.enable = true; 
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  # User Account
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.name;
    extraGroups = [ "wheel" "input" "video" "render" "dialout" "podman" "audio" "networkmanager" ];
  };

  # Sudo Config
  security.sudo = {
    enable = true;
    wheelNeedsPassword = true;
  };

  # Hardware Firmware
  hardware.enableAllFirmware = true;

  # System Packages
  environment.systemPackages = with pkgs; [
    vim
    wget
    curl
    file
    tree
    pciutils
    usbutils
    powertop     # Monitor laptop power usage
    brightnessctl # Control screen brightness
    acpi          # Battery/Thermal info
    libnotify     # For OSD notifications
  ];

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
    };
  };
  
  services.fstrim.enable = true;
  services.power-profiles-daemon.enable = false;

  # Nix Maintenance
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 7d";
  };
  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "@wheel" ];

  system.stateVersion = "25.11";
}