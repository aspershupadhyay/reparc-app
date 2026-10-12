---
title: Gym workout logging
status: proposed
owner: product-and-engineering
updated: 2026-10-09
---

# Section 4: Gym workout logging

## 4.1 Purpose

Help a user plan, start, record, pause, finish, review, and edit a gym workout. The core log must work offline.

## 4.2 User flow

The Workout tab contains the exercise library, saved plans, workout history, and live logging. Users can add a custom exercise without leaving the workout flow.
See [Screens, design system, and motion](02-experience-and-design.md) for shared set-complete and timer motion rules. See [Product and data diagrams](13-diagrams.md) for the session state diagram.



1. Open Workout.
2. Select a saved plan or start an empty workout.
3. Start the session.
4. Add, reorder, or replace exercises.
5. Record each set.
6. Pause or continue the session.
7. Finish the session or save it as incomplete.
8. Review and correct the saved session.

The app must save each set locally before it tries to sync.

## 4.3 Exercise details

An exercise can have:

- A stable record ID.
- A name.
- A variation.
- Equipment.
- Target muscles, if known.
- Position in this session.
- Optional user note.
- Optional source for exercise instructions.

Let users create custom exercises. Do not require a catalog match before they can log a movement.

### Built-in catalog

The app ships 36 coached exercises in seven body areas: chest, back, shoulders, arms, legs, glutes and hamstrings, and core. They live in `app/lib/features/exercises/catalog/`. Logging a built-in exercise creates one exercise row linked by `catalogId`, so all its history stays together. Users can still create their own exercises. See decision D-016.

### Photo library

The app also bundles 873 exercises from Free Exercise DB (public domain, D-017). Data and photos live in `app/assets/exercises/`. Rebuild them with `app/tool/exercise_library/build.py`.

- **Browse (reorganised 2026-10-12):** Workout → Exercises shows a search field, then a grid of body-part cards (Chest, Back, Shoulders, Arms, Legs, Glutes, Core, and **3D body**), each with its icon and number of exercises, then Tools and the user's own exercises. A body-part card opens one card for each of its muscles (Arms: Biceps, Triceps, Forearms). A muscle card opens that muscle's exercises (`/workout/muscle/:muscle`): "Start here" picks first, then one section for each group (for example Triceps: Lateral head, Long head, Heavy presses), then Stretches and Power and cardio. Each section shows four moves and a **Show N more** button. The full list and the **Add exercise** sheet filter by text, body area, and muscle. Each movement shows once; a coached guide replaces its library twin.
- **Where you train (built 2026-10-12):** one filter replaces the ten equipment chips: **All**, **Gym**, or **Home**. Gym means the move needs weights or gym kit (dumbbells, barbells, machines, cables, kettlebells, and other gym gear). Home means body weight, dumbbells, kettlebells, bands, balls, foam rollers, or small kit such as a chair, a box, an ab wheel, or a jump rope. Dumbbell and kettlebell moves are in both. The choice stays while the app is open and applies to muscle pages, search, the Add exercise sheet, and Swap. Code: `Place` in `app/lib/features/exercises/library/library.dart`.
- **Body icons (built 2026-10-12):** each body area and each muscle has a realistic muscle illustration with only that part lit in red-orange. They replace the drawn figure crops. They were made with Figma's image generation, one prompt per icon in one shared style, and checked by eye for the right muscle. The source sheet is the Figma file "Reparc body icons"; the app assets are `app/assets/body/icons/` (256 px WebP, transparent), made by `app/tool/body_icons/process.py`. Rights in AI-generated images under Figma's terms are **To confirm** before a store release.
- **Body map (built 2026-10-10; moved 2026-10-12):** A shaded 3D body, opened from the **3D body** card on Exercises (`/workout/body`). A sideways drag turns it; **Front**, **Side**, and **Back** snap to a view. A tap selects a muscle and shows its name, what it is, and its number of strength moves; **N exercises**, or a second tap, opens that muscle's exercises (`/workout/muscle/:muscle`). Only sideways drags turn it, so the page still scrolls. Reduced motion turns off the fling and snap animations. Since v0.4.7 the body is a realistic adult figure: MakeHuman's CC0 base mesh, shaped as an athletic young man, with 22 muscle regions drawn on it from anatomy (pectoral fan, trapezius diamond, three deltoid heads, the six-pack rows, quad, hamstring, and calf heads). Seams between muscles and heads show as soft grooves, and soft shadow is baked in. The mesh is one asset file (`app/assets/body/body.bin`, about 820 KB), built by `app/tool/body/build.py` (D-033). Code: `app/lib/features/exercises/body3d/`. Screen readers use the body-part cards; the map itself has a label only.
- **Search:** Gym shorthand works (bi, tris, delts, db, kb, rdl, ohp), plural forms match, and group names match (for example "long head"). Results put name matches first, then coached guides and "Start here" picks, then names that start with the first word, then shorter names. The AI library tool uses the same search (`ExerciseLibrary.search`).
- **Equipment labels:** "Bodyweight" is the one word for no equipment. The source's "other" label is replaced by the kit the name shows (for example Pull-up bar, Weight plate, Sled, Box); what stays "Other" is rare kit. Equipment groups (Bodyweight, Dumbbell, Barbell, Machine, Cable, Kettlebell, Band, Ball, Foam roll, and Other) decide Gym and Home and help search. Plain stretches that the source marks "expert" show as Beginner.
- **Detail:** Start and end photos as a cross-fade loop, muscles, level, equipment, and steps. Tap to pause. With reduced motion the loop does not run; the user switches between the start and end photo.
- **Logging:** A library exercise links by `catalogId` = `lib:<source id>`. The add-exercise sheet in a workout searches the same list. A new exercise in a workout starts with three empty sets. Guide links in a workout open above the live screen (`/learn/guide/:id`, `/learn/move/:id`).
- **Offline:** Everything is in the app bundle. The library makes no network requests.

## 4.4 Set details

Support fields that match the set type:

- Repetitions.
- Load and load unit.
- Duration.
- Distance and distance unit.
- Rest duration.
- Effort rating, if the user enables it.
- Notes.
- Completion state.
- Set type: warm-up, working, drop, or timed.

Do not require every field. A timed set may not have load or repetitions. Keep zero separate from missing.

## 4.5 Logging behavior

- Save valid changes locally at once.
- Show a clear saved state.
- Use the last record as a suggestion only.
- Do not mark a suggested value as complete.
- Keep common number fields easy to reach.
- Support undo after delete or replace.
- Keep set order and timestamps.
- Keep session time and rest time separate.
- Let the user skip an exercise without creating a result.
- Let the user finish a session with incomplete exercises.
- Do not save a session with no done sets. **Finish workout** with no ticked set offers **Keep going** or **End without saving** (built 2026-10-10). The finish sheet counts exercises without warm-up moves, as the plan and History do (from 0.4.15).
- **Swap for a similar move** (exercise options in a live or saved session, built 2026-10-10): moves for the same target muscle and kind. The same group comes first, then other equipment, then hand-picked moves; the All, Gym, or Home filter narrows the list. Logged sets stay, and **Undo** puts the old exercise back. Exercises the user made opens the full picker instead.

**History cards** show the date, name, time without pauses, exercise and set counts, total weight in the user's load unit, and a **PR** badge for each heaviest-load record the session still holds. Total weight is missing, not zero, when no set has a load and reps.

Supersets group exercises. They do not merge set records.

## 4.6 Plans and templates

A template contains an ordered list of exercises and optional targets. Starting a template creates a new session. Later edits to the template must not change a saved workout.

Since schema v5 a template is a **plan** with one or more days (4.12). When a day starts, each exercise gets one empty set for each target set, or one empty set when there is no target. The target shows as a note on the exercise, for example "Target: 3 × 5". It is never saved as a done value.

Let the user rename, copy, edit, and delete templates. Do not require a weekly training split.

## 4.7 Personal records

Every record rule must be named. Examples include the highest completed load for an exercise or the most repetitions at a selected load.

Do not compare unlike units or different exercise variations as the same movement. Let the user inspect the source set for each record.

## 4.8 Timer and interruption behavior

The rest timer is optional. It must not block set entry. Keep an active session after app backgrounding, screen lock, or process restart. Ask before discarding an active session.

Do not promise exact background timer behavior until it passes tests on both operating systems.

## 4.9 Limits

Do not infer exercise form, injury, or medical status. Do not estimate calories from sets. If a connected health source supplies energy data, label the source and time range.

## 4.10 AI context

- **Purpose:** Record a workout with enough detail for later review.
- **Flow:** Select plan, start, log sets, pause, finish, review, edit.
- **Reliability:** Local save comes before sync.
- **Data:** Preserve units, order, time, and source.
- **Safety:** Do not infer form, injury, or calories from set data.
- **Done when:** A session survives offline use, app closure, and restart without losing a set.
- **Catalog:** Built-in, original, 36 exercises (D-016). Coach review is **To confirm**.
- **Roadmaps:** Generated, then owned and edited by the user (D-025). Warm-up first, every day.
- **To confirm:** Effort scale and further personal-record rules.

## 4.11 Browse, roadmaps, and the weight calculator

Built 2026-10-06 (D-024, D-025).

**Browse.** Workout → Exercises shows search, then body-part cards. The tree has three steps: body part, then muscle, then group.

- Areas and muscles: Chest (upper, mid, lower chest), Back (lats, upper back, traps, lower back), Shoulders (front, side, rear), Arms (biceps, triceps, forearms), Legs (quads, hamstrings, calves, inner thighs), Glutes (glutes, outer hips), and Core (abs, lower abs, obliques).
- Groups split a muscle by what the move stresses most, for example Triceps: Lateral head (pushdowns, kickbacks), Long head (overhead and lying extensions), Heavy presses (close-grip presses, dips); Biceps: Brachialis, Long head, Short head, Standard curls. Moves that fit no group are under "More moves". A move joins the first group whose words are in its name. Groups live in `app/lib/features/exercises/library/move_groups.dart`.
- A body-part page shows one card for each muscle. A muscle page shows "Start here" picks first, then each group under its own heading, then stretches and power moves. One filter: All, Gym, or Home.
- The target muscle of a library exercise comes from its main muscle; delt heads, upper, mid, and lower chest, lower abs, and obliques come from the exercise name. Reverse (palms-down) curls count as forearms. Picks live in `app/lib/features/exercises/library/library.dart` (`essentials`).

**Roadmaps.** Workout → Roadmap. The user picks a goal, level, days a week, and where they train. The generator is `app/lib/domain/roadmap.dart`. Rules it follows:

- Each muscle about twice a week.
- Every exercise gets at least 3 working sets (owner request 2026-10-08). Sets rise with level (beginner 3, intermediate 3–4, advanced 4–5). Reps in reserve fall with level (3, 2, 1).
- Rep ranges by goal: strength 3–5 on main lifts; muscle and look 6–10 main, 10–15 extras; lean & fit 8–15 with short rest and a cardio finisher; calisthenics 5–10 with a level-based progression for each movement.
- Every day starts with 5 minutes of easy cardio and 4 joint moves for the day's focus. The first loaded main lift gets ramp-up sets (about 50%, 70%, and 85% of the working weight; beginners do two). Body-weight moves (home setup, calisthenics, and pull-ups) get none, because the shares need a working weight.
- Every exercise has a version for a full gym, dumbbells, and home. The user can swap to any of them or to any library exercise.
- Each plan has a progression rule and an easy-week (deload) rule by level.

**Starting.** The Workout tab has one start card at the top. It shows the live workout, else the next roadmap day, else an empty workout. With a roadmap, **Start workout** starts the next day at once, **See the day** opens the day page, and **Empty workout** starts a workout with no exercises. Home's main card starts the same next day. Any day in the week list opens its day page, which has its own **Start workout** button. All start buttons use one function (`app/lib/features/workout/start_workout.dart`). If a workout is already live, they open it instead. On the Exercises and History views the start card folds to one row (D-032).

**Day page (D-032).** The day name is the large title, with one summary line. Warm-up and cool-down fold to one summary row each; tap to open them and see the coaching notes. The main lift has a **Main lift** label and a larger name. Each row shows sets × reps only; rest and reps in reserve are in the edit sheet and the screen-reader label. One **How this day works** link holds the help text.

**In the workout.** The day's warm-up moves come first. Each move gets one warm-up set for each set on the day page (a timed move shows its time). Then the working exercises. Each has a note with the same target line as the day page, for example "Target: 3 × 6–10 · 2:30 min rest · 2 reps left". The first loaded main lift also gets ramp-up sets, and its note gives their weights, for example "50% × 8, 70% × 5 of your working weight". Cool-down stretches show on the day page only; they are not logged. Warm-up sets never count toward volume, set counts, exercise counts in History, or records. Targets are never saved as done values.

**Moving on.** The next day is the one after the last finished day, in roadmap order. Saving a workout as incomplete does not move the roadmap. The user can pick the next day in Customize. Training days are saved only when their number matches the roadmap's days. The plan is JSON in `programs.plan`; the user can change any part.

**Builder.** Changing the goal or level keeps the chosen days a week when the goal offers that number.

**Weight calculator.** Workout → Exercises → Weight calculator (`app/lib/domain/strength.dart`).

- From a set: estimated one-rep max is the mean of the Epley and Brzycki formulas. Reps in reserve add to the reps. Above 10 reps the app warns that the estimate is less reliable. Weights for 1–15 reps and for each goal are rounded down to the next 2.5 kg or 5 lb.
- First time: a cautious first weight for about 10 reps from experience level and body weight, lower for women, then a reps-left test that adjusts it by −5%, 0, +5%, or +10%. These ratios are starting guesses, not strength standards.

**To confirm:** Coach review of the picks, roadmaps, warm-ups, and first-weight ratios.

## 4.12 One plan for roadmaps and plans

**Status:** Accepted and built 2026-10-08 (D-030). The owner took the recommended choice for all four owner choices at the end of this section. Not yet tested on a real phone.

### Purpose

The app has two ways to plan training. A **plan** (`workout_templates`) is one workout. A **roadmap** (`programs`) is a training week. They use different tables, screens, and AI tools. An AI suggestion becomes plans, but an imported AI file becomes a roadmap. Users must learn both. This change makes one thing: a **plan** with one or more days.

### The model

- A plan has 1–7 days. Each day is the same `PlanDay` that roadmaps use now: warm-up, exercises with targets, cool-down.
- A roadmap is a plan made by the builder. It also keeps its goal, level, and equipment.
- A plan the user makes, an old plan, and an AI plan have no goal. They usually have no warm-up.
- The user can **follow** one plan at a time. The followed plan sets Home's main card and the "next day". Finishing a day of the followed plan moves it on, as today.
- The user can start any day of any plan at any time. That does not change the followed plan.
- All plans stay in one table, `programs`. The JSON in `programs.plan` stays the source of the days.

### User flow

1. Workout has three sections: **Plan**, **Exercises**, **History** (was Roadmap, Plans, Exercises, History).
2. **Plan** shows the followed plan's week first, then **Other plans**. With no plans, it shows the goal cards, as Roadmap does now.
3. **New plan** asks: **Build for my goal** (the roadmap builder) or **Make my own** (an empty plan with one day).
4. A plan page lists its days. The user can add, rename, reorder, and remove days, and **Follow this plan**, **Copy**, or **Delete**.
5. A day page is today's roadmap day page. **Add exercise** also offers the user's own exercises.
6. The start card at the top of Workout does not change.

### Data and migration (schema v5)

- `PlanItem.exerciseId` gets a third form: `user:<exercise id>` for an exercise the user made. Built-in guides (`bench-press`) and library moves (`lib:…`) do not change. Starting a day uses that row directly.
- `ProgramPlan.goal`, `level`, and `setup` become optional. The plan's name comes from `programs.name`, so the user can rename it. For a plan without a goal, the `goal`, `level`, and `equipment` columns hold `custom`.
- The v4 → v5 migration copies each old plan into `programs` with the same ID, one day, and `active = false`. Each exercise becomes one item: sets from `target_sets`, reps from `target_reps`. A missing target stays missing: the item gets one set and no reps, which starts exactly as today. A custom exercise gets a `user:` reference, and a built-in one keeps its `catalog_id`.
- Sessions that came from an old plan get `program_id` (the same ID) and `program_day = 0`. `template_id` stays as it is.
- The old tables stay in v5, but the app stops reading or writing them. If the copy fails, the migration stops, and nothing is lost. A later version removes the tables after the copy is proven on real phones.
- Export v5 has no template tables. Import of a v4 or older file copies its plans with the same function the migration uses.
- Encrypted backups restore through the normal migration.

### AI

- `propose_workout_plan` keeps its name and input. Approving a proposal makes **one** plan with one day for each proposed workout, not up to seven separate plans. It is saved, not followed. The user taps **Follow** if they want it.
- `list_workout_plans` returns every plan with its days. `get_roadmap` stays and returns the followed plan.
- The tool text in `app/lib/ai/contract.dart` and `gateway/src/contract.ts` changes, so the owner must redeploy the gateway.
- Proposals that are already waiting still approve, because their stored format does not change.

### States and failure paths

- **Migration failure:** The app shows the database error screen. The v4 data stays as it was. A test must prove this.
- **A plan whose exercise was archived:** The day still starts. The archived exercise is logged, as saved workouts do now.
- **Deleting the followed plan:** Ask first. Afterwards nothing is followed, and Home shows **Start workout**.
- **Deleting a plan:** Saved workouts keep their exercises and sets. `program_id` stays as a plain value.

### Build order

1. **Domain:** optional goal; `user:` references; one function that turns an old plan into a plan. Unit tests.
2. **Migration v5:** the copy, a `schema_v4.sql` fixture, and a migration test that checks every plan, item, target, and session link.
3. **Repository:** list, create, copy, rename, delete, follow, and day editing in `ProgramRepository`. Remove the template methods from `WorkoutRepository`. Export and import.
4. **AI:** proposal approval, `list_workout_plans`, tool text, gateway contract, and their tests.
5. **Screens:** the Plan section, the plan page, the new-plan choice, and the shared day page. Remove `plan_screen.dart` and the Plans section.
6. **Handbook:** 4.6, 4.11, data model (7.2, 7.5 schema history), AI (section 10), diagrams, build progress, and release notes.

Run format, analysis, generated-code checks, and all tests after each step. Test the migration on a real phone with real v4 data before release.

### Acceptance checks

- Every old plan, exercise, target, and session link survives the migration (test).
- A plan with no targets starts with one empty set for each exercise, as today.
- An AI proposal with three workouts makes one plan with three days, and nothing is followed until the user chooses.
- The Workout tab has three sections, and the user can reach every plan in two taps.
- Screen readers name each plan, day, and Follow button. Large text does not cut off day names.

### Owner choices (decided 2026-10-08: the first option of each)

1. **Name.** Call the one thing a **plan** ("Build a plan for my goal"), or call everything a **roadmap**. Recommended: plan.
2. **Old tables.** Keep `workout_templates` and `template_exercises` for one release, then remove them (recommended). Or remove them in v5.
3. **AI proposals.** Several proposed workouts become one plan with days (recommended). Or each workout becomes its own one-day plan.
4. **Following.** An approved AI plan or a new own plan is not followed until the user taps Follow (recommended). Or it is followed at once, as an imported roadmap is now.

**First-run setup (2026-10-10, launch review Block 2, owner choice).** A user with no plan and no saved workout, who has not finished or skipped the setup, sees "Get your plan" on Home instead of a blank workout. The setup asks three questions, one per screen: goal (the five roadmap goals), level (beginner, intermediate, advanced), and days a week (the goal's options, with the suggested one marked). It then builds and follows that roadmap for a full gym and shows "Your first workout" with **Start now** and **Later**. **Skip** is always there, and the setup does not come back after it is finished or skipped (setting `onboarded`). Equipment is not asked; the user can build another plan in Workout. Code: `app/lib/features/onboarding/welcome_screen.dart`.

**First-day help (2026-10-10, launch review Block 3, owner choice: draft, marked unreviewed).** The first time an exercise from the coached guide is in a live workout (no completed set of it in a saved workout yet), its card offers **First time? Set up**: the guide's setup steps (seat, pads, grip, stance), the line "Not yet checked by a coach.", and **Machine taken? Swap**, which opens the same swap as the exercise menu. It goes away once the exercise has a completed set in a saved workout. A qualified coach review of the text is still open (D-016). Code: `_FirstTimeSetup` in `app/lib/features/workout/session_editor.dart`.

## 4.13 Guided workout and voice cues

Built 2026-10-08 (D-031). Owner request: less typing, timers that run on their own, and a voice that says when a set or rest starts and ends. Not yet tested on a real phone.

**Flow (updated 2026-10-08, second owner review: "no user intervention").** By default the whole workout runs on its own, on times the user chooses in Me → Workout guide:

1. **Warm-up.** The user taps **Start workout**. Warm-up moves follow each other with **no rest** between them. A timed move (5 min on the bike) keeps its time. A move done for reps (arm circles) lasts **Each warm-up move** (Auto: about 3 s a rep).
2. **Rest after warm-up.** After the last warm-up move comes one rest, **Rest after warm-up** (default 1 min).
3. **Sets.** Each exercise starts with 3 sets. A set lasts **Each set** (Auto: about 3 s a rep; a timed set keeps its time), then the rest starts: **Rest between sets** (Auto: the plan's rest, else 90 s). A ramp-up set rests 60 s. At the end of the rest the voice counts "Three, two, one" and the next set starts. The next exercise follows in the same way, until every set is done.
4. **Next set filled in.** When a working set ends, the next set of the same exercise is filled in from it if it is empty. **Next set: Same** copies the weight and reps. **Next set: Pyramid** adds 2.5 kg (5 lb) and takes off 2 reps (not below 1). The filled set is not marked done; the user can change it. Missing values stay missing.
5. "Workout complete. Great work!" plays when the user finishes and saves the workout, not before.

The user can still tap **Set done**, **Start now** (ends the rest early), **+15 s**, **Stop timer**, or **End rest** at any time.

**Taps at a change (launch review, 2026-10-10).** The main button changes in place: "Skip rest" becomes "Set done" when the next set starts on its own, and "Set done" becomes "Skip rest" when a rest starts. A tap on the main button in the first 1.5 s after a set or rest starts is ignored, because it was meant for the button before. This stops one late tap from ticking a new set with no weight or reps, or skipping a rest by a double tap. The tick in the set list is not affected (`GuideController.tapSetDone`, `tapSkipRest`).

**Switches.** Me → Workout guide → **Run on its own**: **End each set on time** and **Start the next set on its own**. Both are on by default. With them off, the user starts each set and taps **Set done**, as in the first review. A set that ended on a set time (not a timed set) saves no duration, because the time is a setting, not a measurement.

**Pause.** Pause stops the set clock and the rest. "Paused." and "Back to it." cut off any cue that still plays. On resume the rest goes on from where it was (`WorkoutRepository.resume` moves the rest start by the paused time).

**Stop.** **Stop timer** (set) and **End rest** (rest) are quiet text buttons, away from **+15 s**. They cut off the voice. **+15 s** adds time to a timed set or to the rest.

**What is saved.** Only measured values. The duration of a rep set is the time from **Start set** to **Set done**. A timed set that ran to its time saves that time. A rep set that ended on a guessed time saves none. A time the user typed on a rep set is kept. The rest really taken is saved on the set before, when the next set starts. The guide never saves reps or load; the user types those. **One-tap set (2026-10-10, launch review Block 3):** when the user ticks a set whose weight or reps are empty, the values shown as hints (the set before, or the plan's target reps) are saved, so ✓ means "I did what was planned". This happens only on the user's tap, never when a set ends on its timer; a field with no hint stays empty. When a set becomes done (its time ran out, or a tap), a weight, reps, or time that is on screen but not saved yet is saved first, so nothing the user typed is lost. A value the app wrote, such as a measured time, is never overwritten (`SetRow._saveTyped`, launch review 2026-10-10). Ticking a set in the list also starts the right rest.

**Screen.** While the guide runs a live workout the screen stays on, so cues play on time (`core/screen_awake.dart`, shared with AI connections). It goes off when the workout ends or the guide is off.

**Voice.** 33 short cue clips and 95 exercise names in two ElevenLabs voices, Charlie and Matilda, bundled in `app/assets/voice/` (about 3 MB). `app/tool/voice/postprocess.py` cuts silence at both ends, sets each clip to the same loudness (mean −18 dB, peaks under −1 dBFS), and saves 96 kbps mono MP3. The app loads the clips of the chosen voice when a workout starts, and a new cue can cut off old cues. It lowers other audio, such as music, while a cue plays. No network request, and no workout data leaves the phone.

**Voice script (recorded 2026-10-08).** `app/tool/voice/phrases.json` holds the coach script for the `eleven_v3` model, with audio tags such as `[energetic]` that set the tone and are not spoken. `generate.py` makes a clip again when its text, model, or settings differ from `tool/voice/generated.json`, the record of what each bundled clip was made from. Run `python3 tool/voice/generate.py --dry-run` to see what would change. It reads the key from `ELEVENLABS_API_KEY` and never stores it.

**Exercise names.** The voice names the next exercise: "Next up: Bench press." `tool/voice/names.py` lists the coached exercises and the library exercises that plans use (95 names), with the name the plan shows. It writes `tool/voice/names.json` and `lib/domain/voice_names.dart`. Clips are in `assets/voice/<voice>/names/`. An exercise without a clip, such as one the user made, gets "Next exercise coming up."

**Cues and switches (2026-10-08).** One set of rules (`setPlan`, `restPlan`, `cueBetween` in `app/lib/domain/guide.dart`) drives both the live voice and the lock-screen alerts, so they never disagree. All cues are on by default; Me → Training has a switch for each:

- **Halfway**: in a timed set of 30 s or more.
- **Ten seconds left**: in a rest of 20 s or more. When the next set is on a new exercise, the next exercise is named here.
- **3-2-1 countdown**: one word a second, before the end of a rest or a timed set of 8 s or more, with a light haptic.
- **End of rest and set**: "Time! Good set." and "Rest is up. Start when you're ready." With **Start next set on its own**, the next set's cue ends the rest instead.

A cue is said only within 2 s of its time, and a late tick says only the latest cue, so nothing stale plays after the phone wakes.

**Ramp-up sets.** Their reps and share come from the exercise note ("50% × 8, 70% × 5"). The panel shows "8 reps at 50%", and the set time uses those reps.

**Ring clock (2026-10-09, owner request).** The live workout header is a two-ring clock (`app/lib/features/workout/ring_clock.dart`, `guided_header.dart`). The outer ring is the whole session: one segment for each set, white when done, the set now lit in the phase colour. The inner ring fills as the set or rest runs, with a bright head at "now". Colours by phase, from the shared palette (dark values, because the panel is dark in both modes): warm-up orange to lime, set coral to orange, rest blue to teal, paused grey. The middle holds one word for the phase and the clock. Under the rings: the exercise and one line (the aim, or "Next · …" in a rest). Controls in fixed places: +15 s, one white main button (Set done, Skip rest, Start), stop. As the sets scroll up, the header folds to one slim row with a small ring, the clock, and the main button, so the clock never leaves the screen. Exercise cards show the plan target as small chips; ramp-up sets show their own reps; fields show their unit. With reduced motion the inner ring jumps instead of gliding.

**Phone locked (Speak when locked, on by default).** Who speaks depends on where the app is. On screen, the live voice speaks. When the app goes off screen (locked or another app in front), the live voice stops and the app sets the cues still to come as local notifications that play the same voice clip. When sets end and start on their own, every time ahead is known, so the app sets the whole chain: each set start ("Set two. Go!", "Last set.", "Warm-up."), countdowns, set ends, and rests, up to 150 alerts or 2 hours ahead. It stops at a set that waits for **Set done**. Back on screen, the app catches up: every set that the alerts said started, and that ended on its time, is saved as done at the time the alerts said; then the live voice goes on. A set the alerts did not announce waits for the user. Set-start clips are copies of the bundled clips (no new recordings). Back on screen, every alert is removed. On Android a quiet, ongoing card on the lock screen shows the rest or set clock (a system chronometer) and the next set. Countdown and other short alerts leave the screen after 4 s; end alerts after 2 min. The phone's silent mode and Do Not Disturb apply. Android 14 and later need **Alarms & reminders** for alerts on the second; Me → Training offers it. Without it, only the end cues are set, because Android may deliver them late. The app asks for the notification permission once, on the first guided rest. Sound files: `app/android/app/src/main/res/raw/` (MP3) and `app/assets/voice/alerts/` (CAF for iPhone, copied to Library/Sounds on start), made by `app/tool/voice/alert_sounds.py`. Code: `app/lib/features/workout/lock_alerts.dart`.

**A set that ends while locked.** A timed set that ran out while the phone was locked ends at its set time, not when the app wakes: the saved time is the set time, the set is done at that instant, and the rest starts there.

**Plan time and measured time (schema v6).** A set has two time fields. `targetSec` is the time the plan asks for, such as a 45 s plank. `durationSec` is the time the set measured or the user typed. A plan day writes only `targetSec`. The set row shows the target as the hint. The v6 upgrade moves a target out of `durationSec` for open sets from a plan that have a time and no reps (`AppDatabase.moveTargetTimes`). Done sets keep their time.

**Set rows (2026-10-08).** Each set has weight, reps, and time. The time hint shows the set time the guide assumes. A done set has a dark-green check and a green tint (Energy strong, 5.2:1 on white). The set being timed has a teal outline. Warm-up sets show "W". The next set offers **Same as last set**: one tap fills the last set's weight and reps; it does not mark the set done. In a live workout, a finished exercise folds to one line; tap it to open it.

**Settings.** Me → Training has **Guided workout** (off gives the old manual rest chips) and **Times and voice**, which opens Me → Workout guide: **Times** (Each warm-up move, Rest after warm-up, Each set, Rest between sets, Next set), **Run on its own** (two switches), and **Voice** (Charlie, Matilda, or Off; Speak when locked; one switch per cue).

**Limits (To confirm).**

- The running set (its start, set time, and the last alerted set start) is saved in settings (`guide.running`), so after the app is closed and opened again, the set goes on, a timed set ends at its time, and the catch-up above runs. On start the app removes every lock-screen alert set before it closed, because those alerts no longer match the record.
- With sets that end on time, the saved weight and reps are what the set row holds (typed, or filled in from the set before). The app cannot know if the user really did them. A running rest survives a restart, because it is saved on the session.
- The screen stays on during a guided workout. If the user locks the phone, the lock-screen alerts speak. They cover what is known ahead: a rep set has no set end, so its rest is set only after **Set done**.
- iPhone has no live lock-screen clock (that needs a Live Activity, a native widget extension; not built).
- On iOS, music may stay lowered after a cue. Check on a device.
- Exercises the user made are not named by the voice. A clip for each would need a network call; the app makes none.
- License: the clips were made on the owner's free ElevenLabs plan (non-commercial). A store release needs a paid plan and the clips made again (D-031).
- Screen reader: the set time has a spoken label. Check VoiceOver and TalkBack on devices.
- Code: `app/lib/domain/guide.dart` (rules), `app/lib/features/workout/guide_controller.dart`, `voice.dart`. Tests: `app/test/guide_test.dart`.

## 4.14 GPS runs, walks, and rides

Built 2026-10-12 (D-037, owner request: "full Strava like for running and walking and cycling"). Owner choices: GPS keeps recording with the screen off, with a notification; MapTiler free tier for maps; schema v7. **Not tested on a real phone yet.**

### Purpose

Measure a run, walk, or ride (distance, pace or speed, time, route, splits, climb) as precisely as the phone's GPS allows, on the phone, with no account.

### User and trigger

- **User:** anyone who runs, walks, or cycles, with or without gym training.
- **Trigger:** Workout tab → **Run**, **Walk**, or **Ride** (three buttons under the start card).
- **Preconditions:** no gym workout in progress; location allowed "while using the app"; the phone's location on.

### User flow

1. The user taps **Run**. The first time, the phone asks for location ("while using the app" only; RepArc never asks for "Allow all the time").
2. The recording screen opens: GPS signal, the route, time, distance, pace now, and average pace (rides: speed in km/h or mph).
3. The user puts the phone away. Android shows the notification "Recording your run"; iPhone shows its blue location indicator. Recording goes on with the screen off or in another app.
4. **Pause** turns GPS off and stops the clock. **Resume** starts a new segment, so no distance is counted across the pause (a bus ride during a pause adds nothing).
5. **Finish** → **Finish and save** opens the activity page: map, distance, average pace or speed, moving time, elapsed time, climb, top speed, and splits per km or mile. **Discard** asks again before it deletes. With no distance yet, the sheet offers **Keep going** or **End without saving**.
6. The activity shows in Workout → History with the gym workouts, newest first. The page can rename or delete it.

### How precise it is (`app/lib/domain/track.dart`)

- Raw GPS fixes are saved as the phone gives them (about one a second). All filtering happens when numbers are worked out, so a better rule can recompute old activities.
- Fixes with poor accuracy are dropped (over 20 m for runs and walks, 25 m for rides), and so is any fix that would need a speed the activity cannot reach (over 11 m/s running, 4 m/s walking, 25 m/s riding): a GPS jump or a car.
- A Kalman filter smooths position, weighing each fix by its accuracy against how far the user could have moved. Raw GPS zig-zags a few metres to each side, which adds about 10% to a walk.
- A step counts only when it is longer than the two fixes' uncertainty, so standing still adds no distance. Each segment ends at its last raw fix, so the smoothing lag is not lost.
- Moving time leaves out stops (slower than 0.4 m/s walking, 1 m/s running, 1.5 m/s riding) and gaps over 60 s. Pace is moving time over distance. Splits are interpolated to the exact point where each km or mile was reached.
- Climb uses GPS height with a 3 m dead band; it is an estimate. Top speed is over at least 10 seconds.
- Tests (`app/test/track_test.dart`): a noisy 1 km walk (±4 m on every fix, five seeds) measures within 3%; a square route keeps its corners; 10 minutes standing still adds less than 15 m; jumps and poor fixes are dropped; nothing is counted across a pause.
- **Limits:** GPS under trees, between tall buildings, and indoors is worse; a treadmill run measures nothing. Phone GPS is usually within 1–3% on an open route. **To confirm:** checks against a measured route on real phones.

### Data

- **Create:** `activities` (kind, name, status, start, end, paused time, segment, UTC offset, time zone, distance in metres, moving seconds, climb in metres, top speed in m/s, note) and `activity_points` (time, latitude, longitude, accuracy, altitude, altitude accuracy, segment). Schema v7 with a tested upgrade from v6.
- **Read:** the points, to draw the route and work out the numbers.
- **Update:** name and note. The summary is saved at **Finish**.
- **Delete:** one activity with its points (cascade), or everything in Me → Export or delete. Export and backup include both tables under a new `activity` scope; the AI file export leaves routes out unless the user ticks **Runs, walks, and rides**.
- **Units and time:** metres, seconds, and m/s stored; km or mi from Me → Units. UTC instants with the start's UTC offset.
- **Retention:** until the user deletes it.

### States and failure paths

- **Location refused:** nothing starts; a message says why. **Refused for good:** a **Settings** action. **Location off:** a **Turn on** action.
- **Weak or no GPS:** "Weak GPS" or "Finding GPS" above the map; fixes that are too poor are not used.
- **GPS lost** (location switched off mid-run): "GPS lost. Is location on?" The recording waits; fixes count again when they come back.
- **App closed or the phone restarts:** fixes are saved every 3 seconds, so at most 3 seconds are lost. When RepArc opens again, recording goes on (the app shell restarts GPS); the gap is a straight line if the speed is possible, else a new start.
- **Two things at once:** a GPS activity cannot start while a gym workout runs, and only one activity records at a time.

### Privacy and security

- Routes are where the user lives and trains. They stay on the phone and are never sent to RepArc or any server.
- **Map tiles:** builds with a MapTiler key load map images from MapTiler while a map is on screen. Those requests show MapTiler roughly which area is on screen. Without a key, routes are drawn on a plain grid and no map request is made. The key is a GitHub secret (`MAPTILER_KEY`), passed at build time; it is not in the repository.
- Permissions: location while in use (`ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`), a location foreground service (`FOREGROUND_SERVICE`, `FOREGROUND_SERVICE_LOCATION`) on Android; `NSLocationWhenInUseUsageDescription` and the `location` background mode on iPhone. No background location permission.
- Logs never contain coordinates.

### Accessibility and motion

- Run, Walk, and Ride buttons are named "Record a run with GPS" and so on. Each large number on the recording screen reads as one phrase ("Distance 2.31 km"). The map has a text label. Splits read as "Km 3, 5:12 /km".
- Large text: numbers scale down to fit their box instead of cutting off.
- Buttons are 64 dp high for use while moving. Haptics confirm start, pause, and finish. No motion besides the map following the user.

### Analytics and reporting

- **User progress:** distance, moving time, pace, climb, and splits per activity. Analytics → Workout does not count activities yet (**To confirm** with the owner).
- **Product-use events:** none.

### Health apps

With **Write → Workouts** on (Me → Health apps), each finished run, walk, or ride with distance is written once to Health Connect or Apple Health as a running, walking, or biking workout with its start and end. Distance and route are not written: that needs separate write permissions RepArc does not ask for.

### Acceptance checks

- [x] Numbers from points: distance, moving time, pace, splits, climb, top speed (`track_test.dart`).
- [x] Start, pause, resume, finish, discard, restore after restart, and refused permission (`recorder_test.dart`, `activity_flow_test.dart`).
- [x] v6 to v7 upgrade, export, restore, and delete (`migration_test.dart`, `activity_repository_test.dart`).
- [x] Health write of activities once each (`health_sync_test.dart`).
- [ ] On a real Android phone: a run with the screen off, the notification, battery use over an hour, and distance against a measured route.
- [ ] On an iPhone: background recording and the blue indicator.
- [ ] TalkBack and VoiceOver on the recording screen.

### AI context

- **Purpose:** record GPS runs, walks, and rides on the phone, precisely, with no account.
- **Must preserve:** raw points stay raw; missing summary values stay null; nothing is counted across a pause; routes never leave the phone except as map tile requests and user exports.
- **Must not:** ask for background ("all the time") location; send coordinates to any server; write routes to a health app without a new owner decision.
- **Code:** `app/lib/domain/track.dart`, `app/lib/data/activity_repository.dart`, `app/lib/activity/`.
