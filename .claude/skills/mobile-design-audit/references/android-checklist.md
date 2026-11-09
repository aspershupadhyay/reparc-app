# Android mobile design checklist

Our short summary of every page under
https://developer.android.com/design/ui/mobile (38 pages, read 2026-11-09).
Component detail lives in Material 3 (https://m3.material.io). Open the page
before you rely on a rule for a decision.

## Numbers to check

| Item | Value | Page |
|---|---|---|
| Minimum touch target | 48×48 dp, even if larger than the visible control | foundations/accessibility |
| Text contrast | 4.5:1 minimum | foundations/accessibility |
| Non-text contrast (icons, control edges) | 3:1 | foundations/accessibility |
| Smallest body text | 12 sp; set fonts in sp so they scale | foundations/accessibility |
| Layout grid | 8 dp for layout, 4 dp for small items such as icons | layout-and-content/grids-and-units |
| Compact margin | 16 dp, wider on larger windows | layout-and-content/content-structure |
| Design width | 412 dp, and test at 360 dp | foundations/translate-designs |
| Predictive back margin | keep 8 dp from the screen edge while the page shrinks | patterns/predictive-back |
| Settings grouping | 15 or more settings: move related ones to a subscreen | patterns/settings |

## Foundations

- **Accessibility:** fonts in sp; body at least 12 sp; contrast 4.5:1 text,
  3:1 non-text; more than one cue for links and states; content
  descriptions on icons and images, null on decorative ones; group elements
  so TalkBack moves in sensible blocks; never make a gesture the only way to
  act (add a button or accessibility action next to swipe-to-delete);
  48 dp targets; test with TalkBack, Switch Access, and Voice Access.
- **System bars:** go edge-to-edge; transparent or translucent status bar;
  handle insets with WindowInsets; transparent gesture navigation bar;
  translucent three-button bar over scrolling content; no touch targets under
  gesture insets.
- **Translate iOS designs:** a shared design system may replace Material, but
  swap system UI and behaviour: navigation bar for the tab bar (five items or
  fewer, primary destinations only); left-aligned titles; Up arrow in child
  views; close icon in full-screen dialogs; bottom sheets for action sheets;
  system dialogs for alerts; tabs for segmented controls that switch views;
  Android pickers and inputs.

## Layout and content

- **Edge-to-edge:** draw backgrounds and scrolling content under the bars;
  inset text and buttons; solid app bars draw into the camera cutout; top
  app bars collapse on scroll; do not stack two status-bar protections.
- **Layout basics, app anatomy, content structure:** consistent margins;
  columns for alignment; containment (cards, panes) to group; pin key actions
  where focus matters; set how images crop and scale.
- **Adapt layout:** do not lock to portrait; one pane on compact, one or two
  on medium, several on large; do not stretch buttons or forms to full width
  on large screens; set a maximum width.
- **Grids and units:** dp and sp, never px; 8 dp grid.
- **Images and graphics:** right size for each density; consistent aspect
  ratios; meaningful images only.
- **Postures and orientation:** support foldable postures and rotation; keep
  state across configuration changes.

## Patterns

- **Onboarding and authentication:** show value before asking for an account
  or a permission; collect only what is needed; ask each permission at the
  moment of need ("permission priming") and explain the value; a clear skip
  and a way to resume; steppers or progress for multi-step flows; never
  pre-fill passwords; mask sensitive input; clear recovery ("Forgot
  password"); state the rules (for example password rules) up front; group
  related fields; avoid long scrolling forms; snackbars for brief
  confirmations; errors focus on the fix, never mock or blame.
- **Passkeys:** prefer passkeys and the system credential manager over
  passwords; explain them in plain words.
- **Predictive back:** opt in (`android:enableOnBackInvokedCallback="true"`
  before Android 16; on by default for apps that target Android 16); back
  always works; the preview shows where back goes; do not intercept back
  without a reason (unsaved changes); custom animations keep an 8 dp margin.
- **Settings:** respect system settings, do not copy them; few, well-named
  settings with safe defaults that save battery and data; no app info or
  account management mixed into settings; Settings last in menus (before
  Help and Feedback); never call it "Options" or "Preferences"; subscreen
  titles match the row that opens them; impersonal labels ("Notifications",
  not "Notify me"); avoid "Don't" and "Never" in labels; secondary text shows
  the current value, not a description; switches for on and off, radio
  buttons for one-of-many in a dialog or subscreen; dependent settings sit
  under their parent; settings reachable when signed out.
- **Help content:** a Help and Feedback entry, last in the menu.

## Styles

- **Color:** colour roles through tokens, never raw values in components;
  check contrast; red and green are not enough alone; one colour, one meaning
  across the app; build light and dark schemes; leave plenty of neutral
  surface.
- **Themes:** support light and dark; a fallback scheme when dynamic colour is
  not used; do not lock the app to light; check contrast in every theme.

## Home screen

- **Notifications:** ask permission in context and explain the benefit; do
  not ask again after a dismissal; channels and categories; group several;
  useful actions (up to three collapsed); never for ads, "come back" nudges,
  rating requests, syncing, or errors the app can fix itself; a way to stop
  ongoing ones.
- **Live updates:** only for an ongoing, user-started, time-sensitive
  activity (a workout timer is a good fit).
- **Widgets:** glanceable, one job, resizable, respect system colours and
  corner radius, configuration optional with good defaults.
- **Picture-in-picture:** only for video or live content.

## Page list

See `page-index.md` for every page link.
