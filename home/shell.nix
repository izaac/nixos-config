{
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
  catppuccin.skim.enable = true;
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
    enableBashIntegration = true;
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
    enableBashIntegration = true;
  };

  programs.pay-respects = {
    enable = true;
    enableBashIntegration = true;
  };

  # --- FILE MANAGERS & NAVIGATION ---
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    shellWrapperName = "y";
  };

  programs.broot = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.skim = {
    enable = true;
    enableBashIntegration = true;
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
    enableBashIntegration = true;
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

    # --- VIEWERS & PAGERS ---
    viddy # modern watch
    hexyl # hex viewer
    mdcat # markdown renderer
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
    nix-packages.brush-shell

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
  programs.bash = {
    enable = true;
    enableCompletion = true;

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
      md = "mdcat";

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
      rcp = "rclone sync --progress --fast-list --drive-chunk-size 64M --transfers 8 --checkers 16 --size-only";
      zlj = "zellij";

      # --- GIT ---
      gco = "git checkout";

      # --- NIX MANAGEMENT ---
      ncl = "nh clean all --keep 10 --nogc";
      ncl-full = "direnv prune && nh clean all --keep 10";
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

    initExtra = ''
            # --- WEZTERM INTEGRATION (OSC 133) ---
            if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
              _wezterm_osc133_prompt_start() { printf "\033]133;A\007"; }
              _wezterm_osc133_command_start() { printf "\033]133;C\007"; }
              _wezterm_osc133_command_end() { printf "\033]133;D;%s\007" "$?"; }

              # Inject into PS1/PROMPT_COMMAND for Brush/Bash
              case "$PS1" in
                *"\033]133;A\007"*) ;;
                *) PS1="\[$(_wezterm_osc133_prompt_start)\]$PS1" ;;
              esac

              # Brush-specific hook for command start/end
              if [ -n "$BRUSH_VERSION" ]; then
                # Brush can use DEBUG trap or built-in hooks if available
                # For now, we use the standard bash-compatible approach
                trap '_wezterm_osc133_command_start' DEBUG
                PROMPT_COMMAND="_wezterm_osc133_command_end; ''${PROMPT_COMMAND:-}"
              fi
            fi

            # Suppress brush's bind warnings
            if [ -n "$BRUSH_VERSION" ]; then
              bind() { builtin bind "$@" 2>/dev/null; return 0; }
            fi

            # --- AI HELPERS ---
            # monko: ask Gemini for help in caveman talk
            monko() {
              if [[ $# -eq 0 ]]; then
                echo "Monko need words to think! Use: monko <what is wrong?>"
                return 1
              fi
              ask "Explain this like a caveman named Monko: $*"
            }

            # ask-monko: pipe previous command error to Gemini
            ask-monko() {
              local last_cmd=$(history | tail -n 2 | head -n 1 | sed 's/^[ ]*[0-9]*[ ]*//')
              echo "Monko looking at: $last_cmd"
              ask "I ran '$last_cmd' and it failed. Explain why like a caveman named Monko and suggest a fix."
            }

            # command_not_found_handle: Monko offer help
            command_not_found_handle() {
              echo "Monko not know command: $1"
              echo "Maybe you want: monko why $1 not work?"
              return 127
            }

            # Stage dotfiles
       (used by nrb/ndr/up functions)
            st() { git -C "${userConfig.dotfilesDir}" add .; }
            nrb() { st && nh os switch; }
            ndr() { st && nh os build; }
            up() { st && nh os switch --update; }
            up-browsers() { st && nix flake update nixpkgs && nh os switch; }

            [[ -z "$CLEAN_PATH" ]] && readonly CLEAN_PATH='${cleanPath}'
            [[ -z "$COPILOT_BIN" ]] && readonly COPILOT_BIN='${copilotBin}'
            [[ -z "$GEMINI_BIN" ]] && readonly GEMINI_BIN='${geminiBin}'
            [[ -z "$NH_BIN" ]] && readonly NH_BIN='${nhBin}'

            # --- Gemini CLI ---
            ask() {
              if [[ $# -eq 0 ]]; then
                PATH="$CLEAN_PATH" "$GEMINI_BIN"
              else
                PATH="$CLEAN_PATH" "$GEMINI_BIN" -p "$*"
              fi
            }

            # --- Copilot CLI ---
            ai() {
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
            current_tty=$(tty 2>/dev/null)
            if [[ "$current_tty" != "not a tty" ]]; then
              export GPG_TTY="$current_tty"
            fi
            unset current_tty

            # --- Yazi Wrapper ---
            y() {
              local tmp
              tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
              yazi "$@" --cwd-file="$tmp"
              if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
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
              cat <<ENVRC > .envrc
      use flake ${userConfig.dotfilesDir}/templates#$target
      watch_file package.json
      watch_file yarn.lock
      watch_file pnpm-lock.yaml
      if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
        if [ -f "pnpm-lock.yaml" ]; then pnpm install;
        elif [ -f "yarn.lock" ]; then yarn install;
        else npm install; fi
      fi
      ENVRC
              direnv allow
            }

            pinit() {
              cat <<'ENVRC' > .envrc
      use flake ${userConfig.dotfilesDir}/templates#python
      watch_file requirements.txt
      watch_file pyproject.toml
      if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        if [ ! -d ".venv" ] && [ -f "requirements.txt" ]; then
          uv venv && uv pip install -r requirements.txt
        fi
      fi
      ENVRC
              direnv allow
            }

            rinit() {
              cat <<'ENVRC' > .envrc
      use flake ${userConfig.dotfilesDir}/templates#rust
      watch_file Cargo.toml
      watch_file Cargo.lock
      ENVRC
              direnv allow
            }

            cinit() {
              cat <<'ENVRC' > .envrc
      use flake ${userConfig.dotfilesDir}/templates#c
      watch_file CMakeLists.txt
      watch_file Makefile
      ENVRC
              direnv allow
            }

            cppinit() {
              cat <<'ENVRC' > .envrc
      use flake ${userConfig.dotfilesDir}/templates#cpp
      watch_file CMakeLists.txt
      watch_file Makefile
      ENVRC
              direnv allow
            }

            # fnm (force bash mode — brush is bash-compatible but fnm can't detect it)
            FNM_PATH="/home/${userConfig.username}/.local/share/fnm"
            if [ -d "$FNM_PATH" ]; then
              export PATH="$FNM_PATH:$PATH"
              eval "$(fnm env --shell bash)"
            fi

            # Ensure local binaries are in PATH
            export PATH="$PATH:$HOME/.local/bin:$HOME/bin"

            # --- Distrobox: Host Tool Injection ---
            if [ -d "/run/host/nix/store" ]; then
              export PATH="$HOME/.local/share/distrobox/bin:$PATH"
              unset GI_TYPELIB_PATH
              unset GDK_PIXBUF_MODULE_FILE
              unset XDG_DATA_DIRS

              if [ -L "/run/host/etc/static/ssl/certs/ca-bundle.crt" ]; then
                export SSL_CERT_FILE=$(readlink /run/host/etc/static/ssl/certs/ca-bundle.crt)
                export NIX_SSL_CERT_FILE=$SSL_CERT_FILE
                export GIT_SSL_CAINFO=$SSL_CERT_FILE
              fi

              host_sys=$(readlink /run/host/run/current-system)
              host_user=$(readlink /run/host/etc/profiles/per-user/$USER)
              if [ -n "$host_sys" ]; then export PATH="$PATH:/run/host$host_sys/sw/bin"; fi
              if [ -n "$host_user" ]; then
                host_user_resolved=$(readlink "/run/host$host_user")
                [ -z "$host_user_resolved" ] && host_user_resolved="$host_user"
                export PATH="$PATH:/run/host$host_user_resolved/bin"
              fi
              unset host_sys host_user host_user_resolved
            fi

            # autocd
            shopt -s autocd 2>/dev/null
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

  # Brush epilogue — runs after .bashrc so all tool integrations exist
  home.file.".brushrc".text = ''
    if type starship_precmd &>/dev/null; then
      PROMPT_COMMAND="starship_precmd;''${PROMPT_COMMAND:-}"
    fi
  '';

  # Brush config — enable zsh-style hooks for atuin/starship integration
  xdg.configFile."brush/config.toml".text = ''
    [ui]
    syntax-highlighting = true

    [experimental]
    zsh-hooks = true
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
