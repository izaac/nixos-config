# Command-line front end for the ul-crypt rclone remote. Kept as its own file
# rather than a Nix string: at this length the ${...} escaping that a Nix
# string requires around every shell expansion is a live source of bugs, and a
# plain .sh gets shfmt from treefmt and shellcheck from the editor as well as
# from writeShellApplication at build time.
#
# The wrapper in rclone.nix supplies REMOTE, MOUNT, CACHE, UNIT and RC_ADDR.

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

<dest> is the parent folder on the remote, as with cp: a directory is
placed inside it under its own name, so

  ulc cp ~/Pictures/Holiday\ 2026 photos

creates photos/Holiday 2026. Naming the full path instead would nest it
twice. Existing top-level folders are shown when <dest> is unknown.
USAGE
}

# Four parallel transfers suit the usual one-file-at-a-time use.
# Raising this was measured to make no difference on this link, which
# saturates at around 3.7 MB/s regardless, but it is left tunable for
# a future connection that is not the bottleneck.
transfers="${UL_TRANSFERS:-4}"

# An uncapped transfer takes the whole uplink, and a library-sized
# upload holds it for days. UL_BWLIMIT accepts anything rclone does:
# a rate such as 2M or 2.5M (suffixes are binary, so 2.5M is 2.5
# MiB/s), or a 24-hour timetable to stay out of the way while the
# link is wanted for other things:
#   UL_BWLIMIT="08:00,2.5M 23:00,off"
# In a timetable "off" means unlimited rather than stopped; use 0 to
# pause entirely.
bwlimit=()
[ -n "${UL_BWLIMIT:-}" ] && bwlimit=(--bwlimit "$UL_BWLIMIT")

# rclone verifies the transfer before removing anything, and the data
# never enters the VFS cache. The cost is that the mount's directory
# cache does not notice, hence the refresh afterwards.
refresh() {
  local dir="${1:-}"
  mountpoint -q "$MOUNT" || return 0
  rclone rc --rc-addr "$RC_ADDR" --rc-no-auth \
    vfs/refresh dir="$dir" recursive=true >/dev/null 2>&1 \
    && echo "refreshed: ${dir:-/}" \
    || echo "note: mount is up but the refresh socket did not answer" >&2
}

# Splits "src... dest" into an array and a string, so that multiple
# sources can share one destination the way cp(1) behaves.
split_args() {
  [ $# -ge 2 ] || {
    echo "need at least one source and a destination" >&2
    exit 64
  }
  dest="${*: -1}"
  srcs=("${@:1:$#-1}")
}

transfer() {
  local verb="$1"
  shift
  local srcs dest
  split_args "$@"

  # rclone creates missing destination directories without comment, so
  # a mistyped destination silently becomes a new top-level folder.
  # With `up` the source is deleted afterwards, which makes the typo
  # expensive, so an unknown top level has to be confirmed.
  local top="${dest%%/*}"
  if ! rclone lsf --dirs-only --log-level ERROR "$REMOTE" \
    | grep -qxF "$top/"; then
    echo "'$top' does not exist on the remote. Existing folders:" >&2
    rclone lsf --dirs-only --log-level ERROR "$REMOTE" | sed 's|/$||; s/^/  /' >&2
    read -r -p "create '$top'? [y/N] " reply
    case "$reply" in
      [yY]*) ;;
      *)
        echo "aborted" >&2
        exit 1
        ;;
    esac
  fi

  for s in "${srcs[@]}"; do
    [ -e "$s" ] || {
      echo "no such file or directory: $s" >&2
      exit 66
    }
    # rclone copies the *contents* of a directory into the
    # destination, so name the target after the source to avoid
    # scattering a folder's files across the destination. Printing the
    # resolved target makes that renaming visible before anything
    # moves, since the destination is a parent folder rather than the
    # full path the file ends up at.
    local target="$REMOTE$dest"
    [ -d "$s" ] && target="$target/$(basename "$s")"
    echo "$s -> $target"
    rclone "$verb" "$s" "$target" --progress --check-first --transfers "$transfers" "${bwlimit[@]}"
  done
  refresh "$top"
}

cmd="${1:-}"
[ $# -gt 0 ] && shift

case "$cmd" in
  up) transfer move "$@" ;;
  cp) transfer copy "$@" ;;
  get)
    srcs=()
    dest=""
    split_args "$@"
    for s in "${srcs[@]}"; do
      rclone lsf --log-level ERROR "$REMOTE$s" >/dev/null 2>&1 \
        || {
          echo "not on the remote: $s" >&2
          exit 66
        }
      rclone copy "$REMOTE$s" "$dest" --progress --check-first --transfers "$transfers" "${bwlimit[@]}"
    done
    ;;
  ls) rclone lsf --format "sp" --separator "  " "$REMOTE${1:-}" ;;
  # One corrupt entry on the remote makes rclone emit a NOTICE per
  # listing pass, which is longer than the results themselves.
  find)
    [ $# -ge 1 ] || {
      echo "need a pattern" >&2
      exit 64
    }
    rclone lsf -R --files-only --log-level ERROR "$REMOTE" | grep -i -- "$1"
    ;;
  du) rclone size --log-level ERROR "$REMOTE${1:-}" ;;
  rm)
    [ $# -ge 1 ] || {
      echo "need a path" >&2
      exit 64
    }
    rclone deletefile "$REMOTE$1" && refresh "${1%%/*}"
    ;;
  mkdir)
    [ $# -ge 1 ] || {
      echo "need a path" >&2
      exit 64
    }
    rclone mkdir "$REMOTE$1" && refresh "${1%%/*}"
    ;;

  mount)
    systemctl --user start "$UNIT"
    # The unit is Type=exec, so systemd returns as soon as rclone
    # execs, which is before FUSE has finished attaching. Waiting for
    # the mount means this only returns once the path is usable.
    for _ in $(seq 1 30); do
      if mountpoint -q "$MOUNT"; then
        echo "mounted: $MOUNT"
        exit 0
      fi
      sleep 1
    done
    echo "timed out waiting for $MOUNT" >&2
    systemctl --user --no-pager status "$UNIT" | tail -15 >&2
    exit 1
    ;;
  umount | unmount)
    systemctl --user stop "$UNIT"
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
  refresh) refresh "${1:-}" ;;

  "" | -h | --help | help) usage ;;
  *)
    echo "unknown command: $cmd" >&2
    usage >&2
    exit 64
    ;;
esac
