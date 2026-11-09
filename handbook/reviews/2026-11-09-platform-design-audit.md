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
| 7 | Android | Must | Alerts and the page slide were iOS style on Android. | Android Translate iOS designs; D-023 | **Fixed (owner yes, 2026-11-09):** Material dialog and predictive back transition on Android; iPhone unchanged. |
| 8 | Me | Polish | Row second lines described the row instead of its state; a stale note said RepArc runs no backup. | Android Settings; HIG Settings | **Fixed:** state only ("Targets off", "No backup file yet", the version), or nothing; the stale card is a link to Backup and restore. Notes with safety, privacy, or estimate facts stay. |
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

## Second pass, 2026-11-09: typography, colour, and the whole product

**Owner request:** do the Android dialogs and the settings notes, check
typography and colour psychology, and check the product against a UX and UI
component list (research, IA, flows, wireframes, testing, design system,
type and colour, navigation, inputs, feedback, motion, consistency,
hierarchy, accessibility), as if Apple built the app.

**Method:** the platform checklists, then `references/ux-ui-components.md`
in the skill, then screenshots of Home, Workout, Meal, Analytics, and Me in
light and dark, rendered with the real Inter and Lucide fonts at iPhone size
(390 × 844 points), compared with how Apple's own apps (Fitness, Health,
Settings) handle the same job.

| # | Area | Finding | Guide | Status |
|---|---|---|---|---|
| 12 | Typography | Both fonts used one tracking. On iPhone, SF Pro display sizes (28, 34 pt) were tracked tight (-0.6, -0.8) where Apple's table opens them (+0.38, +0.40). | HIG Typography, tracking values; Inter dynamic metrics | **Fixed:** `trackingFor` uses Apple's table for SF Pro and Inter's formula for Inter. `typography_test.dart`. |
| 13 | Typography | Home ring labels at 11 pt, under Android's 12 sp floor. | Android Accessibility | **Fixed:** 12 pt (`labelSmall`). |
| 14 | Colour | "Coral" was the error red. Protein, the nutrient people try to reach, read as a warning, and red meant five unrelated things. | HIG Color: one colour, one meaning | **Fixed:** systemPink for the category; red only for errors and Delete; exercise mistakes use the error red. A test stops a data colour equal to the error colour. |
| 15 | Colour | The main button is teal in light mode and lime in dark mode. Apple keeps one tint. | HIG Color, Familiarity | **No change:** owner decision (D-023, D-028). Recorded. |
| 16 | Colour | Teal (calm, trust) for selection and links; lime (energy) for the one training action; neutral greys elsewhere. This fits a training app (Apple: "a fitness app might energize"). | HIG Design principles, Delight | Meets. |
| 17 | Inputs | No screen closes the keyboard. iPhone's number pad has no Done key, so the keyboard could cover Save. | HIG Text fields, Entering data | **Fixed:** a tap on empty space closes it, app-wide. Tested in `app_flow_test.dart`. |
| 18 | Writing | Five places told the user where a setting lives ("in Me → Body and goals", "in Settings → Apps → RepArc"). | HIG Writing: link to the setting | **Fixed:** buttons that open the place. iCloud and Google backup paths stay as text: no link exists. |
| 19 | Home | "Log food" twice (card link and shortcut), and the hero title "Get your plan" next to the button "Get my plan". | Handbook 3.16 rules 11 and 14 | **Fixed:** one Log food; hero title "A plan that fits you". |
| 20 | Workout | The Plan tab opened with a question and a two-line paragraph. | Handbook 3.16 rule 4 | **Fixed:** "Choose a goal" and one line. |
| 21 | Research | One owner phone test and a market review exist. No test with other people. | UX research; HIG Craft | **Proposed:** the test plan below. |
| 22 | Usability | No written task test. | Usability testing | **Proposed:** the test plan below. |

### Whole-product check

- **User research and personas:** the product goal (handbook 00) names the
  user and jobs; the launch review adds market research and one phone test.
  Gap: no sessions with people other than the owner.
- **Information architecture:** five tabs, each with one job; Me has eight
  short groups and no group over six rows, under Android's 15-row limit.
  Each action now has one home on Home and Meal.
- **User flows:** handbook 13 has the flow diagrams. Log a food: Meal, tap the
  meal, pick a food, Save (4 taps). Start a free workout: one tap from Home or
  Workout.
- **Wireframes:** the two supplied references (handbook 3.3, 3.4) are the
  layout source.
- **Design system:** tokens in `palette.dart` and `tokens.dart`; shared
  widgets; `design_rules_test.dart` and `palette_test.dart` enforce them.
- **Navigation:** labelled tabs, no hamburger, back always works.
- **Feedback:** saves show a message with Undo where possible; failures keep
  the input (`guardedWrite`); haptics on a few workout events only.
- **Motion:** short, reduce motion respected, no confetti.
- **Accessibility:** labels, live regions, 48-point targets, contrast tests.
  Not yet done: a full TalkBack and VoiceOver pass on a phone.

### Proposed usability test (5 people, 20 minutes each)

Use the release build on a phone. Do not help. Note time, errors, and where
people stop.

1. Log what you ate for breakfast.
2. Start a workout and log two sets of any exercise.
3. Find how much protein you ate yesterday.
4. Get a plan for building muscle, three days a week.
5. Turn on dark mode, then back up your records.

Pass mark: each task done without help in under two minutes. Anything that
fails twice becomes a finding.

### Checks run (second pass)

- `flutter analyze`: no issues.
- `flutter test`: all 447 tests pass after merging the 0.5.4 onboarding work, including the new
  `typography_test.dart` and the colour-meaning check.
- Screenshots in light and dark at iPhone size, in the test harness with real
  fonts. Not a real phone.
