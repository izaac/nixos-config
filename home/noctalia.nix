{
  inputs,
  config,
  ...
}: {
  # Noctalia v5 shell: bar, launcher, notifications, control center, lock
  # screen, OSDs, clipboard history, and session panel. Replaces the previous
  # waybar + fuzzel + mako + swaylock + wlogout stack. Native Wayland + OpenGL
  # ES, so no Qt or GTK runtime. The home-manager module ships the package and
  # writes ~/.config/noctalia/config.toml from the settings below.
  imports = [inputs.noctalia.homeModules.default];

  # Expose the wallpaper collection at the conventional XDG path noctalia
  # scans. This is a live symlink to the git checkout (not copied into the
  # nix store), so pulling new wallpapers there needs no rebuild.
  home.file."Pictures/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/wallpapers";

  programs.noctalia = {
    enable = true;

    # Spawned by niri at session start (see home/niri.nix spawn-at-startup),
    # so the bundled systemd user service stays off to avoid a double launch.
    systemd.enable = false;

    # Skip build-time `noctalia config validate`; the settings below only touch
    # documented keys and validation would force a source build of the binary
    # just to check the file.
    validateConfig = false;

    settings = {
      # The shell palette is generated from the current wallpaper instead of a
      # fixed builtin, so switching wallpapers (control center, wallpaper-random,
      # etc.) recolors the bar, panels, launcher, and lock screen live. Stylix
      # still owns app colors (kitty, tmux, gtk), so those stay catppuccin; only
      # noctalia's own surfaces follow the wallpaper. Swap wallpaper_scheme for a
      # different generator (see docs: m3-tonal-spot, vibrant, muted, etc.).
      theme = {
        mode = "dark";
        source = "wallpaper";
        wallpaper_scheme = "m3-tonal-spot";
      };

      shell = {
        font = "JetBrainsMono Nerd Font";
      };

      # Top bar layout. This mirrors noctalia's default arrangement with two
      # changes: the "network" (wifi) indicator is dropped from the end cluster
      # (network/wifi is still managed from the control center system tab), and
      # a "cpu" system-monitor readout is added. "cpu" is a built-in named
      # widget (type sysmon, stat cpu_usage), so it needs no widget definition.
      bar.main = {
        start = ["launcher" "wallpaper" "workspaces"];
        center = ["clock"];
        end = [
          "media"
          "cpu"
          "tray"
          "notifications"
          "clipboard"
          "bluetooth"
          "volume"
          "brightness"
          "battery"
          "control-center"
          "session"
        ];
      };

      # Widen the media widget for wide displays. max_length is a cap, not a
      # fixed size: the widget only grows to fit the current track title, up to
      # this limit. Titles longer than the cap scroll on hover.
      widget.media = {
        max_length = 400;
        title_scroll = "on_hover";
      };

      # Allow the volume controls to go above 100% (up to 150%), matching the
      # previous wpctl "-l 1.5" cap now that noctalia owns the media keys.
      audio.enable_overdrive = true;

      # Idle timers. Lock the session after 8 minutes idle, then power the
      # display off (DPMS) after 12 minutes. screen-off must set action
      # explicitly because each [idle.behavior.*] entry is parsed fresh (the
      # builtin defaults are not merged in), and the action pairs an automatic
      # screen-on resume so any input wakes the display. suspend stays disabled
      # so idle never powers the system down; suspend remains a manual action
      # from the session panel.
      idle.behavior.lock = {
        enabled = true;
        timeout = 480;
        command = "noctalia:session lock";
      };
      idle.behavior."screen-off" = {
        enabled = true;
        timeout = 720;
        action = "screen_off";
      };
      idle.behavior.suspend.enabled = false;

      # Let an empty password submit at the lock screen so a YubiKey (U2F,
      # via the `login` PAM stack) unlocks with just a tap: press Enter on an
      # empty field and PAM cues the key. Typing the account password still
      # works as usual; this only unblocks the empty-submit path.
      lockscreen.allow_empty_password = true;

      # Wallpaper is drawn by noctalia's own engine now (swaybg is gone). It
      # scans ~/Pictures/Wallpapers (symlinked to the wallpaper repo) so the
      # control center can switch backgrounds live. The initial background is
      # the stylix image, keeping continuity with the static theme.
      wallpaper = {
        enabled = true;
        directory = "${config.home.homeDirectory}/Pictures/Wallpapers";
        fill_mode = "crop";
        default.path = "${config.stylix.image}";
        automation = {
          enabled = false;
          recursive = true;
        };
      };
    };
  };

  # Shell-specific wiring. home/niri.nix keeps only what is shell-agnostic, so
  # ninja and windy can run different shells off the same compositor config.
  programs.niri.settings = {
    spawn-at-startup = [
      {command = ["noctalia"];}
    ];

    # Only the toast namespace carries message content worth hiding from OBS
    # and xdg-desktop-portal captures.
    layer-rules = [
      {
        matches = [{namespace = "^noctalia-notification";}];
        block-out-from = "screencast";
      }
    ];

    binds = {
      # --- Shell panels ---
      "Mod+D".action.spawn = ["noctalia" "msg" "panel-toggle" "launcher"];
      # Alt+Space is the Moonlight-friendly alias: Mac Cmd forwarding to Linux
      # Super is unreliable, but Option (Alt) passes through cleanly.
      "Alt+Space".action.spawn = ["noctalia" "msg" "panel-toggle" "launcher"];
      "Mod+Ctrl+L".action.spawn = ["noctalia" "msg" "session" "lock"];
      "Mod+Shift+P".action.spawn = ["noctalia" "msg" "panel-toggle" "session"];
      "Mod+Shift+N".action.spawn = ["noctalia" "msg" "notification-dnd-toggle"];
      "Mod+S".action.spawn = ["noctalia" "msg" "panel-toggle" "control-center"];
      "Mod+V".action.spawn = ["noctalia" "msg" "panel-toggle" "clipboard"];

      # --- Audio (noctalia native IPC, shows its own OSD) ---
      "XF86AudioRaiseVolume" = {
        action.spawn = ["noctalia" "msg" "volume-up"];
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action.spawn = ["noctalia" "msg" "volume-down"];
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action.spawn = ["noctalia" "msg" "volume-mute"];
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action.spawn = ["noctalia" "msg" "mic-mute"];
        allow-when-locked = true;
      };
      "XF86AudioPlay".action.spawn = ["noctalia" "msg" "media" "toggle"];
      "XF86AudioNext".action.spawn = ["noctalia" "msg" "media" "next"];
      "XF86AudioPrev".action.spawn = ["noctalia" "msg" "media" "previous"];

      # --- Brightness (laptops; noctalia native IPC + OSD) ---
      "XF86MonBrightnessUp" = {
        action.spawn = ["noctalia" "msg" "brightness-up"];
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action.spawn = ["noctalia" "msg" "brightness-down"];
        allow-when-locked = true;
      };

      # --- Compact-keyboard fallbacks (no media keys) ---
      # The Fn layer already emits XF86Audio{Mute,LowerVolume,RaiseVolume}, so
      # only the rest needs mirroring.
      "Mod+F4" = {
        action.spawn = ["noctalia" "msg" "mic-mute"];
        allow-when-locked = true;
      };
      "Mod+F5".action.spawn = ["noctalia" "msg" "media" "toggle"];
      "Mod+F6".action.spawn = ["noctalia" "msg" "media" "previous"];
      "Mod+F7".action.spawn = ["noctalia" "msg" "media" "next"];
    };
  };
}
