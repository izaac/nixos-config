_: {
  programs.wezterm = {
    enable = true;
    enableBashIntegration = true;

    extraConfig = ''
      local wezterm = require 'wezterm'
      local act = wezterm.action
      local config = wezterm.config_builder()

      -- Launch brush as the interactive shell
      config.default_prog = { 'brush', '--login' }

      -- Font (matching Kitty: JetBrainsMono Nerd Font Mono @ 11pt)
      config.font = wezterm.font('JetBrainsMono Nerd Font Mono')
      config.font_size = 11.0

      -- Theme: Catppuccin Mocha (built-in) with Kitty overrides
      config.color_scheme = 'Catppuccin Mocha'
      config.colors = {
        background = '#030305',
        cursor_bg = '#f5e0dc',
        cursor_fg = '#1e1e2e',
        selection_fg = '#1e1e2e',
        selection_bg = '#f5e0dc',
      }

      -- Window
      config.window_padding = {
        left = 10,
        right = 10,
        top = 10,
        bottom = 10,
      }
      config.window_close_confirmation = 'NeverPrompt'
      config.audible_bell = 'Disabled'

      -- Tab Bar (matching Kitty's bottom powerline style)
      config.enable_tab_bar = true
      config.tab_bar_at_bottom = true
      config.use_fancy_tab_bar = false
      config.show_tab_index_in_tab_bar = false

      -- Keybindings (cloned from Kitty)
      config.keys = {
        -- Tabs
        { key = 'T', mods = 'CTRL|SHIFT', action = act.SpawnTab 'CurrentPaneDomain' },
        {
          key = 'T',
          mods = 'CTRL|SHIFT|ALT',
          action = act.PromptInputLine {
            description = 'Rename current tab (leave empty to reset)',
            action = wezterm.action_callback(function(window, _pane, line)
              if line ~= nil then
                window:active_tab():set_title(line)
              end
            end),
          },
        },
        { key = 'PageUp', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(-1) },
        { key = 'PageDown', mods = 'CTRL|SHIFT', action = act.ActivateTabRelative(1) },
        { key = '1', mods = 'CTRL|SHIFT', action = act.ActivateTab(0) },
        { key = '2', mods = 'CTRL|SHIFT', action = act.ActivateTab(1) },
        { key = '3', mods = 'CTRL|SHIFT', action = act.ActivateTab(2) },
        { key = '4', mods = 'CTRL|SHIFT', action = act.ActivateTab(3) },

        -- Splits (Kitty hsplit = pane below, vsplit = pane right)
        { key = 'N', mods = 'CTRL|SHIFT', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
        { key = '|', mods = 'CTRL|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },

        -- Navigate Splits
        { key = 'LeftArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Left' },
        { key = 'RightArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Right' },
        { key = 'UpArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Up' },
        { key = 'DownArrow', mods = 'CTRL|SHIFT', action = act.ActivatePaneDirection 'Down' },

        -- Toggle Zoom (equivalent to Kitty's stack layout toggle)
        { key = 'F', mods = 'CTRL|SHIFT', action = act.TogglePaneZoomState },
      }

      -- Tab title: show process name + cwd basename
      wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, _hover, _max_width)
        local pane = tab.active_pane
        local proc = pane.foreground_process_name:match('([^/]+)$') or 'brush'
        local cwd = pane.current_working_dir
        local dir = '''
        if cwd then
          dir = ' ' .. (cwd.file_path:match('([^/]+)/?$') or cwd.file_path)
        end
        return proc .. dir
      end)

      return config
    '';
  };
}
