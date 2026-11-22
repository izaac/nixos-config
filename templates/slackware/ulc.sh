#!/bin/sh
# Command-line front end for the ul-crypt rclone remote on hosts without
# systemd (Slackware). Derived from home/ulc.sh, which drives the same remote
# through a systemd user unit on NixOS.
#
# Differences from the NixOS version, all forced by the platform:
#   - no systemd: the mount is a background rclone process tracked by a pidfile
#   - rclone comes from Slackware's community repo, so no Nix wrapper supplies
#     the environment; every value has a default and can be overridden
#   - the mount point lives under $HOME, because /mnt requires root here
#
# Install:
#   install -m 755 ulc.sh ~/.local/bin/ulc
#   ul-mount and ul-umount are two-line wrapper scripts that exec
#   "ulc mount" and "ulc umount"; do not symlink them to ulc, the script
#   dispatches on its first argument, not on $0.
#
# The rclone config with the ulozto account and the crypt keys is not managed
# by this script. Provision it from a host that holds a sops key:
#   sops -d --extract '["ul_conf"]' secrets/rclone.yaml |
#     ssh snail 'umask 077; install -m 600 /dev/null ~/.config/rclone/rclone.conf
#                   cat > ~/.config/rclone/rclone.conf'

set -eu

REMOTE="${UL_REMOTE:-ul-crypt:}"
MOUNT="${UL_MOUNT:-$HOME/mnt/ul}"
CACHE="${UL_CACHE:-$HOME/.cache/rclone}"
RUNDIR="${UL_RUNDIR:-$HOME/.cache/ul}"
RC_ADDR="${UL_RC_ADDR:-127.0.0.1:5573}"
PIDFILE="$RUNDIR/mount.pid"
LOGFILE="$RUNDIR/mount.log"
TRANSFERS="${UL_TRANSFERS:-4}"
# Persistent config (what rclone reads by default) and the encrypted copy that
# the card can open. If the persistent file is absent, the encrypted copy is
# decrypted into /dev/shm and shredded once rclone has read it.
CONFFILE="${UL_CONFIG:-$HOME/.config/rclone/rclone.conf}"
ENCCONF="${UL_ENC_CONF:-$HOME/.config/ul/rclone.yaml}"
SHAREDCONF="${UL_SHARED_CONF:-/dev/shm/ul-rclone.conf}"
TMPCONF=""
CONFIG_PATH=""

# Same VFS flags as ninja so behaviour matches between hosts. The cache is
# capped because this mount is used from a laptop-sized disk.
MOUNT_FLAGS="--vfs-cache-mode full
--vfs-cache-max-size 10G
--vfs-cache-max-age 24h
--dir-cache-time 72h
--attr-timeout 72h
--vfs-read-chunk-size 2M
--vfs-read-ahead 128M
--vfs-read-chunk-size-limit 1G
--buffer-size 32M
--no-modtime
--cache-dir $CACHE
--rc --rc-addr $RC_ADDR --rc-no-auth"

usage() {
  cat <<'USAGE'
ulc - work with the ul-crypt remote

  ulc up   <src>... <dest>   upload, verify, then delete the source
  ulc cp   <src>... <dest>   upload and keep the source
  ulc get  <src>... <dest>   download from the remote
  ulc ls   [path]            list a directory
  ulc find <pattern>         search the whole remote by name
  ulc du   [path]            size of a directory
  ulc rm   <path>            delete a file
  ulc mkdir <path>           create a directory

  ulc mount | ulc umount | ulc status
  ulc refresh [dir]          re-read a directory into the mount
  ulc key                    check that the rclone config is present

ul-mount and ul-umount are two-line wrappers for mount and umount.
USAGE
}

need_rclone() {
  command -v rclone >/dev/null 2>&1 || {
    echo "rclone not found, install it first: sudo slackpkg install rclone" >&2
    exit 69
  }
  [ -n "${RCLONE_CONFIG:-}" ] && return 0
  # resolve_config sets CONFIG_PATH directly. Doing this in a command
  # substitution would run the EXIT trap in the subshell and shred the
  # ephemeral config before rclone ever reads it.
  resolve_config "${1:-temp}" || exit $?
  RCLONE_CONFIG="$CONFIG_PATH"
  export RCLONE_CONFIG
}

# rclone reads its config once, at startup. Three sources, in order:
#   1. the persistent file, when it exists (convenient, but on an unencrypted
#      disk it is a liability)
#   2. the shared tmpfs copy created by `ulc mount`, so follow-up commands and
#      the mount itself cost one card touch instead of one per command
#   3. a throwaway tmpfs copy for one-shot commands with no mount running
# Only ever decrypted into /dev/shm, which is RAM. There is no disk swap here.
resolve_config() {
  want_shared="${1:-temp}"

  if [ -f "$CONFFILE" ]; then
    CONFIG_PATH="$CONFFILE"
    return 0
  fi
  if [ -f "$SHAREDCONF" ]; then
    CONFIG_PATH="$SHAREDCONF"
    return 0
  fi
  [ -f "$ENCCONF" ] || {
    echo "no rclone config: neither $CONFFILE nor $ENCCONF exists" >&2
    echo "see 'ulc key' for the provisioning command" >&2
    return 78
  }
  command -v sops >/dev/null 2>&1 || {
    echo "sops not installed; cannot open $ENCCONF" >&2
    return 69
  }

  if [ "$want_shared" = shared ]; then
    # Written beside the target and renamed, so a failed decrypt never leaves
    # a half-written config that later commands would happily reuse.
    target="$SHAREDCONF.$$"
    umask 077
    if ! sops -d --extract '["ul_conf"]' "$ENCCONF" >"$target"; then
      rm -f "$target"
      echo "could not decrypt $ENCCONF (card inserted? PIN and touch?)" >&2
      return 78
    fi
    chmod 600 "$target"
    mv "$target" "$SHAREDCONF"
    CONFIG_PATH="$SHAREDCONF"
    return 0
  fi

  TMPCONF="$(mktemp /dev/shm/ul-conf.XXXXXX)"
  chmod 600 "$TMPCONF"
  trap cleanup_tmpconf EXIT
  trap 'cleanup_tmpconf; exit 129' HUP
  trap 'cleanup_tmpconf; exit 130' INT
  trap 'cleanup_tmpconf; exit 143' TERM

  if ! sops -d --extract '["ul_conf"]' "$ENCCONF" >"$TMPCONF"; then
    echo "could not decrypt $ENCCONF (card inserted? PIN and touch?)" >&2
    return 78
  fi
  CONFIG_PATH="$TMPCONF"
}

cleanup_tmpconf() {
  [ -n "$TMPCONF" ] || return 0
  if command -v shred >/dev/null 2>&1; then
    shred -u "$TMPCONF" 2>/dev/null || rm -f "$TMPCONF"
  else
    rm -f "$TMPCONF"
  fi
  TMPCONF=""
}

# rclone verifies the transfer before removing anything, and the data never
# enters the VFS cache. The mount's directory cache therefore does not notice,
# hence the refresh afterwards.
refresh() {
  dir="${1:-}"
  mountpoint -q "$MOUNT" || return 0
  rclone rc --rc-addr "$RC_ADDR" --rc-no-auth \
    vfs/refresh dir="$dir" recursive=true >/dev/null 2>&1 \
    && echo "refreshed: ${dir:-/}" \
    || echo "note: mount is up but the refresh socket did not answer" >&2
}

split_args() {
  [ $# -ge 2 ] || {
    echo "need at least one source and a destination" >&2
    exit 64
  }
  dest=""
  for a in "$@"; do dest="$a"; done
}

transfer() {
  verb="$1"
  shift
  split_args "$@"

  top="${dest%%/*}"
  if ! rclone lsf --dirs-only --log-level ERROR "$REMOTE" \
    | grep -qxF "$top/"; then
    echo "'$top' does not exist on the remote. Existing folders:" >&2
    rclone lsf --dirs-only --log-level ERROR "$REMOTE" | sed 's|/$||; s/^/  /' >&2
    printf "create '%s'? [y/N] " "$top" >&2
    read -r reply
    case "$reply" in
      [yY]*) ;;
      *)
        echo "aborted" >&2
        exit 1
        ;;
    esac
  fi

  remaining=$#
  while [ "$remaining" -gt 1 ]; do
    s="$1"
    shift
    remaining=$((remaining - 1))
    [ -e "$s" ] || {
      echo "no such file or directory: $s" >&2
      exit 66
    }
    target="$REMOTE$dest"
    if [ -d "$s" ] && [ -z "${ULC_NO_APPEND_BASENAME:-}" ]; then
      target="$target/$(basename "$s")"
    fi
    echo "$s -> $target"
    rclone "$verb" "$s" "$target" --progress --check-first --transfers "$TRANSFERS" ${UL_BWLIMIT:+--bwlimit "$UL_BWLIMIT"}
  done
  refresh "$top"
}

cmd="${1:-}"
[ $# -gt 0 ] && shift

case "$cmd" in
  up)
    need_rclone
    transfer move "$@"
    ;;
  cp)
    need_rclone
    transfer copy "$@"
    ;;
  get)
    need_rclone
    split_args "$@"
    remaining=$#
    while [ "$remaining" -gt 1 ]; do
      s="$1"
      shift
      remaining=$((remaining - 1))
      rclone lsf --log-level ERROR "$REMOTE$s" >/dev/null 2>&1 \
        || {
          echo "not on the remote: $s" >&2
          exit 66
        }
      rclone copy "$REMOTE$s" "$dest" --progress --check-first \
        --transfers "$TRANSFERS" ${UL_BWLIMIT:+--bwlimit "$UL_BWLIMIT"}
    done
    ;;
  ls)
    need_rclone
    rclone lsf --format "sp" --separator "  " "$REMOTE${1:-}"
    ;;
  find)
    need_rclone
    [ $# -ge 1 ] || {
      echo "need a pattern" >&2
      exit 64
    }
    rclone lsf -R --files-only --log-level ERROR "$REMOTE" | grep -i -- "$1"
    ;;
  du)
    need_rclone
    rclone size --log-level ERROR "$REMOTE${1:-}"
    ;;
  rm)
    need_rclone
    [ $# -ge 1 ] || {
      echo "need a path" >&2
      exit 64
    }
    rclone deletefile "$REMOTE$1" && refresh "${1%%/*}"
    ;;
  mkdir)
    need_rclone
    [ $# -ge 1 ] || {
      echo "need a path" >&2
      exit 64
    }
    rclone mkdir "$REMOTE$1" && refresh "${1%%/*}"
    ;;

  mount)
    if mountpoint -q "$MOUNT"; then
      echo "already mounted: $MOUNT"
      exit 0
    fi
    need_rclone shared
    mkdir -p "$RUNDIR" "$MOUNT" "$CACHE"

    # shellcheck disable=SC2086
    nohup rclone mount "$REMOTE" "$MOUNT" $MOUNT_FLAGS \
      >"$LOGFILE" 2>&1 &
    echo $! >"$PIDFILE"

    i=0
    while [ "$i" -lt 30 ]; do
      if mountpoint -q "$MOUNT"; then
        echo "mounted: $MOUNT"
        exit 0
      fi
      sleep 1
      i=$((i + 1))
    done
    echo "timed out waiting for $MOUNT; last log lines:" >&2
    tail -15 "$LOGFILE" >&2 || true
    exit 1
    ;;

  umount | unmount)
    if mountpoint -q "$MOUNT"; then
      fusermount3 -uz "$MOUNT" 2>/dev/null || fusermount -uz "$MOUNT" 2>/dev/null || true
    fi
    if [ -f "$PIDFILE" ]; then
      pid="$(cat "$PIDFILE")"
      # Only kill it if it is still our rclone mount. A stale pidfile plus PID
      # reuse would otherwise take out an unrelated process.
      if [ -r "/proc/$pid/cmdline" ] \
        && tr '\0' ' ' <"/proc/$pid/cmdline" | grep -q "rclone mount .*$MOUNT"; then
        kill "$pid" 2>/dev/null || true
      fi
      rm -f "$PIDFILE"
    fi
    # The shared tmpfs config exists so follow-up commands do not re-prompt for
    # the card. Unmount is the point where that convenience goes away.
    if [ -f "$SHAREDCONF" ]; then
      if command -v shred >/dev/null 2>&1; then
        shred -u "$SHAREDCONF" 2>/dev/null || rm -f "$SHAREDCONF"
      else
        rm -f "$SHAREDCONF"
      fi
      echo "shredded cached config: $SHAREDCONF"
    fi
    echo "unmounted: $MOUNT"
    ;;

  status)
    if mountpoint -q "$MOUNT"; then
      echo "mounted at $MOUNT"
      du -sh "$CACHE" 2>/dev/null | sed 's/^/cache: /'
    else
      echo "not mounted"
    fi
    ;;

  key)
    if [ -f "$CONFFILE" ]; then
      echo "persistent config: $CONFFILE"
      rclone config show 2>/dev/null | grep -E '^\[' | sed 's/^/  /'
      echo "note: on an unencrypted disk this file holds the crypt keys in the clear"
    elif [ -f "$SHAREDCONF" ]; then
      echo "ephemeral cache: $SHAREDCONF (mode 600, in RAM, shredded by ul-umount)"
      rclone config show 2>/dev/null | grep -E '^\[' | sed 's/^/  /'
    elif [ -f "$ENCCONF" ]; then
      echo "ephemeral mode: $ENCCONF"
      echo "  mount decrypts it with sops (card PIN and touch), then shreds the copy"
      command -v sops >/dev/null 2>&1 || echo "  warning: sops is not installed"
    else
      echo "no config yet"
      echo "provision it from a host holding a sops key:"
      echo "  sops -d secrets/rclone.yaml | ssh $(hostname) 'umask 077; cat > ~/.config/ul/rclone.yaml'"
      echo "  or, for a persistent plaintext config:"
      echo "  sops -d --extract '[\"ul_conf\"]' secrets/rclone.yaml | ssh $(hostname) 'umask 077; cat > ~/.config/rclone/rclone.conf'"
      exit 78
    fi
    ;;

  refresh) refresh "${1:-}" ;;

  "" | -h | --help | help) usage ;;
  *)
    echo "unknown command: $cmd" >&2
    usage >&2
    exit 64
    ;;
esac
