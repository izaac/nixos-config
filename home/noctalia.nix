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
      theme = {
        mode = "dark";
        source = "builtin";
        builtin = "Catppuccin";
      };

      shell = {
        font = "JetBrainsMono Nerd Font";
      };

      # Allow the volume controls to go above 100% (up to 150%), matching the
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
