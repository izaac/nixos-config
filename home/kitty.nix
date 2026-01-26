{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    
    font = {
      name = "JetBrainsMono Nerd Font Mono";
      size = 11;
    };

    extraConfig = ''
      # Force Nerd Font v3 icons
      symbol_map U+E000-U+F8FF,U+F0000-U+FFFFF,U+E5FA-U+E62B Symbols Nerd Font Mono
      
      # Tab Bar Aesthetics
      tab_bar_min_tabs            1
      tab_bar_edge                bottom
      tab_bar_style               powerline
      tab_powerline_style         slanted

      # Simplified template to avoid the single-quote escape nightmare
      tab_title_template          "{title}"
      
      # Fix for NVIDIA Wayland
      linux_display_server wayland
    '';

    settings = {
      background_opacity = "0.85";
      background_opacity_unfocused = "0.7";
      window_padding_width = 10;
      enable_audio_bell = false;
      hide_window_decorations = "no";
      confirm_os_window_close = 0;

      # Catppuccin Mocha Colors
      foreground = "#cdd6f4";
      background = "#1e1e2e";
      selection_foreground = "#1e1e2e";
      selection_background = "#f5e0dc";
      cursor = "#f5e0dc";
      active_tab_foreground = "#11111b";
      active_tab_background = "#cba6f7";
      inactive_tab_foreground = "#cdd6f4";
      inactive_tab_background = "#181825";

      # 16 Colors
      color0 = "#45475a"; color8 = "#585b70";
      color1 = "#f38ba8"; color9 = "#f38ba8";
      color2 = "#a6e3a1"; color10 = "#a6e3a1";
      color3 = "#f9e2af"; color11 = "#f9e2af";
      color4 = "#89b4fa"; color12 = "#89b4fa";
      color5 = "#f5c2e7"; color13 = "#f5c2e7";
      color6 = "#94e2d5"; color14 = "#94e2d5";
      color7 = "#bac2de"; color15 = "#a6adc8";
    };

    keybindings = {
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+n" = "new_window_with_cwd";
      "ctrl+shift+left"  = "neighboring_window left";
      "ctrl+shift+right" = "neighboring_window right";
      "ctrl+shift+up"    = "neighboring_window up";
      "ctrl+shift+down"  = "neighboring_window down";
      "ctrl+shift+page_up"   = "previous_tab";
      "ctrl+shift+page_down" = "next_tab";
      "ctrl+shift+1"         = "goto_tab 1";
      "ctrl+shift+2"         = "goto_tab 2";
      "ctrl+shift+3"         = "goto_tab 3";
      "ctrl+shift+4"         = "goto_tab 4";
    };
  };
}
