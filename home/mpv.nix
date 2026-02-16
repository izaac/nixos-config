{ ... }:

{
  catppuccin.mpv.enable = true;
  programs.mpv = {
    enable = true;
    config = {
      autofit = "0";
      autofit-larger = "50%x50%";
      autofit-smaller = "50%x50%";
    };
  };
}
