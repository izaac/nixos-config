{
  lib,
  pkgs,
  ...
}: {
  home.packages = [pkgs.blesh];

  programs.bash = {
    # Load ble.sh early (--attach=none defers attach until the end so
    # bash-preexec / atuin / starship can register their hooks first).
    bashrcExtra = lib.mkBefore ''
      if [[ $- == *i* ]] && [[ -z "''${BLE_VERSION-}" ]]; then
        source ${pkgs.blesh}/share/blesh/ble.sh --attach=none --noinputrc
        # Only show command-elapsed/CPU marker for commands slower than 5s
        # (default ~1s is noisy for routine git/ls/cd output).
        [[ -n "''${BLE_VERSION-}" ]] && bleopt exec_elapsed_enabled='usr+sys>=5000'
      fi
    '';

    # Attach at the very end, after every other integration has been sourced.
    # mkOrder 2100 pushes past starship (1900) and zoxide (2000) so ble.sh
    # captures the final PS1 set by starship instead of the default bare prompt.
    initExtra = lib.mkOrder 2100 ''
      [[ -n "''${BLE_VERSION-}" ]] && ble-attach
    '';
  };
}
