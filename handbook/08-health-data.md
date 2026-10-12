---
title: HealthKit and Health Connect
status: active
owner: mobile-engineering-and-privacy
updated: 2026-10-06
---

# Section 9: HealthKit and Health Connect

**Built (2026-10-06, D-020):** Me → Health apps, with one switch per type: read steps, active energy, and body weight; write finished workouts and eaten meals. Each switch explains the type, read or write, and the benefit, then opens the system sheet for that type only. Code: `app/lib/health/`. Not yet tested on real devices.

**Precise totals and live steps (2026-10-12, owner request, v0.4.17):**

- **Daily totals from the store.** Steps, distance, and active energy per day come from the health store's own totals, not from adding up raw readings. Android: Health Connect `aggregateGroupByPeriod` with one-day periods in local time (native code in `MainActivity`, because the plugin's interval query fails on Android: it reads its bucket length as a `Long`, and Flutter sends small numbers as an `Integer`). iPhone: HealthKit statistics collection queries through the plugin, one bucket a day; a day with a clock change gets its own 23- or 25-hour bucket (`dayRuns`). Both count a moment once when the phone and a watch both recorded it, by the user's source priority, and split a reading that crosses midnight. A day with no data is left out, never 0. Earlier builds added raw active-energy readings, which counted phone and watch twice.
- **Distance** is a new read type (`READ_DISTANCE`; Apple: walking and running distance). Health Connect's distance also includes cycling and other distance that apps record.
- **Live steps** (switch, off by default, shown when Steps is on): while RepArc is open, the phone's step sensor (`pedometer` 4.2.0, MIT) counts steps after the last store read and adds them on screen. It needs "Physical activity" on Android 10+ (asked only when the switch is turned on) or "Motion & Fitness" on iPhone. The store's total is read again every 5 minutes and when the app comes back (every minute without Live steps), and the number never goes down within a day, because the apps that write steps to the store do it in batches. Nothing from the sensor is stored. Code: `app/lib/health/live_steps.dart`.
- **Today** refreshes on its own; each type is read separately, so one failure never hides the others.
- **Analytics → Workout → Steps and distance:** steps a day (average over the days with data), total distance, and a bar per day for the 7, 30, or 90 days chosen. Health Connect lets an app read only 30 days before its first permission was granted, so older days can be gaps.
- **Not done (owner decision needed, 9.3):** heart rate, sleep, and reading other apps' workouts.

## 9.1 Purpose

Use HealthKit on iPhone and Health Connect on Android only for a named feature. Manual logging must work when a user declines.

## 9.2 Permission steps

1. Explain the feature.
2. Name the data type.
3. Say whether the app will read or write it.
4. Explain the user benefit.
5. Ask for that data type only when its feature needs it.
6. Request permission with the system dialog.
7. Continue without the feature if the user declines.
8. Provide a link to platform settings.
9. Let the user pause app sync.

Do not copy the system permission screen.

## 9.3 First data types to assess

Assess workout records first. Add steps, active energy, or nutrition only if a user-facing feature needs them.

Do not request heart rate, location, sleep, body measurements, or clinical records without a separate product decision and review.

## 9.4 Platform behavior

Apple uses fine-grained permission. The app must request only the data types it needs. Apple does not tell the app whether read access was denied. An empty result does not prove denial. Health Connect also uses per-data-type permissions. Explain each requested type before opening the system permission screen. Ask separately when the feature asks for a different type. The operating system can group types in one system sheet. The app must not hide the type list or request unrelated access.

Health Connect uses permission for each data type. It is part of Android 14 and later. Older supported devices may need the Health Connect app. Check service availability before showing a connect action.

## 9.5 Data exchange

- Record the platform source and source record ID.
- Prevent duplicate imports.
- Respect sync pause and record deletion.
- Do not write app workouts or meals unless the user enables this.
- Avoid background reads unless the feature needs them and policy permits them.
- Show the source and date for imported values.

## 9.6 App-store review

Before release, re-check current Apple and Google rules. Match app permissions, store declarations, privacy policy, and actual data use.

Official guidance:

- Apple: https://developer.apple.com/documentation/HealthKit/authorizing-access-to-health-data
- Apple design guidance: https://developer.apple.com/design/human-interface-guidelines/healthkit/
- Android permissions: https://developer.android.com/health-and-fitness/health-connect/ui/permissions
- Google Play health publication: https://developer.android.com/health-and-fitness/health-connect/publish
- Google Play health-data policy: https://support.google.com/googleplay/android-developer/answer/18258653

## 9.7 AI context

- **Purpose:** Exchange only data needed for a feature the user selected.
- **Default:** Do not ask for health access during general onboarding.
- **Minimum access:** Request one justified data type at a time.
- **Fallback:** Manual logging remains available.
- **Never:** Infer denial from an empty query.
- **Chosen:** `health` 13.3.2 and `pedometer` 4.2.0; types in D-020 plus distance (2026-10-12). Health values are read when needed and never copied to a server.
- **To confirm:** Behaviour on real devices, and store declarations before submission.
