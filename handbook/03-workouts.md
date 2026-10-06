---
title: Gym workout logging
status: proposed
owner: product-and-engineering
updated: 2026-10-05
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
- **To confirm:** Effort scale and further personal-record rules.
