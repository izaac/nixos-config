# windy: laptop (Intel i9-11980HK + NVIDIA Prime offload). Optimized for battery, thermals, quiet.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  _force = import ../../lib/mkForceIf.nix {inherit lib;};
  # PCI address of dGPU audio function (HDA controller). Derived from PRIME bus id in nvidia.nix.
  nvidiaAudioFn = let
    parts = lib.splitString ":" (lib.removePrefix "PCI:" config.hardware.nvidia.prime.nvidiaBusId);
    pad = lib.fixedWidthString 2 "0";
  in "0000:${pad (builtins.elemAt parts 0)}:${pad (builtins.elemAt parts 1)}.1";
in {
  imports = [
    ../common.nix
    ./hardware.nix
    ./nvidia.nix
    ./network.nix
    ./ssh.nix
    # nixos-hardware: Intel CPU, NVIDIA Prime offload, laptop power, SSD trim
    inputs.nixos-hardware.nixosModules.common-cpu-intel
    inputs.nixos-hardware.nixosModules.common-gpu-nvidia
    inputs.nixos-hardware.nixosModules.common-pc-laptop
    inputs.nixos-hardware.nixosModules.common-pc-ssd
  ];

  # Host deltas: disable virtualization, printing, sops.
  mySystem = {
    core = {
      virtualization.enable = false;
      printing.enable = false;
      sops.enable = false;
    };
  };

  # Kernel & boot: latest kernel, native backlight, voluntary preempt, NVMe tweaks.
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "boot.shell_on_fail"
      "iommu=pt"
      # Native backlight: acpi_backlight=vendor broke i915 backlight; native restores intel_backlight and Fn keys.
      "acpi_backlight=native"
      # Voluntary preempt: less scheduler overhead than full, better idle power on laptop.
      "preempt=voluntary"
      # Skip ACPI NVMe path to reach deeper APST idle states.
      "nvme.noacpi=1"
    ];

    extraModulePackages = [
      # opengigabyte HID: translates vendor Fn+F3/F4 to XF86MonBrightness; needs intel_backlight.
      (config.boot.kernelPackages.callPackage "${inputs.nix-packages}/pkgs/opengigabyte" {})
    ];
    kernelModules = ["gigabytekbd"];

    kernel.sysctl = {
      "vm.laptop_mode" = 5;
      # Laptop dirty-page tuning: batch writes for longer disk idle (vs desktop in performance.nix).
      "vm.dirty_writeback_centisecs" = _force.sysctlForceIf true "vm.dirty_writeback_centisecs" 6000;
      "vm.dirty_expire_centisecs" = _force.sysctlForceIf true "vm.dirty_expire_centisecs" 6000;
      # NMI watchdog: wakes cores on timer, costs idle power, no value on laptop.
      "kernel.nmi_watchdog" = 0;
    };
  };

  # Power: thermald, TLP tuned for powersave, no turbo, charge limits.
  services = {
    thermald.enable = true;
    scx.enable = _force.mkForceIf true false;

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        # Turbo off: i9-11980HK bursts to 5GHz on idle load, spikes temp/fans. GameMode doesn't re-enable.
        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;
        # Cap sustained load: single core can't push package hot enough for loud fan curve.
        CPU_MAX_PERF_ON_AC = 80;
        CPU_MAX_PERF_ON_BAT = 60;
        INTEL_GPU_MIN_FREQ_ON_AC = 800;
        INTEL_GPU_MIN_FREQ_ON_BAT = 300;
        INTEL_GPU_BOOST_FREQ_ON_AC = 1300;
        INTEL_GPU_BOOST_FREQ_ON_BAT = 800;
        # Runtime PM auto: lets NVMe, WiFi, TBT, dGPU suspend. Required for fine-grained NVIDIA PM.
        RUNTIME_PM_ON_AC = "auto";
        PCIE_ASPM_ON_BAT = "powersupersave";
        # USB autosuspend default; phone exclusion prevents charging interruption.
        USB_EXCLUDE_PHONE = 1;
        # Sound power save off on AC: codec pops on transition. Only card0 (PCH) affected.
        SOUND_POWER_SAVE_ON_AC = 0;
        # Charge limit 75/80%: biggest lever for battery health on mostly-AC laptop.
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    colord.enable = false;
    # acpid: no handlers, logind owns lid/power key. mkForce: nixos-hardware laptop module enables it.
    acpid.enable = _force.mkForceIf true false;
    # irqbalance: spreads interrupts but wakes idle cores. Worth it on desktop (ninja), not on battery.
    irqbalance.enable = false;
    # flatpak: no apps installed, helper and update timer have nothing to do.
    flatpak.enable = false;
  };

  # Bluetooth available but radio starts cold (nothing ever paired).
  hardware.bluetooth.powerOnBoot = false;

  # NVIDIA audio unbind: detach dGPU HDA so GPU reaches D3cold. bind event (not add) because driver must be attached; unbind via systemd-run to avoid device lock deadlock.
  services.udev = {
    extraRules = ''
      ACTION=="bind", SUBSYSTEM=="pci", KERNEL=="${nvidiaAudioFn}", DRIVER=="snd_hda_intel", RUN+="${pkgs.systemd}/bin/systemd-run --no-block ${pkgs.bash}/bin/sh -c 'echo ${nvidiaAudioFn} > /sys/bus/pci/drivers/snd_hda_intel/unbind'"
    '';
    # brightnessctl udev rules for video group brightness control (Fn keys via ashell IPC).
    packages = [pkgs.brightnessctl];
  };

  # NSCD: early-boot restarts exhaust default burst (5), raising limit avoids failed state spam.
  systemd.services.nscd.startLimitBurst = 20;

  # Disable dGPU KMS (modeset=0): external outputs wired to dGPU stay dark; PRIME render offload uses render node; niri on iGPU. Prevents ~12.5W idle draw from pinned KMS device.
  hardware.nvidia.moduleParams."nvidia-drm" = {
    modeset = _force.mkForceIf true 0;
    fbdev = _force.mkForceIf true 0;
  };

  environment.systemPackages = with pkgs; [
    powertop
    acpi
    # libnotify in home/niri.nix; brightnessctl above only for udev rules, not as user command.
  ];
}
