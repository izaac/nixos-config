{
  config,
  lib,
  pkgs,
  userConfig,
  inputs,
  ...
}: let
  nix-packages = inputs.nix-packages.packages.${pkgs.stdenv.hostPlatform.system};
  cleanPath = "/run/wrappers/bin:/etc/profiles/per-user/$USER/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin:/usr/bin:/bin";
  copilotBin = lib.getExe' pkgs.github-copilot-cli "copilot";
  geminiBin = lib.getExe' pkgs.gemini-cli-bin "gemini";
  nhBin = lib.getExe pkgs.nh;
in {
  # 1. Theme & Styling
  # catppuccin.starship.enable = true;
  catppuccin.bat.enable = true;
  catppuccin.fzf.enable = true;
  catppuccin.bottom.enable = true;
  catppuccin.gitui.enable = true;
  catppuccin.yazi.enable = true;
  catppuccin.btop.enable = true;
  catppuccin.k9s.enable = true;
  catppuccin.atuin.enable = true;
  catppuccin.delta.enable = true;

  # 2. CLI Programs

  # --- SHELL & PROMPT ---
  programs.starship = {
    enable = true;
    package = pkgs.starship;
    settings = {
      command_timeout = 5000;
      add_newline = false;
      format = "$directory$hostname$git_branch$git_status$container$character";

      character = {
        success_symbol = "[](bold green) ";
        error_symbol = "[](bold red) ";
        vimcmd_symbol = "[](bold yellow) ";
      };

      hostname = {
        ssh_only = true;
        format = "on [$hostname]($style) ";
        style = "bold dimmed white";
        aliases = {
          "windy" = "󰌢 windy";
          "ninja" = "󰟀 ninja";
        };
      };
    };
  };

  programs.atuin = {
    enable = true;
    enableZshIntegration = true;
    settings = {
      auto_sync = false;
      style = "compact";
      inline_height = 20;
      filter_mode = "global";
      filter_mode_shell_up = "global";
      search_mode = "fuzzy";
    };
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;
  };

  # --- FILE MANAGERS & NAVIGATION ---
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };

  programs.broot = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableZshIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    fileWidgetCommand = "fd --type f";
    changeDirWidgetCommand = "fd --type d";
  };

  # --- VIEWERS & PAGERS ---
  programs.bat.enable = true;

  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      light = false;
      side-by-side = true;
      line-numbers = true;
    };
  };

  programs.tealdeer = {
    enable = true;
    settings = {
      display = {
        compact = true;
        use_pager = true;
      };
      updates = {
        auto_update = true;
      };
    };
  };

  # --- SYSTEM MONITORING ---
  programs.btop = {
    enable = true;
    settings = {
      theme_background = false; # Use terminal background
      update_ms = 500;
      proc_sorting = "cpu lazy";
    };
  };

  programs.bottom = {
    enable = true;
    settings = {
      flags = {
        avg_cpu = true;
        temperature_type = "c";
      };
    };
  };

  # --- NIX UTILS ---
  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
  };

  # 3. System Packages
  home.packages = with pkgs; [
    # --- CORE CLI UTILS ---
    uutils-coreutils-noprefix
    jaq # Rust-based jq replacement
    sd # sed replacement
    choose # cut/awk replacement
    rm-improved # rip replacement for rm
    procs # ps replacement
    pv # pipe viewer
    bc # calculator
    just # command runner

    # --- FILE & TEXT SEARCH ---
    fd
    ripgrep
    ast-grep # structural code search (sg)

    # --- DISK & FILE USAGE ---
    duf # disk usage
    dust # du replacement
    gdu # disk usage analyzer
    ncdu # ncurses disk usage

    # --- VIEWERS & PAGERS ---
    viddy # modern watch
    hexyl # hex viewer
    glow # markdown renderer
    man-db # man pages

    # --- NETWORK & DIAGNOSTICS ---
    trippy # mtr replacement
    gping # ping with graph
    doggo # dns client (dig)
    xh # curl/httpie replacement
    lftp # file transfer

    # --- CLOUD & CONTAINERS ---
    kubernetes-helm
    kubectl
    lazydocker
    rclone
    rsync

    # --- NIX TOOLS ---
    alejandra # formatter
    deadnix # dead code
    statix # linter
    nix-tree # dependency explorer
    comma # run without install (, pkg)
    nvd # diff nix derivations

    # --- SECURITY ---
    sops
    age

    # --- AI CLI TOOLS ---
    github-copilot-cli
    ai-trace-scanner

    # --- MEDIA & ENCODING ---
    nix-packages.vcrunch

    # --- COMPRESSION & ARCHIVING ---
    ouch
    zip
    unzip
    p7zip
    xz
    zstd
    lz4
    gnutar
    gzip
    bzip2
    libarchive

    # --- SYSTEM & HARDWARE ---
    appimage-run
    wl-clipboard
    cliphist
    dwarfs
    fuse3
    nvitop
    nvtopPackages.nvidia
    bluetuith

    # --- TUI / WIDGETS ---
    ticker # stock ticker
    tenki # weather
  ];

  # 4. Shell Configuration
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    historySubstringSearch.enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    shellAliases = {
      # --- CORE OVERRIDES ---
      ls = "ls --group-directories-first --color=auto";
      l = "_smart_eza -lb --git --group-directories-first";
      ll = "_smart_eza -l --group-directories-first";
      la = "_smart_eza -la --group-directories-first";
      lt = "_smart_eza --tree --level=2";
      cd = "z";
      rm = "rip";

      # --- VIEWERS & DATA ---
      cat = "bat";
      jq = "jaq";
      sg = "ast-grep";
      hex = "hexyl";
      md = "glow";

      # --- NETWORK ---
      mtr = "trip";
      ping = "gping";
      curl = "xh";
      dig = "doggo";

      # --- SYSTEM & MONITORING ---
      top = "btop";
      sysls = "systemctl --type=service --state=running";
      ks = "sudo sh -c \"sync; echo 1 > /proc/sys/vm/drop_caches\" && echo \"RAM cache cleared\"";

      # --- NAVIGATION & FILE OPS ---
      cpv = "rsync -ahP --size-only";
      rcp = "rclone copy --progress --fast-list --drive-chunk-size 64M --transfers 8 --checkers 16";

      # --- GIT ---
      lg = "lazygit";
      gco = "git checkout";
      st = "git -C $NH_FLAKE add .";

      # --- NIX MANAGEMENT ---
      nrb = "st && nh os switch";
      ndr = "st && nh os build";
      ncl = "nh clean all --keep 10 --nogc";
      ncl-full = "direnv prune && nh clean all --keep 10";
      up = "st && nh os switch --update";
      up-browsers = "st && nix flake update nixpkgs && nh os switch";
      nv-sys = "nvd diff $(command ls -vd /nix/var/nix/profiles/system-*-link | tail -2)";
      nv-boot = "nvd diff /run/booted-system /run/current-system";

      # --- TERMINAL FIXES & SECURITY ---
      ssh = "TERM=xterm-256color ssh";
      gpg-fix = "gpgconf --kill gpg-agent && rm -f ~/.gnupg/*.lock ~/.gnupg/public-keys.d/*.lock && echo 'GPG Fixed'";

      # --- AI TOOLS ---
      ai-scan = "ai-trace-scan";
      ai-scan-staged = "ai-trace-scan --staged";
      ai-scan-wip = "ai-trace-scan --unstaged";

      # --- GAMING (ELDEN RING) ---
      ersave = "cp -r /home/${userConfig.username}/.local/share/Steam/steamapps/compatdata/1245620/pfx/drive_c/users/steamuser/AppData/Roaming/EldenRing ~/Documents/ER_Backup_$(date +%F)";
      er-offline = "cd /mnt/data/SteamLibrary/steamapps/common/ELDEN\\ RING/Game && if [ -f start_protected_game.exe ] && [ ! -f start_protected_game_original.exe ]; then mv start_protected_game.exe start_protected_game_original.exe && cp eldenring.exe start_protected_game.exe && echo 'Elden Ring Offline Mode (EAC Bypass) ENABLED'; else echo 'Already in offline mode or Game path not found'; fi";
      er-online = "cd /mnt/data/SteamLibrary/steamapps/common/ELDEN\\ RING/Game && if [ -f start_protected_game_original.exe ]; then rm start_protected_game.exe && mv start_protected_game_original.exe start_protected_game.exe && echo 'Elden Ring Online Mode (EAC) RESTORED'; else echo 'Already in online mode or Game path not found'; fi";

      # --- AUDIO ---
      pw-lowlat = "PIPEWIRE_LATENCY='512/48000'";
    };

    sessionVariables = {
      EDITOR = "hx";
      VISUAL = "hx";
    };

    initContent = ''
            typeset -U path PATH

            (( ''${+CLEAN_PATH} )) || readonly CLEAN_PATH='${cleanPath}'
            (( ''${+COPILOT_BIN} )) || readonly COPILOT_BIN='${copilotBin}'
            (( ''${+GEMINI_BIN} )) || readonly GEMINI_BIN='${geminiBin}'
            (( ''${+NH_BIN} )) || readonly NH_BIN='${nhBin}'

            # --- Gemini CLI ---
            function ask() {
              if [[ $# -eq 0 ]]; then
                PATH="$CLEAN_PATH" "$GEMINI_BIN"
              else
                PATH="$CLEAN_PATH" "$GEMINI_BIN" -p "$*"
              fi
            }

            # --- Copilot CLI ---
            function ai() {
              case "$1" in
                "")
                  PATH="$CLEAN_PATH" "$COPILOT_BIN"
                  ;;
                login|init|update|version|help)
                  PATH="$CLEAN_PATH" "$COPILOT_BIN" "$@"
                  ;;
                *)
                  PATH="$CLEAN_PATH" "$COPILOT_BIN" -p "$*"
                  ;;
              esac
            }

            # --- Fast Package Search ---
            nqs() {
              if [[ $# -eq 0 ]]; then
                echo "Usage: nqs <query...>"
                return 2
              fi
              "$NH_BIN" search --limit 50 "$@"
            }

            # --- Familiar Line Navigation ---
            zmodload zsh/terminfo 2>/dev/null || true
            _bind_line_navigation() {
              local key
              local -a home_keys=("$terminfo[khome]" '^[[H' '^[[1~' '^[[7~' '^[OH')
              local -a end_keys=("$terminfo[kend]" '^[[F' '^[[4~' '^[[8~' '^[OF')
              local -a backward_word_keys=("$terminfo[kLFT3]" '^[[1;3D' '^[^[[D' '^[b')
              local -a forward_word_keys=("$terminfo[kRIT3]" '^[[1;3C' '^[^[[C' '^[f')

              for key in "''${home_keys[@]}"; do
                [[ -n "$key" ]] || continue
                bindkey -M emacs "$key" beginning-of-line
                bindkey -M main "$key" beginning-of-line
                bindkey -M viins "$key" beginning-of-line
                bindkey -M vicmd "$key" vi-beginning-of-line
              done

              for key in "''${end_keys[@]}"; do
                [[ -n "$key" ]] || continue
                bindkey -M emacs "$key" end-of-line
                bindkey -M main "$key" end-of-line
                bindkey -M viins "$key" end-of-line
                bindkey -M vicmd "$key" vi-end-of-line
              done

              for key in "''${backward_word_keys[@]}"; do
                [[ -n "$key" ]] || continue
                bindkey -M emacs "$key" backward-word
                bindkey -M main "$key" backward-word
                bindkey -M viins "$key" backward-word
                bindkey -M vicmd "$key" vi-backward-word
              done

              for key in "''${forward_word_keys[@]}"; do
                [[ -n "$key" ]] || continue
                bindkey -M emacs "$key" forward-word
                bindkey -M main "$key" forward-word
                bindkey -M viins "$key" forward-word
                bindkey -M vicmd "$key" vi-forward-word
              done
            }
            _bind_line_navigation
            unset -f _bind_line_navigation

            # --- Smart Eza ---
            _smart_eza() {
              if [[ "$PWD" == *"/mnt/storage"* ]] || [[ "$*" == *"/mnt/storage"* ]]; then
                local args=()
                for arg in "$@"; do
                  [[ "$arg" != "--git" ]] && [[ "$arg" != "-g" ]] && args+=("$arg")
                done
                command eza --icons=never --color=never "''${args[@]}"
              else
                command eza --icons=auto "$@"
              fi
            }

            # --- GPG TTY FIX ---
            local current_tty=$(tty 2>/dev/null)
            if [[ "$current_tty" != "not a typewriter" ]]; then
              export GPG_TTY="$current_tty"
            fi

            # --- Yazi Wrapper ---
            y() {
              local tmp="''$(mktemp -t "yazi-cwd.XXXXXX")"
              yazi "$@" --cwd-file="$tmp"
              if cwd="''$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                builtin cd -- "$cwd"
              fi
              rm -f -- "$tmp"
            }

            # --- Recursive Cat ---
            catr() {
              local target="''${1:-.}"
              rg --files --hidden -g '!.git' "$target" -0 | xargs -0 -I {} sh -c '
                if file -b --mime-type "{}" | grep -q "^text/"; then
                  echo "================================================================================"
                  echo "FILE: {}"
                  echo "================================================================================"
                  cat "{}"
                  echo -e "\n"
                fi
              '
            }

            # --- Project Initializers ---
            ninit() {
              local ver="''${1:-}"
              local target="node"
              if [ -n "$ver" ]; then target="node_$ver"; fi
              cat <<EOF > .envrc
      use flake ${userConfig.dotfilesDir}/templates#$target
      watch_file package.json
      watch_file yarn.lock
      watch_file pnpm-lock.yaml
      if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        if [ -f "pnpm-lock.yaml" ]; then pnpm install;
        elif [ -f "yarn.lock" ]; then yarn install;
        else npm install; fi
      fi
      EOF
              direnv allow
            }

            pinit() {
              cat <<EOF > .envrc
      use flake ${userConfig.dotfilesDir}/templates#python
      watch_file requirements.txt
      watch_file pyproject.toml
      if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        if [ ! -d ".venv" ] && [ -f "requirements.txt" ]; then
          uv venv && uv pip install -r requirements.txt
        fi
      fi
      EOF
              direnv allow
            }

            rinit() {
              cat <<EOF > .envrc
      use flake ${userConfig.dotfilesDir}/templates#rust
      watch_file Cargo.toml
      watch_file Cargo.lock
      EOF
              direnv allow
            }

            cinit() {
              cat <<EOF > .envrc
      use flake ${userConfig.dotfilesDir}/templates#c
      watch_file CMakeLists.txt
      watch_file Makefile
      EOF
              direnv allow
            }

            cppinit() {
              cat <<EOF > .envrc
      use flake ${userConfig.dotfilesDir}/templates#cpp
      watch_file CMakeLists.txt
      watch_file Makefile
      EOF
              direnv allow
            }

            # fnm
            FNM_PATH="/home/${userConfig.username}/.local/share/fnm"
            if [ -d "$FNM_PATH" ]; then
              path=("$FNM_PATH" $path)
              eval "`fnm env`"
            fi

            # Ensure local binaries are in PATH
            path+=("$HOME/.local/bin" "$HOME/bin")

            # --- Distrobox: Host Tool Injection ---
            if [ -d "/run/host/nix/store" ]; then
              path=("$HOME/.local/share/distrobox/bin" $path)
              unset GI_TYPELIB_PATH
              unset GDK_PIXBUF_MODULE_FILE
              unset XDG_DATA_DIRS

              if [ -L "/run/host/etc/static/ssl/certs/ca-bundle.crt" ]; then
                export SSL_CERT_FILE=$(readlink /run/host/etc/static/ssl/certs/ca-bundle.crt)
                export NIX_SSL_CERT_FILE=$SSL_CERT_FILE
                export GIT_SSL_CAINFO=$SSL_CERT_FILE
              fi

              local host_sys=$(readlink /run/host/run/current-system)
              local host_user=$(readlink /run/host/etc/profiles/per-user/$USER)
              if [ -n "$host_sys" ]; then path+=("/run/host$host_sys/sw/bin"); fi
              if [ -n "$host_user" ]; then
                local host_user_resolved=$(readlink "/run/host$host_user")
                [ -z "$host_user_resolved" ] && host_user_resolved="$host_user"
                path+=("/run/host$host_user_resolved/bin")
              fi
            fi
    '';
  };

  # 5. Session Variables & Files
  home.sessionVariables = {
    PAGER = "bat";
    DIRENV_LOG_FORMAT = "";
    TERMINAL = "wezterm";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    ATUIN_NO_MODIFY_DB = "true";
    QA_INFRA_DIR = "/home/${userConfig.username}/repos/qa-infra-automation";
  };

  home.file.".lftprc".text = ''
    set sftp:max-packets-in-flight 32
    set net:socket-buffer 2097152
    set net:socket-maxseg 1440
    set mirror:parallel-directories yes
    set mirror:parallel-transfer-count 2
    set pget:default-n 5
    set net:connection-limit 10
    set net:connection-takeover yes
  '';

  # 6. Desktop Entries
  xdg.desktopEntries.yazi = {
    name = "Yazi";
    exec = "wezterm start -- yazi %u";
    icon = "yazi";
    terminal = false;
    categories = ["Utility" "Core" "System" "FileTools" "FileManager" "ConsoleOnly"];
    mimeType = ["inode/directory"];
    settings = {
      Keywords = "File;Manager;Explorer;Browser;Launcher";
    };
  };

  xdg.desktopEntries.btop = {
    name = "btop++";
    exec = "wezterm start -- btop";
    icon = "btop";
    terminal = false;
    categories = ["System" "Monitor" "ConsoleOnly"];
    settings = {
      Keywords = "system;process;task";
    };
  };
}
