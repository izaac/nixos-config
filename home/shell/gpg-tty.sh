# Keep GPG and gpg-agent tied to the active terminal.
_gpg_update_tty() {
  local current_tty

  current_tty=$(tty 2>/dev/null) || return
  if [[ $current_tty != "not a tty" ]]; then
    export GPG_TTY="$current_tty"
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  fi
}

_gpg_update_tty

if [[ -n ${ZSH_VERSION-} ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _gpg_update_tty
elif [[ -n ${BASH_VERSION-} ]]; then
  PROMPT_COMMAND="_gpg_update_tty${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi
