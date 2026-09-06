#!/usr/bin/env bash
# Add a dialogue-boosted stereo track to video files, without touching the
# streams that are already there.
#
# The problem: dialogue sits in the centre channel, and every path to a stereo
# speaker buries it. A 5.1 track downmixed by a player attenuates the centre,
# and many of the stereo tracks in this library were themselves badly
# downmixed at encode time. Either way the dynamic range is the real culprit:
# voices sit far below effects, so you turn it up for dialogue and get blasted
# by the next explosion.
#
# Measured on 60s samples from this library:
#
#   source                        before            after
#   5.1  (8 Mile)                 -21.8 LUFS  8.0 LU   -22.0 LUFS  3.1 LU
#   stereo mp3 (Casino Royale)    -23.1 LUFS 17.9 LU   -17.5 LUFS  3.1 LU
#
# LRA is loudness range: the gap between quiet and loud passages. Dropping it
# to ~3 LU is what makes dialogue audible without riding the volume control.
#
# The new track is *added*, never substituted. Every original stream is copied
# untouched, so the only change to a file is one extra audio track, which Plex
# lists as "<language> (Boost)".
#
# SAFETY
#   - the source is only ever read, never written in place
#   - output is built in a scratch directory on local disk
#   - the result is validated (stream count, duration, decodes cleanly, the new
#     track exists) before it is allowed near the original
#   - the swap stages a sibling file and renames it, which is atomic within one
#     filesystem: an interruption leaves either the old file or the new one
#   - anything unexpected is skipped and logged rather than guessed at
#   - --dry-run shows the full plan without writing anything
#
# Resumable: files that already contain a "(Boost)" track are skipped, so the
# script can be stopped and restarted freely. That matters here, because a run
# over the whole library takes many hours and this host has a history of
# hanging; see docs/plex.md. Run it detached so an SSH drop does not kill it:
#
#   tmux new -d -s boost '/path/to/dialogue-boost.sh /srv/media/movies'
#   tmux attach -t boost          # watch
#   Ctrl-b d                      # detach again
#
# or without tmux:
#
#   systemd-run --user --unit=dialogue-boost \
#     /path/to/dialogue-boost.sh /srv/media/movies
#   journalctl --user -u dialogue-boost -f
#
# Progress is also appended to the log file printed at the end of each run.
#
# Usage:
#   dialogue-boost.sh --dry-run /srv/media/movies
#   dialogue-boost.sh --limit 3 /srv/media/movies
#   dialogue-boost.sh "/srv/media/movies/Some Film 2020 1080p.mkv"

set -uo pipefail

LABEL="Boost"
DRY_RUN=0
LIMIT=0
KEEP_TEMP=0
WORKDIR="${DIALOGUE_BOOST_WORKDIR:-${TMPDIR:-/tmp}/dialogue-boost}"

# 5.1 sources: weight the centre above the fronts, pull the surrounds back, and
# drop LFE entirely (it is rumble, and stereo speakers cannot reproduce it).
PAN_51='pan=stereo|FL=0.6*FC+0.4*FL+0.2*BL|FR=0.6*FC+0.4*FR+0.2*BR'

# Compress first, then normalise to EBU R128. The compressor does the heavy
# lifting on dynamic range; loudnorm sets a consistent final level and keeps
# true peaks below -1.5 dBTP so nothing clips.
SQUASH='acompressor=threshold=0.03:ratio=4:attack=20:release=300:makeup=3'
NORM='loudnorm=I=-16:LRA=5:TP=-1.5'

usage() {
  sed -n '2,44p' "$0" | sed 's/^# \{0,1\}//'
  exit "${1:-0}"
}

die() {
  printf 'error: %s\n' "$*" >&2
  exit 1
}

log() {
  printf '%s %s\n' "$(date +%H:%M:%S)" "$*" | tee -a "$LOGFILE"
}

args=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --limit)
      LIMIT="${2:-}"
      [[ $LIMIT =~ ^[0-9]+$ ]] || die "--limit needs a number"
      shift 2
      ;;
    --label)
      LABEL="${2:-}"
      [[ -n $LABEL ]] || die "--label needs a value"
      shift 2
      ;;
    --keep-temp)
      KEEP_TEMP=1
      shift
      ;;
    -h | --help) usage 0 ;;
    -*) die "unknown option: $1 (try --help)" ;;
    *)
      args+=("$1")
      shift
      ;;
  esac
done

[[ ${#args[@]} -gt 0 ]] || usage 1

for bin in ffmpeg ffprobe; do
  command -v "$bin" >/dev/null || die "$bin not found in PATH"
done

mkdir -p "$WORKDIR" || die "cannot create $WORKDIR"
LOGFILE="$WORKDIR/dialogue-boost.log"

# Only Matroska. mp4 stores audio differently and avi cannot hold multiple
# modern audio tracks reliably; both are left alone rather than risked.
mapfile -t FILES < <(
  for target in "${args[@]}"; do
    if [[ -f $target ]]; then
      case "${target,,}" in
        *.mkv) printf '%s\n' "$target" ;;
        *) printf 'warning: not a .mkv, skipping: %s\n' "$target" >&2 ;;
      esac
    elif [[ -d $target ]]; then
      find "$target" -type f -iname '*.mkv' -print
    else
      printf 'warning: no such file or directory: %s\n' "$target" >&2
    fi
  done | sort
)

[[ ${#FILES[@]} -gt 0 ]] || die "no .mkv files found in: ${args[*]}"

if [[ $DRY_RUN -eq 1 ]]; then
  log "scanning ${#FILES[@]} file(s) (dry run, nothing will be written)"
else
  log "scanning ${#FILES[@]} file(s)"
fi

processed=0
skipped=0
failed=0

total=${#FILES[@]}
index=0

for src in "${FILES[@]}"; do
  index=$((index + 1))

  if [[ $LIMIT -gt 0 && $processed -ge $LIMIT ]]; then
    log "reached --limit $LIMIT, stopping"
    break
  fi

  name="$(basename "$src")"
  base="[$index/$total] $name"

  [[ -r $src ]] || {
    log "SKIP  unreadable: $base"
    skipped=$((skipped + 1))
    continue
  }

  # Resumability: never add a second boosted track to the same file.
  if ffprobe -v error -select_streams a -show_entries stream_tags=title \
    -of default=nw=1:nk=1 "$src" 2>/dev/null | grep -qF "($LABEL)"; then
    log "SKIP  already boosted: $base"
    skipped=$((skipped + 1))
    continue
  fi

  # Audio-relative channel counts, one per line, in -map 0:a:N order.
  mapfile -t CHANNELS < <(
    ffprobe -v error -select_streams a -show_entries stream=channels \
      -of default=nw=1:nk=1 "$src" 2>/dev/null
  )

  if [[ ${#CHANNELS[@]} -eq 0 ]]; then
    log "SKIP  no audio streams: $base"
    skipped=$((skipped + 1))
    continue
  fi

  # Pick the sources worth boosting, and the filter each one needs. Anything
  # that is not 5.1, stereo or mono is left alone rather than guessed at.
  targets=()
  filters=()
  for i in "${!CHANNELS[@]}"; do
    case "${CHANNELS[$i]}" in
      6)
        targets+=("$i")
        filters+=("${PAN_51},${SQUASH},${NORM}")
        ;;
      1 | 2)
        targets+=("$i")
        filters+=("${SQUASH},${NORM}")
        ;;
      *) : ;;
    esac
  done

  if [[ ${#targets[@]} -eq 0 ]]; then
    log "SKIP  no 5.1/stereo/mono audio (channels: ${CHANNELS[*]}): $base"
    skipped=$((skipped + 1))
    continue
  fi

  src_streams=$(ffprobe -v error -show_entries stream=index -of default=nw=1:nk=1 "$src" 2>/dev/null | wc -l)
  src_dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$src" 2>/dev/null | cut -d. -f1)

  if [[ -z ${src_dur:-} || $src_dur -le 0 ]]; then
    log "SKIP  cannot read duration, refusing to touch: $base"
    skipped=$((skipped + 1))
    continue
  fi

  # Languages, for the track titles.
  langs=()
  for i in "${targets[@]}"; do
    l=$(ffprobe -v error -select_streams "a:$i" -show_entries stream_tags=language \
      -of default=nw=1:nk=1 "$src" 2>/dev/null | head -1)
    langs+=("${l:-und}")
  done

  if [[ $DRY_RUN -eq 1 ]]; then
    desc=""
    for n in "${!targets[@]}"; do
      desc+="a:${targets[$n]}(${CHANNELS[${targets[$n]}]}ch,${langs[$n]}) "
    done
    log "WOULD add ${#targets[@]} track(s) [${desc% }] to: $base"
    processed=$((processed + 1))
    continue
  fi

  # Space check: the working copy is roughly the size of the source. Refuse
  # rather than fill the disk out from under the system.
  src_mb=$(($(stat -c %s "$src" 2>/dev/null || echo 0) / 1024 / 1024))
  avail_mb=$(df -Pm "$WORKDIR" | awk 'NR==2 {print $4}')
  if [[ $avail_mb -lt $((src_mb + 1024)) ]]; then
    log "SKIP  need $((src_mb + 1024))MB free in $WORKDIR, have ${avail_mb}MB: $base"
    skipped=$((skipped + 1))
    continue
  fi

  tmp="$WORKDIR/$$.${name}"
  rm -f "$tmp"

  # Copy every original stream, then append one encoded stereo track per
  # target. Output audio indices continue after the existing audio streams.
  ff=(ffmpeg -hide_banner -v error -nostdin -y -i "$src" -map 0 -c copy)
  for n in "${!targets[@]}"; do
    out=$((${#CHANNELS[@]} + n))
    ff+=(-map "0:a:${targets[$n]}")
    ff+=("-c:a:$out" aac "-b:a:$out" 192k "-ac:a:$out" 2)
    ff+=("-filter:a:$out" "${filters[$n]}")
    ff+=("-metadata:s:a:$out" "title=${langs[$n]} (${LABEL})")
    ff+=("-metadata:s:a:$out" "language=${langs[$n]}")
    ff+=("-disposition:a:$out" 0)
  done
  ff+=("$tmp")

  log "WORK  +${#targets[@]} track(s): $base"

  if ! "${ff[@]}" 2>>"$LOGFILE"; then
    log "FAIL  ffmpeg error, original untouched: $base"
    [[ $KEEP_TEMP -eq 1 ]] || rm -f "$tmp"
    failed=$((failed + 1))
    continue
  fi

  # Validate before the original is at any risk. Each check below is a reason
  # to throw the new file away and move on.
  reason=""
  new_streams=$(ffprobe -v error -show_entries stream=index -of default=nw=1:nk=1 "$tmp" 2>/dev/null | wc -l)
  new_dur=$(ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$tmp" 2>/dev/null | cut -d. -f1)
  want_streams=$((src_streams + ${#targets[@]}))

  if [[ $new_streams -ne $want_streams ]]; then
    reason="stream count $new_streams, expected $want_streams"
  elif [[ -z ${new_dur:-} ]]; then
    reason="cannot read output duration"
  elif [[ $new_dur -lt $((src_dur - 2)) || $new_dur -gt $((src_dur + 2)) ]]; then
    reason="duration ${new_dur}s, source ${src_dur}s"
  elif ! ffprobe -v error -select_streams a -show_entries stream_tags=title \
    -of default=nw=1:nk=1 "$tmp" 2>/dev/null | grep -qF "($LABEL)"; then
    reason="boosted track missing from output"
  elif ! ffmpeg -v error -nostdin -i "$tmp" -t 5 -f null - 2>>"$LOGFILE"; then
    reason="output failed decode check"
  fi

  if [[ -n $reason ]]; then
    log "FAIL  $reason, original untouched: $base"
    [[ $KEEP_TEMP -eq 1 ]] || rm -f "$tmp"
    failed=$((failed + 1))
    continue
  fi

  # Stage beside the original so the rename is within one filesystem and
  # therefore atomic. A crash mid-copy leaves the staging file, not a truncated
  # original; a crash mid-rename leaves one whole file or the other.
  staged="${src}.boost-staging"
  rm -f "$staged"

  if ! cp -f "$tmp" "$staged" 2>>"$LOGFILE"; then
    log "FAIL  could not stage beside original, it is intact: $base"
    rm -f "$staged"
    [[ $KEEP_TEMP -eq 1 ]] || rm -f "$tmp"
    failed=$((failed + 1))
    continue
  fi

  if ! mv -f "$staged" "$src" 2>>"$LOGFILE"; then
    log "FAIL  could not replace original, it is intact: $base"
    rm -f "$staged"
    [[ $KEEP_TEMP -eq 1 ]] || rm -f "$tmp"
    failed=$((failed + 1))
    continue
  fi

  [[ $KEEP_TEMP -eq 1 ]] || rm -f "$tmp"
  log "OK    $base"
  processed=$((processed + 1))
done

log "done: $processed processed, $skipped skipped, $failed failed  (log: $LOGFILE)"
[[ $failed -eq 0 ]]
