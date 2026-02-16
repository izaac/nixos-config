{ pkgs, ... }:

{
    catppuccin.cava.enable = true;
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

      smoothing = {
        noise_reduction = 77;
      };
    };
  };
}
