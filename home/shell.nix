{ pkgs, userConfig, ... }:

{
  home.packages = with pkgs; [
    lsd bat fzf fd ripgrep yazi
    duf btop fastfetch
    zip unzip _7zz peazip
    unrar libarchive
    appimage-run
    wl-clipboard  # Essential for piping to clipboard
    jq
    rsync pv
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    
    shellAliases = {
      ls = "lsd";
      l = "ls -alh";
      ll = "ls -l";
      cat = "bat";
      grep = "rg";
      top = "btop";
      find = "fd";
      vim = "nvim";
      cpv = "rsync -ahP";
      sysls = "systemctl --type=service --state=running";
      # Cache clearing alias
      ks = "sudo sh -c \"sync; echo 1 > /proc/sys/vm/drop_caches\" && echo \"RAM cache cleared\"";
      # Rebuild the system and home-manager in one go
      # OLD: nrb = "sudo nixos-rebuild switch --flake .#ninja";
      # NEW (using nh):
      st = "git -C $NH_FLAKE add -f -N secrets.nix";
      forget = "git -C $NH_FLAKE rm --cached --ignore-unmatch secrets.nix";
      g-push = "forget && git -C $NH_FLAKE push";
      nrb = "st && nh os switch";
      ndry = "nix build .#nixosConfigurations.ninja.config.system.build.toplevel --dry-run";
      ncl = "nh clean all --keep 5";
      up = "st && nh os switch --update"; # Update flake inputs AND switch
      ersave = "cp -r /home/${userConfig.username}/.local/share/Steam/steamapps/compatdata/1245620/pfx/drive_c/users/steamuser/AppData/Roaming/EldenRing ~/Documents/ER_Backup_$(date +%F)";
      gpu = "nvtop";
      ai = "npx @google/gemini-cli@latest";
      ask = "npx @google/gemini-cli@latest chat";
    };

    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      BAT_THEME = "TwoDark";
    };

    initExtra = ''
      # --- GPG TTY FIX ---
      # Critical for GPG password prompts to appear in the terminal
      export GPG_TTY=$(tty)

      # --- FNM (Node Manager) Init ---
      # Add standard local install path to PATH (for Distrobox/manual installs)
      export PATH="$HOME/.local/share/fnm:$PATH"
      
      # Enable 'fnm' command and auto-switching if the binary is found
      if command -v fnm >/dev/null; then
        eval "$(fnm env --use-on-cd)"
      fi

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
    '';
  };

  programs.starship = {
    enable = true;
    settings = {
      command_timeout = 1000;
      add_newline = false;
      format = "$directory$git_branch$git_status$container$character";
      directory.style = "bold lavender";
      container = {
        symbol = "📦";
        style = "bold red";
      };
      character = {
        success_symbol = "[➜](bold green)";
        error_symbol = "[✗](bold red)";
      };
    };
  };
}
