# Zed settings, shared by every host that uses it.
#
# On Darwin the editor itself comes from the homebrew cask rather than nixpkgs.
# Zed ships weekly and nixpkgs cannot keep pace: stable carries 1.3.6 and
# unstable 1.17.2 against the cask's 1.18.1. A cask also lands in /Applications,
# so Spotlight, the Dock, `open -a` and file associations behave normally,
# unlike a nix bundle copied into ~/Applications/Home Manager Apps.
#
# `package = null` therefore installs no editor on Darwin and this module only
# writes ~/.config/zed/settings.json, which is where the cask build reads from.
{pkgs, ...}: {
  programs.zed-editor = {
    enable = true;
    package =
      if pkgs.stdenv.isDarwin
      then null
      else pkgs.zed-editor;
    extensions = [
      "nix"
    ];
    userSettings = {
      telemetry = {
        diagnostics = false;
        metrics = false;
      };
      buffer_font_family = "JetBrainsMono Nerd Font";
    };
  };
}
