# RepArc gym model (ready to use)

`reparc-gym-model.glb` is the painted gym model as one glTF 2.0 binary (8.3 MB). It opens in any glTF
viewer or engine: three.js, Blender, Unity (glTFast), Unreal (glTF importer), Godot, Flutter (a glTF
or three.js view).

What is inside:
- One skinned mesh: 112,292 points, 202,968 triangles, in the bind pose, metres, +Y up, facing +Z.
- A 51-bone skeleton: spine, neck, head, clavicles, upper arms, two-part forearms (for the palm
  twist), hands, three bones a finger, thighs, shins, feet. Bone names are in the file.
- Material: the painting as the base colour (2048 px), its relief as the normal map, roughness 0.72.
- The muscles are sculpted into the surface (`sculpt.py`): real bellies and grooves under the paint.
- `_MUSCLE` vertex attribute (muscle id; 65535 = none) and `_AMP` (belly weight 0 to 1, for bulge effects), stored
  as floats so Blender imports them (its importer drops 16-bit attributes and fails on normalised bytes).
- Scene extras: `muscles` (each part with its side, app muscle group, origin and insertion bones),
  `atlas` (part names), `cats` (app muscle groups), and `labelTexture` (image 2: the muscle part of
  each texel; value = index into `atlas`, 255 = none). Use it to light a muscle in red, as the
  Motion Lab does.

Blender: File → Import → glTF 2.0. Switch the viewport to Material Preview to see the paint. The muscle ids
come in as the `_MUSCLE` point attribute and the tables as scene custom properties. Checked with Blender 5.2
(`../render.py` imports it and renders it). Edits made by hand in Blender do not reach the Motion Lab, which
builds from `model.json`: put a change into the scripts instead.

**Blender file: `reparc-gym-model.blend`** (13 MB, every texture packed). The same body as a real person:
material slot 1 "Skin" (MakeHuman's CC0 skin with painted shorts, a little subsurface scattering) and slot 2
"Painted anatomy". Eyes, brows, lashes, and short hair follow the "head" bone; the armature has the 51 bones.
Three area lights and a camera are set; F12 renders with Cycles. To show the anatomy: select the body, Tab,
select all, pick "Painted anatomy" in the material list, Assign. Built by `../blend.py` (read its top comment).
Edits in this file do not reach the Motion Lab: put lasting changes into the scripts.

Rebuild it after any change to the painting, the muscle atlas, or the mesh, with the commands in
`../README.md` ("Rebuild and check"), and commit the new file. Do not edit it by hand.

Use in other projects: the code and the muscle atlas are RepArc's; the body comes from MakeHuman's
CC0 assets (free for any use); the painting was made with Nano Banana Pro in the owner's Figma
Weave workspace. Before you use the painting outside RepArc, check the Figma and Weave terms of use
for generated images.
