#!/bin/sh
[ -x /usr/bin/batcat ] && [ ! -e /usr/local/bin/bat ] && sudo ln -sf /usr/bin/batcat /usr/local/bin/bat
[ -x /usr/bin/fdfind ] && [ ! -e /usr/local/bin/fd ] && sudo ln -sf /usr/bin/fdfind /usr/local/bin/fd

# Always link starship and atuin from host nix store to match host shell config
# (an older distro package in /usr/bin must never shadow the host version)
for s in /nix/store/*-starship-*/bin/starship; do
  if [ -x "$s" ]; then
    sudo ln -sf "$s" /usr/local/bin/starship
    break
  fi
done

for a in /nix/store/*-atuin-*/bin/atuin; do
  if [ -x "$a" ]; then
    sudo ln -sf "$a" /usr/local/bin/atuin
    break
  fi
done

for z in /nix/store/*-zoxide-*/bin/zoxide; do
  if [ -x "$z" ]; then
    sudo ln -sf "$z" /usr/local/bin/zoxide
    break
  fi
done

# Bash drop-in so atuin's Ctrl-R binding is active in bash logins too.
# zsh picks it up from the host zshrc; bash needs this profile.d hook.
# The interactive guard must come first: /etc/profile.d is sourced by
# non-interactive shells as well (distrobox enter ... -- cmd, ssh, scp),
# where `atuin init bash` emits "line editing not enabled" warnings.
if ! grep -qF 'case $- in *i*)' /etc/profile.d/atuin.sh 2>/dev/null; then
  # shellcheck disable=SC2016 # single quotes are intentional: written literally to profile.d
  printf '%s\n' \
    'case $- in *i*) ;; *) return 0;; esac' \
    'if command -v atuin >/dev/null 2>&1; then eval "$(atuin init bash)"; fi' \
    | sudo tee /etc/profile.d/atuin.sh >/dev/null
fi
exit 0
