{ pkgs, ... }:

{
    programs.cava = {
      enable = true;
      package = pkgs.cava;
      settings = {
      general = {
        # 0 = Auto-fill terminal width. 
        # Change to a specific number (e.g. 100) for specific window sizes.
        bars = 0; 
        framerate = 60;
        # sensitivity = 100;
      };

      input = {
        # Use PipeWire backend
        method = "pipewire";
        source = "auto";
      };

      output = {
        method = "ncurses";
        channels = "stereo";
      };

      color = {
        gradient = 1;
        
        # Cava strictly requires single quotes for hex codes in its config file.
        # Double-quoted to preserve single quotes in the output file.
        gradient_color_1 = "'#94e2d5'"; # Teal
        gradient_color_2 = "'#89dceb'"; # Sky
        gradient_color_3 = "'#74c7ec'"; # Sapphire
        gradient_color_4 = "'#89b4fa'"; # Blue
        gradient_color_5 = "'#cba6f7'"; # Mauve
        gradient_color_6 = "'#f5c2e7'"; # Pink
        gradient_color_7 = "'#eba0ac'"; # Maroon
        gradient_color_8 = "'#f38ba8'"; # Red
      };

      smoothing = {
        noise_reduction = 77;
      };
    };
  };
}
