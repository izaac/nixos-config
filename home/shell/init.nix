_: {
  programs.bash.initExtra = ''
    # Kitty injects OSC 133 via its shell integration; no manual hook needed.

    # GPG TTY FIX
    current_tty=$(tty 2>/dev/null)
    if [[ "$current_tty" != "not a tty" ]]; then
      export GPG_TTY="$current_tty"
    fi
    unset current_tty

    # Note: $HOME/.local/bin and $HOME/bin are added via home.sessionPath
    # in home/shell/env.nix so niri spawn and desktop entries also see them.

    # --- Distrobox Atuin Fix (Persistent Loop) ---
    if [ -d "/run/host/nix/store" ]; then
      _dbx_atuin_fix() {
        if [[ -n "$bash_preexec_imported" ]] || [[ -n "$__bp_imported" ]]; then
          trap -- '__bp_preexec_invoke_exec "$_"' DEBUG
          shopt -s extdebug 2>/dev/null
        fi
      }
      PROMPT_COMMAND=(_dbx_atuin_fix "''${PROMPT_COMMAND[@]}")
    fi

    # autocd
    shopt -s autocd 2>/dev/null

    # --- SSH → persistent tmux session ---
    # Drop every interactive SSH login straight into a long-lived `main` tmux
    # session so flaky links can reconnect into the same shell state.
    # `new-session -A` attaches if it exists, creates it otherwise.
    # Guards: only when (a) interactive, (b) over SSH with a real TTY, and
    # (c) not already inside tmux. VSCode remote injection is excluded so
    # its terminal stays raw.
    if [[ $- == *i* && -n "''${SSH_TTY-}" && -z "''${TMUX-}" && -z "''${VSCODE_INJECTION-}" ]]; then
      exec tmux new-session -A -s main
    fi
  '';
}
