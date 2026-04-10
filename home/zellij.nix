_: {
  catppuccin.zellij.enable = true;

  programs.zellij = {
    enable = true;
    settings = {
      # --- UI & BEHAVIOR ---
      pane_frames = false;
      mouse_mode = true;
      copy_on_select = true;
      session_serialization = true;
      auto_layout = true;
      show_startup_tips = false;
      default_layout = "compact";

      # --- KEYBINDINGS (TMUX-LIKE) ---
      # This mimics your old tmux config:
      # - Prefix: Ctrl-a
      # - Vim navigation (h,j,k,l)
      # - Splits: | (horizontal), v (vertical)
      # - Last window: Ctrl-a
      keybinds = {
        unbind = ["Ctrl b"]; # Unbind default Zellij prefix
        "shared_except \"locked\"" = {
          "bind \"Ctrl a\"" = {
            switch_to_mode = "Tmux";
          };
        };

        tmux = {
          # Navigation (Vim style)
          "bind \"h\"" = {
            MoveFocus = "Left";
            switch_to_mode = "Normal";
          };
          "bind \"j\"" = {
            MoveFocus = "Down";
            switch_to_mode = "Normal";
          };
          "bind \"k\"" = {
            MoveFocus = "Up";
            switch_to_mode = "Normal";
          };
          "bind \"l\"" = {
            MoveFocus = "Right";
            switch_to_mode = "Normal";
          };

          # Splits (Matching your tmux: | for horizontal, v for vertical)
          "bind \"|\"" = {
            NewPane = "Right";
            switch_to_mode = "Normal";
          };
          "bind \"v\"" = {
            NewPane = "Down";
            switch_to_mode = "Normal";
          };

          # Windows/Tabs
          "bind \"c\"" = {
            NewTab = {};
            switch_to_mode = "Normal";
          };
          "bind \"n\"" = {
            GoToNextTab = {};
            switch_to_mode = "Normal";
          };
          "bind \"p\"" = {
            GoToPreviousTab = {};
            switch_to_mode = "Normal";
          };
          "bind \"&\"" = {
            CloseTab = {};
            switch_to_mode = "Normal";
          };
          "bind \"x\"" = {
            CloseFocus = {};
            switch_to_mode = "Normal";
          };

          # Last window toggle (Tmux bind C-a last-window)
          "bind \"Ctrl a\"" = {
            ToggleTab = {};
            switch_to_mode = "Normal";
          };

          # Send prefix (Nested zellij)
          "bind \"a\"" = {
            Write = [1];
            switch_to_mode = "Normal";
          };

          # Rename
          "bind \",\"" = {switch_to_mode = "RenameTab";};
          "bind \"$\"" = {switch_to_mode = "RenamePane";};

          # Detach
          "bind \"d\"" = {Detach = {};};
        };
      };
    };
  };
}
