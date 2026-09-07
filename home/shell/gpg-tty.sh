# Keep GPG and gpg-agent tied to the active terminal.
_gpg_update_tty() {
  local current_tty

  current_tty=$(tty 2>/dev/null) || return
  if [[ $current_tty != "not a tty" ]]; then
    export GPG_TTY="$current_tty"
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1
  fi

  # gpg-agent is a systemd user service and inherits the graphical session,
  # so it cannot tell whether the caller can actually see a GUI dialog. gpg
  # forwards PINENTRY_USER_DATA to the agent, which re-exports it for the
  # pinentry wrapper defined in home/dev.nix. Inside tmux (or on a bare tty)
  # ask for the curses prompt so it renders in the current pane instead of
  # opening a window on some other workspace. The "gui" value is set
  # explicitly rather than left unset so a shell started from a tmux pane
  # does not inherit "curses".
  if [[ -n ${TMUX-} || -z ${WAYLAND_DISPLAY-}${DISPLAY-} ]]; then
    export PINENTRY_USER_DATA=curses
  else
    export PINENTRY_USER_DATA=gui
  fi
}

_gpg_update_tty

if [[ -n ${ZSH_VERSION-} ]]; then
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _gpg_update_tty
elif [[ -n ${BASH_VERSION-} ]]; then
  PROMPT_COMMAND="_gpg_update_tty${PROMPT_COMMAND:+; $PROMPT_COMMAND}"
fi
