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
        framerate = 40;
        # sensitivity = 100;
      };

      input = {
        # Use PipeWire backend
        method = "pipewire";
        source = "auto";
        sample_rate = 44100;
      };

      output = {
        method = "ncurses";
        channels = "stereo";
      };

      smoothing = {
        noise_reduction = 30;
      };
    };
  };
}
