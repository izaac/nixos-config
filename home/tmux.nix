{ pkgs, ... }:

let
  # --- CUSTOM PLUGIN DEFINITION ---
  # Build tmux-menus locally as it is not available in nixpkgs.
  tmux-menus = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-menus";
    version = "unstable-2024-01-26";
    src = pkgs.fetchFromGitHub {
      owner = "jaclu";
      repo = "tmux-menus";
      rev = "main"; 
      sha256 = "sha256-UPWsa7sFy6P3Jo3KFEvZrz4M4IVDhKI7T1LNAtWqTT4="; 
    };
  };
in
{
  programs.tmux = {
    enable = true;
    package = pkgs.small.tmux;
    
    # --- CORE BEHAVIOR ---
    shortcut = "a";          # Replaces C-b with C-a
    baseIndex = 1;           # Start windows at 1
    escapeTime = 0;          # Zero delay for VIM
    aggressiveResize = true; # Better resizing for multi-monitor
    keyMode = "vi";          # Standard VI keys
    mouse = true;            # Enable mouse support (Scrolling/Clicking)

    # --- TERMINAL & SHELL ---
    terminal = "screen-256color"; 
    
    # --- PLUGINS ---
    plugins = with pkgs.tmuxPlugins; [
      sensible
      
      # Custom-built plugin
      tmux-menus 

      {
        plugin = catppuccin;
        extraConfig = '' 
          set -g @catppuccin_flavor 'mocha'
          set -g status-left ""
          set -g status-right '#[fg=#{@thm_crust},bg=#{@thm_teal}] session: #S '
          set -g status-right-length 100
        '';
      }
    ];

    # --- KEYBINDS & MANUAL CONFIG ---
    extraConfig = ''
      # 1. TrueColor Override
      set -ga terminal-overrides ",*-256color:Tc"

      # 2. Pane Colors (Blue/Orange)
      set-option -g display-panes-active-colour colour33
      set-option -g display-panes-colour colour166

      # 3. Activity Alerts
      setw -g monitor-activity on
      set -g visual-activity on

      # 4. The "Alt-Tab" Window Toggle (Critical Fix!)
      bind-key C-a last-window

      # 5. Nested Tmux (C-a a sends prefix inside)
      bind-key a send-prefix

      # --- NAVIGATION (Vim Style) ---
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # --- SPLITS ---
      # Remapped to '|' to avoid conflict with 'h' navigation
      bind | split-window -h
      bind v split-window -v
    '';
  };
}
