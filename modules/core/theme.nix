{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.mySystem.core.theme;
in {
  options.mySystem.core.theme = {
    enable = lib.mkEnableOption "Stylix system-wide theming";
  };

  config = lib.mkIf cfg.enable {
    stylix = {
      enable = true;
      # Pinned to a commit, not `master`: an upstream re-encode/rename would
      # otherwise break every fresh build with a hash mismatch.
      image = pkgs.fetchurl {
        url = "https://raw.githubusercontent.com/orangci/walls-catppuccin-mocha/7bfdf10d16ad3a689f9f0cf3a0930da3d1a245a8/black-hole.png";
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
      targets = {
        grub.enable = false; # Handled by boot module
        kmscon.enable = false; # nixpkgs removed old kmscon options
        nixos-icons.enable = true;
      };
    };
  };
}
