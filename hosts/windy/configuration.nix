{
  config,
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
      # The internal OLED panel (card1-eDP-1) is driven by Intel i915, so use
      # the native GPU backlight interface. acpi_backlight=vendor suppressed
      # the i915 backlight without providing a working vendor interface,
      # leaving /sys/class/backlight empty (no brightness control) and
      # disabling the ACPI brightness key events. native registers
      # intel_backlight and restores the Fn brightness keys.
      "acpi_backlight=native"
    ];

    # opengigabyte HID module: the keyboard sends vendor-specific raw reports
    # for Fn+F3/F4 (brightness) that the kernel does not map, so the keys are
    # dead. This driver translates them into standard XF86MonBrightness events.
    # Built against this host's kernel; needs intel_backlight (acpi_backlight=native).
    extraModulePackages = [
      (config.boot.kernelPackages.callPackage "${inputs.nix-packages}/pkgs/opengigabyte" {})
    ];
    kernelModules = ["gigabytekbd"];
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
        # Disable Intel Turbo Boost. The i9-11980HK bursts to ~5GHz on the
        # slightest load, which spikes package temperature and ramps the fans
        # even at idle. Capping at the base frequency keeps the laptop quiet
        # for everyday use at a modest peak-performance cost. GameMode does not
        # re-enable turbo, so heavy gaming also stays capped here.
        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;
        # Cap sustained CPU load so a single busy core cannot push the whole
        # package hot enough to trigger the loud fan curve.
        CPU_MAX_PERF_ON_AC = 80;
        CPU_MAX_PERF_ON_BAT = 60;
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

  # Disable SOPS on windy: its SSH host key is not enrolled as a sops-nix
  # recipient (and no user age key is present), so secret decryption fails
  # at activation. None of windy's system services consume these secrets,
  # so skip the whole stack here. Re-enable by enrolling windy's host age
  # key in .sops.yaml and re-encrypting the secrets.
  mySystem.core.sops.enable = false;

  # Allow members of the video group to write screen brightness via
  # brightnessctl (installs the packages udev rules that chgrp/chmod the
  # backlight sysfs nodes). Required for the Fn brightness keys to work.
  services.udev.packages = [pkgs.brightnessctl];

  # Detach the NVIDIA dGPU's KMS (card) node from the login seat so the niri
  # compositor never opens it. niri then composites purely on the Intel iGPU
  # and the dGPU can runtime-suspend to D3cold at idle instead of sitting at
  # ~13W. The NVIDIA render node is a separate device and keeps its access
  # rules, so PRIME render offload still wakes the dGPU on demand for games.
  # Trade-off: the external HDMI/DisplayPort outputs are wired to the dGPU and
  # are disabled while it is hidden from the seat.
  services.udev.extraRules = ''
    SUBSYSTEM=="drm", KERNEL=="card*", ATTRS{vendor}=="0x10de", TAG-="master-of-seat"
  '';

  # System Packages
  environment.systemPackages = with pkgs; [
    powertop # Monitor laptop power usage
    acpi # Battery/Thermal info
    # brightnessctl + libnotify live in home/niri.nix (shared HM module)
  ];

  system.stateVersion = "25.11";
}
