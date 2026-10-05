#!/usr/bin/env python3
"""Builds the bundled exercise library from Free Exercise DB.

Source: https://github.com/yuhonas/free-exercise-db (Unlicense, public domain).
The commit is pinned so the output is reproducible.

Output:
  assets/exercises/library.json   compact records the app reads
  assets/exercises/img/<id>_<n>.webp   start and end photos, cropped to 4:3

Needs git and ffmpeg (with libwebp). Run from the app/ folder:
  python3 tool/exercise_library/build.py
"""
import json
import pathlib
import shutil
import subprocess
import sys
import tempfile

REPO = "https://github.com/yuhonas/free-exercise-db"
COMMIT = "f00c92c7dcf1216a928a52c3706c7ce8e2f71ed5"
WIDTH, HEIGHT, QUALITY = 480, 360, 68

APP = pathlib.Path(__file__).resolve().parents[2]
OUT = APP / "assets" / "exercises"


def run(*cmd, cwd=None):
    subprocess.run(cmd, cwd=cwd, check=True)


def main():
    with tempfile.TemporaryDirectory() as tmp:
        src = pathlib.Path(tmp) / "db"
        run("git", "init", "-q", str(src))
        run("git", "fetch", "-q", "--depth", "1", REPO, COMMIT, cwd=src)
        run("git", "checkout", "-q", "FETCH_HEAD", cwd=src)
        records = json.loads((src / "dist" / "exercises.json").read_text())

        if OUT.exists():
            shutil.rmtree(OUT)
        (OUT / "img").mkdir(parents=True)

        out = []
        for r in sorted(records, key=lambda r: r["name"].lower()):
            if len(r["images"]) < 2:
                continue  # every library entry shows a start and an end photo
            for n, rel in enumerate(r["images"][:2]):
                run(
                    "ffmpeg", "-loglevel", "error", "-y", "-i", str(src / "exercises" / rel),
                    "-vf", f"scale={WIDTH}:{HEIGHT}:force_original_aspect_ratio=increase,crop={WIDTH}:{HEIGHT}",
                    "-quality", str(QUALITY), str(OUT / "img" / f"{r['id']}_{n}.webp"),
                )
            out.append({
                "id": r["id"],
                "name": r["name"].strip(),
                "category": r["category"],
                "level": r["level"],
                "equipment": r["equipment"],
                "force": r["force"],
                "mechanic": r["mechanic"],
                "primary": r["primaryMuscles"],
                "secondary": r["secondaryMuscles"],
                "steps": [s.strip() for s in r["instructions"] if s.strip()],
            })

        (OUT / "library.json").write_text(
            json.dumps({"source": REPO, "commit": COMMIT, "license": "Unlicense", "exercises": out},
                       ensure_ascii=False, separators=(",", ":"))
        )
        print(f"{len(out)} exercises written to {OUT.relative_to(APP)}", file=sys.stderr)


if __name__ == "__main__":
    main()
