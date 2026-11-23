# Android platform tools (adb, fastboot) for flashing and debugging phones
# over USB.
# Device permissions come from systemd's built-in udev rules: 70-uaccess.rules
# tags the Android ADB/fastboot USB interfaces with uaccess, so logind grants
# the active seat user access without an adbusers group.
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.mySystem.core.adb;
in {
  options.mySystem.core.adb = {
    enable = lib.mkEnableOption "Android platform tools (adb, fastboot)";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [pkgs.android-tools];
  };
}
