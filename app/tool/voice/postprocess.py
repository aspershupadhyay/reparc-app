#!/usr/bin/env python3
"""Cleans up voice cue files so every cue starts at once and plays at the
same loudness (handbook 4.13).

For each file: cut the silence at the start and end, set the mean level to
TARGET_MEAN_DB, keep peaks under -1 dBFS, and save as mono MP3. Needs ffmpeg.

Usage, from app/: python3 tool/voice/postprocess.py assets/voice/charlie/go.mp3 ...
Add --tail to only cut a sound after a long silence at the end.
generate.py runs this on each new file.
"""
import pathlib
import re
import subprocess
import sys
import tempfile

TARGET_MEAN_DB = -18.0
BITRATE = "96k"

# Cuts quiet audio under -45 dB at both ends; keeps 40 ms so words are not clipped.
TRIM = (
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.04,"
    "areverse,"
    "silenceremove=start_periods=1:start_threshold=-45dB:start_silence=0.06,"
    "areverse"
)


def mean_db(path: pathlib.Path, pre: str) -> float:
    out = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af", f"{pre},volumedetect", "-f", "null", "-"],
        capture_output=True,
        text=True,
        check=True,
    ).stderr
    m = re.search(r"mean_volume: (-?[0-9.]+) dB", out)
    if not m:
        raise RuntimeError(f"No level for {path}")
    return float(m.group(1))


def duration(path: pathlib.Path) -> float:
    out = subprocess.run(
        ["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0", str(path)],
        capture_output=True, text=True, check=True,
    ).stdout
    return float(out)


def cut_tail(path: pathlib.Path) -> None:
    """Cuts a breath or click that follows a long silence at the end.

    Such a sound defeats the silence trim, so the clip keeps up to a second
    of silence and the next cue plays late.
    """
    end = duration(path)
    out = subprocess.run(
        ["ffmpeg", "-hide_banner", "-nostats", "-i", str(path), "-af", "silencedetect=n=-38dB:d=0.25", "-f", "null", "-"],
        capture_output=True, text=True, check=True,
    ).stderr
    starts = [float(x) for x in re.findall(r"silence_start: ([0-9.]+)", out)]
    ends = [float(x) for x in re.findall(r"silence_end: ([0-9.]+)", out)]
    if not starts:
        return
    last_start = starts[-1]
    last_end = ends[len(starts) - 1] if len(ends) >= len(starts) else end
    if end - last_end > 0.2 or last_start < 0.15:
        return
    cut = last_start + 0.05
    with tempfile.TemporaryDirectory() as tmp:
        out_path = pathlib.Path(tmp) / path.name
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(path), "-af",
             f"atrim=0:{cut:.3f},afade=t=out:st={max(cut - 0.03, 0):.3f}:d=0.03",
             "-ac", "1", "-ar", "44100", "-b:a", BITRATE, "-map_metadata", "-1", str(out_path)],
            check=True,
        )
        path.write_bytes(out_path.read_bytes())


def process(path: pathlib.Path) -> None:
    gain = TARGET_MEAN_DB - mean_db(path, TRIM)
    chain = f"{TRIM},volume={gain:.2f}dB,alimiter=limit=0.89:level=false,afade=t=in:d=0.005"
    with tempfile.TemporaryDirectory() as tmp:
        out = pathlib.Path(tmp) / path.name
        subprocess.run(
            ["ffmpeg", "-hide_banner", "-loglevel", "error", "-i", str(path), "-af", chain,
             "-ac", "1", "-ar", "44100", "-b:a", BITRATE, "-map_metadata", "-1", str(out)],
            check=True,
        )
        path.write_bytes(out.read_bytes())
    cut_tail(path)


def main(argv: list[str]) -> int:
    tail_only = "--tail" in argv
    for a in [x for x in argv if x != "--tail"]:
        cut_tail(pathlib.Path(a)) if tail_only else process(pathlib.Path(a))
        print(a)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
