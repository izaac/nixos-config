{lib, ...}: let
  common = import ./kitty-common.nix;
in {
  programs.kitty = {
    enable = true;
    # Shell integration enabled so scroll_to_prompt (shift+up/down) works.
    shellIntegration.mode = "enabled";

    # Font and colors come from Stylix (stylix.targets.kitty); no manual palette.
    settings =
      common.settings
      // {
        # Stylix forces opacity to 1.0; override to keep the translucent look.
        background_opacity = lib.mkForce "0.90";
        confirm_os_window_close = 0;
      };

    inherit (common) keybindings;
  };
}
