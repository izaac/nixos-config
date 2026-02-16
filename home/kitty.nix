{ pkgs, ... }:

{
  catppuccin.kitty.enable = true;
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
    '';

    settings = {
      enabled_layouts = "splits,stack";
      background_opacity = "0.85";
      background_opacity_unfocused = "0.7";
      window_padding_width = 10;
      enable_audio_bell = false;
      hide_window_decorations = "no";
      confirm_os_window_close = 0;
    };

    keybindings = {
      "ctrl+shift+t" = "new_tab_with_cwd";
      "ctrl+shift+n" = "launch --location=hsplit --cwd=current";
      "ctrl+shift+\\" = "launch --location=vsplit --cwd=current";
      "ctrl+shift+f" = "toggle_layout stack";
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
