# GPG TTY FIX — shared by bash (init.nix) and zsh (zsh.nix).
current_tty=$(tty 2>/dev/null)
if [[ $current_tty != "not a tty" ]]; then
  export GPG_TTY="$current_tty"
fi
unset current_tty
