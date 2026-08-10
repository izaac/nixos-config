{
  config,
  pkgs,
  lib,
  osConfig ? {},
  ...
}: let
  isNinja = (osConfig.networking.hostName or "") == "ninja";

  # ashell's network/VPN panels are NetworkManager-only, so they show nothing on
  # a networkd host. The retry loop behind them is fixed in the overlay patch.
  hasNetworkManager = osConfig.networking.networkmanager.enable or false;

  # The system runs niri-unstable; pkgs.niri is stable and would risk an IPC
  # mismatch against the live compositor.
  niri = osConfig.programs.niri.package or pkgs.niri;

  wallpaperDir = "${config.home.homeDirectory}/Pictures/Wallpapers";
  ashellConfig = "${config.home.homeDirectory}/.config/ashell/config.toml";
  # `awww query` reports output geometry, not the current image, so the choice
  # has to be recorded here to survive a logout.
  wallpaperState = "${config.xdg.stateHome}/current-wallpaper";
  thumbDir = "${config.xdg.cacheHome}/wallpaper-thumbs";

  # Semantic colors stay on stylix: a wallpaper-derived palette has no concept
  # of "this one means danger" and could hand out a green error state.
  inherit (config.lib.stylix.colors) withHashtag;

  # matugen fills the {{...}} placeholders and writes ashellConfig. Structure is
  # fixed here; only colors track the wallpaper.
  ashellTemplate = (pkgs.formats.toml {}).generate "ashell-template.toml" {
    log_level = "warn";
    position = "Top";

    modules = {
      left = [["appLauncher" "wallpaper" "Workspaces"]];
      center = ["Tempo"];
      right = [
        "MediaPlayer"
        "SystemInfo"
        ["Tray" "clipboard" "Notifications" "Privacy" "Settings"]
      ];
    };

    CustomModule = [
      {
        name = "appLauncher";
        icon = "󱗼";
        command = lib.getExe pkgs.fuzzel;
        type = "Button";
      }
      {
        name = "wallpaper";
        icon = "󰸉";
        command = "${lib.getExe setWallpaper} pick";
        type = "Button";
      }
      {
        name = "clipboard";
        icon = "󰅇";
        command = lib.getExe clipboardMenu;
        type = "Button";
      }
    ];

    workspaces = {
      visibility_mode = "All";
      indicator_format = "Name";
      enable_workspace_filling = false;
    };

    window_title = {
      mode = "Title";
      truncate_title_after_length = 150;
    };

    system_info = {
      indicators = ["Cpu" "Memory" "Temperature"];
      interval = 5;
      cpu = {
        warn_threshold = 60;
        alert_threshold = 80;
      };
      memory = {
        warn_threshold = 70;
        alert_threshold = 85;
      };
    };

    media_player = {
      indicator_format = "IconAndTitle";
      max_text_length = 100;
    };

    tempo.clock_format = "%a %d %b %R";

    notifications = {
      format = "%H:%M";
      show_timestamps = true;
      show_bodies = true;
      toast = true;
      toast_position = "top_right";
      toast_timeout = 5000;
      toast_limit = 5;
    };

    settings =
      {
        lock_cmd = "lock-now";
        suspend_cmd = "systemctl suspend";
        reboot_cmd = "systemctl reboot";
        shutdown_cmd = "systemctl poweroff";
        logout_cmd = "${lib.getExe niri} msg action quit --skip-confirmation";
        audio_sinks_more_cmd = "${lib.getExe pkgs.wiremix}";
        audio_sources_more_cmd = "${lib.getExe pkgs.wiremix}";
        # Above 100 enables overdrive, matching noctalia's enable_overdrive.
        max_volume = 150;
        volume_step = 5;
        indicators =
          ["IdleInhibitor" "PowerProfile" "Audio" "Microphone" "Bluetooth"]
          ++ lib.optionals hasNetworkManager ["Network" "Vpn"]
          ++ lib.optionals (!isNinja) ["Battery" "Brightness"];
      }
      // lib.optionalAttrs hasNetworkManager {
        wifi_more_cmd = "nm-connection-editor";
        vpn_more_cmd = "nm-connection-editor";
      }
      // lib.optionalAttrs (!isNinja) {
        battery_format = "IconAndPercentage";
      };

    # Defaults to false upstream, which silently kills every volume and
    # brightness overlay the media keys rely on.
    osd = {
      enabled = true;
      timeout = 1500;
      show_volume_percentage = true;
      show_brightness_percentage = true;
    };

    animations.enabled = true;

    appearance = {
      font_name = config.stylix.fonts.monospace.name;
      primary_color = "{{colors.primary.default.hex}}";
      success_color = withHashtag.base0B;
      warning_color = withHashtag.base0A;
      danger_color = withHashtag.base08;
      text_color = "{{colors.on_surface.default.hex}}";
      workspace_colors = [
        "{{colors.primary.default.hex}}"
        "{{colors.tertiary.default.hex}}"
      ];

      bar = {
        surface = "transparent";
        margin = "xs";
      };

      menu.opacity = 0.95;

      background_color = {
        base = "{{colors.surface.default.hex}}";
        weak = "{{colors.surface_container.default.hex}}";
        strong = "{{colors.surface_bright.default.hex}}";
        text = "{{colors.on_surface.default.hex}}";
      };
    };
  };

  matugenConfig = (pkgs.formats.toml {}).generate "matugen-config.toml" {
    config = {};
    templates.ashell = {
      input_path = "${config.xdg.configHome}/matugen/templates/ashell.toml";
      output_path = ashellConfig;
    };
  };

  # --source-color-index is mandatory: matugen prompts interactively when an
  # image yields several candidates, and dies with "not a terminal" in a script.
  regenerateColors = target: ''
    matugen image "${target}" \
      --source-color-index 0 \
      --type scheme-tonal-spot \
      --mode dark \
      --quiet
  '';

  # Defined once and interpolated into both scripts below: if the two ever
  # disagreed, cached thumbnails would silently never be found again.
  thumbHash = ''printf '%s' "$1" | sha1sum | cut -c1-32'';

  # fuzzel renders icons through libpng and libresvg only, with no libjpeg, so
  # most of the collection cannot be previewed directly. Cache a small PNG per
  # image instead; the originals stay untouched, which matters because the
  # wallpaper directory is somebody else's git checkout.
  wallpaperThumb = pkgs.writeShellApplication {
    name = "wallpaper-thumb";
    runtimeInputs = [pkgs.imagemagick pkgs.coreutils];
    text = ''
      dest="${thumbDir}/$(${thumbHash}).png"
      [ -f "$dest" ] && [ "$dest" -nt "$1" ] && exit 0
      mkdir -p "${thumbDir}"
      magick "$1" -thumbnail 256x256 "$dest" 2>/dev/null || true
    '';
  };

  setWallpaper = pkgs.writeShellApplication {
    name = "set-wallpaper";
    runtimeInputs = [pkgs.awww pkgs.matugen pkgs.fuzzel pkgs.coreutils pkgs.findutils pkgs.libnotify wallpaperThumb];
    text = ''
      list_in() {
        find -L "$1" -type d -name .git -prune -o -type f \
          \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) \
          -print | sort
      }

      thumb_path() {
        printf '%s/%s.png' "${thumbDir}" "$(${thumbHash})"
      }

      # fuzzel exits non-zero on escape, and prints nothing if it is dismissed
      # some other way, so both have to be treated as "no choice".
      chose() {
        case "$1" in
          ""|*[!0-9]*) return 1 ;;
        esac
      }

      # Two steps, because a flat list of every wallpaper is too long to scan.
      # Escape in the second menu returns to the category list rather than
      # abandoning the whole picker; escape in the first one quits. Both menus
      # use --index and map the choice back by position, which keeps filenames
      # containing spaces or parentheses intact. Entries are shown relative to
      # the directory being listed, so nested folders still read sensibly.
      pick_menu() {
        local -a cats labels paths
        mapfile -t cats < <(
          find -L "${wallpaperDir}" -mindepth 1 -maxdepth 1 -type d \
            -not -name '.git' -printf '%f\n' | sort
        )

        labels=("All ($(list_in "${wallpaperDir}" | wc -l))")
        local c
        for c in "''${cats[@]}"; do
          labels+=("$c ($(list_in "${wallpaperDir}/$c" | wc -l))")
        done

        local idx scope p
        while true; do
          idx=$(printf '%s\n' "''${labels[@]}" \
            | fuzzel --dmenu --index --minimal-lines --prompt "Category: ") || return 1
          chose "$idx" || return 1

          if [ "$idx" -eq 0 ]; then
            scope="${wallpaperDir}"
          else
            scope="${wallpaperDir}/''${cats[$((idx - 1))]}"
          fi

          mapfile -t paths < <(list_in "$scope")
          [ "''${#paths[@]}" -gt 0 ] || continue

          # Only the chosen category is rendered, so the first run costs a
          # fraction of a second rather than thumbnailing the whole collection.
          printf '%s\n' "''${paths[@]}" | xargs -r -d '\n' -P 8 -n 1 wallpaper-thumb

          # A leading "Back" row makes the escape shortcut discoverable, and
          # shifts every wallpaper index by one. The menu is piped straight
          # into fuzzel because command substitution would strip the NUL bytes
          # the icon protocol depends on.
          # --lines caps the window height: the default of 15 rows at 96px each
          # would fill a 1440p screen. --minimal-lines shrinks it further for
          # small categories instead of padding with blank rows.
          idx=$(
            {
              printf '..  Back to categories\n'
              for p in "''${paths[@]}"; do
                printf '%s\0icon\x1f%s\n' "''${p#"$scope"/}" "$(thumb_path "$p")"
              done
            } | fuzzel --dmenu --index \
              --line-height=96px --lines=6 --minimal-lines \
              --prompt "Wallpaper: "
          ) || continue
          chose "$idx" || continue
          [ "$idx" -eq 0 ] && continue

          printf '%s\n' "''${paths[$((idx - 1))]}"
          return 0
        done
      }

      case "''${1:-random}" in
        pick)   target=$(pick_menu) || exit 0 ;;
        random) target=$(list_in "${wallpaperDir}" | shuf -n 1) ;;
        # Re-apply the wallpaper recorded by a previous run, falling back to the
        # stylix image. Used at session start, where awww has just come up with
        # no wallpaper of its own.
        restore)
          target="${config.stylix.image}"
          if [ -r "${wallpaperState}" ]; then
            saved=$(cat "${wallpaperState}")
            [ -f "$saved" ] && target="$saved"
          fi
          ;;
        *)      target="$1" ;;
      esac

      [ -n "$target" ] || exit 0
      if [ ! -f "$target" ]; then
        notify-send "Wallpaper" "Not found: $target"
        exit 1
      fi

      awww img "$target" --transition-type fade --transition-duration 1
      mkdir -p "$(dirname "${wallpaperState}")"
      printf '%s\n' "$target" > "${wallpaperState}"
      ${regenerateColors "$target"}
    '';
  };

  # Its own layer namespace so the screencast rule can hide clipboard contents
  # without also hiding the application launcher, which shares fuzzel's default.
  clipboardMenu = pkgs.writeShellApplication {
    name = "clipboard-menu";
    runtimeInputs = with pkgs; [stash-clipboard fuzzel wl-clipboard];
    text = ''
      sel=$(stash list | fuzzel --dmenu -n clipboard-menu --prompt "Clipboard: ") || exit 0
      [ -n "$sel" ] || exit 0
      printf '%s' "$sel" | stash decode | wl-copy
    '';
  };

  # awww-daemon must be up before the first `awww img`, and ashell needs its
  # config on disk first: an absent or bad file is only a warning there, and it
  # silently falls back to built-in defaults.
  ashellSession = pkgs.writeShellApplication {
    name = "ashell-session";
    runtimeInputs = [pkgs.awww pkgs.ashell pkgs.coreutils pkgs.util-linux pkgs.libnotify setWallpaper];
    text = ''
      # Liveness is tied to this compositor instance. NIRI_SOCKET carries the
      # niri PID, whereas WAYLAND_DISPLAY is reused verbatim by the next
      # session, so a stale wrapper would otherwise mistake a fresh socket for
      # its own and keep a dead session's bar alive.
      niri_alive() {
        [ -n "''${NIRI_SOCKET:-}" ] && [ -S "$NIRI_SOCKET" ]
      }

      # Linger is on and KillUserProcesses is off, so a previous session's
      # wrapper can still be shutting down. Wait briefly for it to release
      # rather than declining and leaving the session with no bar.
      exec 9>"$XDG_RUNTIME_DIR/ashell-session.lock"
      flock -w 10 9 || exit 0

      # awww-daemon is a Wayland client, so it dies with the compositor and has
      # to be started per session, then re-sent the wallpaper.
      start_wallpaper() {
        if ! awww query >/dev/null 2>&1; then
          awww-daemon &
          for _ in $(seq 1 50); do
            awww query >/dev/null 2>&1 && break
            sleep 0.1
          done
        fi
        set-wallpaper restore || true
      }

      start_wallpaper

      # Supervise ashell so a crash does not leave the session without a bar.
      # A dead compositor means the session ended, so stop rather than respawn;
      # repeated instant failures give up instead of spinning.
      fails=0
      while niri_alive; do
        started=$SECONDS
        ashell || true
        niri_alive || break
        if [ $((SECONDS - started)) -ge 30 ]; then
          fails=0
        else
          fails=$((fails + 1))
        fi
        if [ "$fails" -ge 5 ]; then
          notify-send -u critical "ashell" "Crashed 5 times, giving up" || true
          exit 1
        fi
        sleep 2
        start_wallpaper
      done
    '';
  };
in {
  home.packages = [
    pkgs.ashell
    pkgs.awww
    pkgs.matugen
    pkgs.stash-clipboard
    pkgs.playerctl # ashell IPC covers volume and brightness but not transport
    setWallpaper
    clipboardMenu
    ashellSession
  ];

  # Live symlink to the git checkout rather than a store copy, so pulling new
  # wallpapers there needs no rebuild.
  home.file."Pictures/Wallpapers".source =
    config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/repos/wallpapers";

  # ashell keeps colors inside config.toml with no separate theme file, so that
  # file must stay writable for matugen. Only the template is managed.
  xdg.configFile = {
    "matugen/templates/ashell.toml".source = ashellTemplate;
    "matugen/config.toml".source = matugenConfig;
  };

  # config.toml is a matugen output, so a rebuild that changes the template
  # would leave it stale until the next wallpaper change. Re-render against the
  # wallpaper in use; ashell watches the file and reloads without a restart.
  home.activation.renderAshellConfig = lib.hm.dag.entryAfter ["linkGeneration"] ''
    wallpaper="${config.stylix.image}"
    if [ -r "${wallpaperState}" ]; then
      saved=$(cat "${wallpaperState}")
      [ -f "$saved" ] && wallpaper="$saved"
    fi
    $DRY_RUN_CMD ${lib.getExe pkgs.matugen} image "$wallpaper" \
      --source-color-index 0 \
      --type scheme-tonal-spot \
      --mode dark \
      --quiet || true
  '';

  # stash ships a native clipboard watcher, so no wl-paste wrapper is needed.
  # The history is an unencrypted SQLite file and defaults to keeping entries
  # forever, so every password ever copied would accumulate in it; cap it.
  systemd.user.services.stash = {
    Unit = {
      Description = "stash clipboard history watcher";
      PartOf = ["graphical-session.target"];
      After = ["graphical-session.target"];
    };
    Service = {
      Type = "simple";
      ExecStart = "${lib.getExe pkgs.stash-clipboard} --max-items 500 watch --mime-type text/plain --persist";
      Restart = "on-failure";
      RestartSec = 2;
    };
    Install.WantedBy = ["graphical-session.target"];
  };

  # Shell-specific wiring. home/niri.nix keeps only what is shell-agnostic, so
  # ninja and windy can run different shells off the same compositor config.
  programs.niri.settings = {
    # Starts awww, seeds the config, then supervises ashell for the session.
    spawn-at-startup = [
      {command = [(lib.getExe ashellSession)];}
    ];

    # Only the toast layer carries message content worth hiding from OBS and
    # portal captures; the bar, menus and OSD are harmless. The clipboard menu
    # is worse: it renders the plaintext history, passwords included.
    layer-rules = [
      {
        matches = [
          {namespace = "^ashell-toast-layer";}
          {namespace = "^clipboard-menu";}
        ];
        block-out-from = "screencast";
      }
    ];

    binds = {
      # --- Launcher ---
      "Mod+D".action.spawn = ["fuzzel"];
      # Alt+Space is the Moonlight-friendly alias: Mac Cmd forwarding to Linux
      # Super is unreliable, but Option (Alt) passes through cleanly.
      "Alt+Space".action.spawn = ["fuzzel"];

      # --- Session ---
      "Mod+Ctrl+L".action.spawn = ["lock-now"];
      "Mod+Shift+P".action.spawn = ["wlogout"];
      "Mod+V".action.spawn = ["clipboard-menu"];
      "Mod+Shift+W".action.spawn = ["set-wallpaper" "pick"];

      # No Mod+S or Mod+Shift+N: ashell has no panel-toggle IPC, so the control
      # centre and notifications are reached by clicking their bar modules.

      # --- Audio (ashell native IPC, shows its own OSD) ---
      "XF86AudioRaiseVolume" = {
        action.spawn = ["ashell" "msg" "volume-up"];
        allow-when-locked = true;
      };
      "XF86AudioLowerVolume" = {
        action.spawn = ["ashell" "msg" "volume-down"];
        allow-when-locked = true;
      };
      "XF86AudioMute" = {
        action.spawn = ["ashell" "msg" "volume-toggle-mute"];
        allow-when-locked = true;
      };
      "XF86AudioMicMute" = {
        action.spawn = ["ashell" "msg" "microphone-toggle-mute"];
        allow-when-locked = true;
      };

      # Media transport has no ashell IPC equivalent, so it goes through MPRIS.
      "XF86AudioPlay".action.spawn = ["playerctl" "play-pause"];
      "XF86AudioNext".action.spawn = ["playerctl" "next"];
      "XF86AudioPrev".action.spawn = ["playerctl" "previous"];

      # --- Brightness (laptops; ashell native IPC + OSD) ---
      "XF86MonBrightnessUp" = {
        action.spawn = ["ashell" "msg" "brightness-up"];
        allow-when-locked = true;
      };
      "XF86MonBrightnessDown" = {
        action.spawn = ["ashell" "msg" "brightness-down"];
        allow-when-locked = true;
      };

      # --- Compact-keyboard fallbacks (no media keys) ---
      # The Fn layer already emits XF86Audio{Mute,LowerVolume,RaiseVolume}, so
      # only the rest needs mirroring.
      "Mod+F4" = {
        action.spawn = ["ashell" "msg" "microphone-toggle-mute"];
        allow-when-locked = true;
      };
      "Mod+F5".action.spawn = ["playerctl" "play-pause"];
      "Mod+F6".action.spawn = ["playerctl" "previous"];
      "Mod+F7".action.spawn = ["playerctl" "next"];
    };
  };
}
