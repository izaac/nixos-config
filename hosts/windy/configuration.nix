{
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware.nix
    ./nvidia.nix
    ./network.nix
    ./ssh.nix
    ../../modules/core
    ../../modules/gaming
    ../../modules/desktop
    ../../modules/profiles/workstation.nix
    ../../users/izaac
    # nixos-hardware: Intel CPU, NVIDIA Prime offload, laptop power, SSD trim
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Shared baseline (mySystem flags, bootloader, exfat, tmpfs, flatpak,
  # firmware) comes from modules/profiles/workstation.nix; windy keeps
  # only its laptop deltas.
  boot = {
    # --- KERNEL ---
    kernelPackages = pkgs.linuxPackages_latest;

    # --- CORE HARDWARE TWEAKS ---
    kernelParams = [
      "boot.shell_on_fail"
      "iommu=pt"
      "usbcore.autosuspend=-1"
      # Fix for some Intel/NVIDIA laptop backlight issues
      "acpi_backlight=vendor"
    ];
  };

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

  # System Packages
  environment.systemPackages = with pkgs; [
    powertop # Monitor laptop power usage
    acpi # Battery/Thermal info
    # brightnessctl + libnotify live in home/niri.nix (shared HM module)
  ];

  system.stateVersion = "25.11";
}
