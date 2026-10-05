---
title: Feature specification template
status: reference
owner: product-and-engineering
updated: 2026-10-05
---

# Feature specification template

Copy this template when a feature needs its own handbook section. Replace every instruction in square brackets. Mark unverified items **To confirm**.

## Feature name

[Short name]

## Purpose

[State the user problem this feature solves.]

## User and trigger

- **User:** [Who uses it?]
- **Trigger:** [What starts the flow?]
- **Preconditions:** [What must be true before the flow starts?]

## User flow

1. [First user action.]
2. [App response.]
3. [Next user action.]
4. [Success result.]

## Data

- **Read:** [Fields and source.]
- **Create:** [New records.]
- **Update:** [Fields that can change.]
- **Delete:** [Records removed and where.]
- **Units and time:** [Units, time zone, and timestamps.]
- **Retention:** [How long the data remains.]

Do not store missing values as zero. Keep data source and user-entered data clear.

## States and failure paths

Describe first use, normal use, offline use, loading, validation error, save error, permission refusal, retry, and recovery. Add only states that apply to the feature.

Say what happens if the app closes during the flow. Say how the user can undo or correct an action.

## Privacy and security

- [What sensitive data does the feature use?]
- [Does data leave the device?]
- [What permission or consent is required?]
- [How does the user stop or revoke access?]
- [What must not appear in logs?]

## Accessibility and motion

- [Screen-reader name and state.]
- [Large-text behavior.]
- [Keyboard or one-hand needs.]
- [Motion that explains a change.]
- [Reduced-motion behavior.]
- [Haptics or sound, if needed.]

Do not make motion block the next user action.

## Analytics and reporting

- **User progress metrics:** [Values derived from source records.]
- **Product-use events:** [If any. Do not include private record content.]
- **Data gaps:** [How missing values appear.]

Keep user-facing Analytics separate from product-use analytics.

## Acceptance checks

- [ ] [User-visible behavior passes.]
- [ ] [Data is saved and can be reviewed.]
- [ ] [Offline and error states work.]
- [ ] [Privacy and permission behavior passes.]
- [ ] [Accessibility checks pass.]
- [ ] [Relevant tests pass.]
- [ ] [Documentation matches the shipped behavior.]

## AI implementation brief

- **Purpose:** [One sentence.]
- **Allowed data:** [Exact records.]
- **Must preserve:** [Important invariants.]
- **Must not:** [Forbidden behavior.]
- **Done when:** [Observable result.]
- **To confirm:** [Unresolved choices.]


## AI context

- **Purpose:** [One sentence about this feature.]
- **Read first:** [Handbook sections and diagrams.]
- **Data rule:** [Fields, sources, units, and limits.]
- **Privacy rule:** [Permission and data-sharing behavior.]
- **Motion rule:** [Required feedback and reduced-motion behavior.]
- **Done when:** [Observable acceptance result.]
- **To confirm:** [Open decisions.]
