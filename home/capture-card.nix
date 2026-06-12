{
  pkgs,
  lib,
  osConfig ? {},
  ...
}: let
  hostname = osConfig.networking.hostName or "";
  # One command to watch an Elgato Game Capture HD60 X with live audio.
  # Auto-detects the v4l2 video node and the ALSA audio source, routes the
  # card's audio to the default sink via pw-loopback, then opens mpv with a
  # low-latency profile. The loopback is torn down when mpv exits.
  cardview = pkgs.writeShellApplication {
    name = "cardview";
    runtimeInputs = with pkgs; [pipewire wireplumber mpv v4l-utils coreutils gnugrep gawk procps];
    text = ''
      # Video card name (sysfs/v4l2) uses spaces; the ALSA node name uses
      # underscores, so the two are matched independently. Both can be
      # overridden via env if the hardware ever changes.
      vmatch="''${CARDVIEW_VIDEO_MATCH:-Game Capture}"
      amatch="''${CARDVIEW_AUDIO_MATCH:-Game_Capture}"

      die() { echo "cardview: $*" >&2; exit 1; }

      ##########################################################################
      # 1. Find a *capture-capable* video node for the card.
      #    The HD60 X exposes several /dev/video* nodes; only one (or some)
      #    actually deliver frames. Metadata/output nodes are skipped by
      #    requiring the node to advertise "Video Capture" caps AND at least
      #    one pixel format.
      ##########################################################################
      video_dev=""
      for d in /dev/video*; do
        [ -e "$d" ] || continue
        info=$(v4l2-ctl -d "$d" --info 2>/dev/null) || continue
        echo "$info" | grep -qi "$vmatch" || continue
        # Must advertise video-capture capability …
        echo "$info" | grep -qiE 'Device Caps|Video Capture' || continue
        # … and expose at least one format.
        v4l2-ctl -d "$d" --list-formats 2>/dev/null \
          | grep -qiE '\[[0-9]+\]|Pixel Format' || continue
        # Reject pure metadata nodes (no width/height capability).
        if v4l2-ctl -d "$d" --all 2>/dev/null | grep -qiE 'Width/Height[[:space:]]*:[[:space:]]*[1-9]'; then
          video_dev="$d"
          break
        fi
        # Fall back: keep first format-bearing node if none report geometry.
        [ -z "$video_dev" ] && video_dev="$d"
      done
      [ -n "$video_dev" ] || die "no capture-capable video device found (match: '$vmatch'). Plugged in? Run: v4l2-ctl --list-devices"

      ##########################################################################
      # 2. Find the card's ALSA *source* (input) node in PipeWire.
      ##########################################################################
      audio_node=$(pw-cli ls Node 2>/dev/null \
        | grep -oE "alsa_input[^\"]*''${amatch}[^\"]*" \
        | grep -iE 'analog-stereo|analog-mono|stereo|mono' \
        | head -n1)
      # Loosen the suffix requirement if the strict match found nothing.
      [ -n "$audio_node" ] || audio_node=$(pw-cli ls Node 2>/dev/null \
        | grep -oE "alsa_input[^\"]*''${amatch}[^\"]*" | head -n1)
      [ -n "$audio_node" ] || die "no capture-card audio source found (match: '$amatch'). Run: wpctl status"

      echo "cardview: video=$video_dev"
      echo "cardview: audio=$audio_node"

      ##########################################################################
      # 3. Route card audio -> default sink via pw-loopback, then PROVE the
      #    link actually attached to the card source (the historical bug was
      #    pw-loopback silently falling back to the default mic).
      ##########################################################################
      # Log lands in the user-private runtime dir, not world-writable /tmp.
      loop_log="''${XDG_RUNTIME_DIR:-/tmp}/cardview-loopback.log"
      pw-loopback -C "$audio_node" </dev/null >"$loop_log" 2>&1 &
      loop_pid=$!
      trap 'kill "$loop_pid" 2>/dev/null || true' EXIT INT TERM

      linked=0
      for _ in 1 2 3 4 5 6 7 8 9 10; do
        if ! kill -0 "$loop_pid" 2>/dev/null; then
          die "pw-loopback died. Log: $(cat "$loop_log")"
        fi
        if pw-link -l 2>/dev/null \
          | grep -A1 "input.pw-loopback-$loop_pid" \
          | grep -q "$audio_node"; then
          linked=1
          break
        fi
        sleep 0.5
      done
      [ "$linked" -eq 1 ] || die "audio failed to link to the card (wrong source captured). Log: $(cat "$loop_log")"

      # Make sure the destination (default sink) is audible.
      default_sink=$(wpctl status 2>/dev/null | awk '/Sinks:/{f=1} f&&/\*/{print; exit}')
      if echo "$default_sink" | grep -qi 'MUTED'; then
        echo "cardview: default sink is MUTED -> unmuting" >&2
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 0 2>/dev/null || true
      fi

      echo "cardview: audio linked OK -> playing video"

      ##########################################################################
      # 4. Open the video. mpv keeps the process in the foreground; on exit the
      #    trap tears down the loopback so nothing lingers.
      ##########################################################################
      mpv "av://v4l2:$video_dev" --no-audio --profile=low-latency --untimed --demuxer-lavf-o=video_size=1920x1080,input_format=nv12,framerate=60 "$@"
    '';
  };
in {
  # Capture card lives on the ninja desktop only.
  home.packages = lib.optionals (hostname == "ninja") [cardview];
}
