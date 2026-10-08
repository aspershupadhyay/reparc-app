#!/usr/bin/env python3
"""Builds the bundled voice cues (handbook 4.13).

Reads the API key from the ELEVENLABS_API_KEY environment variable. Never
write the key to a file or commit it. The app itself makes no network
request for voice: it plays the files in app/assets/voice/.

A clip is made again when its text, model, or settings in phrases.json
differ from tool/voice/generated.json, or when its file is missing. Each
new clip goes through postprocess.py (needs ffmpeg).

Usage, from app/:
  python3 tool/voice/generate.py --dry-run   # list what would be made
  ELEVENLABS_API_KEY=... python3 tool/voice/generate.py
"""
import json
import os
import pathlib
import sys
import time
import urllib.request

from postprocess import process

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent.parent / "assets" / "voice"
RECORD = HERE / "generated.json"


def main(argv: list[str]) -> int:
    dry = "--dry-run" in argv
    spec = json.loads((HERE / "phrases.json").read_text())
    record = json.loads(RECORD.read_text())
    settings = spec.get("voice_settings", {})
    # Exercise names ("Next up: Bench press.") from names.py go in names/.
    names = json.loads((HERE / "names.json").read_text())
    phrases = {**spec["phrases"], **{f"names/{k}": v["text"] for k, v in names.items()}}
    todo = []
    for voice in spec["voices"]:
        for name, text in phrases.items():
            want = {"text": text, "model": spec["model"], "settings": settings}
            path = OUT / voice / f"{name}.mp3"
            if not path.exists() or record["clips"].get(f"{voice}/{name}") != want:
                todo.append((voice, name, want, path))
    for voice, name, _, _ in todo:
        print(f"{'would make' if dry else 'make'} {voice}/{name}")
    print(f"{len(todo)} clips, {sum(len(w['text']) for _, _, w, _ in todo)} characters")
    if dry or not todo:
        return 0
    key = os.environ.get("ELEVENLABS_API_KEY")
    if not key:
        print("Set ELEVENLABS_API_KEY.", file=sys.stderr)
        return 1
    for voice, name, want, path in todo:
        body = {"text": want["text"], "model_id": want["model"]}
        if settings:
            body["voice_settings"] = settings
        req = urllib.request.Request(
            f"https://api.elevenlabs.io/v1/text-to-speech/{spec['voices'][voice]}?output_format={spec['format']}",
            data=json.dumps(body).encode(),
            headers={"xi-api-key": key, "Content-Type": "application/json", "Accept": "audio/mpeg"},
        )
        path.parent.mkdir(parents=True, exist_ok=True)
        with urllib.request.urlopen(req, timeout=60) as r:
            path.write_bytes(r.read())
        process(path)
        record["clips"][f"{voice}/{name}"] = want
        # Save after each clip, so a failed run keeps what it made.
        RECORD.write_text(json.dumps(record, indent=2, ensure_ascii=False) + "\n")
        time.sleep(0.3)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
