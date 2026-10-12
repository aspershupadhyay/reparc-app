# RepArc gym model (ready to use)

`reparc-gym-model.glb` is the painted gym model as one glTF 2.0 binary (7.8 MB). It opens in any glTF
viewer or engine: three.js, Blender, Unity (glTFast), Unreal (glTF importer), Godot, Flutter (a glTF
or three.js view).

What is inside:
- One skinned mesh: 112,292 points, 202,968 triangles, in the bind pose, metres, +Y up, facing +Z.
- A 51-bone skeleton: spine, neck, head, clavicles, upper arms, two-part forearms (for the palm
  twist), hands, three bones a finger, thighs, shins, feet. Bone names are in the file.
- Material: the painting as the base colour (2048 px), its relief as the normal map, roughness 0.72.
- `_MUSCLE` vertex attribute (muscle id; 65535 = none) and `_AMP` (belly weight, for bulge effects).
- Scene extras: `muscles` (each part with its side, app muscle group, origin and insertion bones),
  `atlas` (part names), `cats` (app muscle groups), and `labelTexture` (image 2: the muscle part of
  each texel; value = index into `atlas`, 255 = none). Use it to light a muscle in red, as the
  Motion Lab does.

Rebuild it after any change to the painting, the muscle atlas, or the mesh, with the commands in
`../README.md` ("Rebuild and check"), and commit the new file. Do not edit it by hand.

Use in other projects: the code and the muscle atlas are RepArc's; the body comes from MakeHuman's
CC0 assets (free for any use); the painting was made with Nano Banana Pro in the owner's Figma
Weave workspace. Before you use the painting outside RepArc, check the Figma and Weave terms of use
for generated images.
