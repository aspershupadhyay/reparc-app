# Instructions for AI agents and contributors

## Required reading

Before you change code, data, design, or project rules:

1. Read this file.
2. Read handbook/README.md.
3. Follow the accepted five-tab map in handbook/02-experience-and-design.md and handbook/12-decisions.md.
4. Read handbook/15-validated-plan.md before planning new screens, stack changes, health access, sync, or AI connections.
5. Read the handbook section that owns the feature.
6. Read handbook/13-diagrams.md when the change affects a user flow or data flow.
7. Use handbook/14-feature-spec-template.md when you add a new feature.
8. Read handbook/16-production-and-app-updates.md before changing CI, release automation, signing, update checks, or store delivery.
9. Read the launch review, handbook/reviews/2026-10-10-launch-review/index.html, before planning Play Store work, onboarding, food data, the body map, or other UX polish. It holds findings from a phone test and market research, with proposals. It is not a set of accepted decisions: treat its proposals as **Proposed** until the owner accepts them.

## Repositories

- **`aspershupadhyay/reparc-app` (private):** all source code, the handbook, the gateway, and CI. Do all work here. This file lives here.
- **`aspershupadhyay/reparc` (public):** builds and the website only: a README, GitHub Releases, and the static `site/` files on its `gh-pages` branch. Never push source code, handbook files, or git history to it. The release and website workflows publish to it with the `RELEASES_TOKEN` secret.
- Work only in a clone whose `origin` is `reparc-app`. Check with `git remote -v` before any push.
- Never make `reparc-app` public, not even for a few minutes. Its history contains all source; bots copy newly public repositories within minutes, and public forks stay public. Do not suggest it as a fix for Actions minutes.
- The app's update check, the website download links, and the Support link point to the public `reparc` repository. See handbook/16-production-and-app-updates.md, section 17.9.

## Authority and status

- Follow direct user instructions first.
- **Owner instruction (2026-10-05):** Push every change directly to the `main` branch of `reparc-app` on GitHub as soon as it is ready. Do not ask for confirmation first. Run the matching checks before each push.
- Keep the five accepted tabs: Home, Workout, Meal, Analytics, and Me.
- Keep the two supplied image files as visual references for Meal and Workout. Read them before changing those screens.
- Treat the handbook as the product and architecture plan.
- Treat **Accepted** decisions as current project rules.
- Treat **Proposed** decisions as unapproved.
- Treat **To confirm** items as unresolved.
- Never present a planned feature as built.
- Never claim a security, privacy, performance, or policy result without evidence.
- **Owner instruction (2026-10-10):** Ship production-ready work only. Do not make dev, debug, or test variants of the app (no "Reparc dev", no separate application ID). Every change goes to `main` in a state that can be released, and reaches the owner's phone as a normal release (a version bump, release notes, and a `v*` tag) through the in-app update flow. Test on the phone with that release build.
- Never make the app install an update by itself, and never download one without the user's tap. Before store release, the app checks GitHub Releases for a newer build. On Android, when the user taps **Download and install**, the app downloads the APK, checks its SHA-256 against the release's `SHA256SUMS.txt`, and hands it to Android's installer, which asks the user to confirm. A file that fails the check is deleted. iPhone opens the release page (owner decisions D-029, 2026-10-06, and its update of 2026-10-08). Use App Store or Google Play flows once the app is in a store, and remove `REQUEST_INSTALL_PACKAGES` from a Play build.

## Before implementation

- State the user problem the change solves.
- Identify the smallest change that solves it.
- Check user flows, data fields, units, time, offline behavior, and failure states.
- Check privacy, security, permissions, and accessibility.
- Check the feature's AI context and acceptance checks.
- If an unresolved choice affects privacy, account access, health data, AI access, licensing, data loss, a public API, or a migration, stop and ask the user before choosing.
- Do not ask for approval for routine, reversible implementation details that follow an accepted decision.

## UI and motion

- Use the shared tokens in handbook/02-experience-and-design.md.
- Do not add a separate visual theme for Meal, Gym, or Analytics.
- Use motion only to explain a change or confirm an action.
- Keep motion out of the user's way during data entry.
- Respect reduced-motion settings.
- Test screen readers, large text, and real-device performance.

## Data and AI

- Save core records locally before optional sync.
- Keep missing values distinct from zero.
- Keep units, timestamps, and data sources.
- Do not log private records, prompts, tokens, or provider keys.
- Do not let AI change a record without user approval.
- Keep product-use analytics separate from the user's progress analytics.

## Builds, releases, and Actions minutes

- The repository is private, so GitHub Actions minutes are limited. A job that fails within seconds with no runner and no log usually means the minutes or the spending limit are used up. Tell the owner to check Settings → Billing; do not re-run it again and again.
- CI is split to save minutes (handbook 17.5): `ci.yml` runs quick Linux checks on code pull requests; `android-build.yml` and `ios-build.yml` run only when their own build files change. iPhone builds run on a Mac, which costs 10 times the minutes. Keep it that way.
- Push handbook-only or workflow-only changes straight to `main`; they need no pull request run.
- Release: bump `version` in `app/pubspec.yaml` (raise the `+N` build number every time), add `release-notes/<version>.md`, push to `main`, then run the **Release** workflow with the tag `v<version>`. It publishes the APKs to the public `reparc` repository and keeps the Google Play bundle as the private `play-bundle` artifact (handbook 17.10).
- Two builds, one app (D-036): the GitHub APK has the in-app updater for testing; the Play bundle (`--dart-define=REPARC_STORE=play`) has none.

## Testing on the owner's phone (Latch)

- The owner can connect their phone through Latch. Test the release build that came through the in-app update, never a dev build.
- Tap a text field before typing into it. Text set into a field without focus never reaches the app, and it looks like an app bug when it is not (2026-10-11).
- Do not save, change, or delete the owner's records or settings while testing unless they ask. Close forms without saving.

## Food data

- Foods are grouped by country (owner direction, 2026-10-10). Values come from USDA (SR Legacy and FNDDS, public domain). A dish USDA does not have is a recipe estimate, marked as an estimate with its recipe stored. Never add values from copyrighted tables (for example IFCT) without the owner's licence.
- Recipe estimates leave sodium out (salt is unknown). Check USDA values for sense before shipping them (USDA's paneer entry was wrong).

## Body art and motion

- **Body icons** (`app/assets/body/icons/`, one per body area and muscle): made with Figma's image generation (`generate_image`, model `gpt-image-2.5-sunburst`) on the owner's Figma Education plan, one prompt per icon in one shared style: grey anatomy, only the target muscle in red-orange, white background. Check each image for the right muscle, then run `app/tool/body_icons/process.py` (transparent background, 256 px WebP). The design sheet is the Figma file "Reparc body icons" (https://www.figma.com/design/9MOMlAWYiEqYB0AVlOHc0q). The owner confirmed use of these images (2026-10-12). Read `app/tool/body_icons/README.md`.
- **3D body map** (in the app): `app/tool/body/` builds `app/assets/body/body.bin` from MakeHuman's CC0 data (D-033).
- **Gym model** (our own anatomical body, `app/tool/motion/`): the CC0 MakeHuman body with 51 bones and 50 muscle parts and 7 tendons a side drawn as 2D shapes on unwrapped surface charts (`charts.py`, `atlas.py`), carved as rounded bellies with grooves (`gym.py`), with fine detail in textures baked straight from the shapes (`bake.py`: muscle ID, fibres by line integral convolution, normal map), with constant-volume bulge (thickness ∝ √(L₀/L)) from each muscle's origin, via points, and insertion. `build.py` makes the page and `glb.py` a standard `.glb` with the textures inside. **Its look comes from a painting** (`paint.py`, 2026-10-12): drawn muscle shapes never matched the icons, so the smooth body was rendered in four grey views, repainted in the icons' style by Nano Banana Pro in the owner's Figma Weave (`paint/prompt.txt`, `paint/sheets.json`), and baked onto the body with its own UV layout (xatlas) into three 2048 px textures: the paint (`albedo`), relief from the paint (`normal`), and the muscle part of each texel (`label`, snapped to the painted muscle edges by a watershed). Since 2026-10-12 `sculpt.py` sculpts each painted muscle into the base mesh as a real belly with grooves at its painted edges (run it after `paint.py build`); `render.py` renders the `.glb` in Blender (`pip install bpy`) with studio light, in `clay` to judge the shape. **Skin look** (2026-10-13, owner's ask "make it a real human"): `skin.py` gives the same body MakeHuman's CC0 skin, painted shorts, eyes, brows, lashes, and short hair (MakeHuman's CC0 system assets pack); the page opens in the skin look and a Skin / Muscles button switches to the painted anatomy; both light the working muscles red. The model ships as the 25k-point base mesh; the page and `glb.py` subdivide it once exactly as `paint.subdivide()` does. Keep those two in step: a change to one subdivision must go into the other. `paint.py build` stops if a painting's outline overlap is under 0.9 (one run came back cropped). The `.glb` carries the painting and opens in any glTF viewer. The built `.glb` is committed at `app/tool/motion/dist/` (read its README); rebuild and commit it after any change to the painting, atlas, or mesh. The page and textures are not committed: rebuild them with the README's commands (needs `pip install xatlas`). Weave model runs: the workspace's 2 free runs are used (2026-10-12); more need a paid Weave plan, and every run needs the owner's yes to the quoted cost first. Before a new painting, measure which views add the most coverage (README, "More paintings"). Phone: the page caps the pixel ratio, uses a smaller shadow map, and steps quality down when frames are slow; `__lab.perf()` reports it. Frame rate on a real phone is not measured yet: test the page on the owner's phone (Latch) before claiming it. Change muscle shapes only in `atlas.py`, and check them in 3D renders against the body icons at the same framing (see the README's `__lab.debug` and `__lab.parts`), not on the flat charts. Do not add Z-Anatomy or BodyParts3D data (CC BY-SA) without the owner's licence decision.
- **Motion Lab** (prototype, not in the app): animates the gym model doing exercises in three.js, with form checks measured on the skeleton. Live demo (sculpted and painted model, 2026-10-12): https://claude.ai/artifact/Gxrcz3spGVHuVqL2Vyov3E (before sculpting: https://claude.ai/artifact/MYT4TBnagnZaCRYAr7UdZW; the older atlas-only demo: https://claude.ai/artifact/JArExRx3VRAxtg3YQW92c2). Moving it into the app is D-038, **Proposed**; do not build it into the app until the owner accepts D-038. Read `app/tool/motion/README.md` before changing a move or a muscle. Run `check.js`; every form check must pass. Never widen a check's range to make it pass.
- **Gym model: known limits and next work** (2026-10-12; pick up from here):
  - Built moves: 5 only (dumbbell curl, goblet squat, push-up, lateral raise, Romanian deadlift; 26 form checks). Every other exercise needs its own start and end pose, tempo, and form checks in `lab.html` (about 10 to 20 lines each; copy the text from the coached guide in `lib/features/exercises/catalog/`).
  - Equipment: only hex dumbbells exist. Barbell, bench, cable stack, pull-up bar, and machines are not built. Build each prop once in `lab.html` and reuse it.
  - Shoulder blade: there is a clavicle bone but no scapula bone, so rows, pull-ups, and overhead presses will look less accurate at the shoulder. Add a scapula bone (with skin weights in `export.py`) before those moves.
  - Hidden areas: the sides of the chest under the arms, the armpits, and the inner thighs have no real paint (diffused paint with drawn fibre strokes). They show in a lateral raise. Fix: one more painting (arms raised, four low three-quarter views; README "More paintings"). Weave needs a paid plan for it; ask the owner first.
  - Stretch: the painting was made on a standing body, so it stretches a little in extreme poses (a deep overhead reach, a split).
  - Red highlight: follows the painted muscle edges where a view sees the muscle clearly; elsewhere it uses the atlas, which can sit a little off. The quads in the squat show small grey gaps.
  - Fingers close as one grip; the thumb is approximate. Toes are one bone a foot.
  - Phone: not tested on a real phone. Frame rate is unmeasured (the cloud browser draws in software). Test the page on the owner's phone (Latch) and read `__lab.perf()`.
  - Not coach-reviewed: the checks prove the model matches the target ranges, not that a coach approved the form.
  - Not in the app: D-038 is **Proposed**. Do not build the Motion Lab into the app until the owner accepts it.
  - The demo link (https://claude.ai/artifact/MYT4TBnagnZaCRYAr7UdZW) is private to the owner's account. Another account rebuilds the page from the repo (README "Rebuild and check").
- Postures follow the app's coached guides. Do not claim a move is coach-verified: the checks prove the model matches the target ranges, not that a coach approved them.

## Verification and handbook updates

- Follow the test plan in handbook/11-open-source-release.md.
- Run checks that match the change.
- Report checks that did not run.
- Update the owning handbook section and related diagram when behavior changes.
- Keep updates small and focused.
- Write documentation in plain English. Aim for about 80% of ASD-STE100. Do not claim formal compliance.
