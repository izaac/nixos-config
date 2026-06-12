{
  config,
  lib,
  ...
}: let
  cfg = config.mySystem.core.audio;
in {
  options.mySystem.core.audio = {
    enable = lib.mkEnableOption "Core Audio (Pipewire) configuration";
  };

  config = lib.mkIf cfg.enable {
    # Audio (Pipewire)
    services.pulseaudio.enable = false;
    security.rtkit.enable = true;
    services.pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
    };
  };
}
