# Shared baseline for laptop hosts (e.g. windy).
# Sets battery, thermal, and power-saving defaults using lib.mkDefault.
{
  pkgs,
  lib,
  ...
}: {
  services = {
    thermald.enable = lib.mkDefault true;

    tlp = {
      enable = lib.mkDefault true;
      settings = {
        CPU_SCALING_GOVERNOR_ON_AC = lib.mkDefault "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = lib.mkDefault "powersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = lib.mkDefault "power";
        CPU_ENERGY_PERF_POLICY_ON_BAT = lib.mkDefault "power";
        RUNTIME_PM_ON_AC = lib.mkDefault "auto";
        PCIE_ASPM_ON_BAT = lib.mkDefault "powersupersave";
        USB_EXCLUDE_PHONE = lib.mkDefault 1;
        SOUND_POWER_SAVE_ON_AC = lib.mkDefault 0;
        START_CHARGE_THRESH_BAT0 = lib.mkDefault 75;
        STOP_CHARGE_THRESH_BAT0 = lib.mkDefault 80;
      };
    };

    colord.enable = lib.mkDefault false;
    irqbalance.enable = lib.mkOverride 900 false;
  };

  boot.kernel.sysctl = {
    "vm.laptop_mode" = lib.mkDefault 5;
    "kernel.nmi_watchdog" = lib.mkDefault 0;
  };

  hardware.bluetooth.powerOnBoot = lib.mkOverride 900 false;

  services.udev.packages = [pkgs.brightnessctl];

  environment.systemPackages = with pkgs; [
    powertop
    acpi
  ];
}
