# UX and UI components checklist

A second pass after the platform checklists. It covers the whole product, not
only the guides' rules. For each item: look for evidence in the project (code,
handbook, tests, research notes). "No evidence" is a finding, not a pass.

Work with an Apple mindset: compare each screen with how Apple's own app for
the same job would do it (Fitness, Health, Reminders, Settings, Clock). Ask
"would this ship in an Apple app?" and write down why not.

## UX: structure and flow

### User research and personas
- Is there a written target user, their main jobs, and their pains?
- Is there evidence from real people (interviews, a phone test, reviews of
  competitors' store pages), not only the team's opinion?
- Gap to report: decisions made without any user evidence.

### Information architecture
- Draw the site map: tabs, then each screen under them, then sheets. Every
  screen has one parent. Nothing important is more than three taps deep.
- Each tab has one job. Labels are nouns people use, not internal names.
- Settings: grouped by purpose; 15 or more items move to subscreens
  (Android); task options sit next to the task (HIG).
- Each action has one home. If the same action is in two places, one is a
  shortcut and is labelled the same way.

### User flows and journeys
- For the top three tasks, count taps and screens from launch to done.
  Remove any step that asks for something the app can know or default.
- Check every exit: back, swipe down, cancel, the app going to the
  background, a phone call, a lost connection. Nothing is lost.
- First run: show value before an account, a permission, or a setup step.

### Wireframes and hierarchy
- Squint test: blur the screenshot. The one thing that matters should still
  stand out. If two things compete, one must step back.
- Each screen: one title, one primary action, then content in order of use.

### Prototyping and usability testing
- Is there a test plan with real tasks and a pass mark? Five people find most
  problems. Watch, do not help. Record time, errors, and where they hesitate.
- Test on a real phone, one-handed, outdoors, with large text, and with a
  screen reader.

## UI: the visual and interactive layer

### Design system and style guide
- Tokens for colour, type, spacing, radius, motion, defined once; screens use
  only tokens. A test or lint blocks raw values.
- Shared components: button, field, row, card, empty state, dialog, sheet,
  message. Each defines default, pressed, disabled, loading, error, and empty
  states and an accessibility label.

### Typography
- One family per platform: the system font on iPhone (SF Pro) and either the
  system font or one licensed screen font on Android.
- Follow the platform type scale (iOS text styles; Material type scale).
  Body 17 pt on iOS, at least 12 sp anywhere on Android.
- Use the typeface's own tracking: Apple's tracking table for SF Pro (text
  sizes tight, display sizes slightly open); the font's documented metrics
  for others. Do not copy SF tracking onto another font, or the reverse.
- Hierarchy by size and weight, not by colour alone. Avoid light weights.
- Tabular figures for numbers that change (timers, weights, totals).
- No text in images. Sentence case. No all-caps body text.

### Colour and colour psychology
- One colour, one meaning across the app (HIG Color; Android Color). Make a
  table: colour, what it means, where it is used. Any colour with two
  unrelated meanings is a finding.
- Red is read as error, danger, or stop. Never use the error red for data the
  user wants more of (for example a nutrient target). Green reads as done or
  good; do not use it for a warning.
- Brand colour for selection and links; one energy or accent colour for the
  main action; neutral greys for everything else. Plenty of neutral surface.
- The main action keeps the same colour meaning in light and dark mode, or
  the change is deliberate and recorded.
- Contrast 4.5:1 text, 3:1 icons and control edges, in both modes, and with
  Increase Contrast.
- Never colour alone: add a shape, icon, or word.

### Navigation elements
- Tabs for top-level places (labels always shown). No hamburger menu on
  phones when tabs fit. Back always works; Android back previews.
- Titles say where you are. Toolbars hold few items; the rest go in one
  labelled More menu.

### Input elements
- Right keyboard per field (number, decimal, email). Next and Done keys move
  through a form in order.
- The keyboard can always be closed: a tap outside, a drag, or a Done key.
  iPhone's number pad has no Done key.
- Labels stay visible; hints show the format; errors say how to fix it, next
  to the field, while typing where possible.
- Pick lists over typing; steppers or sliders with a field for big changes.
- Switches only for on and off that take effect at once.

### Feedback and status
- Every tap gets a pressed state within 100 ms.
- Saving: show success only after the save worked; show the failure and keep
  the input if it failed.
- Use the lightest form that works: inline text, then a message bar with
  Undo, then a dialog only for decisions that cannot be undone.
- Loading: content placeholders or a spinner in the place the content will
  appear; progress with time when it is long.
- Haptics for a few clear events (a set done, a timer end), consistent, and
  never on every tap.

### Micro-interactions and motion
- Motion explains a change (where something came from or went) or confirms an
  action. 100 to 300 ms. Interruptible. Never delays input.
- Reduce Motion: replace movement with a fade or an instant change.
- One curve family. No bounce on the whole screen, no confetti, no shimmer
  after load.

## Principles to check last

- **Usability and consistency:** same look means same behaviour; same place
  for the same action on every screen.
- **Visual hierarchy:** size, weight, contrast, and space make the most
  important thing obvious.
- **Accessibility:** labels for screen readers, logical focus order, keyboard
  and switch access, text scaling, contrast, reduced motion, no time limits
  without a way to extend.
