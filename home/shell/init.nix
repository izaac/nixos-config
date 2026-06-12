_: {
  # Minimal bash initExtra for fallback shell (no heavy config).
  # Primary shell is zsh; the GPG snippet is shared via gpg-tty.sh.
  programs.bash.initExtra = builtins.readFile ./gpg-tty.sh;
}
