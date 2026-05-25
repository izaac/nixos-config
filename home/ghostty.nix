_: {
  programs.ghostty = {
    enable = true;
    enableBashIntegration = true;
    installVimSyntax = true;

    # Colors come from Stylix (stylix.targets.ghostty); no manual palette here.
    settings = {
      font-family = "JetBrainsMono Nerd Font Mono";
      font-size = 11;

      window-padding-x = 8;
      window-padding-y = 8;
      background-opacity = 0.90;

      # enableBashIntegration above already sources the integration script;
      # disable ghostty's auto-injection to avoid double-loading (extra prompt on new tab).
      shell-integration = "none";
      shell-integration-features = "cursor,sudo,title";

      scrollback-limit = 10000;

      # Tabs hidden — tmux handles windows/panes.
      gtk-tabs-location = "hidden";

      confirm-close-surface = false;
      mouse-hide-while-typing = true;
      copy-on-select = "clipboard";

      command = "bash";

      keybind = [
        "ctrl+shift+t=new_tab"
        "ctrl+shift+page_up=previous_tab"
        "ctrl+shift+page_down=next_tab"
        "ctrl+shift+one=goto_tab:1"
        "ctrl+shift+two=goto_tab:2"
        "ctrl+shift+three=goto_tab:3"
        "ctrl+shift+four=goto_tab:4"

        "ctrl+shift+n=new_split:down"
        "ctrl+shift+backslash=new_split:right"

        "ctrl+shift+left=goto_split:left"
        "ctrl+shift+right=goto_split:right"
        "ctrl+shift+up=goto_split:up"
        "ctrl+shift+down=goto_split:down"

        "ctrl+shift+f=toggle_split_zoom"

        "shift+up=jump_to_prompt:-1"
        "shift+down=jump_to_prompt:1"
      ];
    };
  };
}
