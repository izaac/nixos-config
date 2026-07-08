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

      # previous wpctl "-l 1.5" cap now that noctalia owns the media keys.
      audio.enable_overdrive = true;

      # Auto-lock on idle only. screen-off (DPMS) and suspend are left
      # untouched by timers, so this never powers the display or system down;
      # suspend stays a manual action from the session panel. suspend is
      # pinned off explicitly so a future noctalia default can't silently
      # enable idle autosuspend.
      idle.behavior.lock = {
        enabled = true;
        timeout = 600;
        command = "noctalia:session lock";
      };
      idle.behavior.suspend.enabled = false;

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
}
