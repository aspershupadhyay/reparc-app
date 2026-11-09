# Apple HIG checklist (iPhone focus)

Our short summary of the HIG pages that matter for a phone app. Each heading
links to its page. Open the page before you rely on a rule for a decision.
Base URL: https://developer.apple.com/design/human-interface-guidelines/

## Numbers to check

| Item | Value | Page |
|---|---|---|
| Minimum hit area | 44×44 pt (visionOS 60×60 pt) | accessibility, buttons |
| Text contrast | 4.5:1 minimum; 3:1 for large or bold text | accessibility |
| Default text styles (Large size) | Large Title 34, Title 1 28, Title 2 22, Title 3 20, Headline 17 semibold, Body 17, Callout 16, Subheadline 15, Footnote 13, Caption 1 12, Caption 2 11 (pt) | typography |
| Dynamic Type | 7 standard sizes plus 5 accessibility sizes; layouts must adapt to all | typography |
| Dimming under clear glass on bright content | about 35% dark layer | materials |

## Foundations

- **[Accessibility](https://developer.apple.com/design/human-interface-guidelines/accessibility):** support larger text; prefer system
  colours; meet contrast, or offer higher contrast when Increase Contrast is
  on; never colour alone; label everything for VoiceOver; offer alternatives
  to gestures; give controls space as well as size; keep time limits rare; be
  careful with fast or blinking motion (tighten springs, follow the finger,
  replace movement with fades under Reduce Motion, avoid animating blur);
  for Assistive Access, one task per screen and confirm hard-to-undo actions.
- **[Color](https://developer.apple.com/design/human-interface-guidelines/color):** one meaning per colour; check light, dark, and
  increased contrast; test in bright light and on several screens; do not
  hard-code system colour values or change their meaning; iOS has system and
  grouped background sets (primary, secondary, tertiary) for hierarchy.
- **[Dark Mode](https://developer.apple.com/design/human-interface-guidelines/dark-mode):** support both modes; prefer adaptive colours;
  soften pure white backgrounds; use base and elevated backgrounds for layers.
  Apple advises against an app-only appearance setting (a project may decide
  otherwise; report it, do not remove it).
- **[Layout](https://developer.apple.com/design/human-interface-guidelines/layout):** order by importance; align to aid scanning; group
  related items; progressive disclosure; make controls look different from
  content; adapt to size classes, not device names; respect safe areas;
  preview with many text sizes and languages.
- **[Typography](https://developer.apple.com/design/human-interface-guidelines/typography):** use readable sizes; avoid light weights; use
  weight, size, and colour for hierarchy; few typefaces; prefer built-in text
  styles; support Dynamic Type; scale meaningful icons with text; keep
  truncation rare at large sizes; keep hierarchy at every size.
- **[Materials](https://developer.apple.com/design/human-interface-guidelines/materials):** Liquid Glass is for the control and navigation
  layer only, never the content layer; use it sparingly; use vibrant colours
  on materials.
- **[Motion](https://developer.apple.com/design/human-interface-guidelines/motion):** purposeful, optional, short, precise, follows the
  gesture, can be cancelled; avoid motion on frequent interactions.
- **[Icons](https://developer.apple.com/design/human-interface-guidelines/icons) and [SF Symbols](https://developer.apple.com/design/human-interface-guidelines/sf-symbols):** simple, consistent weight
  with nearby text, optically centred, labelled, familiar icons for familiar
  actions.
- **[Writing](https://developer.apple.com/design/human-interface-guidelines/writing):** decide the voice; match tone to context; be action
  oriented; consistent capitalisation; clear next steps on blank screens;
  clear error messages; settings labels short; link straight to a setting
  instead of describing where it is; hints in text fields.
- **[Inclusion](https://developer.apple.com/design/human-interface-guidelines/inclusion):** plain, welcoming language; define terms; avoid
  humour that excludes; avoid gender unless needed (then offer inclusive
  options); people-first language about disability.
- **[Privacy](https://developer.apple.com/design/human-interface-guidelines/privacy):** ask only for what you need, when you need it, with a
  clear purpose string; process on device where possible; never precede the
  system alert with a misleading screen; store secrets in the keychain.
- **[Branding](https://developer.apple.com/design/human-interface-guidelines/branding):** brand through colour, type, and voice; do not let
  branding get in the way of content; do not repeat the logo on every screen.

## Patterns

- **[Launching](https://developer.apple.com/design/human-interface-guidelines/launching):** launch fast; the launch screen looks like the
  first screen without text; restore the previous state.
- **[Onboarding](https://developer.apple.com/design/human-interface-guidelines/onboarding):** teach by doing; prefer tips in context to one
  long flow; keep it short and optional; postpone setup; no licence text; ask
  permissions in context; let people use the app before asking for ratings.
- **[Loading](https://developer.apple.com/design/human-interface-guidelines/loading):** show something at once; let people do other things;
  say how long; prefer determinate progress.
- **[Feedback](https://developer.apple.com/design/human-interface-guidelines/feedback):** accessible; built into the interface where
  possible; alerts only for critical, actionable news; warn before
  unexpected, irreversible data loss; confirm important completions; explain
  why something cannot happen.
- **[Entering data](https://developer.apple.com/design/human-interface-guidelines/entering-data):** get data from the system; offer choices
  instead of typing; validate as people type; mark required data clearly.
- **[Modality](https://developer.apple.com/design/human-interface-guidelines/modality):** only when it clearly helps; short and simple;
  always an obvious way out; confirm before closing with unsaved changes; one
  modal at a time.
- **[Undo and redo](https://developer.apple.com/design/human-interface-guidelines/undo-and-redo):** predictable; show the result; allow more
  than one step.
- **[Settings](https://developer.apple.com/design/human-interface-guidelines/settings):** best defaults; few settings; do not repeat system
  settings; task options in the task, not in Settings.
- **[Searching](https://developer.apple.com/design/human-interface-guidelines/searching):** search where it matters most; one place; show
  scope; suggestions; respect privacy of history.
- **[Charting data](https://developer.apple.com/design/human-interface-guidelines/charting-data) and [Charts](https://developer.apple.com/design/human-interface-guidelines/charts):** use a chart to
  highlight something; keep it simple; common chart types; describe the main
  message in text; label for VoiceOver; do not hide critical data behind
  interaction; never colour alone.
- **[Playing haptics](https://developer.apple.com/design/human-interface-guidelines/playing-haptics):** use system patterns by their
  meaning; consistent; complement other feedback; do not overuse; optional.
- **[Managing notifications](https://developer.apple.com/design/human-interface-guidelines/managing-notifications) and
  [Notifications](https://developer.apple.com/design/human-interface-guidelines/notifications):** permission first; honest urgency; no
  marketing without opt-in; no notifications that only say "open the app"; no
  private data in previews; controls inside the app.
- **[Workouts](https://developer.apple.com/design/human-interface-guidelines/workouts):** only relevant data during a workout; a distinct
  look for an active workout; big, easy controls; legible in motion; explain
  missing sensor data; a summary at the end; discard very short sessions.
- **[Offering help](https://developer.apple.com/design/human-interface-guidelines/offering-help):** tips short and actionable; do not
  explain standard controls.
- **[Ratings and reviews](https://developer.apple.com/design/human-interface-guidelines/ratings-and-reviews):** ask after real use, at a
  natural pause, never during a task.
- **[Managing accounts](https://developer.apple.com/design/human-interface-guidelines/managing-accounts):** let people use the app before
  sign-in where possible; support account deletion in the app.

## Components

- **[Tab bars](https://developer.apple.com/design/human-interface-guidelines/tab-bars):** navigation, not actions; always visible on
  top-level screens; labels on every tab; no "More" overflow tab; do not hide
  or disable tabs; badges only for critical news.
- **[Toolbars](https://developer.apple.com/design/human-interface-guidelines/toolbars):** few items; a More menu for the rest; standard Back
  and Close; prominent style for Done or Submit; concise titles; large title
  on top-level screens.
- **[Buttons](https://developer.apple.com/design/human-interface-guidelines/buttons):** one prominent button for the likely action; style
  not size marks the preferred choice; a pressed state on custom buttons; text
  when it is clearer than an icon; never give the primary role to a
  destructive action; show progress in the button for slow actions.
- **[Menus](https://developer.apple.com/design/human-interface-guidelines/menus) and [Context menus](https://developer.apple.com/design/human-interface-guidelines/context-menus):** short labels; most
  used first; group related items; one submenu level; every context-menu item
  also reachable in the main interface; familiar icons.
- **[Alerts](https://developer.apple.com/design/human-interface-guidelines/alerts):** rare; not for information only; not for common
  undoable actions; not at launch; title says the situation; buttons are
  verbs; Cancel with any destructive choice.
- **[Action sheets](https://developer.apple.com/design/human-interface-guidelines/action-sheets):** for choices about an action the person
  started; destructive choice marked; Cancel present.
- **[Sheets](https://developer.apple.com/design/human-interface-guidelines/sheets):** for short tasks; one at a time; grabber and swipe to
  dismiss when resizable; medium detent for progressive disclosure; do not
  show Cancel, Done, and Back together.
- **[Lists and tables](https://developer.apple.com/design/human-interface-guidelines/lists-and-tables):** short row text; feedback on
  selection; info button only for more detail.
- **[Segmented controls](https://developer.apple.com/design/human-interface-guidelines/segmented-controls):** closely related choices;
  about five segments at most; nouns; text or icons, not both.
- **[Toggles](https://developer.apple.com/design/human-interface-guidelines/toggles):** switches in list rows; clear what they change;
  outside lists use a toggle button.
- **[Text fields](https://developer.apple.com/design/human-interface-guidelines/text-fields):** hints; secure fields for secrets; size fits
  the text; number formatters; validate when it helps; a Clear button.
- **[Pickers](https://developer.apple.com/design/human-interface-guidelines/pickers), [Steppers](https://developer.apple.com/design/human-interface-guidelines/steppers), [Sliders](https://developer.apple.com/design/human-interface-guidelines/sliders):** logical
  order; pair a stepper or slider with a text field for big changes.
- **[Progress indicators](https://developer.apple.com/design/human-interface-guidelines/progress-indicators):** determinate when possible;
  accurate; keep moving; consistent place; let people cancel.
- **[Scroll views](https://developer.apple.com/design/human-interface-guidelines/scroll-views):** make scrolling obvious; no nested scroll
  in the same direction; auto-scroll only as far as needed.
- **[Page controls](https://developer.apple.com/design/human-interface-guidelines/page-controls):** ordered pages only; not too many.
- **[Activity rings](https://developer.apple.com/design/human-interface-guidelines/activity-rings):** only for Move, Exercise, and Stand;
  never as decoration or for other data; make other rings look different.

## Technologies a fitness or health app touches

- **[HealthKit](https://developer.apple.com/design/human-interface-guidelines/healthkit):** ask only when needed; explain why in the system
  sheet; a clear privacy policy; manage sharing in system settings; call it
  "Apple Health", not "HealthKit", in the interface; use only Apple's Health
  icon, unchanged, not as a button.
- **[Generative AI](https://developer.apple.com/design/human-interface-guidelines/generative-ai):** say where AI is used and what it can
  and cannot do; ask before using personal data; let people refine or undo
  results; get permission before irreversible actions; plan for wrong output;
  the app works without the AI feature.
- **[VoiceOver](https://developer.apple.com/design/human-interface-guidelines/voiceover):** labels for all key elements; headings; group
  and order elements; announce changes; make charts accessible; hide
  decorative images.
- **[Right to left](https://developer.apple.com/design/human-interface-guidelines/right-to-left):** flip progress and navigation controls;
  never flip numerals, photos, logos, or real-world objects.
