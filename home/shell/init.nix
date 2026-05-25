_: {
  programs.bash.initExtra = ''
    # Ghostty injects OSC 133 via its bash integration; no manual hook needed.

    # GPG TTY FIX
    current_tty=$(tty 2>/dev/null)
    if [[ "$current_tty" != "not a tty" ]]; then
      export GPG_TTY="$current_tty"
    fi
    unset current_tty

    # Ensure local binaries are in PATH
    export PATH="$PATH:$HOME/.local/bin:$HOME/bin"

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
  '';
}
