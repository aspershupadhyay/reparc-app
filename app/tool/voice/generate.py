#!/usr/bin/env python3
"""Builds the bundled voice cues (handbook 4.13).

Reads the API key from the ELEVENLABS_API_KEY environment variable. Never
write the key to a file or commit it. The app itself makes no network
request for voice: it plays the files in app/assets/voice/.

Usage: ELEVENLABS_API_KEY=... python3 tool/voice/generate.py
Run from app/. Existing files are kept; delete one to make it again.
"""
import json
import os
import pathlib
import sys
import time
import urllib.request

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent.parent / "assets" / "voice"


def main() -> int:
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        print("Set ELEVENLABS_API_KEY.", file=sys.stderr)
        return 1
    spec = json.loads((HERE / "phrases.json").read_text())
    for voice, voice_id in spec["voices"].items():
        folder = OUT / voice
        folder.mkdir(parents=True, exist_ok=True)
        for name, text in spec["phrases"].items():
            path = folder / f"{name}.mp3"
            if path.exists():
                continue
            req = urllib.request.Request(
                f"https://api.elevenlabs.io/v1/text-to-speech/{voice_id}?output_format={spec['format']}",
                data=json.dumps({"text": text, "model_id": spec["model"]}).encode(),
                headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"},
            )
            with urllib.request.urlopen(req, timeout=60) as r:
                path.write_bytes(r.read())
            print(f"{voice}/{name}.mp3")
            time.sleep(0.3)
    return 0


if __name__ == "__main__":
    sys.exit(main())
