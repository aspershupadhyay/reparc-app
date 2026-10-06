---
title: Validated plan and prototype decisions
status: proposed
owner: product-and-engineering
updated: 2026-10-06
---

# Section 16: Validated plan and prototype decisions

## 16.1 Decision summary

**Verdict: Test.** Build the smallest useful app after the screen map and technical risks pass a prototype. Do not build every proposed service in the first release.

**Confidence:** Medium for the mobile direction. Low for market demand until user research is complete.

**Reason:** The product has a clear core loop: plan or log a workout, plan or log a meal, and understand progress. Local-first storage supports this loop without a server. The supplied references give the team a visual direction. The team has not yet tested the product with its intended users.

**Biggest risks:** Users may not want both meal and gym tracking in one app. Food values may be incomplete or costly to source. Sync and remote AI access add privacy and security work. Health integrations depend on third-party packages and platform rules.

**Next test:** Test the five-tab prototype and a small Flutter local-storage prototype with the same target users.

**Decision trigger:** Continue after users can complete the core logging tasks and the local prototype meets measured device targets. Change scope if users prefer one core job or logging remains slow.

## 16.2 Competition and product position

The market already has strong workout loggers, coaching apps, and meal trackers. A broad feature list will not make this app different.

A first public feature scan on 2026-10-05 found:

| Product | Public feature area | What this means for Gym |
|---|---|---|
| [Hevy](https://www.hevyapp.com/features/) | Workout logging, routines, history, analytics, community, coach tools, and a ChatGPT app/plugin | Basic gym logging and AI connection are not unique by themselves. |
| [Strong](https://help.strongapp.io/article/229-my-first-workout) | Build and log a workout from the workout screen | A fast, reliable live set logger is a baseline expectation. |
| [Fitbod](https://help.fitbod.me/hc/en-us/sections/360001078993-Understanding-Fitbod-How-It-Works) | Plans based on goals, experience, equipment, workout preferences, and workout history | Do not promise adaptive coaching until the data and safety rules are proven. |
| [MacroFactor](https://macrofactor.com/macrofactor/) | Food search, barcode and label logging, recipes, nutrition analytics, and AI-assisted logging | Meal logging needs a deliberate source and quality plan. Manual entry alone may limit appeal. |

This is a starting scan, not a full competitive study. Product features and prices change. Re-check the current apps and store listings before launch. Do not copy their brand, text, or protected assets.

**Differentiation hypothesis to test:** One calm, fast product for gym logging and meal tracking, with useful progress views, local-first data, clear sources, user export, and AI access that the user controls. This may reduce app switching and improve trust. User interviews must prove that this problem matters enough to make people switch.

During Stage A, compare at least three direct alternatives. Record who they serve, their first-session flow, logging steps, free and paid limits, offline behavior, data export, health connections, AI use, accessibility, and user complaints. Use the same sample tasks in each app. Do not treat the feature matrix as proof that users will switch or pay.

**Decision trigger:** Continue only if target users name a specific pain that this app can solve better. Record what evidence would change the product scope. Choose a sustainable open-source support model after testing willingness to pay or support the project.

## 16.3 Confirmed navigation and ownership

Use five main tabs in this order:

1. **Home:** Today summary, next action, and quick links.
2. **Workout:** Exercise library, plans, workout history, and live logging.
3. **Meal:** Meal plan, food entry, and meal history.
4. **Analytics:** Progress from saved user records.
5. **Me:** Account, sync, health, AI and MCP connections, privacy, export, deletion, and support.

This map follows the user's latest instruction. Keep these five labels consistent in designs, code, screenshots, and help text. Do not put Meal or Workout under an Activity tab.

Put AI and MCP connections under **Me → AI connections**. Show each provider, granted data categories, connection state, last access where available, and a clear revoke or disconnect action. Keep AI, health access, and cloud sync as separate controls.

## 16.4 Supplied UI references

The user supplied both reference images. The handbook stores copies here:

- [Meal planner UI reference](references/meal-ui-reference.png)
- [Workout UI reference](references/workout-ui-reference.png)

Use the first image to guide Meal screen hierarchy and layout. Use the second image to guide Workout screen hierarchy and visual energy. Use the same app theme, tokens, and font on both screens. Do not treat sample values, names, people, logos, or promotional marks as product content. The images are design references, not evidence of user needs or permission to reuse third-party assets.

## 16.5 Recommended first release

Build a private beta with these features:

- Home, Workout, Meal, Analytics, and Me tabs.
- Manual exercise and meal entry.
- Exercise library with user-created movements.
- Workout plans and complete set-by-set session logging.
- Meal plans and custom food entries.
- Local history, correction, and deletion.
- Analytics that open the saved records behind each result.
- Local export and clear storage warnings.
- A tested decision for OS backup and local data recovery.
- Accessible layouts, reduced-motion behavior, and purposeful motion.

Keep core logging usable without sign-in or network access. Do not add cloud sync, remote MCP, BYOK calls, a commercial food database, social features, or company product analytics to this beta.

HealthKit and Health Connect remain planned product capabilities. First complete their technical and policy spike. Add them in a later release when the supported data types, user benefit, platform targets, and package are clear. Ask before each data type. The operating system can group requested data types in one sheet. Show each requested type before opening that sheet. Manual logging must keep working when the user declines.

## 16.6 Verified technology direction

### Mobile

Use **Flutter and Dart** as the working mobile choice. Official Flutter release documentation lists stable Flutter 3.47. Use the latest approved 3.47 patch when implementation starts, record the bundled Dart version, and pin the SDK. Do not assume that 3.47 remains the right version at build time.

Flutter is a reasonable fit for one custom visual system and a shared iPhone/Android UI. It does not guarantee a smaller app or better performance. Measure an optimized build on real devices before setting product claims.

### Candidate libraries

Package registry pages checked on 2026-10-05 list these versions:

| Need | Candidate | Plan |
|---|---|---|
| UI state | flutter_riverpod 3.4.3 | Prototype with it. Keep feature state separate from widgets. |
| Navigation | go_router 18.0.2 | Prototype the five persistent tabs and nested pages. |
| Local database | Drift 2.35.1 with SQLite | Prototype transactions, migrations, and recovery. |
| Secure keys | flutter_secure_storage 11.2.0 | Prototype key storage and upgrade behavior. Do not store records or logs here. |
| Health APIs | health_connector 3.11.1 or health 13.3.2 | Evaluate one at a time. Do not add either to the core app before the health spike. |

These are versions published in package registries. The Flutter release and package pages are linked from [Technology stack](10-technology-stack.md). They are not tested together, frozen dependencies, or a security review. Confirm SDK constraints, licenses, open issues, maintainers, transitive packages, and platform builds. Then commit the package lock file. If a package is incompatible, choose a supported version and update this table.

The health packages have native platform requirements. The current health_connector guide lists Android API 26+, iOS 15+, a FlutterFragmentActivity requirement, and a newer SDK extension requirement for some Health Connect features. The health package also lists iOS 15+ and FlutterFragmentActivity setup for its Android permission flow. Health Connect itself requires Android 9+ with Google Play services ([Android availability](https://developer.android.com/health-and-fitness/health-connect/availability)). These package and platform ranges are not the same. Pick the app's minimum OS versions after the device prototype and intended user reach are known.

### Flutter versus Expo

Keep Flutter as the working choice. Reopen the comparison only if the team has much stronger React and TypeScript experience or the prototype finds a concrete Flutter limitation. Expo also needs development builds for native Health APIs. Compare optimized builds and real permission flows, not hot-reload speed or Expo Go.

### Backend

Do not build a backend for the local-first beta. A later sync or remote MCP service may use Node.js, TypeScript, Fastify, PostgreSQL, and the official MCP SDK. Treat these as candidates. Select hosting, identity, region, backups, retention, and operations only after the team approves a cloud data flow.

## 16.7 Data, sign-in, and AI plan

Keep workout and meal records in the app's local database first. Explain that phone-only data can be lost if the device is lost or erased. Provide export.

Apple or Google sign-in is identity. It does not save or back up records to the user's Apple or Google account. Review Apple login rules if Google is offered on iPhone ([App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)). Sync and backup need a separate service and a separate user choice. Do not require sign-in for core logging.

Keep external AI out of the first beta. A BYOK key only authenticates the app to a model provider. It does not give the model access to the app's local records. If the app sends selected records to a model, show which data leaves the phone and which provider receives it.

A remote MCP server cannot access records stored only on the phone. It needs an approved server-side copy or a working relay. Remote MCP therefore needs a backend, account binding, OAuth scopes, user consent, data retention rules, and security tests. Start with read-only access if this stage is approved. Put controls in **Me → AI connections**. Never claim that remote AI data stays on the phone.

For early experiments, use a user-selected export or share action. Do not send records in the background. Do not let AI change a workout or meal without user approval.

## 16.8 Visual and motion plan

Keep one theme across all five tabs. Use SF Pro on iPhone and Inter elsewhere (D-023), one reviewed Lucide icon family, and shared color, spacing, type, and radius tokens. The Meal and Workout references guide composition, not separate themes.

Build these states for every important screen: first use, loading, saved, save failure, offline, empty, disabled, and permission unavailable. State must be clear without color or animation.

Use motion to show where a screen came from, confirm a saved action, and explain a value change. Use short tab transitions, a clear set-complete response, a quiet saved-meal insert, and a one-time chart update. Keep timers accurate without relying on animation. Do not block input for an effect. Respect the device's reduced-motion setting. Use haptics only for meaningful actions and follow system settings.

The five-tab navigation must retain visible labels and accessible names. Keep each touch target at least 48 logical pixels unless platform review requires more. Check large text, one-handed workout use, VoiceOver, TalkBack, and contrast in rendered screens. The handbook's color ratios are calculated for the listed pairings; verify actual components after implementation.

Do not call the interface “amazing” or “fast” as a verified result until people use it and the team measures a release build.

## 16.9 Build and proof stages

### Stage A: User proof

- Select the first user group.
- Interview and observe people who log workouts or meals today.
- Test whether one app for both jobs makes their routine easier.
- Record the tasks, friction, and current alternatives.
- Decide whether both Meal and Workout belong in the first release.

### Stage B: Five-tab screen prototype

- Make all five tabs clickable.
- Test the exact supplied references as visual direction.
- Test a set-entry flow, a meal-entry flow, a progress drill-down, and AI controls in Me.
- Test empty, error, offline, permission-denied, and large-text states.
- Fix task failures before detailed illustration or motion work.

### Stage C: Flutter technical prototype

- Pin Flutter stable and Dart versions.
- Build the five-tab navigation shell.
- Save a workout set and meal entry in SQLite through Drift.
- Close and reopen the app during and after saves.
- Test one lower-cost supported Android phone and one supported iPhone.
- Measure startup, screen response, battery, memory, and release size.
- Test reduced motion and screen-reader labels.
- Prototype each health package separately only if health remains in scope.
- Record results and update the decision log.

### Stage D: Private beta

- Build the core local-first product.
- Add data correction, export, deletion, and migrations.
- Test every analytics result against its source records.
- Run privacy, accessibility, reliability, and device checks.
- Fix data-loss and data-mixing issues before release.

### Stage E: Optional connections

- Add health access with individual purpose text and minimum data types.
- Add sign-in only when sync or another user benefit requires it.
- Add sync after conflict, recovery, deletion, and backup behavior pass review.
- Add BYOK or remote MCP only after data-sharing screens and provider controls pass privacy and security review.
- Test account linking and record restore across iPhone and Android.

## 16.10 Decisions and status

**Accepted from the user's instruction:** Five tabs named Home, Workout, Meal, Analytics, and Me. Workout owns exercise browsing, plans, history, and set logging. Me owns AI and MCP connection controls. The two supplied images are the Meal and Workout layout references. Use one shared theme. Include optional HealthKit and Health Connect access after the health-data stage passes.

**Proposed:** Flutter as the mobile baseline; Riverpod, go_router, Drift, and secure storage as candidates; local-first core; delayed cloud and AI service work.

**To confirm:** Target user, launch countries, exact OS minimums, database encryption, account and backup service, remote MCP model, food data source, launch license, numeric performance targets, and support owner.

## 16.11 Official checks made

These sources were checked on 2026-10-05:

- [Flutter stable release notes](https://docs.flutter.dev/release/release-notes) list Flutter 3.47.
- [pub.dev flutter_riverpod](https://pub.dev/packages/flutter_riverpod) lists 3.4.3.
- [pub.dev go_router](https://pub.dev/packages/go_router) lists 18.0.2.
- [pub.dev drift](https://pub.dev/packages/drift) lists 2.35.1.
- [pub.dev flutter_secure_storage](https://pub.dev/packages/flutter_secure_storage) lists 11.2.0.
- [pub.dev health_connector](https://pub.dev/packages/health_connector) lists 3.11.1.
- [pub.dev health](https://pub.dev/packages/health) lists 13.3.2.
- [Apple HealthKit authorization](https://developer.apple.com/documentation/HealthKit/authorizing-access-to-health-data) describes fine-grained access and the limits on detecting denied read permission.
- [Android Health Connect permissions](https://developer.android.com/health-and-fitness/health-connect/ui/permissions) describes permission management and connection controls.
- [Google Play health data policy](https://support.google.com/googleplay/android-developer/answer/18258653) describes its health-data policy requirements.
- [Apple App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/) includes login service and health-data review rules.

A current package page does not prove compatibility, security, accessibility, or good performance in this app. The build must prove those points.

## 16.13 Build progress

Updated 2026-10-06. This records what exists in code. It is not evidence of device quality.

**Built in `app/` (local-first, no network code):**

- Five-tab shell with preserved tab state and a persistent control that returns to a live workout.
- Workout: exercise library with custom exercises, plans with ordered exercises and optional targets, copy and delete plans, empty or plan-based sessions, set-by-set logging, set types, pause and continue, optional rest timer, finish or save as incomplete, discard with confirmation, history, and correction of saved sessions. Session time comes from stored timestamps, so it survives a restart.
- Meal: day selector, meal slots that the user can add, rename, time, and remove, planned versus eaten entries, custom foods with optional nutrients, saved foods, serving size kept apart from amount eaten, estimate flag, and source.
- Analytics: 7, 30, and 90 day ranges, workouts, training days, completed sets, recorded reps, meal coverage, nutrition totals with missing-value counts, a per-day bar chart without lines across missing days, the records behind each summary, and personal records with the named rule "Heaviest completed load".
- Me: units, rest timer, energy view switch, honest states for account, health, and AI connections, app updates screen, JSON export through the system share sheet, delete all records, privacy summary, and licenses.
- CI workflow for format, generated code, analysis, tests, and Android and iOS debug builds.

**Checked:** 27 unit and widget tests pass on Linux with Flutter 3.47.6. Screens were rendered in a test harness and reviewed.

**Not yet checked:** Real iPhone and Android devices, release builds, startup and set-entry timing, app size, VoiceOver, TalkBack, large text on devices, reduced motion on devices, and the CI workflow on GitHub runners. The Android and iOS builds did not run locally because the build machine has no Android SDK or Xcode.

**Redesign (2026-10-05, owner request):** New light and dark themes without purple (D-015). Meal tab rebuilt to follow the meal reference. Home simplified to one main action and large tiles. Analytics rebuilt with a training heatmap, change against the previous period, volume, muscles trained by body area, best lifts, and a macro donut. Built-in catalog of 36 coached exercises with an animated, rotatable 3D body model (D-016). Database schema v2 with a tested migration. 38 tests pass.

**Exercise library (2026-10-05, owner request):** Bundled 873 public-domain exercises from Free Exercise DB with start and end photos (D-017). Workout → Exercises now has search, body-area tiles, and a full list filtered by area and equipment. Library detail pages show the photos as a cross-fade loop, muscles, and steps. Coached guides use library photos in place of the body model. The add-exercise sheet searches the same list. CI uploads the release-mode APK as a plain file.

**Device test fixes (2026-10-06):** First test on a real Android phone (realme RMX3710, Android 15). Fixed: the guide link in a live workout switched tabs instead of opening the guide; nutrition legend names wrapped letter by letter; "Protein" was cut off on the Meal summary; pill tabs and area chips could not be activated by screen readers; muscle labels overflowed at large text. Also: a new exercise in a workout starts with one empty set, the library hides filters while the keyboard is open, and entries without equipment say "No equipment".

**AI, health, backup, and brand (2026-10-06, owner request):**

- AI connections over MCP (D-018): Wi-Fi server on the phone and the owner's own gateway on Vercel (`gateway/`), 12 tools, separate switches for workouts, meals, health, and plan suggestions, access windows of 15 minutes to 2 hours, sign-in approval with a match code, app keys, revocation, and an activity list without content.
- AI proposals (D-019): workout and meal plans wait for review in Me → AI connections and on Home.
- Apple Health and Health Connect (D-020): per-type switches, today's steps and active energy on Home, write-back of finished workouts and eaten meals.
- Backup and restore (D-021): phone backup rules and encrypted backup files.
- App icon, splash, and animated intro (D-022). Website in `site/`. Release workflow that publishes an APK and an IPA to GitHub Releases.
- Database schema v3 with a tested migration. 77 app tests and 14 gateway tests pass on Linux. A release APK builds locally.

**Not yet checked for this work:** Health access, the Wi-Fi server, and the online gateway on real devices; a deployed gateway on Vercel; the iOS build on a GitHub macOS runner; claude.ai, ChatGPT, Codex, and Cursor against a live gateway. See the compatibility note in section 10.2.

**Not built:** update metadata checks, update alerts, sign-in, live two-way sync, automatic backup files to a cloud drive, crash reporting, App Store and Google Play signing in CI.

**Owner request (2026-10-06):** iOS-native look on both platforms (D-023). Exercises browse by body area, then muscle, with drawn body icons and "Start here" picks (D-024). Slow, tempo-timed exercise demos with half speed and a slider. Weight calculator. Five roadmaps × three levels with warm-ups, equipment swaps, and full editing (D-025). Fibre, sugar, and sodium; opt-in daily targets; USDA food list; Plan my day by diet (D-026). Home rebuilt around one action, today's food, and the week. Analytics split into Workout and Meal tabs with more metrics. Read-only MCP tools, a local stdio MCP server, scoped export, and AI plan import with approval (D-027). Database schema v4 with a tested migration from v3. 319 unit and widget tests pass on Linux with Flutter 3.47.6. The joint "R" mark in teal and lime (D-028). Update alerts for GitHub builds and logged warm-ups (D-029). 326 tests pass.

**Workout and roadmap clean-up (2026-10-06, owner request):** One start card on the Workout tab (live workout, else the next roadmap day, else an empty workout); Start on that card and on Home starts the next roadmap day at once. One start function for every kind of workout. The day page and the live workout share one target line, and the ramp-up weights are in the first lift's note. Warm-up moves get the number of sets set on the day page. Ramp-up sets only on loaded lifts. Pull-ups can swap to a lat pulldown again. Plans show their target as a note and start each exercise with at least one set. History counts exercises without warm-up moves. 331 tests pass on Linux with Flutter 3.47.6. Not checked on a real device.

**Not checked for this round:** Real devices, VoiceOver and TalkBack on the new screens, large text on devices, and coach or dietitian review of the content.

## 16.12 AI context

- **Purpose:** Give every contributor the current, evidence-based build order.
- **First navigation:** Home, Workout, Meal, Analytics, Me.
- **First product:** Manual logging, local save, history, traceable analytics, export, and deletion.
- **References:** Read the two supplied image files linked in Section 3 before changing Meal or Workout screens.
- **Stack:** Use the dated candidates in Section 11. Re-check them before adding dependencies.
- **Sign-in:** Identity does not equal backup.
- **AI:** A BYOK key is not access to app records. Remote MCP needs an approved route to records.
- **Health:** Ask only for a named data type when the related feature needs it.
- **Motion:** Use shared motion rules. Respect reduced motion. Never delay logging.
- **Do not:** Build cloud services before approval, claim a test without evidence, or silently change the accepted five-tab map.
