#!/usr/bin/env python3
"""Cleans up voice cue files so every cue starts at once and plays at the
same loudness (handbook 4.13).

For each file: cut the silence at the start and end, set the mean level to
TARGET_MEAN_DB, keep peaks under -1 dBFS, and save as mono MP3. Needs ffmpeg.

Usage, from app/: python3 tool/voice/postprocess.py assets/voice/charlie/go.mp3 ...
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


def main(argv: list[str]) -> int:
    for a in argv:
        process(pathlib.Path(a))
        print(a)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
