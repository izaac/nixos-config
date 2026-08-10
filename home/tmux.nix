{pkgs, ...}: let
  # tmux-menus is not in nixpkgs; build it locally with a pinned rev so the
  # source is reproducible (older config used `rev = "main"` which moves).
  tmux-menus = pkgs.tmuxPlugins.mkTmuxPlugin {
    pluginName = "tmux-menus";
    rtpFilePath = "menus.tmux";
    version = "unstable-2026-05-22";
    src = pkgs.fetchFromGitHub {
      owner = "jaclu";
      repo = "tmux-menus";
      rev = "77a95a7e31fe26ab9615f3f734c793fe436ec219";
      hash = "sha256-pqm2CFnaOdi9fpU85uoQoA/V3925liqwElcd/N7LAtQ=";
    };
  };
in {
  # Theming comes from Stylix (modules/core/theme.nix); no manual catppuccin
  # block needed — `programs.tmux.enable` is enough for Stylix to colorize.

  programs.tmux = {
    enable = true;
    package = pkgs.tmux;

    # --- CORE BEHAVIOR ---
    shortcut = "a"; # Replaces C-b with C-a
    baseIndex = 1; # Start windows at 1
    escapeTime = 0; # Zero delay for VIM
    aggressiveResize = true; # Better resizing for multi-monitor
    keyMode = "vi"; # Standard VI keys
    mouse = true; # Enable mouse support (Scrolling/Clicking)

    # --- TERMINAL & SHELL ---
    terminal = "tmux-256color";

    # --- PLUGINS ---
    # tmux-menus loaded manually in extraConfig below so we can set
    # @menus_use_cache BEFORE plugin init (Nix store is read-only).
    plugins = with pkgs.tmuxPlugins; [
      sensible
    ];

    # --- KEYBINDS & MANUAL CONFIG ---
    extraConfig = ''
      # tmux-menus: disable cache (plugin folder is read-only on Nix store),
      # rebind trigger to "m" for menu (default \ now used for pane split),
      # then run-shell the plugin entrypoint manually.
      set -g @menus_use_cache "no"
      set -g @menus_trigger "m"
      run-shell ${tmux-menus}/share/tmux-plugins/tmux-menus/menus.tmux

      # 0. Status bar (Stylix paints the colors; format only here)
      set -g status-interval 5
      set -g status-justify left

      # Left: session name, prefix indicator when active
      set -g status-left "#[bold] #S #[default]#{?client_prefix,#[reverse] PREFIX #[noreverse],}"
      set -g status-left-length 40

      # Window list: index:name + flags (* current, - last, ! bell, Z zoomed)
      set -g window-status-format " #I:#W#F "
      set -g window-status-current-format " #[bold]#I:#W#F#[nobold] "

      # Right: minimal clock — ashell bar already shows full date.
      set -g status-right " %H:%M "
      set -g status-right-length 10

      # 1. TrueColor Override + modern terminal feature flags. Kitty
      # supports OSC 52 clipboard relay and RGB color; tell tmux so yanks
      # reach the Wayland clipboard and color rendering stays true.
      set -ga terminal-overrides ",*-256color:Tc"
      set -as terminal-features ',*:RGB:clipboard'
      set -s set-clipboard on

      # Forward focus events to apps inside tmux (fixes nvim autoread,
      # tmux 3.5+ async refresh hooks).
      set -g focus-events on

      # 2. Pane Colors (Blue/Orange)
      set-option -g display-panes-active-colour colour33
      set-option -g display-panes-colour colour166

      # 3. Activity Alerts
      setw -g monitor-activity on
      set -g visual-activity on

      # 4. The "Alt-Tab" Window Toggle
      bind-key C-a last-window

      # 5. Nested Tmux (C-a a sends prefix inside)
      bind-key a send-prefix

      # --- NAVIGATION (Vim Style) ---
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind Left  select-pane -L
      bind Down  select-pane -D
      bind Up    select-pane -U
      bind Right select-pane -R

      # --- TMUX-NAVIGATOR (seamless Ctrl+HJKL across vim splits and tmux panes) ---
      is_vim="ps -o state= -o comm= -t '#{pane_tty}' \
        | grep -iqE '^[^TXZ ]+ +(\\S+\\/)?g?\\.?(view|l?n?vim?x?|fzf)(diff)?$'"
      bind-key -n 'C-h' if-shell "$is_vim" 'send-keys C-h'  'select-pane -L'
      bind-key -n 'C-j' if-shell "$is_vim" 'send-keys C-j'  'select-pane -D'
      bind-key -n 'C-k' if-shell "$is_vim" 'send-keys C-k'  'select-pane -U'
      bind-key -n 'C-l' if-shell "$is_vim" 'send-keys C-l'  'select-pane -R'
      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R

      # --- SPLITS ---
      bind "\\" split-window -h
      bind v split-window -v

      # --- COPY MODE (Vim Style) ---
      # `v` begins a selection and `y` yanks like Vim. These live in the
      # copy-mode-vi key table, so they do not collide with the prefix `v`
      # split above. Rectangle selection stays on `C-v` (tmux default).
      bind-key -T copy-mode-vi v send-keys -X begin-selection
      bind-key -T copy-mode-vi y send-keys -X copy-selection-and-cancel
    '';
  };
}
