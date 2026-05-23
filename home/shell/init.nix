_: {
  programs.bash.initExtra = ''
    # --- WEZTERM INTEGRATION (OSC 133) ---
    if [[ "$TERM_PROGRAM" == "WezTerm" ]]; then
      _wezterm_osc133_prompt_start() { printf "\033]133;A\007"; }
      _wezterm_osc133_command_start() { printf "\033]133;C\007"; }
      _wezterm_osc133_command_end() { printf "\033]133;D;%s\007" "$?"; }

      # Pre-encode user vars once at init
      _wezterm_user_b64=$(echo -n "$(id -un)" | base64 2>/dev/null)
      _wezterm_host_b64=$(cat /proc/sys/kernel/hostname 2>/dev/null | base64 2>/dev/null)
      _wezterm_user_vars_precmd() {
        printf "\033]1337;SetUserVar=%s=%s\007" "WEZTERM_USER" "$_wezterm_user_b64"
        printf "\033]1337;SetUserVar=%s=%s\007" "WEZTERM_HOST" "$_wezterm_host_b64"
      }

      # Inject into PS1/PROMPT_COMMAND
      case "$PS1" in
        *"\033]133;A\007"*) ;;
        *) PS1="\[$(_wezterm_osc133_prompt_start)\]$PS1" ;;
      esac
    fi

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
