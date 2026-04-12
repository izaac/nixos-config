{
  pkgs,
  lib,
  config,
  ...
}:
with lib; let
  cfg = config.mySystem.core.theme;
in {
  options.mySystem.core.theme = {
    enable = mkEnableOption "Stylix system-wide theming";
  };

  config = mkIf cfg.enable {
    stylix = {
      enable = true;
      image = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/master/black-hole.png";
        sha256 = "0nq4qxx3i4s84v4srxvggzlvp15sc2wgf4vc4awaijwdzqy79nfr";
      };
      base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
      polarity = "dark";

      cursor = {
        package = pkgs.bibata-cursors;
        name = "Bibata-Modern-Ice";
        size = 24;
      };

      fonts = {
        monospace = {
          package = pkgs.nerd-fonts.jetbrains-mono;
          name = "JetBrainsMono Nerd Font";
        };
        sansSerif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Sans";
        };
        serif = {
          package = pkgs.dejavu_fonts;
          name = "DejaVu Serif";
        };
        sizes = {
          applications = 12;
          terminal = 13;
          desktop = 11;
          popups = 12;
        };
      };

      # Global overrides
      targets.grub.enable = false; # Handled by boot module
      targets.nixos-icons.enable = true;
    };
  };
}
