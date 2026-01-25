{ config, pkgs, ... }:

{
  programs.kitty = {
    enable = true;

    # 1. Font Configuration
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      # You can specify size here if needed, e.g., size = 12;
    };

    # 2. Keybindings
    keybindings = {
      "ctrl+shift+n" = "new_window_with_cwd";
      "ctrl+shift+t" = "new_tab_with_cwd";
      
      # Directional Navigation
      "ctrl+shift+left"  = "neighboring_window left";
      "ctrl+shift+right" = "neighboring_window right";
      "ctrl+shift+up"    = "neighboring_window up";
      "ctrl+shift+down"  = "neighboring_window down";

      # Tab Navigation
      "ctrl+shift+pageup"   = "previous_tab";
      "ctrl+shift+pagedown" = "next_tab";
      "ctrl+shift+1"        = "go_to_tab 1";
      "ctrl+shift+2"        = "go_to_tab 2";
      "ctrl+shift+3"        = "go_to_tab 3";
      "ctrl+shift+4"        = "go_to_tab 4";
    };

    # 3. General Settings & Colors (Catppuccin Mocha)
    settings = {
      # Font rendering
      bold_font        = "auto";
      italic_font      = "auto";
      bold_italic_font = "auto";

      # Symbol Mapping (Nerd Fonts v3)
      # We quote the key because it contains spaces and special characters
      "symbol_map U+E000-U+F8FF,U+F0000-U+FFFFF,U+E5FA-U+E62B" = "Symbols Nerd Font Mono";

      # Window Layout
      background_opacity = "0.85";
      window_padding_width = 10;
      hide_window_decorations = "no";
      
      # Note: 'background_opacity_unfocused' is not a standard Kitty option 
      # but I included it since it was in your config. 
      # If it errors, remove the line below.
      background_opacity_unfocused = "0.7"; 

      # Tab Bar
      tab_bar_min_tabs    = 1;
      tab_bar_edge        = "bottom";
      tab_bar_style       = "powerline";
      tab_powerline_style = "slanted";
      tab_title_template  = "{title}{' :{}:'.format(num_windows) if num_windows > 1 else ''}";

      # --- Catppuccin Mocha Colors ---
      foreground           = "#cdd6f4";
      background           = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";

      cursor            = "#f5e0dc";
      cursor_text_color = "#1e1e2e";
      url_color         = "#f5e0dc";

      active_border_color   = "#b4befe";
      inactive_border_color = "#6c7086";
      bell_border_color     = "#f9e2af";

      wayland_titlebar_color = "system";
      macos_titlebar_color   = "system";

      active_tab_foreground   = "#11111b";
      active_tab_background   = "#cba6f7";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#181825";
      tab_bar_background      = "#11111b";

      # Marks
      mark1_foreground = "#1e1e2e";
      mark1_background = "#b4befe";
      mark2_foreground = "#1e1e2e";
      mark2_background = "#cba6f7";
      mark3_foreground = "#1e1e2e";
      mark3_background = "#74c7ec";

      # The 16 Terminal Colors
      color0  = "#45475a";
      color8  = "#585b70";
      color1  = "#f38ba8";
      color9  = "#f38ba8";
      color2  = "#a6e3a1";
      color10 = "#a6e3a1";
      color3  = "#f9e2af";
      color11 = "#f9e2af";
      color4  = "#89b4fa";
      color12 = "#89b4fa";
      color5  = "#f5c2e7";
      color13 = "#f5c2e7";
      color6  = "#94e2d5";
      color14 = "#94e2d5";
      color7  = "#bac2de";
      color15 = "#a6adc8";
    };
  };
}
