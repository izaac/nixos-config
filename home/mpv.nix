# Declarative mpv configuration via Home Manager.
# Keybinds use vim-style hjkl (no modifier) which is safe: mpv captures
# all input when focused, so there is no conflict with niri (Mod+*),
# tmux (C-a), kitty (Ctrl+Shift+*), or LazyVim (only inside nvim).
{pkgs, ...}: {
  programs.mpv = {
    enable = true;
    config = {
      # --- VIDEO ---
      profile = "gpu-hq";
      gpu-api = "vulkan";
      hwdec = "auto-safe";
      vo = "gpu-next";

      # --- AUDIO ---
      volume = 80;
      volume-max = 150;
      audio-pitch-correction = true;

      # --- OSD ---
      osd-bar = false; # use osc instead of bar
      osd-font-size = 32;
      osd-duration = 2000;

      # --- SUBTITLES ---
      sub-auto = "fuzzy";
      sub-font-size = 40;
      sub-border-size = 2;

      # --- WINDOW ---
      keep-open = true;
      autofit-larger = "90%x90%";
      cursor-autohide = 1000;

      # --- SCREENSHOTS ---
      screenshot-format = "png";
      screenshot-directory = "~/Pictures/Screenshots";
      screenshot-template = "mpv-%F-%P";

      # --- CACHE / PERFORMANCE ---
      cache = true;
      demuxer-max-bytes = "512MiB";
      demuxer-max-back-bytes = "128MiB";
    };

    bindings = {
      # --- PLAYBACK ---
      "SPACE" = "cycle pause";
      "q" = "quit";
      "Q" = "quit-watch-later";

      # --- SEEK (vim-style: h/l = left/right) ---
      "h" = "seek -5";
      "l" = "seek 5";
      "H" = "seek -30";
      "L" = "seek 30";
      "Ctrl+h" = "seek -60";
      "Ctrl+l" = "seek 60";

      # --- VOLUME (vim-style: j/k = down/up) ---
      "j" = "add volume -2";
      "k" = "add volume 2";
      "m" = "cycle mute";

      # --- CHAPTERS ---
      "." = "playlist-next";
      "," = "playlist-prev";
      ">" = "add chapter 1";
      "<" = "add chapter -1";

      # --- SPEED ---
      "[" = "multiply speed 0.9";
      "]" = "multiply speed 1.1";
      "BS" = "set speed 1.0";

      # --- SUBTITLES ---
      "s" = "cycle sub-visibility";
      "S" = "cycle sub";

      # --- WINDOW ---
      "f" = "cycle fullscreen";
      "o" = "show-progress";
      "i" = "script-binding stats/display-stats-toggle";

      # --- SCREENSHOTS ---
      "p" = "screenshot";
    };

    scripts = with pkgs.mpvScripts; [
      mpris # MPRIS2 integration (playerctl pause/play from lock screen)
      uosc # Modern minimal UI replacing default OSC
      thumbfast # Thumbnail previews on seek bar
    ];
  };
}
