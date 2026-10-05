---
title: Scope and release stages
status: accepted
owner: product-and-engineering
updated: 2026-10-05
---

# Section 2: Scope and release stages

## 2.1 Purpose

This section defines what the first production release must do. It also defines how the team moves from discovery to public release and long-term support. Production controls begin with the first commit. Internal design checks and test builds do not become disposable customer products.

A stage is complete only when its exit checks pass. A planned feature is not a shipped feature.

## 2.2 Product scope

### First release must include

- Create, edit, and delete a gym workout.
- Add exercises and record each set.
- Save a workout while the phone is offline.
- Plan and record meals.
- View workout and meal history.
- View personal progress in an Analytics tab.
- Correct saved records.
- Show units, dates, and data sources.
- Provide clear empty, loading, save-failure, and offline states.
- Provide a way to export and delete local records.
- Meet basic screen-reader and text-size needs on iPhone and Android.

### First release must not include

- A social feed or public user profiles.
- Ads based on workout, meal, or health data.
- Medical diagnosis or treatment advice.
- Automatic workout or meal changes without user approval.
- AI write access to user records.
- A watch app.
- A food database or barcode service before its source, cost, coverage, and license are reviewed.

### Features that need a separate release decision

These features add service, privacy, security, or support work. Do not include them by default. HealthKit and Health Connect are planned app capabilities. Their release must pass the health-data stage.

- Account sign-in.
- Cloud sync and backup.
- Remote MCP access.
- BYOK provider keys.
- Product-use analytics sent to a service.

**To confirm:** Which of these features must be in the first public release. The product owner must approve this list before the team estimates or builds them.

## 2.3 Release stages

### Stage 0: User research

**Purpose:** Confirm the user problem and choose the first user group.

**Work:**

1. Interview people who record gym sessions or meals.
2. Ask what they record and what they do not record.
3. Watch users complete a workout-log task in their current app.
4. Ask what makes logging slow or unclear.
5. Show the two supplied screen references.
6. Ask users which parts help them complete a real task.

Do not present the proposed app as a finished product. Do not treat compliments as proof of demand.

**Exit checks:**

- Name the first user group.
- List the three main problems that users report.
- Record what users do today to solve each problem.
- Identify one problem that the first release will solve.
- Record open questions and evidence.

### Stage 1: Product and screen validation

**Purpose:** Confirm the flows before the team commits to detailed implementation. This is an internal validation step. It is not a public app release or a throwaway implementation.

**Work:**

1. Draw the five main tabs: Home, Workout, Meal, Analytics, and Me.
2. Put the exercise library, plans, history, and logging inside Workout. Put account and AI connections inside Me.
3. Build the meal flow from plan to saved meal.
4. Build the workout flow from start to saved set.
5. Include empty, error, offline, and large-text states.
6. Test the internal screen model with users from the selected group.

**Exit checks:**

- Users can find Workout and Meal from the main navigation.
- Users can find AI connections under Me.
- Users can log one meal and one set without coaching.
- Users can find Analytics and understand its labels.
- The team records every usability issue.
- The product owner approves the screen map.

### Stage 2: Production foundation

**Purpose:** Build production-grade vertical slices. Keep the approved code, architecture, security controls, and tests. Do not create throwaway app code.

**Work:**

1. Build production-quality Meal and live Workout flows with the shared architecture.
2. Save a meal and a workout locally.
3. Close and reopen the app.
4. Test offline logging.
5. Build an optimized release app for each platform.
6. Measure startup time, set-entry response, memory, and download size.
7. Build the HealthKit and Health Connect permission spike only after data types and purpose text are approved.
8. Keep Flutter unless team skill or measured engineering evidence creates a reason to change.

**Exit checks:**

- A saved set and meal remain after app restart.
- Logging works without network access.
- The release build works on a supported iPhone and Android device.
- Measured performance meets targets that the product owner approved.
- The mobile stack decision is recorded in the technology section.

**To confirm:** Numeric performance and app-size targets. Set these after measuring a baseline on named test devices.

### Stage 3: Production candidate

**Purpose:** Complete the core production app and test it through internal and closed store tracks. Do not publish a placeholder or disposable prototype as the customer app.

**Scope:**

- Meal logging.
- Gym workout logging.
- Local history and edits.
- Analytics from saved records.
- Local export and deletion.
- Shared design system.
- Accessibility states.

Do not add account sync, remote MCP, or BYOK unless the product owner approved them for this release and the required privacy work is complete. HealthKit and Health Connect are planned for a later release after the health-data checks pass.

**Exit checks:**

- Required workout and meal flows pass on both platforms.
- The app does not lose records during interruption tests.
- Export and deletion work.
- Analytics match their source records.
- Screen-reader and text-size checks pass.
- No open high-risk data-loss or privacy issue remains.

### Stage 4: Optional account and sync

**Purpose:** Let users back up or use records across devices.

Start only after the team defines identity, encryption, account recovery, sync conflicts, export, deletion, and support access.

**Exit checks:**

- The user can see what data syncs.
- The user can recover an account or understands when recovery is not possible.
- A sync retry does not create duplicate records.
- The user can export and delete cloud records.
- Tests prove one account cannot read another account's records.
- The privacy policy matches the data flow.

### Stage 5: Health connections

**Purpose:** Add a user-selected feature that reads or writes HealthKit or Health Connect data.

Request only the data types that the feature needs. Keep manual logging available when access is refused.

**Exit checks:**

- Each data type has a written user benefit.
- Permission text names that benefit.
- Grant, refusal, limited access, revocation, and unavailable states work.
- The app-store declarations and privacy policy match the implementation.

### Stage 6: MCP and BYOK pilot

**Purpose:** Let a user connect a compatible AI client or provider.

Start with read-only access. Require clear consent, narrow access, expiry, and revocation. Explain when records go to a remote AI service.

**Exit checks:**

- The user can choose which data categories to share.
- Tests prove that access is limited to the correct user and data.
- Revoked access stops working.
- Logs do not contain private records, prompts, or keys.
- AI responses show sources and do not invent missing values.
- The privacy and security reviews pass.

### Stage 7: Public production release

**Purpose:** Publish the approved production app to its official app stores and publish the open-source repository.

Complete the production and release checks in the testing, release, and support sections. Re-check current Apple and Google rules before submission. Use the app update process in [Production readiness and app updates](16-production-and-app-updates.md).

**Exit checks:**

- Store forms and privacy policy match the app.
- Release builds are signed and measured.
- Export, deletion, backup restore, and account isolation tests pass where those features exist.
- Support and security contact paths work.
- The license and third-party notices are present.
- A staged rollout and rollback plan are ready.

### Stage 8: Support and maintenance

**Purpose:** Keep the app safe and useful after release.

Review crashes, user reports, security reports, accessibility issues, performance, and dependency updates. Publish a release note for each user-visible change.

**Exit checks for each release:**

- Changes have a reviewer.
- Data migrations have a backup and recovery plan.
- Security fixes have a response owner.
- Release checks pass on iPhone and Android.
- Users can understand what changed.

### Stage 9: Feature end-of-life

**Purpose:** Stop support for a feature without trapping user data.

Before removing a feature:

1. Explain what will change and when.
2. Provide an export path for affected records.
3. State whether records will remain viewable.
4. Stop new data collection for the feature.
5. Remove related permissions and credentials.
6. Update the privacy policy and handbook.
7. Follow applicable data-retention rules.

Do not delete user records without a clear reason and notice.

## 2.4 Stage control

Keep a short stage report with:

- Current stage.
- Work completed.
- Exit checks passed.
- Open risks.
- Decisions needed.
- Owner and review date.

**To confirm:** The people who own product approval, mobile engineering, security review, release, and user support.

## 2.5 Production bar from the first commit

- Use protected pull requests and required CI checks.
- Keep development, test, and production settings separate.
- Keep signing keys and service secrets out of source control.
- Test saved data, migrations, permissions, exports, and updates.
- Use release builds for performance and store checks.
- Keep an owner for incidents, security reports, support, and releases.
- Do not ship a feature that has not passed its release gate.

Use the execution order in this handbook. Close user, product, licensing, and release-owner questions before public launch. Do not wait to add privacy, test, accessibility, and migration controls until launch work.

**Execution order:** Confirm the first user group and first-release scope. Validate the five-tab flows. Lock the build stack and minimum device support. Build the local-first production foundation. Complete core logging and analytics. Pass internal release gates. Add separately approved account, health, AI, or MCP features only after their gates pass. Submit through private store tracks. Release publicly after review. Operate updates and support for every released version.

See [Production readiness and app updates](16-production-and-app-updates.md).

## 2.6 AI context

- **Section purpose:** Define what belongs in each release and how to prove readiness.
- **First production release:** Core Home, Workout, Meal, Analytics, and Me flows, local record review, export, deletion, health connections after platform gates, and the in-app update experience.
- **Later features:** Cloud sync, remote MCP, and BYOK need separate approval.
- **Stage rule:** Do not pass an exit check without evidence.
- **Production rule:** Use internal validation, but keep the code and controls release-ready from the first commit.
- **Risk rule:** Mark unknown targets and owners as **To confirm**.
- **Do not:** Claim a feature is built or compliant because this plan describes it.
