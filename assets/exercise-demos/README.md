# Exercise demonstration drafts

These files are original, procedural Blender samples for the Reparc Workout tab.
They use one shared palette and Manrope text.

## Preview files

- [Bodyweight squat](bodyweight_squat.gif)
- [Push-up](push_up.gif)
- [One-arm dumbbell row](one_arm_dumbbell_row.gif)

Each GIF is 480 by 480 pixels. Each GIF loops at 20 frames per second. The current files use about 100 to 340 KB each.

## Status

These are visual drafts. A qualified coach has not reviewed the movement. Do not present them as trusted exercise instructions until the movement and cues receive review. Do not use them to score a user's form or make health claims.

## Rebuild

Install Blender 5.2 or a compatible later release and FFmpeg. Run this command from the repository root:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python tools/render_exercise_demos.py
```

To render one movement, set `REPARC_RENDER_ONLY` to `bodyweight_squat`, `push_up`, or `one_arm_dumbbell_row`.

The generator is [render_exercise_demos.py](../../tools/render_exercise_demos.py). It creates temporary PNG frames and uses FFmpeg to write the looping GIFs.

## Licenses

- The generator and original demo artwork follow the repository's [AGPL-3.0-only license](../../LICENSE).
- The Manrope font uses the SIL Open Font License. Keep the included [font license](OFL-Manrope.txt) with the font file.
- Blender and FFmpeg are external tools. This repository does not include their binaries.
