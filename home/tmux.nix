{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    
    # 1. Core Settings
    shortcut = "a";          # Replaces C-b with C-a
    baseIndex = 1;           # Start windows at 1
    escapeTime = 0;          # Zero delay for VIM
    aggressiveResize = true; # Better resizing for multi-monitor
    keyMode = "vi";          # Standard VI keys

    # 2. Terminal Colors
    terminal = "screen-256color"; # Standard Setting
    
    # 3. Plugins (Replaces TPM)
    plugins = with pkgs.tmuxPlugins; [
      sensible
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

    # 4. Manual Config & Keybinds
    extraConfig = ''
      # TrueColor Override
      set -ga terminal-overrides ",*-256color:Tc"

      # Pane Colors
      set-option -g display-panes-active-colour colour33
      set-option -g display-panes-colour colour166

      # Activity Monitoring
      setw -g monitor-activity on
      set -g visual-activity on

      # --- NAVIGATION (Vim Style) ---
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R

      # --- SPLITS ---
      # Cayeto fix: I remapped split-horizontal to '|' so it doesn't 
      # conflict with 'h' (navigation) above.
      bind | split-window -h
      bind v split-window -v
      
      # Allow C-a a to send prefix to nested session
      bind-key a send-prefix
    '';
  };
}
