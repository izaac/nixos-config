_: {
  catppuccin.zellij.enable = true;

  programs.zellij = {
    enable = true;
    settings = {
      # Simplified UI — hides tips and extra bars
      simplified_ui = true;
      pane_frames = false;

      # Mouse support
      mouse_mode = true;

      # Copy on select
      copy_on_select = true;

      # Session management
      session_serialization = true;
      auto_layout = true;

      # Default layout
      default_layout = "compact";
    };
  };
}
