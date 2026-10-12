# Motion Lab (prototype)

A three.js page that shows the app's realistic body, rigged with a skeleton, doing exercises with correct form. It is a prototype for the owner to judge. It is **not** in the app: decision D-038 (Proposed) covers moving it in.

Live demo (private to the owner): https://claude.ai/artifact/JArExRx3VRAxtg3YQW92c2

## What it does

- Same body as the app's body map: MakeHuman's CC0 base mesh, shaped and posed by `tool/body/`, 25,373 vertices, 22 muscle regions.
- 54 bones with MakeHuman's own skin weights: trunk, neck, head, collarbones, upper arms, a two-part forearm (so the forearm can twist: palms up, neutral, or down), hands, three bones for each finger (so hands close on a dumbbell), thighs, shins, and feet.
- Muscle fibre striations in the shader, from a fibre direction for each vertex (`export.py` sets them from anatomy). Main muscles are red-orange and helpers light orange, the same as the body icons.
- Two-bone IK pins feet to the floor (squats, deadlifts) and hands to the floor (push-ups). Knees track over the toes.
- Each move shows its tempo phases, the app's coached steps, cues, mistakes, and breathing, and a live joint angle.
- **Form checks.** Each move lists checks with target ranges (for example "Elbows about 45°: upper arm 30–60° from the body"). The page measures them on the posed skeleton at the start and end of the rep and shows pass or fail with the measured value. `check.js` runs them all and fails if any check fails. The ranges follow common coaching standards and the app's coached text; a review by a qualified coach is **To confirm**.

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
cd app
python3 -I tool/motion/export.py /tmp/mh/makehuman/data /tmp/body.json     # about 15 s
python3 -I tool/motion/build.py /tmp/body.json /tmp/motion-lab.html        # one 1.4 MB page
node tool/motion/check.js /tmp/motion-lab.html /tmp/motion-shots           # form checks + screenshots
```

In a cloud session: `PLAYWRIGHT=/opt/node-tools/node_modules/playwright CHROMIUM=/opt/pw-browsers/chromium node tool/motion/check.js …`. The page loads three.js r147 from jsDelivr, so the check needs network access.

To update the live demo, publish `/tmp/motion-lab.html` with the Artifact tool and the URL above.

## Known limits

- Poses are set by hand as joint angles (minutes for each move); the checks catch mistakes. Building poses from the library's start and end photos with a pose-estimation model is a possible next step, not started.
- Fibre lines are drawn by the shader, so they are an illustration, not real fibre paths.
- Fingers close as one grip; the thumb is approximate.
