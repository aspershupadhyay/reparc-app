---
title: Gym workout logging
status: proposed
owner: product-and-engineering
updated: 2026-10-06
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

- **Browse:** Workout → Exercises shows a search field, body-area tiles with counts, the coached guides, and the user's own exercises. The full list filters by text, body area, and equipment. Each movement shows once; a coached guide replaces its library twin.
- **Detail:** Start and end photos as a cross-fade loop, muscles, level, equipment, and steps. Tap to pause. With reduced motion the loop does not run; the user switches between the start and end photo.
- **Logging:** A library exercise links by `catalogId` = `lib:<source id>`. The add-exercise sheet in a workout searches the same list. A new exercise in a workout starts with one empty set. Guide links in a workout open above the live screen (`/learn/guide/:id`, `/learn/move/:id`).
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

**Browse.** Workout → Exercises shows search, then seven body areas. An area opens its muscles: Chest (upper chest, mid and lower chest), Back (lats, upper back, lower back), Shoulders (front, side, rear), Arms (biceps, triceps, forearms), Legs (quads, hamstrings, calves, inner thighs), Glutes, and Core (abs, obliques). Each muscle shows "Start here" picks first, then more options. Filters: Strength, Stretch, or Power & cardio, and one equipment type. The target muscle of a library exercise comes from its main muscle; delt heads, upper chest, and obliques come from the exercise name. Picks live in `app/lib/features/exercises/library/library.dart` (`essentials`).

**Roadmaps.** Workout → Roadmap. The user picks a goal, level, days a week, and where they train. The generator is `app/lib/domain/roadmap.dart`. Rules it follows:

- Each muscle about twice a week.
- Sets per exercise rise with level (beginner 2–3, intermediate 3–4, advanced 4–5). Reps in reserve fall with level (3, 2, 1).
- Rep ranges by goal: strength 3–5 on main lifts; muscle and look 6–10 main, 10–15 extras; lean & fit 8–15 with short rest and a cardio finisher; calisthenics 5–10 with a level-based progression for each movement.
- Every day starts with 5 minutes of easy cardio and 4 joint moves for the day's focus. The first loaded main lift gets ramp-up sets (about 50%, 70%, and 85% of the working weight; beginners do two). Body-weight moves (home setup, calisthenics, and pull-ups) get none, because the shares need a working weight.
- Every exercise has a version for a full gym, dumbbells, and home. The user can swap to any of them or to any library exercise.
- Each plan has a progression rule and an easy-week (deload) rule by level.

**Starting.** The Workout tab has one start card at the top. It shows the live workout, else the next roadmap day, else an empty workout. With a roadmap, **Start** starts the next day at once, **See the day** opens the day page, and **Empty workout** starts a workout with no exercises. Home's main card starts the same next day. Any day in the week list opens its day page, which has its own **Start workout** button. All start buttons use one function (`app/lib/features/workout/start_workout.dart`). If a workout is already live, they open it instead.

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

## 4.13 Guided workout and voice cues

Built 2026-10-08 (D-031). Owner request: less typing, timers that run on their own, and a voice that says when a set or rest starts and ends. Not yet tested on a real phone.

**Flow (updated 2026-10-08 after a review of the guide).** The user starts each set and ends each rep set. The guide times, speaks, and counts the rest. It does not guess when a lift is done.

1. In a live workout, the panel shows the next set and its aim, such as "Next · Bench press · set 2 of 4" and "60 kg × 8". The weight and reps come from the set, else the set before, else the plan target.
2. Tap **Start set**. The voice says "Set two. Go!", "Last set. Make it count!", "Warm-up. Nice and easy." for a warm-up move, or "Go!" for a ramp-up set.
3. The set clock is the big number. A rep set counts up until the user taps **Set done**. A timed set counts to its time, says "Halfway." in a long set, says "Time! Set done." and ends on its own.
4. The rest comes from the plan (the "rest" in the exercise note). Else it is the **Default rest** in Me → Training, else 90 s. A warm-up move rests 20 s. A ramp-up set rests 60 s. The voice says "Rest. Ninety seconds." The rest clock is the big number.
5. At 10 s left it says "Ten seconds." When the next set is on a new exercise, it adds "Next exercise." here, so the set cue plays at the start of the set.
6. At the end it says "Rest over. Get ready." with a strong haptic. The clock shows "Rest over by". The user taps **Start set**.
7. "Workout complete. Great work!" plays when the user finishes and saves the workout, not before.

**Switches for a hands-free workout.** Me → Training → **Start next set on its own** (off by default): at the end of the rest the voice counts "Three", "Two", "One", one word a second with a light haptic, and the next set starts. **Finish rep sets on time** (off by default): a rep set ends on a set time, from **Set time** (30–90 s) or about 3 s a rep. A set that ends on a guessed time saves no duration.

**Pause.** Pause stops the set clock and the rest. "Paused." and "Back to it." cut off any cue that still plays. On resume the rest goes on from where it was (`WorkoutRepository.resume` moves the rest start by the paused time).

**Stop.** **Stop timer** (set) and **End rest** (rest) are quiet text buttons, away from **+15 s**. They cut off the voice. **+15 s** adds time to a timed set or to the rest.

**What is saved.** Only measured values. The duration of a rep set is the time from **Start set** to **Set done**. A timed set that ran to its time saves that time. A rep set that ended on a guessed time saves none. A time the user typed on a rep set is kept. The rest really taken is saved on the set before, when the next set starts. The guide never saves reps or load; the user types those. Ticking a set in the list also starts the right rest.

**Screen.** While the guide runs a live workout the screen stays on, so cues play on time (`core/screen_awake.dart`, shared with AI connections). It goes off when the workout ends or the guide is off.

**Voice.** 33 short clips in two ElevenLabs voices, Charlie and Matilda, bundled in `app/assets/voice/` (about 1 MB). `app/tool/voice/postprocess.py` cuts silence at both ends, sets each clip to the same loudness (mean −18 dB, peaks under −1 dBFS), and saves 96 kbps mono MP3. "Three", "Two", and "One" were cut from the first "Three. Two. One." clip. The app loads the clips of the chosen voice when a workout starts, and a new cue can cut off old cues. It lowers other audio, such as music, while a cue plays. No network request, and no workout data leaves the phone.

**Voice script (ready, not recorded).** `app/tool/voice/phrases.json` holds a warmer coach script for the `eleven_v3` model, with audio tags such as `[energetic]`. `generate.py` makes a clip again when its text, model, or settings differ from `tool/voice/generated.json`, the record of what the bundled clips were made from. Run `python3 tool/voice/generate.py --dry-run` to see the list. It needs `ELEVENLABS_API_KEY`. The bundled clips still use the first script.

**Set rows (2026-10-08).** Each set has weight, reps, and time. The time hint shows the set time the guide assumes. A done set has a dark-green check and a green tint (Energy strong, 5.2:1 on white). The set being timed has a teal outline. Warm-up sets show "W". The next set offers **Same as last set**: one tap fills the last set's weight and reps; it does not mark the set done. In a live workout, a finished exercise folds to one line; tap it to open it.

**Off switches.** Me → Training → **Guided workout** (off gives the old manual rest chips), **Voice** (Charlie, Matilda, or Off), **Start next set on its own**, **Finish rep sets on time**, and **Set time**.

**Limits (To confirm).**

- The set timer lives in memory. After the app restarts, tap **Start set** again. A running rest survives a restart, because it is saved on the session.
- The screen stays on during a guided workout. If the user locks the phone or leaves the app, iOS stops timers, so cues may not play there. Android may also delay them. A local notification for the end of a rest needs a notification permission and is not built (owner choice needed).
- On iOS, music may stay lowered after a cue. Check on a device.
- The plan target time of a timed set and the measured time share one field (`durationSec`). Keeping them apart needs a database migration (owner choice needed).
- Exercise names are not spoken. Each name needs its own clip.
- Screen reader: the set time has a spoken label. Check VoiceOver and TalkBack on devices.
- Code: `app/lib/domain/guide.dart` (rules), `app/lib/features/workout/guide_controller.dart`, `voice.dart`. Tests: `app/test/guide_test.dart`.
