# Body map mesh

`build.py` makes `app/assets/body/body.bin`, the 3D body on Workout → Exercises. The app reads it in `lib/features/exercises/body3d/body_model.dart`.

## Source

The body is MakeHuman's hm08 base mesh, its shape targets, and its default skeleton and skin weights. MakeHuman released these assets as CC0 in September 2020 (`LICENSE.ASSETS.md` in their repository, and the header of each file). The notice is in `app/assets/licenses/makehuman-CC0.txt` and shows on the licences page. MakeHuman's program code is AGPL. We do not use or ship it: these scripts only read the data files.

## Rebuild

```sh
git clone --depth 1 https://github.com/makehumancommunity/makehuman.git /tmp/mh
cd app
python3 -I tool/body/build.py /tmp/mh/makehuman/data /tmp/body.npz
python3 -I tool/body/preview.py /tmp/body.npz /tmp/body     # PNG from 5 angles
flutter test tool/body/render_body_test.dart --update-goldens   # the app's own renderer
flutter test test/body_map_test.dart
```

You need Python 3 with NumPy and Pillow. The build is deterministic, so the same inputs give the same file.

## Steps

1. **Shape** (`mh.py`): a young adult man with MakeHuman's own macro sliders: muscle 1.0, weight 0.5, ideal proportions, and an even ethnic mix. The sliders mix targets the same way MakeHuman does.
2. **Pose** (`pose.py`): the arms come down from the A-pose to 13° from the sides, with the forearms 15° out. Each vertex follows its bones by their skin weights, with a dual-quaternion blend so the shoulders keep their volume.
3. **Scale**: metres, 1.78 m tall, feet on y = 0, and the hips at z = 0. Y is up, Z points out of the chest, and X points to the figure's left.
4. **Refine** (`refine.py`): MakeHuman puts most of its detail into the face, hands, and feet. Each quad of the trunk and limbs is split into four. The new points are placed on a curved surface (Phong tessellation), and the edges where split quads meet unsplit ones are fanned so there are no cracks. The result has 25,373 vertices and 50,742 triangles.
5. **Muscles** (`muscles.py`): each vertex goes to a body segment (by its skin weights), and then to a muscle by anatomical rules measured on this mesh: the pectoral fan in three bands, the trapezius diamond, three deltoid heads, the six-pack rows, the quad and hamstring heads, the two calf heads, and so on. Heads and blocks are sub-regions: their seams show as grooves, but a tap picks the whole muscle. The list order matches `mapMuscles` in Dart.
6. **Shading**: grooves fade 1 cm from each seam. Bare skin has no outline. Muscle colour fades in over 2 cm. Soft shadow (ambient occlusion) is baked from 160 directions.
7. **Write**: one little-endian binary file. See `write()` in `build.py` for the layout. `BodyMesh.parse` checks the magic, the version, and the exact length.

## Checks

`test/body_map_test.dart` checks these points:

- The mesh is closed, with one winding throughout.
- Its volume is that of an adult.
- It is 1.78 m tall and the same width on both sides.
- Every muscle in the browse tree is on both sides.
- A turned body draws about half its triangles.
- A tap on each muscle's anchor picks that muscle from every view where the muscle shows.
- Tap, select, and open work in the widget.

When you change a region, look at `preview.py`'s sheet and the renders from `render_body_test.dart` from the front, side, back, and three-quarter views.
