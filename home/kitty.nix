{lib, ...}: {
  programs.kitty = {
    enable = true;
    # Shell integration enabled so scroll_to_prompt (shift+up/down) works.
    shellIntegration.mode = "enabled";

    # Font and colors come from Stylix (stylix.targets.kitty); no manual palette.
    settings = {
      # Stylix forces opacity to 1.0; override to keep the translucent look.
      background_opacity = lib.mkForce "0.90";
      window_padding_width = 8;
      scrollback_lines = 10000;

      confirm_os_window_close = 0;
      copy_on_select = "clipboard";
      mouse_hide_wait = "3.0";

      # The tab indicator we came back for: terminal-drawn powerline tabs.
      tab_bar_style = "powerline";
      tab_powerline_style = "slanted";
      tab_bar_edge = "bottom";
      tab_bar_min_tabs = 1;

      # splits layout for in-terminal panes; stack for zoom toggle.
      enabled_layouts = "splits,stack";
    };

    keybindings = {
      "ctrl+shift+t" = "new_tab";
      "ctrl+shift+x" = "close_tab";
      "ctrl+shift+page_up" = "previous_tab";
      "ctrl+shift+page_down" = "next_tab";
      "ctrl+shift+1" = "goto_tab 1";
      "ctrl+shift+2" = "goto_tab 2";
      "ctrl+shift+3" = "goto_tab 3";
      "ctrl+shift+4" = "goto_tab 4";

      "ctrl+shift+n" = "launch --location=hsplit --cwd=current";
      "ctrl+shift+backslash" = "launch --location=vsplit --cwd=current";

      "ctrl+shift+left" = "neighboring_window left";
      "ctrl+shift+right" = "neighboring_window right";
      "ctrl+shift+up" = "neighboring_window up";
      "ctrl+shift+down" = "neighboring_window down";

      "ctrl+shift+f" = "toggle_layout stack";

      "shift+up" = "scroll_to_prompt -1";
      "shift+down" = "scroll_to_prompt 1";
    };
  };
}
