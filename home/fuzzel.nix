{ pkgs, ... }:

{
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "${pkgs.kitty}/bin/kitty";
        layer = "overlay";
        icon-theme = "breeze-dark";
        width = 50;
        font = "JetBrainsMono Nerd Font:size=24";
        line-height = 36; 
        fields = "filename,name,generic";
        show-actions = true;
        anchor = "center";
        lines = 10;
        horizontal-pad = 40;
        vertical-pad = 20;
        inner-pad = 10;
      };
      colors = {
        background = "1e1e2edd"; # Catppuccin Mocha Base + alpha
        text = "cdd6f4ff";       # Text
        match = "f38ba8ff";      # Red
        selection = "585b70ff";  # Surface 2
        selection-text = "cdd6f4ff";
        selection-match = "f38ba8ff";
        border = "cba6f7ff";     # Mauve
      };
      border = {
        width = 3;
        radius = 10;
      };
    };
  };
}
