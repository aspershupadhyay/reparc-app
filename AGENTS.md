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

## Authority and status

- Follow direct user instructions first.
- **Owner instruction (2026-10-05):** Push every change directly to the `main` branch on GitHub as soon as it is ready. Do not ask for confirmation first. Run the matching checks before each push.
- Keep the five accepted tabs: Home, Workout, Meal, Analytics, and Me.
- Keep the two supplied image files as visual references for Meal and Workout. Read them before changing those screens.
- Treat `assets/exercise-demos/` GIFs as draft visual samples until a qualified coach reviews the movements and release assets receive rights and accessibility checks.
- Treat the handbook as the product and architecture plan.
- Treat **Accepted** decisions as current project rules.
- Treat **Proposed** decisions as unapproved.
- Treat **To confirm** items as unresolved.
- Never present a planned feature as built.
- Never claim a security, privacy, performance, or policy result without evidence.
- Never make the app install executable updates directly from GitHub. Use approved App Store or Google Play flows.

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

## Verification and handbook updates

- Follow the test plan in handbook/11-open-source-release.md.
- Run checks that match the change.
- Report checks that did not run.
- Update the owning handbook section and related diagram when behavior changes.
- Keep updates small and focused.
- Write documentation in plain English. Aim for about 80% of ASD-STE100. Do not claim formal compliance.
