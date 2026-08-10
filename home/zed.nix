_: {
  programs.zed-editor = {
    enable = true;
    extensions = [
      "nix"
    ];
    userSettings = {
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      buffer_font_family = "JetBrainsMono Nerd Font";
    };
  };
}
