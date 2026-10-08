#!/usr/bin/env python3
"""Copies the voice clips that lock-screen alerts play (handbook 4.13).

A notification cannot play a Flutter asset, so each platform gets its own
copy: Android in res/raw (MP3), iPhone in the Runner bundle (CAF, 16-bit
PCM, which iOS needs for notification sounds). Run from app/ after the
clips change. Needs ffmpeg.
"""
import pathlib
import subprocess

APP = pathlib.Path(__file__).resolve().parent.parent.parent
VOICES = ["charlie", "matilda"]
# Clip name in assets/voice/<voice>/ for each alert.
CLIPS = ["rest_over", "time"]


def main() -> None:
    raw = APP / "android/app/src/main/res/raw"
    ios = APP / "ios/Runner/Sounds"
    raw.mkdir(parents=True, exist_ok=True)
    ios.mkdir(parents=True, exist_ok=True)
    for v in VOICES:
        for c in CLIPS:
            src = APP / f"assets/voice/{v}/{c}.mp3"
            name = f"voice_{v}_{c}"
            (raw / f"{name}.mp3").write_bytes(src.read_bytes())
            subprocess.run(
                ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
                 "-ac", "1", "-ar", "22050", "-c:a", "pcm_s16le", str(ios / f"{name}.caf")],
                check=True,
            )
            print(name)


if __name__ == "__main__":
    main()
