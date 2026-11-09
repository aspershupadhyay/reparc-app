---
title: Analytics and progress
status: proposed
owner: product-and-engineering
updated: 2026-10-06
---

# Section 6: Analytics and progress

## 6.1 Purpose

Show the user's own progress from saved records. This Analytics tab is not the team's product-use analytics.

## 6.2 First measures

Calculate these values from source records:

- Workout count by date range.
- Training days.
- Exercise history.
- Completed sets and repetitions.
- Load changes for matching exercise variation and unit.
- Personal records with a named rule.
- Meal history.
- Nutrition totals for recorded values.
- Progress against a goal the user set.
- Data coverage, such as days with a workout or meal record.

Do not show a value if its source records do not support it.

## 6.3 Chart rules

Each chart must show:

- Metric name.
- Unit.
- Date range.
- Data source.
- Coverage or missing-data state.
- Whether values are estimates.

Let the user open a chart point or summary and see its source records. Do not draw a line across missing dates as if the user recorded data. Do not compare unlike exercise variations. Do not rank users.

### Drill-down pages (2026-11-09, owner request)

Owner: "for each dashboard if user clicks on it it shouldn't direct them to the permission page, it should drill down about their data", and charts that anyone understands at one glance.

- **Route:** `/trend/<metric>` above the tabs, so Back returns to the card. Metrics: steps, distance, active energy, body weight, workouts, volume lifted, energy eaten, protein. Code: `app/lib/features/analytics/metric_screen.dart`, chart `trend_chart.dart`.
- **Opened from:** Home's steps, distance, and active energy tiles and its week card; Analytics' steps, body weight, weekly volume, and nutrition cards. None of them opens Me → Health apps or a form any more.
- **Page:** range (7 days, 30 days, 90 days, 1 year; 30 by default); the headline (a daily average over days with data, a total for workouts and volume, the latest value for weight); the change against the period before, in plain words; the chart; three numbers (average or per week, best day, days with data; for weight lowest, highest, change); and every day with data, newest first.
- **Chart:** bars for daily amounts, a line for weight. The newest point is in full colour, older ones lighter. A dashed line is the average; a solid line is the user's target (energy and protein). Tap or drag reads one point's value and day, with a haptic tick. A day with no data is a dot on the base line, never a bar of 0. One year shows weeks. The chart reads out as one sentence for screen readers.
- **Not connected:** a health metric whose type is off shows **Connect <metric>** on the same page, which opens the system sheet for that one type.
- **Bars elsewhere** (Analytics cards) also show the newest bar in full colour and the rest lighter.
- **Tests:** `app/test/health_screens_test.dart` (Home steps opens the trend with the right average; Connect on the page).

## 6.4 Goals

A goal is optional and user-set. The app can show progress against it. Do not shame the user or describe a missed goal as failure.

**To confirm:** Which goal types are in the first release. Do not add weight-loss or body-size goals by default.

## 6.5 Product-use measurement

Product-use analytics help the team understand app reliability and use. They are separate from personal progress.

If added, collect the smallest set of events needed. Do not include exercise names, food names, load values, meal contents, health records, or free-text notes. Explain the choice and provide a control before collection.

## 6.6 AI context

- **Purpose:** Help the user understand their own history.
- **Separate:** Personal progress from company usage data.
- **Show:** Metric, unit, range, source, coverage, and estimate state.
- **Never:** Fill missing dates or claim a trend proves cause.
- **Done when:** Every summary can be traced to saved source records.
- **To confirm:** First-release metrics, optional product analytics, and goal types.

## 6.7 Workout and Meal tabs

Built 2026-10-06. Analytics has two tabs so each reads on its own. Both use the same range (7, 30, or 90 days).

**Workout:** workouts and training days with change against the previous period; volume (load × reps of working sets, warm-ups excluded, pounds converted with the exact factor 0.45359237, sets without load or reps counted apart); working sets and reps; average session time without pauses; roadmap workouts done against planned weekdays; working sets per muscle per week against the common 10–20 range; estimated one-rep max over time for a chosen exercise (sets of 1–10 reps only; days without a usable set are not drawn); best lifts; weekly volume; and body weight.

**Meal:** days with eaten food; daily averages for each nutrient over days that have a value (an empty day is not a zero day); days on target when targets are on; protein and fibre per day with the target line; and the energy split (4 kcal/g protein and carbs, 9 kcal/g fat).

Calculations live in `app/lib/domain/analytics.dart` and have unit tests.

## PR moment and weekly streak (2026-10-10, launch review Block 3)

**PR moment.** When a finished workout beats an earlier best (the heaviest completed load for the same exercise and unit, as in Best lifts), a card says "New best" with the lift, before the saved workout opens, with a strong haptic. A first time on an exercise is not a record, and a tie keeps the earlier record. **Share** makes an image of the card and opens the phone's share sheet; the image holds only the lifts shown. Code: `newRecordsIn` in `app/lib/domain/analytics.dart`, `app/lib/features/workout/record_moment.dart`.

**Weekly streak.** Home's This week card shows "N weeks in a row" when weeks Monday to Sunday reached the target: the plan's days a week minus one (one missed day is forgiven), at least one, and one without a plan. The current week never breaks the streak before it ends. Code: `app/lib/domain/streak.dart`.

