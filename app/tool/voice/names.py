#!/usr/bin/env python3
"""Lists the exercise names the voice can say (handbook 4.13).

Takes the coached exercises (lib/features/exercises/catalog/) and the
library exercises that plans use (lib/domain/roadmap.dart). Writes
tool/voice/names.json for generate.py and lib/domain/voice_names.dart, the
list of names the app has a clip for. Run from app/.
"""
import json
import pathlib
import re

APP = pathlib.Path(__file__).resolve().parent.parent.parent


def key(catalog_id: str) -> str:
    """File name for a catalog ID: 'lib:Barbell_Shrug' -> 'lib_barbell_shrug'."""
    return re.sub(r"[^a-z0-9]+", "_", catalog_id.lower()).strip("_")


def main() -> None:
    names = {}
    for f in sorted((APP / "lib/features/exercises/catalog").glob("*.dart")):
        for cid, name in re.findall(r"\bid: '([^']+)',\s*name: '((?:[^'\\]|\\.)+)'", f.read_text()):
            names[cid] = name.replace("\\'", "'")
    roadmap = (APP / "lib/domain/roadmap.dart").read_text()
    # The name a plan gives a library exercise is the name the user sees.
    given = {}
    for lid, name in re.findall(r"'lib:([^']+)',\s*(?:name:\s*)?'((?:[^'\\]|\\.)+)'", roadmap):
        given.setdefault(lid, name.replace("\\'", "'"))
    lib = {e["id"]: e["name"] for e in json.loads((APP / "assets/exercises/library.json").read_text())["exercises"]}
    for lid in sorted(set(re.findall(r"'lib:([^']+)'", roadmap))):
        if lid in given:
            names[f"lib:{lid}"] = given[lid]
        elif lid in lib:
            # "Lateral Raise - With Bands" -> "Lateral raise".
            n = lib[lid].split(" - ")[0]
            names[f"lib:{lid}"] = n[0] + n[1:].lower()
    out = {key(c): {"id": c, "text": f"Next up: {n}."} for c, n in sorted(names.items())}
    (APP / "tool/voice/names.json").write_text(json.dumps(out, indent=2, ensure_ascii=False) + "\n")
    ids = "\n".join(f"  '{c}'," for c in sorted(names))
    (APP / "lib/domain/voice_names.dart").write_text(
        "// Written by tool/voice/names.py. Do not edit by hand.\n\n"
        "/// Catalog IDs of exercises the voice can name: \"Next up: Bench press.\"\n"
        "/// Clips are in `assets/voice/<voice>/names/`.\n"
        f"const spokenExercises = <String>{{\n{ids}\n}};\n"
    )
    print(len(out), "names,", sum(len(v["text"]) for v in out.values()), "characters per voice")


if __name__ == "__main__":
    main()
