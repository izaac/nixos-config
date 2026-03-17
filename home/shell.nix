{
  config,
  pkgs,
  userConfig,
  ...
}: {
  # catppuccin.starship.enable = true;
  catppuccin.bat.enable = true;
  catppuccin.fzf.enable = true;
  catppuccin.bottom.enable = true;
  catppuccin.lazygit.enable = true;
  catppuccin.yazi.enable = true;
  catppuccin.btop.enable = true;
  catppuccin.k9s.enable = true;
  catppuccin.atuin.enable = true;

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

  programs.bat.enable = true;

  home.packages = with pkgs; [
    # --- CORE UTILS ---
    fzf
    fd
    ripgrep
    uutils-coreutils
    ouch
    duf
    dust
    bottom
    sops
    age
    fastfetch
    gdu
    jq
    rsync
    pv
    bc
    ncdu
    lazydocker
    rclone
    ticker
    tenki
    viddy
    lftp
    man-db
    kubernetes-helm
    kubectl
    procs
    just
    nix-tree
    comma
    nvd

    # --- NIX DEVELOPMENT TOOLS ---
    alejandra
    deadnix
    statix

    # --- MEDIA & ENCODING ---
    (callPackage ../pkgs/vcrunch {})

    # --- COMPRESSION & ARCHIVING ---
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

    # --- SYSTEM TOOLS ---
    appimage-run
    wl-clipboard
    dwarfs
    fuse3
    nvitop
    nvtopPackages.nvidia
    bluetuith
  ];

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

  home.sessionVariables = {
    DIRENV_LOG_FORMAT = "";
    TERMINAL = "kitty";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
    # Prevent Atuin from trying to migrate the database inside Distrobox.
    # This keeps host Atuin versions (NixOS) safe from rolling-release containers (Arch).
    ATUIN_NO_MODIFY_DB = "true";
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    autocd = true;
    historySubstringSearch.enable = true;
    dotDir = "${config.xdg.configHome}/zsh";

    shellAliases = {
      # Use uutils-ls for basic listing, keep eza for detailed/smart views
      ls = "uutils-ls --group-directories-first --color=auto";
      uls = "uutils-ls --group-directories-first --color=auto";
      l = "_smart_eza -lb --git --group-directories-first";
      ll = "_smart_eza -l --group-directories-first";
      la = "_smart_eza -la --group-directories-first";
      lt = "_smart_eza --tree --level=2";
      cd = "z";
      cat = "bat";
      top = "btop";
      vim = "TERM=xterm-256color nvim";
      nvim = "TERM=xterm-256color nvim";
      cpv = "rsync -ahP";
      sysls = "systemctl --type=service --state=running";
      lg = "lazygit";
      # Cache clearing alias
      ks = "sudo sh -c \"sync; echo 1 > /proc/sys/vm/drop_caches\" && echo \"RAM cache cleared\"";
      # Rebuild the system and home-manager in one go
      st = "git -C $NH_FLAKE add .";
      gco = "git checkout";
      nrb = "st && nh os switch";
      ndr = "st && nh os build"; # Build without switching (no sudo needed)
      # Nix Tools
      nqs = "nix-env -qaP | fzf --preview 'nix-env -qaP {}' --preview-window=right:70%:wrap";
      ncl = "nh clean all --keep 10 --nogc";
      # Full cleanup: prune stale direnvs, then garbage collect everything
      ncl-full = "direnv prune && nh clean all --keep 10";
      # Diff aliases
      nv-sys = "nvd diff $(command ls -vd /nix/var/nix/profiles/system-*-link | tail -2)";
      nv-boot = "nvd diff /run/booted-system /run/current-system";
      up = "st && nh os switch --update"; # Update flake inputs AND switch
      up-browsers = "st && nix flake update nixpkgs-latest && nh os switch"; # Update ONLY browsers and switch
      ersave = "cp -r /home/${userConfig.username}/.local/share/Steam/steamapps/compatdata/1245620/pfx/drive_c/users/steamuser/AppData/Roaming/EldenRing ~/Documents/ER_Backup_$(date +%F)";
      er-offline = "cd /mnt/data/SteamLibrary/steamapps/common/ELDEN\\ RING/Game && if [ -f start_protected_game.exe ] && [ ! -f start_protected_game_original.exe ]; then mv start_protected_game.exe start_protected_game_original.exe && cp eldenring.exe start_protected_game.exe && echo 'Elden Ring Offline Mode (EAC Bypass) ENABLED'; else echo 'Already in offline mode or Game path not found'; fi";
      er-online = "cd /mnt/data/SteamLibrary/steamapps/common/ELDEN\\ RING/Game && if [ -f start_protected_game_original.exe ]; then rm start_protected_game.exe && mv start_protected_game_original.exe start_protected_game.exe && echo 'Elden Ring Online Mode (EAC) RESTORED'; else echo 'Already in online mode or Game path not found'; fi";
      # --- NVIDIA TWEAKS ---
      gpg-fix = "gpgconf --kill gpg-agent && rm -f ~/.gnupg/*.lock ~/.gnupg/public-keys.d/*.lock && echo 'GPG Fixed'";
      ssh = "TERM=xterm-256color ssh";

      # Per-App Audio Overrides (Anticipation Strategy)
      pw-lowlat = "PIPEWIRE_LATENCY='512/48000'";
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    initContent = ''
            # --- Gemini CLI ---
            # -p for non-interactive if args present
            ask() {
              if [[ $# -eq 0 ]]; then
                npx --yes @google/gemini-cli@latest
              else
                npx --yes @google/gemini-cli@latest -p "$*"
              fi
            }

            # --- Smart Eza ---
            # No icons/git on network shares to prevent hangs
            _smart_eza() {
              if [[ "$PWD" == *"/mnt/storage"* ]] || [[ "$*" == *"/mnt/storage"* ]]; then
                # Strip --git and -g flags for network shares to avoid hangs
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
            # Critical for GPG password prompts to appear in the terminal
            export GPG_TTY=$(tty)

            # --- Yazi Wrapper (CD on exit) ---
            y() {
              local tmp="''$(mktemp -t "yazi-cwd.XXXXXX")"
              yazi "$@" --cwd-file="$tmp"
              if cwd="''$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
                builtin cd -- "$cwd"
              fi
              rm -f -- "$tmp"
            }

            # --- Recursive Cat (The "Dump" Tool) ---
            # Optimized with ripgrep for speed
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

            # --- Project Initializers (Golden Master) ---
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
        echo "📦 node_modules missing. Attempting install..."
        if [ -f "pnpm-lock.yaml" ]; then pnpm install;
        elif [ -f "yarn.lock" ]; then yarn install;
        else npm install; fi
      fi
      EOF
              direnv allow
            }

            pinit() {
              local ver="''${1:-}"
              local target="python"
              if [ -n "$ver" ]; then target="python_$ver"; fi

              cat <<EOF > .envrc
      use flake ${userConfig.dotfilesDir}/templates#python
      watch_file requirements.txt
      watch_file pyproject.toml

      if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
        if [ ! -d ".venv" ] && [ -f "requirements.txt" ]; then
          echo "📦 Creating virtual environment and installing dependencies..."
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
              export PATH="$FNM_PATH:$PATH"
              eval "`fnm env`"
            fi

            # Ensure local binaries are in PATH
            export PATH="$PATH:$HOME/.local/bin:$HOME/bin"

            # --- Distrobox: Host Tool Injection ---
            # Map host Nix tools into containers
            if [ -d "/run/host/nix/store" ]; then
              # Scrub host variables that poison the container environment.
              # NixOS leaks paths that confuse container tools (like dnf),
              # making them try to load incompatible host libraries.
              unset GI_TYPELIB_PATH
              unset GDK_PIXBUF_MODULE_FILE
              unset XDG_DATA_DIRS

              # Fix broken SSL certs in containers.
              # Distrobox mounts NixOS's /etc/ssl, but its symlinks point to unmounted /etc/static paths.
              # We bypass the dead links by pointing directly to the real certs in the /nix/store.
              if [ -L "/run/host/etc/static/ssl/certs/ca-bundle.crt" ]; then
                export SSL_CERT_FILE=$(readlink /run/host/etc/static/ssl/certs/ca-bundle.crt)
                export NIX_SSL_CERT_FILE=$SSL_CERT_FILE
                export GIT_SSL_CAINFO=$SSL_CERT_FILE
              fi

              # Find the current system and user profile in the store
              local host_sys=$(readlink /run/host/run/current-system)
              local host_user=$(readlink /run/host/etc/profiles/per-user/$USER)

              if [ -n "$host_sys" ]; then
                export PATH="$PATH:/run/host$host_sys/sw/bin"
              fi
              if [ -n "$host_user" ]; then
                # User profile might link to /etc/static, resolve one more level
                local host_user_resolved=$(readlink "/run/host$host_user")
                [ -z "$host_user_resolved" ] && host_user_resolved="$host_user"
                export PATH="$PATH:/run/host$host_user_resolved/bin"
              fi
            fi
    '';
  };

  # direnv: Automatically load development environments when entering project directories
  programs.direnv = {
    enable = true;
    # nix-direnv: Prevents dev environments from being garbage collected
    # Creates GC roots in ~/.local/share/direnv/allow/ so your cached
    # environments persist across 'nh clean' and 'nix-collect-garbage'
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f";
    fileWidgetCommand = "fd --type f";
    changeDirWidgetCommand = "fd --type d";
  };

  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
  };

  programs.pay-respects = {
    enable = true;
    enableZshIntegration = true;
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

  programs.nix-index = {
    enable = true;
    enableZshIntegration = true;
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

  programs.btop = {
    enable = true;
    settings = {
      theme_background = false; # Use terminal background
      update_ms = 500;
      proc_sorting = "cpu lazy";
    };
  };

  programs.starship = {
    enable = true;
    package = pkgs.starship;
    settings = {
      command_timeout = 5000;
      add_newline = false;
      format = "$directory$hostname$git_branch$git_status$container$character";

      hostname = {
        ssh_only = true;
        format = "on [$hostname]($style) ";
        style = "bold dimmed white";
        aliases = {
          "windy" = "󰌢 windy";
          "ninja" = "󰟀 ninja";
        };
      };

      # Custom icons/styles for specific hosts
      # Note: This is evaluated based on the current hostname
    };
  };

  programs.lazygit.enable = true;
  programs.yazi = {
    enable = true;
    enableZshIntegration = true;
    shellWrapperName = "y";
  };

  xdg.desktopEntries.yazi = {
    name = "Yazi";
    exec = "kitty -e yazi %u";
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
    exec = "kitty -e btop";
    icon = "btop";
    terminal = false;
    categories = ["System" "Monitor" "ConsoleOnly"];
    settings = {
      Keywords = "system;process;task";
    };
  };
}
