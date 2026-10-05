---
title: Product goal
status: accepted
owner: product
updated: 2026-10-05
---

# Section 1: Product goal

## 1.1 Purpose

Build a fitness app for iPhone and Android.

The app will use five main tabs: Home, Workout, Meal, Analytics, and Me.

The app will help a person:

- Plan and record meals.
- Plan and record gym workouts.
- Review progress over time.
- Control how the app stores and shares personal data.

Flutter is the current proposed mobile framework. The detailed technology choice belongs in a later section. We will mark each technology as **To confirm** until the stack section is approved.

## 1.2 User problem

The app should make daily fitness records easy to create and easy to understand.

A person must be able to record a workout without losing time between sets. A person must be able to record a meal without guessing what the app saved. The app must show when a value is missing or estimated.

These are product goals. We have not yet proved that users have these problems or that this app solves them better than current apps.

## 1.3 Intended user

The first planned user is a person who trains at a gym and wants to keep a workout history. The app will also support people who want to plan and record meals.

**To confirm:** The first release must choose a main user group. For example, it could focus on people who lift weights, people new to the gym, or people who want both meal and workout tracking. This choice changes the first release and its screen design.

## 1.4 Product outcome

A user should be able to:

1. Open the app and understand what to do next.
2. Record a workout exercise and each set.
3. Plan or record a meal.
4. Review saved records and progress.
5. Correct or remove a record.
6. Understand where each value came from.
7. Control optional account, health, and AI access.

Do not add a feature only because a competitor has it. Add it when it helps the selected user complete a real task.

## 1.5 Product rules

- Make common logging actions quick.
- Keep workout and meal records clear.
- Show units, dates, and data sources.
- Do not change a record without the user's action.
- Do not show a missing value as zero.
- Mark estimates as estimates.
- Keep health permissions optional.
- Explain when data leaves the phone.
- Do not give medical or diet treatment advice.
- Let the user review AI suggestions before they change a record.

The exact data storage and account rules are not approved in this section. The data and privacy sections must define them before implementation.

## 1.6 Product measures

Test these questions with users:

- Can the user record a set without help?
- Can the user record a meal without confusion?
- Can the user find a past workout or meal?
- Can the user correct a saved record?
- Can the user explain which data an optional connection can access?

**To confirm:** Set numeric targets after user research. Do not make up targets before a baseline exists.

## 1.7 Health and safety limits

The app records fitness activity and food information. It is not a medical service.

The app must not:

- Diagnose a health condition.
- Tell a user to start, stop, or change treatment.
- Claim that a calorie value is exact when it is an estimate.
- Claim that a workout log can detect injury or exercise form.

Any future coaching feature needs a separate review. It must name its data source and show its limits.

## 1.8 First release boundary

The first release is planned to cover:

- Gym workout planning and logging.
- Meal planning and logging.
- A user-facing progress and analytics area.
- Data review and correction.
- HealthKit and Health Connect are planned as optional connections. Ship them after their data types, permissions, package, and policy checks pass. A user can refuse access and still use manual logging.

**To confirm:** Whether account sign-in, cloud sync, MCP, and BYOK belong in the first public release. These features add privacy, security, support, and release work. The roadmap section must set their release order.

## 1.9 AI context

- **Section purpose:** Define the app's user goal and product limits.
- **Build toward:** Meal logging, gym logging, useful progress views, and clear data control.
- **Do not assume:** A user group, paid plan, cloud service, food database, or AI provider.
- **Data rule:** Preserve source, unit, date, and missing values.
- **Safety rule:** Do not present the app as a medical service.
- **Status:** The user approved this product goal. Items marked **To confirm** still need a decision.
