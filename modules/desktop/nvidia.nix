{
  config,
  pkgs,
  lib,
  ...
}:
with lib; let
  cfg = config.mySystem.desktop.nvidia;
in {
  options.mySystem.desktop.nvidia = {
    enable = mkEnableOption "Shared NVIDIA driver baseline (graphics + open module + VAAPI)";
  };

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = ["nvidia"];

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
        ];
      };

      nvidia = {
        modesetting.enable = true;
        open = true; # Open modules required for RTX 50-series; supported on Turing+
        nvidiaSettings = true;
      };
    };
  };
}
