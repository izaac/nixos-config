_: {
  catppuccin.zellij.enable = true;

  programs.zellij = {
    enable = true;
    settings = {
      # Clean UI but keep the keybinding helper bar
      pane_frames = false;

      # Mouse support
      mouse_mode = true;

      # Copy on select
      copy_on_select = true;

      # Session management
      session_serialization = true;
      auto_layout = true;

      # Disable startup tips
      show_startup_tips = false;
    };
  };
}
