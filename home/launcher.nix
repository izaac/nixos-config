_: {
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "wezterm";
        layer = "overlay";
        width = 40;
        lines = 12;
        prompt = "> ";
      };
      border = {
        radius = 8;
        width = 2;
      };
    };
  };
}
