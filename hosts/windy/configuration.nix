{
  config,
  pkgs,
  lib,
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
      # The internal OLED panel (card1-eDP-1) is driven by Intel i915, so use
      # the native GPU backlight interface. acpi_backlight=vendor suppressed
      # the i915 backlight without providing a working vendor interface,
      # leaving /sys/class/backlight empty (no brightness control) and
      # disabling the ACPI brightness key events. native registers
      # intel_backlight and restores the Fn brightness keys.
      "acpi_backlight=native"

      # --- ENERGY EFFICIENCY ---
      # The inverse of ninja, which compiles a bespoke low-latency kernel and
      # boots it with preempt=full. windy stays on the cached linuxPackages_latest
      # (a structuredExtraConfig would defeat the binary cache and make every
      # kernel bump a multi-hour local compile on a laptop, costing far more
      # energy than the config could save) and tunes for power at boot instead.
      #
      # PREEMPT_DYNAMIC lets the preemption model be chosen on the command line.
      # voluntary preempts at fewer points than full, so the scheduler runs less
      # often and the CPU reaches its idle states more readily. Interactive
      # latency is slightly worse, which is the right trade here.
      "preempt=voluntary"

      # Let the PCIe link drop into its deepest sleep state between transfers.
      # This is the single largest idle win on a laptop of this generation.
      "pcie_aspm.policy=powersupersave"

      # Skip the ACPI-mediated NVMe power path, which on many Intel laptops
      # blocks the controller from reaching APST's deeper idle states.
      "nvme.noacpi=1"

      # Panel Self Refresh. The panel advertises PSR1 support but i915's auto
      # mode (enable_psr=-1) leaves it disabled, so the display controller
      # re-scans the framebuffer continuously even on a completely static
      # screen. Forcing it on lets the panel hold its own image instead, which
      # matters most at this resolution: there is no lower mode to fall back to,
      # eDP-1 only offers 3840x2160, so every refresh moves 8.3M pixels.
      # Helps while reading or idling, does nothing during video playback.
      # If the display ever flickers or dims oddly, drop this line; PSR on OLED
      # is occasionally glitchy and the previous generation boots without it.
      "i915.enable_psr=1"

      # USB autosuspend is left at the kernel default. ninja opts out of it in
      # hosts/ninja/performance.nix for input latency; a laptop wants the sleep.
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

  # Laptop sysctl deltas. modules/core/performance.nix tunes dirty-page
  # writeback for a desktop that is always plugged in; a laptop wants the
  # opposite, so writeback batches into fewer, larger flushes and the disk
  # stays idle for longer stretches. mkForce because the shared module sets
  # these at normal priority.
  boot.kernel.sysctl = {
    "vm.laptop_mode" = 5;
    "vm.dirty_writeback_centisecs" = lib.mkForce 6000;
    "vm.dirty_expire_centisecs" = lib.mkForce 6000;
    # The NMI watchdog wakes every core on a timer purely to detect hard
    # lockups. Real cost on idle power, no value on a personal laptop.
    "kernel.nmi_watchdog" = 0;
  };

  # Laptop-specific Power Management
  services = {
    thermald.enable = true;

    # The gaming module defaults scx_lavd on for every host that enables it.
    # scx_lavd optimises for frame latency by keeping cores awake, which fights
    # TLP for control of this machine's power. TLP wins here.
    scx.enable = lib.mkForce false;

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

        # --- Runtime power management ---
        # Let idle PCIe devices (NVMe, Wi-Fi, Thunderbolt, the NVIDIA GPU)
        # suspend themselves. finegrained NVIDIA power management in
        # hosts/windy/nvidia.nix depends on runtime PM being allowed.
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";

        # USB autosuspend, now that the kernel parameter no longer forbids it.
        # The deny list keeps input devices responsive; anything else may sleep.
        USB_AUTOSUSPEND = 1;
        USB_EXCLUDE_BTUSB = 0;
        USB_EXCLUDE_PHONE = 1;

        # Wi-Fi radio power saving costs a little latency on wake, which is
        # invisible for browsing and worth several hundred milliwatts.
        WIFI_PWR_ON_AC = "off";
        WIFI_PWR_ON_BAT = "on";

        # Power down the audio codec after a second of silence. Some codecs
        # pop on transition; this one does not.
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;

        # Aggressive SATA link power management for the secondary drive.
        SATA_LINKPWR_ON_AC = "med_power_with_dipm";
        SATA_LINKPWR_ON_BAT = "min_power";

        # Firmware-level power hints (Intel platform profile).
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "low-power";

        # Stop charging at 80% and only start again below 75%. Far and away the
        # biggest lever on long-term battery health for a laptop that mostly
        # lives on AC.
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };
    # Disable unnecessary services
    colord.enable = false;

    # --- Daemons pruned for idle power ---

    # acpid runs with no handlers here (no /etc/acpi/events entries) and
    # systemd-logind already owns the lid switch and power key. ninja force
    # disables it for the same reason. mkForce because nixos-hardware's laptop
    # module turns it on.
    acpid.enable = lib.mkForce false;

    # irqbalance spreads interrupts across cores to avoid thermal hotspots,
    # which means periodically waking cores that were idle. Worth it on ninja,
    # not on a machine running off a battery.
    irqbalance.enable = false;

    # No flatpak apps are installed here, so the system helper and the weekly
    # update timer have nothing to do. home/flatpak.nix follows this switch.
    flatpak.enable = false;
  };

  # Bluetooth stays available, but the radio starts cold rather than powered up
  # at every boot. Nothing has ever been paired with this machine.
  hardware.bluetooth.powerOnBoot = false;

  # --- PRUNED FOR IDLE POWER ---
  mySystem.core = {
    # Podman, the docker CLI shim, quickemu/quickgui/virt-viewer/remmina and the
    # nvidia-container-toolkit CDI generator. Containers belong on ninja.
    virtualization.enable = false;

    # CUPS, cups-browsed, avahi-daemon and the declarative queue. cups-browsed
    # and avahi both poll the network continuously to discover printers, which
    # is pure drain on a machine that leaves the LAN. Print from ninja.
    printing.enable = false;

    # Mesh VPN and Tailscale SSH, matching ninja. tailscaled is event-driven
    # and idles cheaply, so it stays.
    tailscale.enable = true;
  };

  # Disable SOPS on windy: its SSH host key is not enrolled as a sops-nix
  # recipient (and no user age key is present), so secret decryption fails
  # at activation. None of windy's system services consume these secrets,
  # so skip the whole stack here. Re-enable by enrolling windy's host age
  # key in .sops.yaml and re-encrypting the secrets.
  mySystem.core.sops.enable = false;

  # Allow members of the video group to write screen brightness via
  # brightnessctl's udev rules (they chgrp/chmod the backlight sysfs nodes).
  # Required for the Fn brightness keys, which drive brightness through
  # ashell's IPC writing directly to those nodes.
  services.udev.packages = [pkgs.brightnessctl];

  # Disable KMS on the dGPU. modules/desktop/nvidia.nix turns modesetting on,
  # and the nixpkgs module also forces nvidia-drm.modeset=1 whenever PRIME
  # offload is enabled, which registers /dev/dri/card0 for the dGPU. niri
  # composites on the Intel iGPU (render-drm-device in home/niri.nix), but the
  # card node still sits on the login seat and something opens it at session
  # start, pinning the GPU awake: runtime_suspended_time stayed at 0 across a
  # whole uptime while the card burned ~12.5W in P8, over half the machine's
  # idle draw. With modeset=0 the dGPU exposes only its render node, so nothing
  # can hold the KMS device and it reaches D3cold. PRIME render offload runs off
  # the render node and is unaffected, so games still use the dGPU on demand.
  #
  # Trade-off: the external HDMI/DisplayPort outputs are wired to the dGPU and
  # stay dark. Previously attempted with a udev rule that stripped the seat tags
  # (541facc), which left niri unable to start at all; overriding the module
  # parameter is the supported knob and leaves the seat untouched.
  hardware.nvidia.moduleParams."nvidia-drm" = {
    modeset = lib.mkForce 0;
    fbdev = lib.mkForce 0;
  };

  # System Packages
  environment.systemPackages = with pkgs; [
    powertop # Monitor laptop power usage
    acpi # Battery/Thermal info
    # libnotify lives in home/niri.nix (shared HM module); brightnessctl is
    # installed above only for its udev rules, not as a user command.
  ];

  system.stateVersion = "25.11";
}
