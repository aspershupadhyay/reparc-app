#!/usr/bin/env python3
"""Copies the voice clips that lock-screen alerts play (handbook 4.13).

A notification cannot play a Flutter asset, so each platform gets its own
copy: Android in res/raw (MP3), iPhone as CAF (IMA4, a format iOS accepts
for notification sounds) in assets/voice/alerts/, which the app copies to
Library/Sounds on start. Run from app/ after the clips change. Needs ffmpeg.
"""
import pathlib
import subprocess

APP = pathlib.Path(__file__).resolve().parent.parent.parent
VOICES = ["charlie", "matilda"]
# Clip name in assets/voice/<voice>/ for each alert.
CLIPS = ["halfway", "ten_left", "three", "two", "one", "time", "rest_over"]


def main() -> None:
    raw = APP / "android/app/src/main/res/raw"
    ios = APP / "assets/voice/alerts"
    raw.mkdir(parents=True, exist_ok=True)
    ios.mkdir(parents=True, exist_ok=True)
    for v in VOICES:
        for c in CLIPS:
            src = APP / f"assets/voice/{v}/{c}.mp3"
            name = f"voice_{v}_{c}"
            (raw / f"{name}.mp3").write_bytes(src.read_bytes())
            subprocess.run(
                ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", "-i", str(src),
                 "-ac", "1", "-ar", "22050", "-c:a", "adpcm_ima_qt", str(ios / f"{v}_{c}.caf")],
                check=True,
            )
            print(name)


if __name__ == "__main__":
    main()
