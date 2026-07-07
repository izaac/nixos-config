{inputs, ...}: {
  # Noctalia v5 shell: bar, launcher, notifications, control center, lock
  # screen, OSDs, clipboard history, and session panel. Replaces the previous
  # waybar + fuzzel + mako + swaylock + wlogout stack. Native Wayland + OpenGL
  # ES, so no Qt or GTK runtime. The home-manager module ships the package and
  # writes ~/.config/noctalia/config.toml from the settings below.
  imports = [inputs.noctalia.homeModules.default];

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
    };
  };
}
