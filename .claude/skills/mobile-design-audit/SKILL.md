---
name: mobile-design-audit
description: Audit and improve a phone app's UI against Apple's Human Interface Guidelines (including the 2026 design principles) and Android's mobile design guidance. Use when asked to review, audit, polish, declutter, or make an app feel "premium", "simple", or "native"; before shipping a new screen; or when checking accessibility, touch targets, contrast, Dynamic Type, dark mode, onboarding, permissions, empty states, settings, notifications, predictive back, or edge-to-edge. Works for Flutter, SwiftUI, UIKit, Jetpack Compose, React Native, and web apps that run on phones.
---

# Mobile design audit (Apple HIG + Android)

This skill turns the two platform guides into a repeatable audit. It finds
problems, ranks them, fixes the small safe ones, and lists the rest with a
source for each claim.

Sources (read on 2026-11-09, all pages):
- Apple Human Interface Guidelines, 173 pages: https://developer.apple.com/design/human-interface-guidelines
- Apple design principles page (reintroduced June 2026): https://developer.apple.com/design/human-interface-guidelines/design-principles
- WWDC26 session 250, the design principles talk (notes in `references/wwdc26-design-principles.md`)
- Android mobile design, 38 pages: https://developer.android.com/design/ui/mobile

The reference files hold our own short summaries, not copies of the guides.
When a rule matters for a decision, open the linked page and read it. Run
`scripts/fetch_guidelines.py` to download every page again as Markdown when
you need the full text or want to check for changes.

## Files

- `references/principles.md`: the eight Apple principles as audit questions.
- `references/apple-checklist.md`: HIG rules by topic, with numbers (sizes, contrast, text styles).
- `references/android-checklist.md`: Android rules by topic, with numbers (dp, sp, insets, back).
- `references/wwdc26-design-principles.md`: notes from the WWDC26 talk.
- `references/ux-ui-components.md`: the whole-product pass: research, IA,
  flows, testing, design system, typography, colour psychology, navigation,
  inputs, feedback, and motion. Use it after the platform checklists.
- `references/page-index.md`: every HIG and Android page, grouped, with links.
- `references/report-template.md`: the format for the audit report.
- `scripts/fetch_guidelines.py`: crawls both sites into Markdown files.

## Workflow

1. **Read the project's own rules first.** Look for AGENTS.md, CLAUDE.md, a
   design handbook, design tokens, a decision log, and design tests. Project
   decisions win over the platform guides. If a guide conflicts with an
   accepted decision, report the conflict. Do not change the decision.
2. **Map the app.** List the navigation (tabs, stacks, sheets), every screen,
   and the shared widgets (buttons, cards, rows, empty states, dialogs). Note
   the theme: colours, type scale, spacing, radii, motion tokens.
3. **Name the purpose.** Write one sentence: who uses the app, for what, and
   what feeling it should give (Apple "Delight": a fitness app energizes). Each
   screen then gets one sentence: the one thing a person comes to do there.
4. **Audit each screen.** For each screen, go through the questions in
   `references/principles.md`, then the topic rules in both checklists that
   apply to what is on the screen. Check these states, not only the happy path:
   first run, empty, loading, error, offline, large text (200% and the largest
   accessibility size), dark mode, screen reader, reduced motion, small phone
   (360 dp / iPhone SE width), and a long translated label.
   Then make the whole-product pass in `references/ux-ui-components.md`.
   Take screenshots of each main screen (light and dark) and look at them
   as Apple's design team would: compare with Apple's own app for the same
   job, and list every place where ours would not ship.
5. **Write findings.** One finding = one problem on one screen. Give each:
   severity, the evidence (file and line, or a screenshot), the rule with its
   source link, the smallest fix, and the risk of the fix. Severities:
   - **Blocker:** data loss, a broken flow, a policy or privacy breach, or an
     action a screen-reader user cannot complete.
   - **Must:** fails a platform rule with a number (contrast, target size,
     text scaling), or confuses most people.
   - **Polish:** clutter, inconsistency, wording, motion.
6. **Fix.** Fix the small, safe, reversible items that follow existing project
   decisions. Leave anything that touches privacy, health data, accounts,
   licensing, data migration, or a recorded decision for the owner, and say
   so. Fix in shared widgets when the same problem is on many screens.
7. **Verify.** Run the project's analyzer, tests, and any design-rule tests.
   Add a test for each behaviour you changed when the project has widget
   tests. Look at the result: a screenshot at phone size, in light and dark.
   Say which checks you could not run (for example, no real phone, no
   VoiceOver or TalkBack pass).
8. **Report.** Use `references/report-template.md`. Separate "fixed" from
   "proposed". Never call a planned item built. Never claim an accessibility
   or performance result you did not measure.

## The short list (check these first)

These catch most problems in most apps:

1. **One focal point per screen.** The most important action is the most
   visible thing. One primary (filled) button per area. Style, not size, marks
   the preferred choice.
2. **No duplicate actions.** A floating button that repeats a row's "+" or a
   hero title that repeats its button is clutter.
3. **Icon-only buttons are rare.** Use a text label when a word is clearer.
   Put rare actions in one labelled "More" menu. Every icon-only control has
   an accessibility label.
4. **Empty screens give the next step** and a button to take it. Not an
   illustration and a slogan; not rows of zeros or dashes.
5. **Missing is not zero.** Show "no value" differently from 0.
6. **Touch targets:** at least 44×44 pt (iOS) and 48×48 dp (Android), with
   space between them.
7. **Contrast:** text at least 4.5:1 (3:1 for large text); icons and control
   edges at least 3:1. Never colour alone: add a shape, icon, or word.
8. **Text scales.** Respect the system text size (Dynamic Type, sp). Do not
   clamp it. Layouts reflow at large sizes; important text does not truncate.
9. **Dark mode and light mode both work**, with system or semantic colours.
10. **Permissions at the moment of need**, with one sentence on why. Never at
    launch unless the app cannot work without it.
11. **Destructive actions:** offer undo for common, reversible actions;
    confirm only actions that cannot be undone. Cancel is always there.
12. **Feedback:** every tap shows a pressed state; slow actions show progress;
    success and failure are announced to screen readers.
13. **Motion is short, can be interrupted, never blocks input, and respects
    reduce motion.** No confetti as a substitute for craft.
14. **Writing:** plain words, verbs on buttons ("Save workout", not "OK"),
    sentence case, no jargon, no blame in errors, no hype.
15. **Settings are few.** Good defaults first. Do not copy system settings.
    Task options sit next to the task.
16. **Android specifics:** draw edge-to-edge and handle insets; opt in to
    predictive back; no touch targets under gesture insets; notification
    channels; system back always works.
17. **One colour, one meaning.** The error red is never a data colour.
18. **Type follows the platform:** iOS text styles and Apple's tracking for
    SF Pro; the font's own metrics elsewhere; tabular figures for numbers.
19. **The keyboard can always be closed** (iPhone's number pad has no Done).
20. **iOS specifics:** tab bar for navigation only (never actions), labels on
    every tab, large titles on top-level screens, sheets with a clear dismiss,
    swipe-to-dismiss where safe.

## Cross-platform apps

A cross-platform app can keep one brand and one design system. Both guides
allow this (Android's "Translate iOS designs" page says a shared design system
can replace Material). But keep each platform's expectations for system
behaviour: back gesture, system bars and insets, share sheets, permission
dialogs, notifications, date and time pickers, and text scaling. Report where
an iOS pattern on Android (or the reverse) changes behaviour, not only looks.

## What not to do

- Do not redesign the app because a guide shows a different style.
- Do not add a feature to satisfy a guideline unless the owner asks.
- Do not widen a test's allow list to make it pass.
- Do not quote long passages from the guides. Link the page.
