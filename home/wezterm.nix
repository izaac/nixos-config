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

      -- Window
      config.window_background_opacity = 0.90
      config.window_padding = {
        left = 8,
        right = 8,
        top = 8,
        bottom = 8,
      }
      config.window_close_confirmation = 'NeverPrompt'
      config.audible_bell = 'Disabled'

      -- Scrollback
      config.scrollback_lines = 10000

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

      -- Tab Bar (matching Kitty's bottom powerline style)
      config.enable_tab_bar = true
      config.tab_bar_at_bottom = true
      config.use_fancy_tab_bar = false
      config.show_tab_index_in_tab_bar = false

      -- Keybindings (cloned from Kitty)
      config.keys = {
        -- Quick Select for Nix store paths
        {
          key = 's',
          mods = 'CTRL|SHIFT',
          action = act.QuickSelectArgs {
            label = 'select nix store path',
            patterns = { '/nix/store/[^\\s/]+' },
            action = wezterm.action_callback(function(window, pane, selection)
              wezterm.log_info('Selected: ' .. selection)
              window:copy_to_clipboard(selection)
            end),
          },
        },
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

        -- Jump to previous command (needs shell integration)
        { key = 'UpArrow', mods = 'SHIFT', action = act.ScrollToPrompt(-1) },
        { key = 'DownArrow', mods = 'SHIFT', action = act.ScrollToPrompt(1) },

        -- Project Switcher (fuzzy find in repos)
        {
          key = 'P',
          mods = 'CTRL|SHIFT',
          action = act.InputSelector {
            title = 'Project Switcher',
            choices = {
              { label = 'NixOS Config', id = os.getenv('HOME') .. '/nixos-config' },
              { label = 'Nix Packages', id = os.getenv('HOME') .. '/repos/nix-packages' },
              { label = 'Traefik Migration', id = os.getenv('HOME') .. '/repos/traefik-migration' },
            },
            fuzzy = true,
            action = wezterm.action_callback(function(window, pane, id, label)
              if id then
                window:perform_action(act.SpawnTab { cwd = id }, pane)
              end
            end),
          },
        },
      }

      -- Tab title: show process name + cwd basename with icons
      wezterm.on('format-tab-title', function(tab, _tabs, _panes, _config, _hover, _max_width)
        local pane = tab.active_pane
        local title = pane.foreground_process_name:match('([^/]+)$') or 'brush'
        local cwd = pane.current_working_dir
        local dir = ""

        if cwd then
          if cwd.file_path == os.getenv("HOME") then
            dir = " ~"
          else
            dir = " " .. (cwd.file_path:match('([^/]+)/?$') or cwd.file_path)
          end
        end

        local icons = {
          ['hx'] = '󰚀',
          ['helix'] = '󰚀',
          ['nix'] = '󱄅',
          ['git'] = '󰊢',
          ['yazi'] = '󰇥',
          ['brush'] = '󱆃',
          ['btop'] = '󰄦',
          ['sudo'] = '󰌆',
          ['ssh'] = '󰒍',
          ['man'] = '󰈙',
          ['cat'] = '󰈙',
          ['bat'] = '󰈙',
        }

        local icon = icons[title] or '󰆍'
        local tab_title = string.format(" %s %s%s ", icon, title, dir)

        -- Tab colors: active vs inactive, special for SSH/Sudo
        local bg, fg
        if title == 'ssh' then
          bg = '#f5e0dc' -- Rosewater
          fg = '#1e1e2e'
        elseif title == 'sudo' then
          bg = '#f38ba8' -- Red
          fg = '#1e1e2e'
        elseif tab.is_active then
          bg = '#89b4fa' -- Catppuccin Blue
          fg = '#1e1e2e'
        else
          bg = '#1e1e2e' -- Mantle
          fg = '#6c7086' -- Overlay0 (dimmed)
        end

        return {
          { Background = { Color = bg } },
          { Foreground = { Color = fg } },
          { Text = tab_title },
        }
      end)

      -- Nix Store Hyperlinks: Open in Yazi on Ctrl+Click
      config.hyperlink_rules = wezterm.default_hyperlink_rules()
      table.insert(config.hyperlink_rules, {
        regex = [[(/nix/store/[^/\s]+)]],
        format = 'nix-store:$1',
      })

      wezterm.on('open-uri', function(window, pane, uri)
        local store_path = uri:match('^nix%-store:(.+)$')
        if store_path then
          window:perform_action(
            act.SpawnCommandInNewTab {
              args = { 'yazi', store_path },
            },
            pane
          )
          return false
        end
      end)

      return config
    '';
  };
}
