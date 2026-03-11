{ pkgs, userConfig, ... }:

{
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
    enableBashIntegration = false;
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
    enableBashIntegration = true;
  };

  programs.eza = {
    enable = true;
    enableBashIntegration = true;
    icons = "auto";
    git = true;
  };

  programs.bat.enable = true;

  home.packages = with pkgs; [
    # --- CORE UTILS ---
    fzf fd ripgrep
    duf dust bottom fastfetch gdu
    jq rsync pv bc
    ncdu lazydocker rclone
    ticker tenki viddy
    lftp
    man-db
    kubernetes-helm
    kubectl
    procs just nix-tree comma nvd
    
    # --- MEDIA & ENCODING ---
    (callPackage ../pkgs/vcrunch { })
    
    # --- COMPRESSION & ARCHIVING ---
    zip unzip 
    p7zip
    xz zstd lz4 
    gnutar gzip bzip2
    libarchive
    
    # --- SYSTEM TOOLS ---
    bash-preexec
    appimage-run
    wl-clipboard
    dwarfs
    fuse3
    nvitop
    nvtopPackages.nvidia
    bluetuith
  ];

  home.sessionVariables = {
    DIRENV_LOG_FORMAT = "";
    TERMINAL = "kitty";
    MANPAGER = "sh -c 'col -bx | bat -l man -p'";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    
    shellAliases = {
      # Use the smart eza wrapper defined in initExtra
      ls = "_smart_eza --group-directories-first";
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
      ndr = "st && nh os build"; # Dry-run: build without switching (no sudo needed)
      ndry = "nix build .#nixosConfigurations.ninja.config.system.build.toplevel --dry-run"; # Old dry-run
      # Nix cleanup: keep last 10 generations, preserve dev environments
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

      # Canary: Query the latest versions and CACHE status on nixos-unstable
      canary = ''
        echo "--- [ CANARY ] nixos-unstable status ---"
        # Fetching version numbers using the tarball URL (still efficient for this)
        nix-instantiate --eval --json --strict -E "let pkgs = import (builtins.fetchTarball \"https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz\") {}; in { gnome = pkgs.gnome-shell.version; kernel = pkgs.linuxPackages_zen.kernel.version; nvidia = pkgs.linuxPackages.nvidia_x11.version; }" | jq

        echo -e "\n--- Cache Check (Binary Availability) ---"
        function _check() {
          local name=$1
          local attr=$2
          local res
          # Use github:nixos/nixpkgs/nixos-unstable for clean flake attribute access
          # NIXPKGS_ALLOW_UNFREE is required for NVIDIA
          res=$(NIXPKGS_ALLOW_UNFREE=1 nix build --dry-run "github:nixos/nixpkgs/nixos-unstable#$attr" --impure --no-link 2>&1)
          
          if echo "$res" | grep -q "will be built"; then
            echo -e "$name: \033[0;31mBUILD REQUIRED\033[0m (Wait for hydra!)"
          elif echo "$res" | grep -q "will be fetched"; then
            echo -e "$name: \033[0;32mCACHE HIT\033[0m (Binary available)"
          elif [ -z "$res" ] || echo "$res" | grep -q "already exists"; then
            # Empty output often means it's already in the store and nothing needs to be done
            echo -e "$name: \033[0;32mCACHE HIT\033[0m (Already present)"
          else
            echo -e "$name: \033[0;33mERROR\033[0m (Nix failed to evaluate)"
            # For debugging
            # echo "$res"
          fi
        }
        
        _check "GNOME Shell " "gnome-shell"
        _check "Linux Kernel" "linuxPackages_6_18.kernel"
        _check "GCC Compiler " "gcc"
        _check "Glibc Library" "glibc"
        _check "Systemd Core " "systemd"
        _check "Wine Wayland " "wineWow64Packages.waylandFull"
        _check "Firefox Browser" "firefox"
        _check "Chromium Web " "chromium"
      '';

      # Per-App Audio Overrides (Anticipation Strategy)
      pw-lowlat = "PIPEWIRE_LATENCY='512/48000'";
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    initExtra = ''
      # --- Gemini CLI Wrapper ---
      # Automatically uses -p (non-interactive) if arguments are provided
      # to avoid the "Positional arguments now default to interactive mode" notice.
      function ask() {
        if [[ $# -eq 0 ]]; then
          npx --yes @google/gemini-cli@latest
        else
          npx --yes @google/gemini-cli@latest -p "$*"
        fi
      }

      # --- Smart eza Wrapper ---
      # Prevents hangs on network mounts
      function _smart_eza() {
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
      function y() {
        local tmp="''$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="''$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }

      # --- Recursive Cat (The "Dump" Tool) ---
      # Optimized with ripgrep for speed
      function catr() {
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
      function ninit() {
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

      function pinit() {
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

      function rinit() {
        cat <<EOF > .envrc
use flake ${userConfig.dotfilesDir}/templates#rust
watch_file Cargo.toml
watch_file Cargo.lock
EOF
        direnv allow
      }

      function cinit() {
        cat <<EOF > .envrc
use flake ${userConfig.dotfilesDir}/templates#c
watch_file CMakeLists.txt
watch_file Makefile
EOF
        direnv allow
      }

      function cppinit() {
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

      # --- Atuin Initialization (Manual) ---
      # Force initialization even if line editing is not detected in SHELLOPTS.
      # This ensures Atuin records history in all interactive sessions.
      if [ -f "${pkgs.bash-preexec}/share/bash/bash-preexec.sh" ]; then
        source "${pkgs.bash-preexec}/share/bash/bash-preexec.sh"
      fi
      if command -v atuin >/dev/null; then
        eval "$(atuin init bash)"
        
        # Override the Up Arrow keybinding to use the full interactive search 
        # (exactly like Ctrl+R) instead of the inline shell-up behavior.
        bind -x '"\e[A": __atuin_history'
        bind -x '"\eOA": __atuin_history'
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
    enableBashIntegration = true;
    defaultCommand = "fd --type f";
    fileWidgetCommand = "fd --type f";
    changeDirWidgetCommand = "fd --type d";
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
  };

  programs.pay-respects = {
    enable = true;
    enableBashIntegration = true;
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
    enableBashIntegration = true;
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
    enableBashIntegration = true;
    shellWrapperName = "y";
  };

  xdg.desktopEntries.yazi = {
    name = "Yazi";
    exec = "kitty -e yazi %u";
    icon = "yazi";
    terminal = false;
    categories = [ "Utility" "Core" "System" "FileTools" "FileManager" "ConsoleOnly" ];
    mimeType = [ "inode/directory" ];
    settings = {
      Keywords = "File;Manager;Explorer;Browser;Launcher";
    };
  };

  xdg.desktopEntries.btop = {
    name = "btop++";
    exec = "kitty -e btop";
    icon = "btop";
    terminal = false;
    categories = [ "System" "Monitor" "ConsoleOnly" ];
    settings = {
      Keywords = "system;process;task";
    };
  };
}
