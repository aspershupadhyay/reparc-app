---
title: Analytics and progress
status: proposed
owner: product-and-engineering
updated: 2026-10-05
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
