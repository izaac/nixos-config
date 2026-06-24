{pkgs, ...}: let
  # On unlock, focus may have drifted to the headless dummy HDMI-A-1 (parked
  # at x=10000 for Sunshine), making niri keybinds appear "dead" until Chief
  # mouses to DP-1. Wrap swaylock so the focus is explicitly returned to DP-1
  # the moment the user unlocks. The wrapper depends on `daemonize = false`
  # so the chained niri command runs AFTER unlock, not immediately.
  # writeShellApplication for shellcheck + pinned swaylock; focus restore
  # must run even if swaylock exits non-zero, hence the explicit || true.
  swaylock-refocus = pkgs.writeShellApplication {
    name = "swaylock-refocus";
    runtimeInputs = [pkgs.swaylock-effects];
    text = ''
      swaylock "$@" || true
      niri msg action focus-monitor DP-1 || true
    '';
  };
in {
  home.packages = [swaylock-refocus];

  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      # Foreground so swaylock-refocus can chain the focus-monitor call
      # after unlock. swayidle/niri.spawn/wlogout all handle a foreground
      # child cleanly (fork+exec without wait).
      daemonize = false;
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
        timeout = 480;
        command = "${swaylock-refocus}/bin/swaylock-refocus";
      }
      {
        timeout = 720;
        command = "niri msg action power-off-monitors";
        resumeCommand = "niri msg action power-on-monitors";
      }
    ];
    events = {
      before-sleep = "${swaylock-refocus}/bin/swaylock-refocus";
      lock = "${swaylock-refocus}/bin/swaylock-refocus";
    };
  };
}
