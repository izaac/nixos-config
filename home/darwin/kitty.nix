{
  lib,
  pkgs,
  ...
}: {
  # macOS ships bash 3.2, but ~/.bashrc uses bash 5 features (Ble.sh, globstar,
  # `[[ -v ]]`). kitty's default `shell .` follows $SHELL, which the macOS GUI
  # launchd session can leave stale at /bin/bash after a login-shell change,
  # making a fresh window fall back to 3.2 and choke on the rc file. Pin kitty
  # to the nix bash. On macOS kitty needs explicit flags so the shell reads its
  # rc files: `--login` sources .bash_profile -> .bashrc, `-i` forces
  # interactive (bash rejects the long `--interactive`, hence the short flag).
  #
  # A custom shell disables kitty's automatic shell integration. `no-rc` keeps
  # the KITTY_* env vars but skips kitty's own rc injection so we load the
  # integration manually (see the bashrc hook below). With integration working,
  # kitty can tell an idle prompt from a running command, so the default
  # `confirm_os_window_close -1` only warns on close when a job is running, and
  # `macos_quit_when_last_window_closed` fully ends the instance otherwise.
  # kitty defaults Option to composed characters; treat it as Alt/Meta so
  # Option+Arrow word motion and other Meta bindings reach the shell.
  # Keybinds mirror ninja (home/kitty.nix). ctrl+tab cycles tabs since the
  # MacBook lacks physical PageUp/PageDown (kept for external keyboards).
  home.file.".config/kitty/kitty.conf".text = ''
    shell ${pkgs.bashInteractive}/bin/bash --login -i
    shell_integration no-rc
    macos_option_as_alt yes
    macos_quit_when_last_window_closed yes
    confirm_os_window_close -1

    enabled_layouts splits,stack

    map ctrl+shift+t new_tab
    map ctrl+shift+1 goto_tab 1
    map ctrl+shift+2 goto_tab 2
    map ctrl+shift+3 goto_tab 3
    map ctrl+shift+4 goto_tab 4

    map ctrl+tab next_tab
    map ctrl+shift+tab previous_tab
    map ctrl+shift+page_up previous_tab
    map ctrl+shift+page_down next_tab

    map ctrl+shift+n launch --location=hsplit --cwd=current
    map ctrl+shift+backslash launch --location=vsplit --cwd=current

    map ctrl+shift+left neighboring_window left
    map ctrl+shift+right neighboring_window right
    map ctrl+shift+up neighboring_window up
    map ctrl+shift+down neighboring_window down

    map ctrl+shift+f toggle_layout stack

    map shift+up scroll_to_prompt -1
    map shift+down scroll_to_prompt 1
  '';

  # Source kitty's bash integration after starship (1900) / zoxide (2000) but
  # before ble-attach (2100, see blesh.nix) so ble.sh picks up kitty's
  # PROMPT_COMMAND hook when it attaches. Guarded to kitty windows only.
  programs.bash.initExtra = lib.mkOrder 2050 ''
    if [[ $- == *i* && -n "''${KITTY_INSTALLATION_DIR-}" ]]; then
      builtin source "$KITTY_INSTALLATION_DIR/shell-integration/bash/kitty.bash"
    fi
  '';
}
