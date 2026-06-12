# Kitty on macOS. programs.kitty installs pkgs.kitty (kitty.app lands in
# ~/Applications/Home Manager Apps via Home Manager's copyApps), replacing
# the old manually-installed bundle.
#
# Shared settings/keybinds come from home/kitty-common.nix. Darwin extras:
#   - shell pinned to the nix zsh: kitty's default `shell .` follows $SHELL,
#     which a stale GUI launchd session can leave at the old login shell.
#     `--login` so .zprofile is sourced in every new window.
#   - kitty detects zsh by basename and injects its shell integration, so
#     scroll_to_prompt and idle-prompt detection work without manual hooks.
#   - macos_option_as_alt: Option acts as Alt/Meta for word motion/bindings.
#   - confirm_os_window_close -1: only warn on close while a job is running;
#     macos_quit_when_last_window_closed then ends the instance.
#   - ctrl+tab tab cycling since the MacBook lacks PageUp/PageDown
#     (ctrl+shift+page_* kept in common for external keyboards).
#   - No Stylix on this host: font and opacity set manually.
{pkgs, ...}: let
  common = import ../kitty-common.nix;
in {
  programs.kitty = {
    enable = true;
    shellIntegration.mode = "enabled";

    settings =
      common.settings
      // {
        shell = "${pkgs.zsh}/bin/zsh --login";
        macos_option_as_alt = "yes";
        macos_quit_when_last_window_closed = "yes";
        confirm_os_window_close = -1;

        font_size = 14;
        background_opacity = "0.90";
      };

    keybindings =
      common.keybindings
      // {
        "cmd+w" = "close_tab";
        "ctrl+tab" = "next_tab";
        "ctrl+shift+tab" = "previous_tab";
      };
  };
}
