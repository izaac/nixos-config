{
  config,
  pkgs,
  lib,
  osConfig ? {},
  ...
}: let
  # Both timers run from the start of idle, not chained: lock at 6 minutes,
  # blank the displays 5 minutes later. Suspend stays manual, via the ashell
  # settings panel or wlogout.
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
        saved=$(cat "${wallpaperState}")
        [ -f "$saved" ] && wallpaper="$saved"
      fi

      exec swaylock -f --image "$wallpaper"
    '';
  };
in {
  # The only two C tools left here. Every Rust Wayland locker surveyed is
  # unproven (largest 83 stars, next dead since 2025) and waylock is Zig, so a
  # security boundary stays on the battle-tested implementation.
  home.packages = [
    pkgs.wlogout
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
    timeouts = [
      {
        timeout = lockTimeout;
        command = lib.getExe lockNow;
      }
      {
        timeout = screenOffTimeout;
        command = "${lib.getExe niri} msg action power-off-monitors";
        resumeCommand = "${lib.getExe niri} msg action power-on-monitors";
      }
    ];
  };

  # wlogout only backs the Mod+Shift+P keybind; the ashell settings panel
  # already exposes the same actions. Stylix has no wlogout target, so the
  # styling is derived from the base16 palette by hand.
  xdg.configFile = let
    inherit (config.lib.stylix.colors) withHashtag;
    icons = "${pkgs.wlogout}/share/wlogout/icons";
  in {
    "wlogout/layout".text = ''
      {"label":"lock","action":"${lib.getExe lockNow}","text":"Lock","keybind":"l"}
      {"label":"logout","action":"${lib.getExe niri} msg action quit --skip-confirmation","text":"Logout","keybind":"e"}
      {"label":"suspend","action":"systemctl suspend","text":"Suspend","keybind":"u"}
      {"label":"reboot","action":"systemctl reboot","text":"Reboot","keybind":"r"}
      {"label":"shutdown","action":"systemctl poweroff","text":"Shutdown","keybind":"s"}
    '';

    "wlogout/style.css".text = ''
      * {
        box-shadow: none;
        font-family: "${config.stylix.fonts.monospace.name}";
        font-size: ${toString config.stylix.fonts.sizes.popups}pt;
      }

      window {
        background-color: alpha(${withHashtag.base00}, 0.9);
      }

      button {
        margin: 8px;
        border-radius: 12px;
        border: 2px solid ${withHashtag.base02};
        background-color: ${withHashtag.base01};
        color: ${withHashtag.base05};
        background-repeat: no-repeat;
        background-position: center;
        background-size: 25%;
      }

      button:focus,
      button:hover {
        background-color: ${withHashtag.base0D};
        color: ${withHashtag.base00};
        border-color: ${withHashtag.base0D};
        outline-style: none;
      }

      /* Absolute store paths: wlogout resolves these relative to nothing. */
      #lock     { background-image: url("${icons}/lock.png"); }
      #logout   { background-image: url("${icons}/logout.png"); }
      #suspend  { background-image: url("${icons}/suspend.png"); }
      #reboot   { background-image: url("${icons}/reboot.png"); }
      #shutdown { background-image: url("${icons}/shutdown.png"); }
    '';
  };
}
