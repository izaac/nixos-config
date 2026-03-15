#!/usr/bin/env python3
"""
vcrunch: A video re-encoding tool suite.
"""

import argparse
import glob
import os
import shutil
import signal
import subprocess
import sys
import time
from pathlib import Path


# --- GLOBAL UTILS ---


def run_cmd(cmd, check=True, capture_output=False):
    """Run a shell command."""
    try:
        result = subprocess.run(
            cmd,
            shell=False,
            check=check,
            capture_output=capture_output,
            text=True,
        )
        return result
    except subprocess.CalledProcessError as e:
        if not check:
            return e
        cmd_str = " ".join(cmd) if isinstance(cmd, list) else cmd
        print(f"\n[Error] Command failed: {cmd_str}")
        sys.exit(1)


def get_duration(file_path):
    """Get the duration of a video file in seconds."""
    cmd = [
        "ffprobe",
        "-v",
        "error",
        "-probesize",
        "100M",
        "-analyzeduration",
        "100M",
        "-show_entries",
        "format=duration",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(file_path),
    ]
    res = run_cmd(cmd, capture_output=True)
    return float(res.stdout.strip())


def format_size(size_bytes):
    """Format bytes to human readable string."""
    for unit in ["B", "KB", "MB", "GB", "TB"]:
        if size_bytes < 1024.0:
            return f"{size_bytes:.2f} {unit}"
        size_bytes /= 1024.0
    return f"{size_bytes:.2f} PB"


def get_audio_codec(file_path):
    """Probe the first audio stream to determine its codec."""
    cmd = [
        "ffprobe",
        "-v",
        "error",
        "-probesize",
        "100M",
        "-analyzeduration",
        "100M",
        "-select_streams",
        "a:0",
        "-show_entries",
        "stream=codec_name",
        "-of",
        "default=noprint_wrappers=1:nokey=1",
        str(file_path),
    ]
    res = run_cmd(cmd, capture_output=True, check=False)
    if res.returncode == 0:
        return res.stdout.strip().lower()
    return None


def send_notification(title, message):
    """Send a desktop notification if possible."""
    if shutil.which("notify-send"):
        run_cmd(["notify-send", title, message, "--icon=video-x-generic"])


def build_ffmpeg_cmd(in_file, out_file, args):
    """Build the FFmpeg command."""
    ext = Path(out_file).suffix.lower()

    # Video Logic
    vcodec = "hevc_nvenc" if getattr(args, "gpu", False) else args.vcodec
    # hevc_nvenc uses -cq (Constant Quantization) instead of -crf
    if vcodec == "hevc_nvenc":
        video_args = [
            "-c:v",
            vcodec,
            "-rc",
            "vbr",
            "-cq",
            str(args.crf),
            "-preset",
            "p6" if args.preset == "slow" else "p4",  # approximate preset map
        ]
        # For MP4 container, Apple devices prefer hvc1
        tag_args = ["-tag:v", "hvc1"] if ext == ".mp4" else []
    else:
        video_args = [
            "-c:v",
            vcodec,
            "-crf",
            str(args.crf),
            "-preset",
            args.preset,
        ]
        tag_args = (
            ["-tag:v", "hvc1"] if ext == ".mp4" and vcodec == "libx265" else []
        )

    # Audio Logic
    audio_args = []
    if args.acodec == "auto":
        acodec_actual = get_audio_codec(in_file)
        if acodec_actual in ["aac", "opus"]:
            audio_args = ["-c:a", "copy"]
        else:
            audio_args = [
                "-c:a",
                "aac",
                "-b:a",
                args.abitrate,
                "-af",
                "aresample=async=1",
            ]
    elif args.acodec == "copy":
        audio_args = ["-c:a", "copy"]
    else:
        audio_args = [
            "-c:a",
            args.acodec,
            "-b:a",
            args.abitrate,
            "-af",
            "aresample=async=1",
        ]

    cmd = (
        [
            "ffmpeg",
            "-nostdin",
            "-v",
            "warning",
            "-stats",
            "-probesize",
            "100M",
            "-analyzeduration",
            "100M",
            "-i",
            str(in_file),
            "-map",
            "0",
        ]
        + video_args
        + [
            "-c:s",
            "copy",
        ]
        + audio_args
        + tag_args
        + [str(out_file)]
    )

    return cmd


def add_encoding_args(parser):
    """Add encoding parameters to a parser."""
    parser.add_argument(
        "--gpu",
        action="store_true",
        help="Use NVIDIA NVENC for hardware accelerated encoding",
    )
    parser.add_argument(
        "--crf",
        type=int,
        default=26,
        help="Constant Rate Factor (default: 26)",
    )
    parser.add_argument(
        "--preset",
        type=str,
        default="slow",
        help="Encoder preset (default: slow)",
    )
    parser.add_argument(
        "--vcodec",
        type=str,
        default="libx265",
        help="Video codec (default: libx265)",
    )
    parser.add_argument(
        "--acodec",
        type=str,
        default="auto",
        help=(
            "Audio codec: 'auto' (copies aac/opus, otherwise aac), "
            "'copy', or specific codec like 'aac' (default: auto)"
        ),
    )
    parser.add_argument(
        "--abitrate",
        type=str,
        default="128k",
        help="Audio bitrate if transcoding (default: 128k)",
    )


# --- ANALYZE MODE ---


def mode_analyze(args):
    """Analyze a file to find encoding settings."""
    file = args.file
    filename = os.path.basename(file)
    print(f"--- Original Analysis: {filename} ---")

    probe_cmd = [
        "ffprobe",
        "-v",
        "error",
        "-probesize",
        "100M",
        "-analyzeduration",
        "100M",
        "-select_streams",
        "v:0",
        "-show_entries",
        "stream=codec_name,bit_rate,width,height,avg_frame_rate",
        "-of",
        "default=noprint_wrappers=1",
        file,
    ]
    run_cmd(probe_cmd)

    duration = get_duration(file)
    orig_size = os.path.getsize(file)
    orig_mb = orig_size / (1024 * 1024)
    print(f"Size: {orig_mb:.1f} MB | Duration: {duration/60:.1f} min")
    print("-" * 48)

    start_time = "00:05:00"
    test_len = 30

    def run_test(name, codec, quality, extra):
        out = f"test_{name}.mp4"
        print(f"Testing {name}... ", end="", flush=True)

        cmd = (
            [
                "ffmpeg",
                "-nostdin",
                "-y",
                "-ss",
                start_time,
                "-t",
                str(test_len),
                "-probesize",
                "100M",
                "-analyzeduration",
                "100M",
                "-i",
                file,
                "-c:v",
                codec,
            ]
            + quality.split()
            + extra.split()
            + ["-c:a", "copy", "-an", out]
        )

        if run_cmd(cmd, check=False, capture_output=True).returncode != 0:
            print("FAILED")
            return

        test_size = os.path.getsize(out)
        est_size = (test_size / test_len) * duration / (1024 * 1024)
        savings = 100 - (est_size * 100 / orig_mb)
        print(
            f"Done. Est. Final Size: {est_size:.1f} MB "
            f"(~{savings:.1f}% smaller)"
        )

        if os.path.exists(out):
            os.remove(out)

    run_test("x265_CRF24", "libx265", "-crf 24", "-preset medium")
    run_test("x265_CRF28", "libx265", "-crf 28", "-preset medium")
    run_test("NVENC_CQ28", "hevc_nvenc", "-rc vbr -cq 28", "-preset p4")


# --- BATCH MODE ---


def mode_batch(args):
    """Batch encode local files."""
    work_dir = Path(args.path).resolve()
    os.chdir(work_dir)

    target_dir = Path("crunch")
    scratch_dir = Path(".vcrunch_tmp")
    target_dir.mkdir(exist_ok=True)
    scratch_dir.mkdir(exist_ok=True)

    files = sorted([f for ext in ("*.mp4", "*.mkv") for f in glob.glob(ext)])
    total = len(files)

    if total == 0:
        print("No .mp4 or .mkv files found.")
        return

    print(f"--- VCRUNCH LOCAL BATCH ---\nTotal: {total} files\n" + "-" * 27)

    try:
        for i, f in enumerate(files, 1):
            out_name = Path(f).name
            if (target_dir / out_name).exists():
                print(f"[{i}/{total}] Skipping (exists): {out_name}")
                continue

            print(f"[{i}/{total}] PROCESSING: {f}")

            cmd = build_ffmpeg_cmd(f, scratch_dir / out_name, args)

            if run_cmd(cmd, check=False).returncode == 0:
                shutil.move(scratch_dir / out_name, target_dir / out_name)
                
                # --- Validation & Stats ---
                orig_dur = get_duration(f)
                orig_size = os.path.getsize(f)
                
                final_path = target_dir / out_name
                new_dur = get_duration(final_path)
                new_size = os.path.getsize(final_path)
                
                diff_dur = abs(orig_dur - new_dur)
                savings = 100 - (new_size * 100 / orig_size)
                
                status = "Verified" if diff_dur < 0.5 else f"MISMATCH ({diff_dur:.2f}s)"
                
                print(f"  DONE: {out_name}")
                print(f"  STATS: {format_size(new_size)} ({savings:.1f}% smaller) | Duration: {status}\n")
            else:
                print(f"  FAILED: {f}")
                sys.exit(1)
    except KeyboardInterrupt:
        print("\n[Interrupted] Stopping batch process...")
        sys.exit(0)

    send_notification(
        "Video Crunch Complete", f"Finished {total} files in {os.getcwd()}"
    )


# --- SHARE MODE ---


def keep_alive_loop(mount_path):
    """Background keep-alive loop replacing bash 'while true'."""
    while True:
        try:
            # Wake mount by listing the directory
            subprocess.run(
                ["ls", mount_path],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
        except Exception:
            pass
        time.sleep(30)


def mode_share(args):
    """Network-to-local batch encoding."""
    import multiprocessing

    source_dir = Path(args.source).resolve()
    basename = source_dir.name
    scratch_dir = Path.home() / ".cache" / "vcrunch"
    local_target = Path.home() / "Documents" / f"{basename}_H265"

    scratch_dir.mkdir(parents=True, exist_ok=True)
    local_target.mkdir(parents=True, exist_ok=True)

    # Detach from network share CWD
    os.chdir(scratch_dir)

    files = sorted(
        list(source_dir.glob("*.mp4")) + list(source_dir.glob("*.mkv"))
    )
    total = len(files)

    print(
        f"--- VCRUNCH SHARE MODE ---\n"
        f"Source: {source_dir}\n"
        f"Target: {local_target}\n"
        f"Total:  {total} files\n" + "-" * 26
    )

    keep_alive_proc = None
    if str(source_dir).startswith("/mnt/"):
        keep_alive_proc = multiprocessing.Process(
            target=keep_alive_loop, args=(str(source_dir),), daemon=True
        )
        keep_alive_proc.start()

    def cleanup(signum, frame):
        if keep_alive_proc and keep_alive_proc.is_alive():
            keep_alive_proc.terminate()
        sys.exit(1)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    try:
        for i, f_path in enumerate(files, 1):
            fname = f_path.name
            out_fname = f_path.name

            if (local_target / out_fname).exists():
                print(f"[{i}/{total}] Skipping: {out_fname}")
                continue

            print(f"[{i}/{total}] PROCESSING: {fname}")

            # Fetch with pv
            print("  -> Copying to scratch...")
            success = False
            for attempt in range(5):
                # Wake mount
                run_cmd(
                    ["ls", str(source_dir.parent)],
                    check=False,
                    capture_output=True,
                )

                # Instead of pv ... > ..., use Python to handle the redirect
                pv_cmd = ["pv", str(f_path)]
                try:
                    with open(scratch_dir / fname, "wb") as out_f:
                        res = subprocess.run(pv_cmd, stdout=out_f)
                        if res.returncode == 0:
                            success = True
                            break
                except Exception:
                    pass

                print(f"  [Wait] Retrying copy... ({attempt+1}/5)")
                time.sleep(2)

            if not success:
                print("  FAILED: Could not copy file.")
                break

            # Encode
            print("  -> Encoding...")
            cmd = build_ffmpeg_cmd(
                scratch_dir / fname, scratch_dir / f"out_{out_fname}", args
            )

            if run_cmd(cmd, check=False).returncode == 0:
                shutil.move(
                    scratch_dir / f"out_{out_fname}", local_target / out_fname
                )
                
                # --- Validation & Stats ---
                final_path = local_target / out_fname
                orig_dur = get_duration(scratch_dir / fname)
                orig_size = os.path.getsize(scratch_dir / fname)
                new_dur = get_duration(final_path)
                new_size = os.path.getsize(final_path)
                
                diff_dur = abs(orig_dur - new_dur)
                savings = 100 - (new_size * 100 / orig_size)
                
                if os.path.exists(scratch_dir / fname):
                    os.remove(scratch_dir / fname)
                
                status = "Verified" if diff_dur < 0.5 else f"MISMATCH ({diff_dur:.2f}s)"
                
                print(f"  DONE: {out_fname}")
                print(f"  STATS: {format_size(new_size)} ({savings:.1f}% smaller) | Duration: {status}\n")
            else:
                print("  FAILED: Encoding error.")
                break
    except KeyboardInterrupt:
        print("\n[Interrupted] Stopping share process...")
    finally:
        if keep_alive_proc and keep_alive_proc.is_alive():
            keep_alive_proc.terminate()

    send_notification(
        "Video Crunch Complete",
        f"Finished {total} files. Check {local_target}",
    )


# --- MAIN CLI ---


def main():
    parser = argparse.ArgumentParser(
        description="vcrunch: Video re-encoding suite",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Quick Examples:
  vcrunch analyze movie.mkv          # Check potential savings
  vcrunch batch                      # Crunch all videos in current folder
  vcrunch batch --gpu --crf 28       # Use NVIDIA GPU with specific quality
  vcrunch share /mnt/storage/movies  # Copy from share, crunch locally, save back
        """,
    )
    subparsers = parser.add_subparsers(dest="command", required=False)

    # Analyze
    p_analyze = subparsers.add_parser(
        "analyze", help="Find encoding settings for a file"
    )
    p_analyze.add_argument("file", help="Video file to analyze")

    # Batch
    p_batch = subparsers.add_parser(
        "batch", help="Encode all .mp4 and .mkv in a folder to crunch/"
    )
    p_batch.add_argument(
        "path",
        nargs="?",
        default=".",
        help="Folder containing videos (default: current directory)",
    )
    add_encoding_args(p_batch)

    # Share
    p_share = subparsers.add_parser("share", help="Network-to-local encoding")
    p_share.add_argument("source", help="Path to network share folder")
    add_encoding_args(p_share)

    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(0)

    args = parser.parse_args()

    if not args.command:
        parser.print_help()
        sys.exit(0)

    if args.command == "analyze":
        mode_analyze(args)
    elif args.command == "batch":
        mode_batch(args)
    elif args.command == "share":
        mode_share(args)


if __name__ == "__main__":
    main()
