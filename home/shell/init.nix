_: {
  # Minimal bash initExtra for fallback shell (no ble.sh, no heavy config).
  # Primary shell is now zsh.
  programs.bash.initExtra = ''
    # GPG TTY FIX
    current_tty=$(tty 2>/dev/null)
    if [[ "$current_tty" != "not a tty" ]]; then
      export GPG_TTY="$current_tty"
    fi
    unset current_tty
  '';
}
