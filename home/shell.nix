{ pkgs, userConfig, ... }:

{
  catppuccin.starship.enable = true;
  catppuccin.bat.enable = true;
  catppuccin.fzf.enable = true;
  catppuccin.lsd.enable = true;
  catppuccin.bottom.enable = true;
  catppuccin.lazygit.enable = true;
  catppuccin.yazi.enable = true;
  catppuccin.btop.enable = true;
  catppuccin.k9s.enable = true;

  home.packages = with pkgs; [
    # --- CORE UTILS ---
    lsd bat fzf fd ripgrep
    duf dust bottom fastfetch gdu
    tldr jq rsync pv
    ncdu lazydocker
    ticker tenki viddy
    lftp
    khal
    khard
    man-db
    kubernetes-helm
    kubectl
    
    # --- COMPRESSION & ARCHIVING ---
    zip unzip 
    p7zip
    xz zstd lz4 
    gnutar gzip bzip2
    libarchive
    
    # --- SYSTEM TOOLS ---
    appimage-run
    wl-clipboard
    dwarfs fuse3
    nvitop
    nvtopPackages.nvidia
    bluetuith
  ];

  home.sessionVariables = {
    DIRENV_LOG_FORMAT = "";
    TERMINAL = "kitty";
  };

  programs.bash = {
    enable = true;
    enableCompletion = true;
    
    shellAliases = {
      ls = "lsd";
      l = "ls -alh";
      ll = "ls -l";
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
      # OLD: nrb = "sudo nixos-rebuild switch --flake .#ninja";
      # NEW (using nh):
      st = "git -C $NH_FLAKE add -f -N secrets.nix";
      forget = "git -C $NH_FLAKE rm --cached --ignore-unmatch secrets.nix";
      g-push = "forget && git -C $NH_FLAKE push";
      gco = "git checkout";
      nrb = "st && nh os switch";
      ndr = "st && nh os build"; # Dry-run: build without switching (no sudo needed)
      ndry = "nix build .#nixosConfigurations.ninja.config.system.build.toplevel --dry-run"; # Old dry-run
      # Nix cleanup: keep last 10 generations, preserve dev environments
      ncl = "nh clean all --keep 10 --nogc";
      # Full cleanup: prune stale direnvs, then garbage collect everything
      ncl-full = "direnv prune && nh clean all --keep 10";
      up = "st && nh os switch --update"; # Update flake inputs AND switch
      ersave = "cp -r /home/${userConfig.username}/.local/share/Steam/steamapps/compatdata/1245620/pfx/drive_c/users/steamuser/AppData/Roaming/EldenRing ~/Documents/ER_Backup_$(date +%F)";
      gpu = "nvitop";
      gpg-fix = "gpgconf --kill gpg-agent && rm -f ~/.gnupg/*.lock ~/.gnupg/public-keys.d/*.lock && echo 'GPG Fixed'";
      ssh = "TERM=xterm-256color ssh";
      ask = "npx @google/gemini-cli@latest chat";
      
      # Per-App Audio Overrides (Anticipation Strategy)
      pw-lowlat = "PIPEWIRE_LATENCY='1024/48000'";
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
    };

    initExtra = ''
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
        rg --files --hidden --glob '!.git' "$target" | xargs -I {} sh -c '
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
use flake ~/nixos-config/templates#$target
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
use flake ~/nixos-config/templates#$target
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
use flake ~/nixos-config/templates#rust
watch_file Cargo.toml
watch_file Cargo.lock
EOF
        direnv allow
      }

      function cinit() {
        cat <<EOF > .envrc
use flake ~/nixos-config/templates#c
watch_file CMakeLists.txt
watch_file Makefile
EOF
        direnv allow
      }

      function cppinit() {
        cat <<EOF > .envrc
use flake ~/nixos-config/templates#cpp
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

      # Ensure local binaries are in PATH (at the end to avoid overrides)
      export PATH="$PATH:$HOME/.local/bin:$HOME/bin"
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

  programs.zoxide = {
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
      command_timeout = 1000;
      add_newline = false;
      format = "$directory$hostname$git_branch$git_status$container$character";
      
      hostname = {
        ssh_only = true;
        format = "on [$hostname]($style) ";
        style = "bold dimmed white";
        hosts_alias = {
          "windy" = "󰌢 windy";
          "ninja" = "󰟀 ninja";
        };
      };

      # Custom icons/styles for specific hosts
      # Note: This is evaluated based on the current hostname
    };
  };

  programs.lazygit.enable = true;
  programs.yazi.enable = true;
  programs.k9s.enable = true;
  programs.gh.enable = true;

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
