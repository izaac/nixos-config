# windy: laptop (Intel i9-11980HK + NVIDIA Prime offload).
# Optimized for battery life, thermals, quiet operation.
{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  # "PCI:1:0:0" -> "0000:01:00.1", the PCI address of the audio function that
  # sits alongside the dGPU. Derived from the PRIME bus id in ./nvidia.nix so
  # the two cannot drift apart. Function 1 is the HDA controller; the GPU
  # itself is function 0.
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

  # --- HOST DELTAS ---
  mySystem = {
    core = {
      virtualization.enable = false;
      printing.enable = false;
      sops.enable = false;
    };
  };

  # --- KERNEL & BOOT ---
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;

    kernelParams = [
      "boot.shell_on_fail"
      "iommu=pt"
      "acpi_backlight=native"
      "preempt=voluntary"
      "nvme.noacpi=1"
    ];

    extraModulePackages = [
      (config.boot.kernelPackages.callPackage "${inputs.nix-packages}/pkgs/opengigabyte" {})
    ];
    kernelModules = ["gigabytekbd"];

    kernel.sysctl = {
      "vm.laptop_mode" = 5;
      "vm.dirty_writeback_centisecs" = lib.mkForce 6000;
      "vm.dirty_expire_centisecs" = lib.mkForce 6000;
      "kernel.nmi_watchdog" = 0;
    };
  };

  # --- POWER MANAGEMENT ---
  services = {
    thermald.enable = true;
    scx.enable = lib.mkForce false;

    tlp = {
      enable = true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_BOOST_ON_AC = 0;
        CPU_BOOST_ON_BAT = 0;
        CPU_MAX_PERF_ON_AC = 80;
        CPU_MAX_PERF_ON_BAT = 60;
        INTEL_GPU_MIN_FREQ_ON_AC = 800;
        INTEL_GPU_MIN_FREQ_ON_BAT = 300;
        INTEL_GPU_BOOST_FREQ_ON_AC = 1300;
        INTEL_GPU_BOOST_FREQ_ON_BAT = 800;
        RUNTIME_PM_ON_AC = "auto";
        PCIE_ASPM_ON_BAT = "powersupersave";
        USB_EXCLUDE_PHONE = 1;
        SOUND_POWER_SAVE_ON_AC = 0;
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
      };
    };

    colord.enable = false;
    acpid.enable = lib.mkForce false;
    irqbalance.enable = false;
    flatpak.enable = false;
  };

  hardware.bluetooth.powerOnBoot = false;

  # --- NVIDIA AUDIO FUNCTION UNBIND ---
  services.udev = {
    extraRules = ''
      ACTION=="bind", SUBSYSTEM=="pci", KERNEL=="${nvidiaAudioFn}", DRIVER=="snd_hda_intel", RUN+="${pkgs.systemd}/bin/systemd-run --no-block ${pkgs.bash}/bin/sh -c 'echo ${nvidiaAudioFn} > /sys/bus/pci/drivers/snd_hda_intel/unbind'"
    '';
    packages = [pkgs.brightnessctl];
  };

  systemd.services.nscd.startLimitBurst = 20;

  hardware.nvidia.moduleParams."nvidia-drm" = {
    modeset = lib.mkForce 0;
    fbdev = lib.mkForce 0;
  };

  environment.systemPackages = with pkgs; [
    powertop
    acpi
  ];
}
