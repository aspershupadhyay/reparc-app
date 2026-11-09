---
title: Platform design audit (Apple HIG and Android)
status: review
updated: 2026-11-09
---

# Platform design audit, 2026-11-09

**Owner request (2026-11-09):** audit the app against Apple's Human Interface
Guidelines and Android's design guidance, read every page, watch the Apple
design video in the VoiceBox folder "Apple Design Videos", make a reusable
skill, and make the app premium, easy, and free of clutter.

Items marked **Fixed** are in the app. Items marked **Proposed** are not
accepted decisions; they need the owner's yes.

## Scope

- **Read:** all 173 Apple HIG pages, including the design principles page that
  Apple reintroduced in June 2026; all 38 Android design pages under
  developer.android.com/design (the 36 mobile pages and the two overview
  pages); the WWDC26 session 250 talk on design principles (transcribed from
  the owner's file).
- **Checked in code:** Home, Meal, Analytics empty state, the tab shell, theme
  and page transitions, dialogs, permissions, the Android manifest.
- **Not checked:** a real phone, TalkBack or VoiceOver, 200% text on a device,
  a 360 dp screen. These need the owner's phone (Latch) and the next release.
- **Skill:** `.claude/skills/mobile-design-audit/` holds the method and our
  summaries of both guides. Copy the folder to `~/.claude/skills/` to use it
  in other projects.

## What already meets the guides

- Five labelled tabs for navigation only; each keeps its state (HIG tab bars).
- One focal point per screen and one primary action per area (handbook 3.8).
- Missing values are not zero (HIG feedback and charts: do not mislead).
- Location, notification, and health permissions are asked when the user
  turns on the feature, not at launch (HIG privacy, Android onboarding).
- Text scale is not clamped, so system text size works (HIG typography,
  Android sp rule). Large-text layouts were fixed in the launch review.
- Reduce motion turns page slides into a fade (HIG motion, accessibility).
- 48-point minimum targets in the tokens (`minTarget`), above Apple's 44 pt.
- Contrast pairs are checked by `palette_test.dart` (4.5:1 text, 3:1 icons).
- Deleting a workout asks first, because it cannot be undone; copying a day
  offers Undo instead of a dialog (HIG alerts, undo).
- An active workout has its own dark panel and a persistent control to return
  to it (HIG workouts).

## Findings

| # | Screen | Severity | Finding | Guide | Status |
|---|---|---|---|---|---|
| 1 | Meal | Polish | The floating **Add food** button repeated each meal's add row and covered the end of the timeline. | HIG Buttons (one prominent action); handbook 3.16 rule 14 | **Fixed:** removed. Each meal's row adds food. |
| 2 | Meal | Polish | Three round icon-only buttons in the title (targets, meal times, date). | HIG Buttons (text when clearer), Toolbars (a More menu); handbook 3.16 rule 13 | **Fixed:** the date button stays; **Targets** and **Meal times** are labelled items in one **More** menu. |
| 3 | Meal | Polish | An empty day without targets showed six rows of dashes. | HIG Writing (clear next steps on blank screens); WWDC26 Simplicity | **Fixed:** one line, "Nothing logged", with **Plan my day** and **Set targets**. With targets set, the bars stay, because they show the day's goals. |
| 4 | Home | Polish | Four empty rings with dashes before the first food of the day. | HIG Writing; handbook 3.16 | **Fixed:** "Nothing logged today" and **Log food**. The rings come back with the first food. |
| 5 | Analytics | Polish | Empty state was an icon in a circle and "Your progress shows here". | HIG Writing; handbook 3.16 rule 15 | **Fixed:** "Finish a workout to see your lifts" and an **Open Workout** button. `EmptyState` now takes an optional icon. |
| 6 | Android | Must | Predictive back was not turned on, so Android 13 to 15 showed no back preview. | Android Predictive back | **Fixed:** `android:enableOnBackInvokedCallback="true"`. Test the back gesture on the phone after the next release. |
| 7 | Android | Must | Alerts and the page slide are iOS style on Android (Cupertino dialog, iOS slide). Android's guide keeps one brand but asks for the platform's system behaviour: system dialogs, the back preview, Android pickers. | Android Translate iOS designs; D-023 | **Proposed:** keep the look; on Android use the Material dialog and the predictive-back page transition. Needs the owner, because D-023 chose the iOS look on both. |
| 8 | Me | Polish | 54 `StatusLine` footnotes. Android Settings: secondary text shows the current value, not a description; drop text the label already says. | Android Settings; HIG Settings | **Proposed:** review each screen; keep only notes a user needs before acting. |
| 9 | Me | Polish | An in-app Light, Dark, Auto setting. Apple advises against an app-only appearance setting; Android allows it. | HIG Dark Mode | **No change:** an owner decision. Auto is the default, so the system setting wins unless the user picks one. |
| 10 | Home, Meal | Polish | Nutrient rings look like rings. Apple asks apps to make ring-like elements look different from Activity rings. RepArc's are single, side by side, labelled, and in other colours. | HIG Activity rings | **No change.** Low risk; check again before the App Store. |
| 11 | Workout | Proposed feature | A running rest timer is a good fit for an Android Live Update and an iPhone Live Activity. | Android Live updates; HIG Live Activities | **Proposed.** A new feature; not built. |

## The design principles applied to RepArc

- **Purpose:** log a workout or a meal fast, and see real progress. Every
  change above removes something that did not serve that.
- **Agency and forgiveness:** Undo after copying a day; a confirm only before
  a delete that cannot be undone. Keep this pattern for new destructive
  actions.
- **Responsibility:** AI changes need approval (D-018, D-019); permissions on
  demand. The WWDC26 talk's example (an AI suggesting a food a person is
  allergic to) applies to "Plan my day": plans are always shown before they are
  added, and are added as planned, never as eaten.
- **Simplicity:** one line instead of rows of dashes; two buttons instead of
  three; one way to add food on the Meal tab.
- **Craft and delight:** the remaining work is on a real phone: frame rate,
  TalkBack and VoiceOver, 200% text, and a 360 dp screen.

## Checks run

- `flutter analyze`: no issues.
- `flutter test`: all tests pass, including `design_rules_test.dart`.
- Not run: real-phone checks (see Scope).
