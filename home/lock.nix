{
  config,
  pkgs,
  lib,
  osConfig ? {},
  ...
}: let
  isNinja = (osConfig.networking.hostName or "") == "ninja";

  # Lock at 6 minutes. Screen power-off (screenOffTimeout) is disabled on ninja
  # because DPMS power-off cycles the DisplayPort connector on NVIDIA, which
  # triggers a known niri and vblank deadlock upon display wake.
  lockTimeout = 360;
  screenOffTimeout = 660;

  # The system runs niri-unstable; pkgs.niri is stable and would risk an IPC
  # mismatch against the live compositor.
  niri = osConfig.programs.niri.package or pkgs.niri;

  # Written by set-wallpaper in home/ashell.nix. Read at runtime rather than
  # baked in, so the lock screen tracks whatever wallpaper is current.
  wallpaperState = "${config.xdg.stateHome}/current-wallpaper";

  lockNow = pkgs.writeShellApplication {
    name = "lock-now";
    runtimeInputs = with pkgs; [swaylock-effects playerctl];
    text = ''
      playerctl --all-players pause 2>/dev/null || true

      # Falling back to the stylix image keeps the lock usable before the first
      # set-wallpaper run. Without any image swaylock would fall back to the
      # flat colour, which is also fine, just less obviously intentional.
      wallpaper="${config.stylix.image}"
      if [ -r "${wallpaperState}" ]; then
        saved="$(< "${wallpaperState}")"
        [ -f "$saved" ] && wallpaper="$saved"
      fi

      exec swaylock -f --image "$wallpaper"
    '';
  };
in {
  home.packages = [
    lockNow
  ];

  stylix.targets.swaylock = {
    enable = true;
    # Stylix would pin the static theme image into the config file, which then
    # takes precedence over the wallpaper lock-now passes on the command line.
    image.enable = false;
  };

  # No grace period: it unlocks on any mouse or key event for N seconds with no
  # password, which both defeats the idle lock and makes wlogout's Lock button
  # appear to do nothing, since the click that triggered it unlocks the screen.
  programs.swaylock = {
    enable = true;
    package = pkgs.swaylock-effects;
    settings = {
      show-failed-attempts = true;
      indicator-caps-lock = true;
      fade-in = 0.2;

      # Deliberately not `screenshots`: that renders the actual desktop, and a
      # blur is obfuscation rather than concealment. lock-now passes the current
      # wallpaper instead, so nothing on screen is real content.
      scaling = "fill";
      effect-blur = "12x3";
      effect-vignette = "0.4:0.6";

      # Clock inside the indicator, always visible so the ring is not a blank
      # circle while idle.
      clock = true;
      indicator = true;
      indicator-radius = 110;
      indicator-thickness = 8;
      timestr = "%H:%M";
      datestr = "%a %d %b";
      font = config.stylix.fonts.monospace.name;
      font-size = 28;
    };
  };

  services.swayidle = {
    enable = true;
    events = {
      before-sleep = lib.getExe lockNow;
      lock = lib.getExe lockNow;
    };
    timeouts =
      [
        {
          timeout = lockTimeout;
          command = lib.getExe lockNow;
        }
      ]
      ++ lib.optionals (!isNinja) [
        {
          timeout = screenOffTimeout;
          command = "${lib.getExe niri} msg action power-off-monitors";
          resumeCommand = "${lib.getExe niri} msg action power-on-monitors";
        }
      ];
  };
}
