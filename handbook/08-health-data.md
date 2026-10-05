---
title: HealthKit and Health Connect
status: proposed
owner: mobile-engineering-and-privacy
updated: 2026-10-05
---

# Section 9: HealthKit and Health Connect

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
- **To confirm:** Exact data types and Flutter plugin after a device prototype.
