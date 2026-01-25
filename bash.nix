{ config, pkgs, ... }:

{
  # 1. Install the tools your aliases rely on
  home.packages = with pkgs; [
    lsd          # The 'ls' replacement
    bat          # The 'cat' replacement
    fzf          # Fuzzy finder
    fd           # 'find' replacement
    ripgrep      # 'grep' replacement
    yazi         # Terminal file manager
    duperemove   # Deduplication tool
    fdupes       # Deduplication tool
    mktemp       # Usually builtin, but good to have coreutils
    moc          # Console music player (mocp)
  ];

  # 2. Broot needs special handling in Nix to work correctly
  programs.broot = {
    enable = true;
    enableBashIntegration = true; # Replaces the manual 'source' line
  };

  # 3. Bash Configuration
  programs.bash = {
    enable = true;
    enableCompletion = true;

    # Translate 'exports' to sessionVariables
    sessionVariables = {
      EDITOR = "nvim";
      VISUAL = "nvim";
      
      # Bat & Manpager
      BAT_THEME = "TwoDark";
      PAGER = "bat --style=numbers,changes --italic-text=always";
      MANPAGER = "sh -c 'col -bx | bat -l man -p'";
      
      # SSH
      SSH_KEY_PATH = "${config.home.homeDirectory}/.ssh/id_ed25519";
      
      # Wine & Nix
      WINEFSYNC = "1";
      NIXPKGS_ALLOW_UNFREE = "1";
      
      # FZF
      FZF_DEFAULT_COMMAND = "fd --type f";
      FZF_DEFAULT_OPTS = "--height 40% --tmux bottom,40% --layout reverse --border top";
    };

    # Translate 'aliases'
    shellAliases = {
      ks = "sudo sh -c \"sync; echo 1 > /proc/sys/vm/drop_caches\" && echo \"RAM cache cleared\"";
      sysls = "systemctl --type=service --state=running";
      rm = "rm --preserve-root";
      duperm = "fdupes -r /home | duperemove --fdupes";
      vim = "nvim";
      gco = "git checkout";
      ls = "lsd";
      mocp = "mocp -T darkdot_theme";
    };

    # Custom Functions (The 'y' function for Yazi)
    initExtra = ''
      # Yazi wrapper to change directory on exit
      function y() {
        local tmp
        tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';
  };
}
