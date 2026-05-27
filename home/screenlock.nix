{pkgs, ...}: {
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      daemonize = true;
      screenshots = true;
      effect-blur = "9x5";
      effect-vignette = "0.5:0.5";
      clock = true;
      indicator = true;
      indicator-radius = 120;
      indicator-thickness = 8;
      fade-in = "0.2";
      # Pressing Enter with no input shouldn't fire a full PAM cycle (the
      # YubiKey U2F prompt takes a few seconds to time out). Show failed
      # attempts so a wrong-password vs forgotten-tap is obvious.
      ignore-empty-password = true;
      show-failed-attempts = true;
    };
  };

  services.swayidle = {
    enable = true;
    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.swaylock-effects}/bin/swaylock";
      }
      {
        timeout = 600;
        command = "niri msg action power-off-monitors";
        resumeCommand = "niri msg action power-on-monitors";
      }
    ];
    events = {
      before-sleep = "${pkgs.swaylock-effects}/bin/swaylock";
      lock = "${pkgs.swaylock-effects}/bin/swaylock";
    };
  };
}
