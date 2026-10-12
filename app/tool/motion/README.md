# RepArc gym model and Motion Lab (prototype)

**The gym model** is RepArc's own anatomical body: the app's CC0 MakeHuman body with a skeleton, and 50 muscle parts and 7 tendons a side laid on it from anatomy, in the style of the body icons (grey anatomy, the working muscle lit). It is one asset we can use anywhere: the Motion Lab page reads it as JSON, and `gym.py` also writes a standard glTF file (`.glb`) for Blender, three.js, game engines, or Flutter.

**The Motion Lab** is a three.js page that shows the model doing exercises with correct form. It is a prototype for the owner to judge. It is **not** in the app: decision D-038 (Proposed) covers moving it in.

## How the gym model is built (`charts.py`, `atlas.py`, `assign.py`, `gym.py`)

1. **Charts.** The trunk and each limb are unwrapped into flat coordinates in metres: arc length around a vertical axis (trunk) or around the bone (limbs), and height or distance along the bone. Both sides share one drawing.
2. **Atlas.** Each muscle is a 2D shape on a chart: a rounded polygon (pectoralis, latissimus, trapezius, obliques, glutes, rectus abdominis blocks) or a tapered spindle (biceps, triceps and quad heads, forearm muscles, calves). Shapes are signed distance functions. Heads are separate parts: three deltoid heads, two biceps heads, three triceps heads, three pectoral heads, four rectus abdominis blocks, three serratus slips, two gastrocnemius heads, and so on. Each part names its app muscle (for highlights), its fibre direction, its belly height, and its origin, via points, and insertion.
3. **Assignment.** The mesh is subdivided once (101,486 vertices). Each point takes the muscle with the lowest signed distance. Shapes are drawn 8 mm large, so neighbours meet in one seam halfway between them (a Voronoi-style split): depth inside a muscle is the distance to the nearer of its own edge and that seam.
4. **Relief.** Each belly rises with a rounded profile, h = H·s·(2 − s) with s = depth / R, and a groove of 3.2 mm sits at every seam. Normals are recomputed, and a cavity term from mean curvature darkens grooves and lightens bellies (as sculpting tools do), with baked ambient occlusion on top.
5. **Fibres.** The fibre direction is set in chart space (along the spindle, or toward the insertion for fan muscles such as the pectoralis).
6. **Textures (`bake.py`).** The charts double as the texture layout (one side; the other mirrors). Fine detail lives in 2048 px textures baked straight from the atlas shapes, so muscle edges are crisp at any distance: a muscle-ID map (nearest filtering; the page colours each part from it), a detail map (fibre streaks, tendons, seams), and a tangent-space normal map. Fibres are drawn with line integral convolution (Cabral and Leedom, 1993): noise averaged along each muscle's fibre direction, which gives long thin streaks like an anatomy plate. `gym.py` splits vertices where a triangle crosses a chart border or a limb's back seam, and stores tangents from the chart's basis vectors.
7. **Heads of one muscle.** Parts in one group (pectoralis, trapezius, deltoid, biceps, triceps, gastrocnemius) meet in a faint line, not a deep groove (`atlas.FAINT_GROUPS`). A part with `over` lies over its neighbours (the sartorius over the quads). Fan muscles split into heads along rays from their insertion (`ray_split`).

## Painted model (`paint.py`): the icons' look on the 3D body

The body icons look real because they are paintings. Drawing muscle shapes on the mesh (steps 2 to 6) never matched them. So the model wears a painting in the icons' style, baked into ordinary textures:

1. **Painting.** `paint.py views` renders the smooth body as grey orthographic views in one sheet (`paint/sheets.json` says the pose, the views and the layout). An image model repaints the sheet in the icons' style and keeps every outline in place (`paint/prompt.txt`; the painting is `paint/painted-2026-10-12.webp`, made with Nano Banana Pro in the owner's Figma Weave).
2. **UV layout.** xatlas cuts the 25k-point base mesh into 275 charts and packs them for 2048 px. The page and `glb.py` subdivide the mesh once on the Phong surface, exactly as `paint.subdivide()` does, so texture and surface agree. Copies that a UV seam makes share one normal (a weld key), so seams do not show in the light.
3. **Bake.** For every texel, each painted view that sees it adds its colour, weighted by facing³ and faded out within 15 px of an outline or occlusion edge (paintings draw dark outlines there). Each view is first aligned to our outline (affine ECC on the silhouettes; the overlap must be 0.9 or more, or the build stops). Outputs:
   - `albedo.webp`: the paint. Points no view sees (about 30 %: under the arms, between the legs) take colour diffused over the surface from their neighbours, and where the paint is thin, fibre strokes in the paint's own colour are drawn along each muscle's fibre direction (line integral convolution, with sign-free tracing; strokes cut short at a chart edge are left out because they read as noise).
   - `normal.webp`: relief from the paint (a high-pass of its brightness used as height, 1.5 mm for a full step), glTF convention, so the scene light moves over the painted bellies and fibres.
   - `label.png`: the muscle part of each texel, for the red highlight. It starts from our atlas and is moved onto the painted muscle edges by a watershed on each painting (only the sure middle of each atlas part seeds it; bare skin of the head, hands and feet seeds its own region; islands under 300 px go back to the atlas; a 7-texel majority filter removes specks). Only a clear view (weight above 0.25) moves a border.
4. **Page.** The page tints the target red from the paint's own shading (as in the icons) and helpers half way. The painting already holds the light, so the scene light adds only a little.

**More paintings.** `paint/sheets.json` takes more sheets (another pose and other views); `build` blends them all. A sheet with the arms raised seen from four low three-quarter views would cut the badly seen surface from 21 % to 7 % (measured). It was not painted: the owner's Weave workspace allows 2 free model runs, both used (2026-10-12); more runs need a paid Weave plan.

## Holding the weights

- A dumbbell sits where a closed hand holds it: the centre of the loop the fingers make (knuckles, middle joints, end joints, tips), along the knuckle line (`fist()` in `lab.html`). The check "Hand closed on the handle" measures the fingertips' distance from the handle axis.
- The goblet squat orients each hand from a wanted palm and finger direction (`handFrame()`), then solves the arm so the hands press the sides of the top plate. Its check measures the hands against the plate rim.
- Arm IK takes its lengths from the bind pose, because the hand sits below a forearm twist bone (fixed 2026-10-12: the hands fell short before).

## Muscle physics (in the page)

- **Constant volume.** Muscle volume V = A·L stays the same, so when a muscle shortens its cross-section grows: thickness scales with √(L₀/L). Each frame the page measures every muscle's path length from origin through via points to insertion on the posed skeleton, and the vertex shader pushes the belly out (or in) along the normal.
- **Via points.** Tendons that wrap over a joint (quads over the kneecap, triceps over the elbow) pass through a via point, as in musculoskeletal models such as OpenSim. Without it, a straight line made the rectus femoris shorten far too much in a deep squat.
- **Tension.** Working muscles (the move's main and helper muscles) get a little extra fullness while the set runs.
- Measured with `window.__lab.bulge()`: in a curl the biceps long head goes from +3.3 to +5.9 mm while the triceps thins to −1.5 mm; in a goblet squat the glutes thin as they stretch (+4.5 to −1.3 mm), and the rectus femoris barely changes (hip flexion and knee flexion cancel out, a known effect called Lombard's paradox).

## Why our own model

Research (2026-10-12): the best open anatomical muscle models, Z-Anatomy and BodyParts3D, are share-alike (CC BY-SA), which needs an owner decision for a closed-source app (D-035); ready-made écorché models are paid. Our model uses only CC0 MakeHuman data plus our own atlas, so it has no licence questions. Using Z-Anatomy instead would be a licensing decision for the owner.

References: Ramos and Larboulette, "A Muscle Model for Enhanced Character Skinning", Journal of WSCG 2013 (parametric muscles over skinning with volume preservation); OpenSim musculoskeletal models (muscle paths with via points).

Live demo (private to the owner): https://claude.ai/artifact/JArExRx3VRAxtg3YQW92c2

## What it does

- Same body as the app's body map: MakeHuman's CC0 base mesh, shaped and posed by `tool/body/`, 25,373 vertices, 22 muscle regions.
- 51 bones with MakeHuman's own skin weights: trunk, neck, head, collarbones, upper arms, a two-part forearm (so the forearm can twist: palms up, neutral, or down), hands, three bones for each finger (so hands close on a dumbbell), thighs, shins, and feet.
- Muscle fibre striations in the shader, from a fibre direction for each vertex (`export.py` sets them from anatomy). Main muscles are red-orange and helpers light orange, the same as the body icons.
- Two-bone IK pins feet to the floor (squats, deadlifts) and hands to the floor (push-ups). Knees track over the toes.
- Each move shows its tempo phases, the app's coached steps, cues, mistakes, and breathing, and a live joint angle.
- **Form checks.** Each move lists checks with target ranges (for example "Elbows about 45°: upper arm 30–60° from the body"). The page measures them on the posed skeleton at the start and end of the rep and shows pass or fail with the measured value. `check.js` runs them all and fails if any check fails. The ranges follow common coaching standards and the app's coached text; a review by a qualified coach is **To confirm**.

## Checking shapes

Compare against the body icons at the same framing. In the page, `window.__lab.debug(true)` paints every muscle part its own colour, `window.__lab.parts(['Rectus femoris'])` lights single parts, and `window.__lab.highlight(['quads'])` lights an app muscle. Judge shapes in 3D renders like these, not on the flat charts.

## Adding a move

A move is data in the `EX` list of `lab.html`, not code:

- `keys`: two poses (start and end) as joint angles: `pelvis`, `spine`, `chest`, `neck`, `thigh`, `knee`, `hipAbd`, `hipOut`, `shFlex`, `shAbd`, `elbow`, `twist` (+ is palm up), `wrist`, `grip` (0 open to 1 fist), `clav`. The comment above `applyPose` explains each one.
- `tempo`: phases as `[label, key, seconds, step index]`.
- `ground`: `'feet'` keeps both feet planted; `after()` adds IK (see Push-up and Goblet squat).
- Text: `summary`, `steps`, `cues`, `mistakes`, `breathing`. Copy them from the coached guide in `lib/features/exercises/catalog/` so the app and the demo agree.
- `checks`: `[title, rule, measure, pass test, unit, 'start' | 'end' | 'both']`. Add one check for each form point in the steps. Then run `check.js`, look at the screenshots, and fix the angles until every check passes. Never widen a range to make a check pass.

## Rebuild and check

```sh
# MakeHuman data (CC0 assets only; their code is AGPL and is not used)
git clone --depth 1 --filter=blob:none --sparse https://github.com/makehumancommunity/makehuman.git /tmp/mh
git -C /tmp/mh sparse-checkout set makehuman/data/3dobjs makehuman/data/rigs makehuman/data/targets/macrodetails
pip install xatlas==0.0.11 opencv-python-headless numpy pillow   # paint.py needs xatlas (UV layout) and OpenCV
cd app
BASE_CACHE=/tmp/base.npz python3 -I tool/motion/export.py /tmp/mh/makehuman/data /tmp/body.json   # rigged body, about 15 s
python3 -I tool/motion/gym.py /tmp/base.npz /tmp/gym.json                                         # gym model, about 15 s
python3 -I tool/motion/bake.py /tmp/gym-tex                                                       # textures, about 20 s
python3 -I tool/motion/paint.py build /tmp/base.npz /tmp/gym.json tool/motion/paint/sheets.json /tmp/paint-out   # painted model + textures, about 90 s
python3 -I tool/motion/build.py /tmp/paint-out/model.json /tmp/paint-out /tmp/motion-lab.html     # painted page, 2.7 MB
python3 -I tool/motion/glb.py /tmp/paint-out/model.json /tmp/paint-out tool/motion/dist/reparc-gym-model.glb   # painted .glb, 7.8 MB (committed)
python3 -I tool/motion/build.py /tmp/gym.json /tmp/gym-tex /tmp/motion-lab-atlas.html            # older atlas-only page
# A new painting: python3 -I tool/motion/paint.py views /tmp/base.npz /tmp/gym.json tool/motion/paint/sheets.json 0 /tmp/sheet_in.png
node tool/motion/check.js /tmp/motion-lab.html /tmp/motion-shots           # form checks + screenshots
```

In a cloud session: `PLAYWRIGHT=/opt/node-tools/node_modules/playwright CHROMIUM=/opt/pw-browsers/chromium node tool/motion/check.js …`. The page loads three.js r147 from jsDelivr, so the check needs network access.

To update the live demo, publish `/tmp/motion-lab.html` with the Artifact tool and the URL above.

## Known limits

- Poses are set by hand as joint angles (minutes for each move); the checks catch mistakes. Building poses from the library's start and end photos with a pose-estimation model is a possible next step, not started.
- Fibre lines are drawn by the shader along each muscle's set direction; they are an illustration, not traced fibres.
- Deep muscles (rhomboids, iliopsoas, rotator cuff under the deltoid) are not drawn: the model shows the surface layer.
- Size: the page is 2.7 MB (a 1.75 MB base mesh and three 2048 px textures); in the browser the mesh is 112,292 points and 202,968 triangles after subdivision. Building it takes about 130 ms on a desktop and about 470 ms with the CPU slowed 4× (Pixel 7 emulation). Phones get a pixel ratio of at most 1.5 and a 1024 px shadow map, and the page steps the pixel ratio down to 1 if frames average over 28 ms for 2 s. `__lab.perf()` reports all of this. **Not measured:** frame rate on a real phone (the cloud browser draws in software, so its frame times say nothing about a phone GPU).
- Hidden areas (sides of the chest under the arms, armpits, inner thighs) carry diffused paint with drawn fibre strokes, not real painting. They are softer than the rest; a second painting fixes this (see "More paintings").
- The red highlight follows the painted edges where a view sees the muscle clearly; elsewhere it uses our atlas, which can sit a little off the painted muscle.
- Fingers close as one grip; the thumb is approximate.
