{
  config,
  pkgs,
  lib,
  inputs,
  osConfig ? {},
  ...
}: let
  # ninja-only pieces (49" monitor layout, render device) are gated on
  # the hostname so the laptop does not inherit them.
  isNinja = (osConfig.networking.hostName or "") == "ninja";
  xwaylandSatellite = inputs.niri-flake.packages.${pkgs.stdenv.hostPlatform.system}.xwayland-satellite-unstable;
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

  home.packages = with pkgs; [
    # wl-clipboard lives in home/shell/packages.nix
    slurp # Region picker (screen recorder)
    wf-recorder # Screen recorder (Wayland)
    libnotify # notify-send for screen-record feedback
  ];

  programs.niri.settings = {
    prefer-no-csd = true;

    # On windy (Intel + NVIDIA hybrid) force niri to composite on the Intel
    # iGPU, which already drives the internal panel (card1/renderD128). Without
    # this niri picks the NVIDIA dGPU and keeps the RTX 3080 powered on around
    # the clock, which runs hot and spins the fans up constantly. Compositing
    # on Intel lets the dGPU runtime-suspend (PRIME offload still routes games
    # to it on demand). ninja is NVIDIA-only, so it must keep niri's default.
    debug = lib.mkIf (!isNinja) {
      render-drm-device = "/dev/dri/by-path/pci-0000:00:02.0-render";
    };

    # Screenshots land in a single dated folder instead of niri's default
    # scatter pattern. Path is expanded by niri itself; ~ → $HOME.
    screenshot-path = "~/Pictures/Screenshots/Screenshot %Y-%m-%d %H-%M-%S.png";

    # Privacy: hide notifications from screencast/recording sinks. Noctalia
    # toasts use the `noctalia-notification` layer namespace; password-manager
    # style toasts stay out of OBS/xdg-desktop-portal captures.
    layer-rules = [
      {
        matches = [{namespace = "^noctalia-notification";}];
        block-out-from = "screencast";
      }
    ];

    # ninja's monitor layout only — windy keeps niri's automatic output
    # handling for whatever is plugged into its ports.
    outputs = lib.optionalAttrs isNinja {
      # LG UltraGear 49" — pin to native 144Hz mode at origin.
      "DP-1" = {
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
      # Noctalia shell: bar, launcher, notifications, control center, lock,
      # OSDs, clipboard history, and session panel (see home/noctalia.nix).
      {command = ["noctalia"];}
      # Keep clipboard data alive when source window loses focus.
      {command = ["wl-clip-persist" "--clipboard" "regular"];}
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
      # SILENT HILL f: Steam/Proton sometimes opens tiled under niri.
      {
        matches = [
          {app-id = "^steam_app_2947440$";}
          {title = "^SILENT HILL f.*";}
        ];
        open-fullscreen = true;
      }
      # Lords of the Fallen: opens windowed/tiled under niri; force fullscreen
      # so it owns the whole output.
      {
        matches = [
          {app-id = "^steam_app_1501750$";}
          {title = "^Lords of the Fallen.*";}
        ];
        open-fullscreen = true;
      }
      # SPICE Viewer (virt-viewer, spicy) and Remmina session: open wider than default
      {
        matches = [
          {app-id = "^(remote-viewer|spicy)$";}
          {app-id = "^org\.remmina\.Remmina$";}
        ];
        excludes = [{title = "^Remmina Remote Desktop Client$";}];
        default-column-width = {proportion = 3.0 / 4.0;};
      }
      # Remmina main menu: open narrow
      {
        matches = [
          {
            app-id = "^org\.remmina\.Remmina$";
            title = "^Remmina Remote Desktop Client$";
          }
        ];
        default-column-width = {proportion = 1.0 / 3.0;};
      }
    ];

    binds = with config.lib.niri.actions; {
      # --- Apps ---
      "Mod+Return".action = spawn "kitty";
      "Mod+D".action = spawn "noctalia" "msg" "panel-toggle" "launcher";
      # Alt+Space is the Moonlight-friendly alternative: Mac Cmd forwarding to
      # Linux Super is unreliable, but Option (Alt) passes through cleanly.
      "Alt+Space".action = spawn "noctalia" "msg" "panel-toggle" "launcher";
      "Mod+E".action = spawn "nemo";
      "Mod+B".action = spawn "brave-origin";
      "Mod+Ctrl+L".action = spawn "noctalia" "msg" "session" "lock";
      "Mod+Shift+P".action = spawn "noctalia" "msg" "panel-toggle" "session";
      "Mod+Shift+N".action = spawn "noctalia" "msg" "notification-dnd-toggle";
      "Mod+S".action = spawn "noctalia" "msg" "panel-toggle" "control-center";
      "Mod+V".action = spawn "noctalia" "msg" "panel-toggle" "clipboard";

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

      # --- Audio (noctalia native IPC, shows its own OSD) ---
      "XF86AudioRaiseVolume" = {
        action = spawn "noctalia" "msg" "volume-up";
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action = spawn "noctalia" "msg" "volume-down";
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action = spawn "noctalia" "msg" "volume-mute";
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action = spawn "noctalia" "msg" "mic-mute";
        allow-when-locked = true;
      };
      "XF86AudioPlay".action = spawn "noctalia" "msg" "media" "toggle";
      "XF86AudioNext".action = spawn "noctalia" "msg" "media" "next";
      "XF86AudioPrev".action = spawn "noctalia" "msg" "media" "previous";

      # --- Brightness (laptops; noctalia native IPC + OSD) ---
      "XF86MonBrightnessUp" = {
        action = spawn "noctalia" "msg" "brightness-up";
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action = spawn "noctalia" "msg" "brightness-down";
        allow-when-locked = true;
      };

      # --- Compact-keyboard fallbacks (no media/Print keys) ---
      # The Fn layer already emits XF86Audio{Mute,LowerVolume,RaiseVolume}
      # (Fn+F8/F9/F10), so volume stays handled above. These cover the rest.
      "Mod+F4" = {
        action = spawn "noctalia" "msg" "mic-mute";
        allow-when-locked = true;
      };
      "Mod+F5".action = spawn "noctalia" "msg" "media" "toggle";
      "Mod+F6".action = spawn "noctalia" "msg" "media" "previous";
      "Mod+F7".action = spawn "noctalia" "msg" "media" "next";
      "Mod+F8".action.screenshot = {};
      "Mod+F9".action.screenshot-screen = {};
      "Mod+F10".action.screenshot-window = {};
      "Mod+F11".action = spawn (lib.getExe screenRecord) "region";
      "Mod+F12".action = spawn (lib.getExe screenRecord) "screen";
    };
  };
}
