{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  xwaylandSatellite = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable;
  audioSinkMenu = pkgs.writeShellApplication {
    name = "audio-sink-menu";
    runtimeInputs = with pkgs; [pulseaudio fuzzel gawk coreutils];
    text = ''
      sel=$(pactl list sinks | awk '
        /^Sink #/      { id=$2; sub("#","",id) }
        /Description:/ { sub(/^[[:space:]]*Description: /,""); print id"\t"$0 }
      ' | fuzzel --dmenu --prompt "Audio: ")
      [ -n "$sel" ] && pactl set-default-sink "$(echo "$sel" | cut -f1)"
    '';
  };
  osdNotify = pkgs.writeShellApplication {
    name = "osd-notify";
    runtimeInputs = with pkgs; [wireplumber brightnessctl libnotify gawk coreutils gnugrep];
    text = ''
      # Single-bubble OSD via mako: same sync tag replaces prior notification,
      # so spinning the volume wheel updates one bubble instead of stacking.
      bar() {
        # tr is byte-oriented and mangles multibyte chars, so build the bar
        # one glyph at a time to keep the output valid UTF-8.
        local pct=$1 filled empty i out=""
        filled=$((pct / 5))
        [ "$filled" -gt 20 ] && filled=20
        empty=$((20 - filled))
        for ((i = 0; i < filled; i++)); do out+="█"; done
        for ((i = 0; i < empty;  i++)); do out+="░"; done
        printf '%s' "$out"
      }

      notify() {
        # $1=sync-tag $2=icon $3=title $4=value(0-100) $5=body-extra
        notify-send \
          -h "string:x-canonical-private-synchronous:$1" \
          -h "int:value:$4" \
          -t 1500 \
          -i "$2" \
          "$3" "$(bar "$4")  $4%  $5"
      }

      volume() {
        wpctl set-volume -l 1.5 @DEFAULT_AUDIO_SINK@ "$1" >/dev/null
        read -r _ raw muted < <(wpctl get-volume @DEFAULT_AUDIO_SINK@)
        pct=$(awk -v v="$raw" 'BEGIN{printf "%d", v*100}')
        if [ "$muted" = "[MUTED]" ]; then
          notify volume audio-volume-muted "Volume" "$pct" "(muted)"
        else
          icon=audio-volume-high
          [ "$pct" -lt 66 ] && icon=audio-volume-medium
          [ "$pct" -lt 33 ] && icon=audio-volume-low
          notify volume "$icon" "Volume" "$pct" ""
        fi
      }

      mute_sink() {
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
        read -r _ raw muted < <(wpctl get-volume @DEFAULT_AUDIO_SINK@)
        pct=$(awk -v v="$raw" 'BEGIN{printf "%d", v*100}')
        if [ "$muted" = "[MUTED]" ]; then
          notify volume audio-volume-muted "Volume" "$pct" "(muted)"
        else
          notify volume audio-volume-high "Volume" "$pct" ""
        fi
      }

      mute_source() {
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        if wpctl get-volume @DEFAULT_AUDIO_SOURCE@ | grep -q MUTED; then
          notify-send -h string:x-canonical-private-synchronous:mic \
                      -t 1500 -i microphone-sensitivity-muted \
                      "Microphone" "Muted"
        else
          notify-send -h string:x-canonical-private-synchronous:mic \
                      -t 1500 -i microphone-sensitivity-high \
                      "Microphone" "Unmuted"
        fi
      }

      brightness() {
        brightnessctl set "$1" >/dev/null
        cur=$(brightnessctl get)
        max=$(brightnessctl max)
        pct=$(( cur * 100 / max ))
        notify brightness display-brightness "Brightness" "$pct" ""
      }

      case "$1" in
        volume-up)    volume "5%+" ;;
        volume-down)  volume "5%-" ;;
        volume-mute)  mute_sink ;;
        mic-mute)     mute_source ;;
        brightness-up)   brightness "5%+" ;;
        brightness-down) brightness "5%-" ;;
        *) echo "usage: osd-notify {volume-up|volume-down|volume-mute|mic-mute|brightness-up|brightness-down}" >&2; exit 2 ;;
      esac
    '';
  };
  screenRecord = pkgs.writeShellApplication {
    name = "screen-record";
    runtimeInputs = with pkgs; [wf-recorder slurp libnotify coreutils procps];
    text = ''
      mode="''${1:-region}"
      outdir="$HOME/Videos"
      mkdir -p "$outdir"
      if pgrep -x wf-recorder >/dev/null; then
        pkill -INT -x wf-recorder
        notify-send "Screen recording" "Stopped"
        exit 0
      fi
      out="$outdir/rec-$(date +%Y%m%d-%H%M%S).mp4"
      case "$mode" in
        region)
          geom=$(slurp) || exit 0
          notify-send "Screen recording" "Started (region) → $out"
          wf-recorder -g "$geom" -f "$out"
          ;;
        screen)
          notify-send "Screen recording" "Started (screen) → $out"
          wf-recorder -f "$out"
          ;;
      esac
    '';
  };
in {
  # Apply Stylix theme tokens to niri config.
  stylix.targets.niri.enable = true;

  # wlogout custom layout: drop suspend + hibernate.
  xdg.configFile."wlogout/layout".text = ''
    {
        "label" : "lock",
        "action" : "swaylock-refocus",
        "text" : "Lock",
        "keybind" : "l"
    }
    {
        "label" : "logout",
        "action" : "niri msg action quit --skip-confirmation",
        "text" : "Logout",
        "keybind" : "e"
    }
    {
        "label" : "reboot",
        "action" : "systemctl reboot",
        "text" : "Reboot",
        "keybind" : "r"
    }
    {
        "label" : "shutdown",
        "action" : "systemctl poweroff",
        "text" : "Shutdown",
        "keybind" : "s"
    }
  '';

  home.packages = with pkgs; [
    brightnessctl # Screen brightness control
    swaybg # Wallpaper daemon
    # wl-clipboard + cliphist live in home/shell/packages.nix
    grim # Screen capture
    slurp # Region picker
    wf-recorder # Screen recorder (Wayland)
    playerctl # MPRIS media control
    libnotify # notify-send for keybind feedback
    wlogout # Graphical power menu (logout/reboot/poweroff/suspend/lock)
  ];

  programs.niri.settings = {
    prefer-no-csd = true;

    # Screenshots land in a single dated folder instead of niri's default
    # scatter pattern. Path is expanded by niri itself; ~ → $HOME.
    screenshot-path = "~/Pictures/Screenshots/Screenshot %Y-%m-%d %H-%M-%S.png";

    # Privacy: hide notifications from screencast/recording sinks. Mako
    # uses the `notifications` layer namespace; password-manager-style
    # toast notifications stay out of OBS/xdg-desktop-portal captures.
    layer-rules = [
      {
        matches = [{namespace = "^notifications$";}];
        block-out-from = "screencast";
      }
    ];

    # LG UltraGear 49" — pin to native 144Hz mode at origin so the dummy
    # HDMI output (configured far right at x=10000) never auto-stacks on top.
    outputs."DP-1" = {
      mode = {
        width = 3440;
        height = 1440;
        refresh = 143.923;
      };
      position = {
        x = 0;
        y = 0;
      };
      variable-refresh-rate = false;
    };

    # Headless dummy HDMI plug for Sunshine streaming. Parked at x=10000 so
    # the cursor cannot drift onto it during normal desktop use; the main
    # monitor stays the only practical workspace. Use Mod+M to focus the
    # dummy (next launched app lands there) and Mod+Shift+M to send the
    # focused window/column to it.
    outputs."HDMI-A-1" = {
      mode = {
        width = 1920;
        height = 1080;
        refresh = 60.0;
      };
      position = {
        x = 10000;
        y = 0;
      };
      variable-refresh-rate = false;
    };

    # X11 app compatibility — niri-flake auto-spawns this when the path is set
    # and both niri and xwayland-satellite are on the unstable channel.
    xwayland-satellite.path = lib.getExe xwaylandSatellite;

    input = {
      keyboard.xkb = {
        layout = "us";
      };
      touchpad = {
        tap = true;
        dwt = true; # Disable touchpad while typing (prevents palm clicks)
        natural-scroll = true;
        accel-profile = "flat";
      };
      mouse.accel-profile = "flat";
      warp-mouse-to-focus.enable = true;
      focus-follows-mouse.enable = false;
    };

    layout = {
      gaps = 8;
      center-focused-column = "never";
      preset-column-widths = [
        {proportion = 1.0 / 3.0;}
        {proportion = 0.5;}
        {proportion = 2.0 / 3.0;}
      ];
      default-column-width.proportion = 0.5;
      focus-ring.enable = false;
      border = {
        enable = true;
        width = 2;
      };
    };

    hotkey-overlay.skip-at-startup = true;

    spawn-at-startup = [
      {command = ["waybar"];}
      {command = ["mako"];}
      {command = ["nm-applet" "--indicator"];}
      {command = ["blueman-applet"];}
      {command = ["swaybg" "-i" "${config.stylix.image}" "-m" "fill"];}
      {command = ["sh" "-c" "wl-paste --watch cliphist store"];}
    ];

    window-rules = [
      # Picture-in-Picture: float by default (Firefox + Chromium-based)
      {
        matches = [
          {
            app-id = "firefox$";
            title = "^Picture-in-Picture$";
          }
          {
            app-id = "^(google-chrome|brave-browser|brave-origin|chromium)$";
            title = "^Picture in picture$";
          }
        ];
        open-floating = true;
      }
      # Common popups: small floats
      {
        matches = [
          {app-id = "org.gnome.Calculator$";}
          {app-id = "blueman-manager$";}
          {app-id = "nm-connection-editor$";}
          {app-id = "pavucontrol$";}
        ];
        open-floating = true;
      }
      # Steam: float all sub-dialogs (Friends, Settings, popups); main library tiles.
      {
        matches = [{app-id = "^[Ss]team$";}];
        excludes = [{title = "^Steam$";}];
        open-floating = true;
      }
      # Elden Ring: auto-fullscreen so it owns the whole output (no niri chrome),
      # critical when streaming via sunshine which captures the active monitor.
      {
        matches = [
          {app-id = "^steam_app_1245620$";}
          {title = "^ELDEN RING.*";}
        ];
        open-fullscreen = true;
      }
    ];

    binds = with config.lib.niri.actions; let
      sh = spawn "sh" "-c";
    in {
      # --- Apps ---
      "Mod+Return".action = spawn "kitty";
      "Mod+D".action = spawn "fuzzel";
      # Alt+Space is the Moonlight-friendly alternative: Mac Cmd forwarding to
      # Linux Super is unreliable, but Option (Alt) passes through cleanly.
      "Alt+Space".action = spawn "fuzzel";
      "Mod+E".action = spawn "nemo";
      "Mod+B".action = spawn "brave-origin";
      "Mod+Ctrl+L".action = spawn "swaylock-refocus";
      "Mod+Shift+P".action = spawn "wlogout" "-b" "2";
      "Mod+Shift+N".action.spawn = ["makoctl" "mode" "-t" "do-not-disturb"];
      "Mod+S".action = spawn (lib.getExe audioSinkMenu);
      "Mod+V".action = sh "cliphist list | fuzzel --dmenu | cliphist decode | wl-copy";

      # --- Direct power actions (skip menu) ---
      "Mod+Ctrl+Shift+S".action = spawn "systemctl" "suspend";
      "Mod+Ctrl+Shift+R".action = spawn "systemctl" "reboot";
      "Mod+Ctrl+Shift+Q".action = spawn "systemctl" "poweroff";

      # --- Window/session ---
      "Mod+Q".action = close-window;
      "Mod+Shift+E".action.quit.skip-confirmation = true;

      # --- Focus ---
      "Mod+Left".action = focus-column-left;
      "Mod+Right".action = focus-column-right;
      "Mod+Down".action = focus-window-down;
      "Mod+Up".action = focus-window-up;
      "Mod+H".action = focus-column-left;
      "Mod+J".action = focus-window-down;
      "Mod+K".action = focus-window-up;
      "Mod+L".action = focus-column-right;

      # --- Move ---
      "Mod+Shift+Left".action = move-column-left;
      "Mod+Shift+Right".action = move-column-right;
      "Mod+Shift+Down".action = move-window-down;
      "Mod+Shift+Up".action = move-window-up;
      "Mod+Shift+H".action = move-column-left;
      "Mod+Shift+J".action = move-window-down;
      "Mod+Shift+K".action = move-window-up;
      "Mod+Shift+L".action = move-column-right;

      # --- Workspaces ---
      "Mod+1".action.focus-workspace = 1;
      "Mod+2".action.focus-workspace = 2;
      "Mod+3".action.focus-workspace = 3;
      "Mod+4".action.focus-workspace = 4;
      "Mod+5".action.focus-workspace = 5;
      "Mod+6".action.focus-workspace = 6;
      "Mod+7".action.focus-workspace = 7;
      "Mod+8".action.focus-workspace = 8;
      "Mod+9".action.focus-workspace = 9;
      "Mod+Shift+1".action.move-column-to-workspace = 1;
      "Mod+Shift+2".action.move-column-to-workspace = 2;
      "Mod+Shift+3".action.move-column-to-workspace = 3;
      "Mod+Shift+4".action.move-column-to-workspace = 4;
      "Mod+Shift+5".action.move-column-to-workspace = 5;
      "Mod+Shift+6".action.move-column-to-workspace = 6;
      "Mod+Shift+7".action.move-column-to-workspace = 7;
      "Mod+Shift+8".action.move-column-to-workspace = 8;
      "Mod+Shift+9".action.move-column-to-workspace = 9;
      "Mod+Page_Down".action = focus-workspace-down;
      "Mod+Page_Up".action = focus-workspace-up;

      # --- Sunshine dummy monitor (HDMI-A-1) ---
      "Mod+M".action.focus-monitor = "HDMI-A-1";
      "Mod+Shift+M".action.move-column-to-monitor = "HDMI-A-1";

      # --- Mouse wheel focus column ---
      "Mod+WheelScrollDown" = {
        action = focus-column-right;
        cooldown-ms = 150;
      };
      "Mod+WheelScrollUp" = {
        action = focus-column-left;
        cooldown-ms = 150;
      };

      # --- Layout ---
      "Mod+R".action = switch-preset-column-width;
      "Mod+F".action = maximize-column;
      "Mod+Shift+F".action = fullscreen-window;
      "Mod+Minus".action = set-column-width "-10%";
      "Mod+Equal".action = set-column-width "+10%";

      # --- Screenshots (niri defaults) ---
      "Print".action.screenshot = {};
      "Ctrl+Print".action.screenshot-screen = {};
      "Alt+Print".action.screenshot-window = {};

      # --- Screen recording (toggle: press to start, press again to stop) ---
      "Shift+Print".action = spawn (lib.getExe screenRecord) "region";
      "Ctrl+Shift+Print".action = spawn (lib.getExe screenRecord) "screen";

      # --- Audio (wpctl + mako OSD) ---
      "XF86AudioRaiseVolume" = {
        action = spawn (lib.getExe osdNotify) "volume-up";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action = spawn (lib.getExe osdNotify) "volume-down";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action = spawn (lib.getExe osdNotify) "volume-mute";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action = spawn (lib.getExe osdNotify) "mic-mute";
        allow-when-locked = true;
      };
      "XF86AudioPlay".action = spawn "playerctl" "play-pause";
      "XF86AudioNext".action = spawn "playerctl" "next";
      "XF86AudioPrev".action = spawn "playerctl" "previous";

      # --- Brightness (laptops) ---
      "XF86MonBrightnessUp" = {
        action = spawn (lib.getExe osdNotify) "brightness-up";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action = spawn (lib.getExe osdNotify) "brightness-down";
        allow-when-locked = true;
      };
    };
  };
}
