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
    enable = mkEnableOption "Shared NVIDIA driver baseline (graphics + open module + VAAPI/VDPAU)";
  };

  config = mkIf cfg.enable {
    services.xserver.videoDrivers = ["nvidia"];

    hardware = {
      graphics = {
        enable = true;
        enable32Bit = true;
        extraPackages = with pkgs; [
          nvidia-vaapi-driver
          libva-vdpau-driver
          libvdpau-va-gl
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
