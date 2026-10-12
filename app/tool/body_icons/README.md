# Body icons

`app/assets/body/icons/` holds one icon for each body area (`area_<area>.webp`) and each muscle (`<muscle>.webp`, named as in the `Muscle` enum). The app shows them through `MuscleIcon` and `bodyIconAsset` in `lib/features/exercises/muscle_map.dart`.

## Source

The icons were made on 2026-10-12 with Figma's image generation (model `gpt-image-2.5-sunburst`), one prompt for each icon. The design sheet is the Figma file "Reparc body icons" in the owner's drafts. Each prompt used the same style and named one muscle:

> Realistic anatomical muscle illustration for a premium fitness app icon. All muscles in soft neutral light grey with fine muscle fiber detail and subtle shading. ONLY the <muscle> is highlighted in vivid saturated red-orange. Plain flat pure white background, centered, no text, no labels, no skin, minimal, consistent soft studio lighting.

Each result was checked by eye for the right muscle before use. Rights in AI-generated images under Figma's terms are **To confirm** before a store release.

## Rebuild

Save each 1024 px PNG from Figma as `<name>.png` in one folder, then from `app/`:

```sh
python3 -I tool/body_icons/process.py <folder> assets/body/icons
```

You need Python 3 with NumPy, Pillow, and OpenCV (`opencv-python-headless`). The script makes the white background around the figure transparent, removes the white fringe at the edge, trims and pads the figure to a square, and saves a 256 px WebP. `test/body_library_test.dart` checks that every area and muscle has its file.
