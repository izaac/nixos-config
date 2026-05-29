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
  home.file.".config/kitty/kitty.conf".text = ''
    shell ${pkgs.bashInteractive}/bin/bash --login -i
    shell_integration no-rc
    macos_option_as_alt yes
    macos_quit_when_last_window_closed yes
    confirm_os_window_close -1
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
