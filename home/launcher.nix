{
  config,
  lib,
  ...
}: let
  # Pull the Stylix base16 palette so the colors block matches the rest
  # of the system theme (auto-updates when Stylix changes). 90% opacity
  # on the background — alpha 0xe6 ≈ 230/255. mkForce overrides the
  # opaque defaults that stylix.targets.fuzzel writes.
  c = config.lib.stylix.colors;
  f = lib.mkForce;
in {
  # Default launcher — Mod+D in niri. Compact command palette feel.
  programs.fuzzel = {
    enable = true;
    settings = {
      main = {
        terminal = "ghostty";
        layer = "overlay";
        width = 40;
        lines = 12;
        prompt = "> ";
        icon-theme = "Papirus-Dark";
      };
      colors = {
        background = f "${c.base00}e6";
        text = f "${c.base05}ff";
        match = f "${c.base0D}ff";
        selection = f "${c.base02}ff";
        selection-text = f "${c.base05}ff";
        selection-match = f "${c.base0D}ff";
        border = f "${c.base0D}ff";
      };
      border = {
        radius = 8;
        width = 2;
      };
    };
  };
}
