{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.mySystem.desktop.intel;
in {
  options.mySystem.desktop.intel = {
    enable = lib.mkEnableOption "Shared Intel Arc / Xe GPU driver baseline";
  };

  config = lib.mkIf cfg.enable {
    services.xserver.videoDrivers = ["modesetting"];

    hardware.graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        intel-media-driver
        vpl-gpu-rt
        intel-compute-runtime
      ];
      extraPackages32 = with pkgs.driversi686Linux; [
        intel-media-driver
      ];
    };

    environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
    };
  };
}
