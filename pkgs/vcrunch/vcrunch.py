#!/usr/bin/env python3
"""
vcrunch: A consolidated video re-encoding tool suite.
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
            shell=True,
            check=check,
            capture_output=capture_output,
            text=True,
        )
        return result
    except subprocess.CalledProcessError as e:
        if not check:
            return e
        print(f"\n[Error] Command failed: {cmd}")
        sys.exit(1)


def get_duration(file_path):
    """Get the duration of a video file in seconds."""
    cmd = (
        f'ffprobe -v error -show_entries format=duration '
        f'-of default=noprint_wrappers=1:nokey=1 "{file_path}"'
    )
    res = run_cmd(cmd, capture_output=True)
    return float(res.stdout.strip())


def send_notification(title, message):
    """Send a desktop notification if possible."""
    if shutil.which("notify-send"):
        run_cmd(f'notify-send "{title}" "{message}" --icon=video-x-generic')


# --- ANALYZE MODE ---

def mode_analyze(args):
    """Analyze a file to find the best encoding settings."""
    file = args.file
    filename = os.path.basename(file)
    print(f"--- Original Analysis: {filename} ---")

    probe_cmd = (
        f'ffprobe -v error -select_streams v:0 '
        f'-show_entries stream=codec_name,bit_rate,width,height,'
        f'avg_frame_rate -of default=noprint_wrappers=1 "{file}"'
    )
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
            f'ffmpeg -nostdin -y -ss {start_time} -t {test_len} '
            f'-i "{file}" -c:v {codec} {quality} {extra} '
            f'-c:a copy -an "{out}"'
        )

        if run_cmd(cmd, check=False, capture_output=True).returncode != 0:
            print("FAILED")
            return

        test_size = os.path.getsize(out)
        est_size = (test_size / test_len) * duration / (1024 * 1024)
        savings = 100 - (est_size * 100 / orig_mb)
        print(f"Done. Est. Final Size: {est_size:.1f} MB "
              f"(~{savings:.1f}% smaller)")
        os.remove(out)

    run_test("x265_CRF24", "libx265", "-crf 24", "-preset medium")
    run_test("x265_CRF28", "libx265", "-crf 28", "-preset medium")
    run_test("NVENC_CQ28", "hevc_nvenc", "-rc vbr -cq 28", "-preset p4")


# --- BATCH MODE ---

def mode_batch(args):
    """Batch encode local files."""
    target_dir = Path("crunch")
    scratch_dir = Path(".vcrunch_tmp")
    target_dir.mkdir(exist_ok=True)
    scratch_dir.mkdir(exist_ok=True)

    files = sorted(glob.glob("*.mp4"))
    total = len(files)

    if total == 0:
        print("No .mp4 files found.")
        return

    print(f"--- VCRUNCH LOCAL BATCH ---\nTotal: {total} files\n" + "-" * 27)

    for i, f in enumerate(files, 1):
        if (target_dir / f).exists():
            print(f"[{i}/{total}] Skipping (exists): {f}")
            continue

        print(f"[{i}/{total}] PROCESSING: {f}")

        cmd = (
            f'ffmpeg -nostdin -v warning -stats -i "{f}" '
            f'-c:v libx265 -crf 28 -preset slow -c:a copy '
            f'-tag:v hvc1 "{scratch_dir}/{f}"'
        )

        if run_cmd(cmd, check=False).returncode == 0:
            shutil.move(scratch_dir / f, target_dir / f)
            print(f"  DONE: {f}\n")
        else:
            print(f"  FAILED: {f}")
            sys.exit(1)

    send_notification(
        "Video Crunch Complete",
        f"Finished {total} files in {os.getcwd()}"
    )


# --- SHARE MODE ---

def mode_share(args):
    """Robust network-to-local batch encoding."""
    source_dir = Path(args.source).resolve()
    basename = source_dir.name
    scratch_dir = Path.home() / ".cache" / "vcrunch"
    local_target = Path.home() / "Documents" / f"{basename}_H265"

    scratch_dir.mkdir(parents=True, exist_ok=True)
    local_target.mkdir(parents=True, exist_ok=True)

    # Detach from network share CWD
    os.chdir(scratch_dir)

    files = sorted(list(source_dir.glob("*.mp4")))
    total = len(files)

    print(
        f"--- VCRUNCH SHARE MODE ---\n"
        f"Source: {source_dir}\n"
        f"Target: {local_target}\n"
        f"Total:  {total} files\n" + "-" * 26
    )

    keep_alive_proc = None
    if str(source_dir).startswith("/mnt/"):
        keep_cmd = (
            f'while true; do ls "{source_dir}" >/dev/null 2>&1; '
            f'sleep 30; done'
        )
        keep_alive_proc = subprocess.Popen(keep_cmd, shell=True)

    def cleanup(signum, frame):
        if keep_alive_proc:
            keep_alive_proc.terminate()
        sys.exit(1)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)

    try:
        for i, f_path in enumerate(files, 1):
            fname = f_path.name
            if (local_target / fname).exists():
                print(f"[{i}/{total}] Skipping: {fname}")
                continue

            print(f"[{i}/{total}] PROCESSING: {fname}")

            # Fetch with pv
            print("  -> Copying to scratch...")
            success = False
            for attempt in range(5):
                # Wake mount
                run_cmd(
                    f'ls "{source_dir.parent}" >/dev/null 2>&1',
                    check=False
                )

                pv_cmd = f'pv "{f_path}" > "{scratch_dir}/{fname}"'
                if run_cmd(pv_cmd, check=False).returncode == 0:
                    success = True
                    break

                print(f"  [Wait] Retrying copy... ({attempt+1}/5)")
                time.sleep(2)

            if not success:
                print("  FAILED: Could not copy file.")
                break

            # Encode
            print("  -> Encoding...")
            cmd = (
                f'ffmpeg -nostdin -v warning -stats '
                f'-i "{scratch_dir}/{fname}" '
                f'-c:v libx265 -crf 26 -preset slow -pix_fmt yuv420p10le '
                f'-maxrate 1500k -bufsize 3000k -c:a copy -tag:v hvc1 '
                f'"{scratch_dir}/out_{fname}"'
            )

            if run_cmd(cmd, check=False).returncode == 0:
                shutil.move(
                    scratch_dir / f"out_{fname}",
                    local_target / fname
                )
                os.remove(scratch_dir / fname)
                print(f"  DONE: {fname}\n")
            else:
                print("  FAILED: Encoding error.")
                break
    finally:
        if keep_alive_proc:
            keep_alive_proc.terminate()

    send_notification(
        "Video Crunch Complete",
        f"Finished {total} files. Check {local_target}"
    )


# --- MAIN CLI ---

def main():
    parser = argparse.ArgumentParser(
        description="vcrunch: High-performance video re-encoding suite"
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Analyze
    p_analyze = subparsers.add_parser(
        "analyze",
        help="Find best settings for a file"
    )
    p_analyze.add_argument("file", help="Video file to analyze")

    # Batch
    subparsers.add_parser(
        "batch",
        help="Encode all .mp4 in CWD to crunch/"
    )

    # Share
    p_share = subparsers.add_parser(
        "share",
        help="Robust network-to-local encoding"
    )
    p_share.add_argument("source", help="Path to network share folder")

    args = parser.parse_args()

    if args.command == "analyze":
        mode_analyze(args)
    elif args.command == "batch":
        mode_batch(args)
    elif args.command == "share":
        mode_share(args)


if __name__ == "__main__":
    main()
