---
title: Competitor review and Play media check
status: findings-and-proposals
date: 2026-11-08
---

# Competitor review: Hevy, MyFitnessPal, openGym (2026-11-08)

Owner request: "check all the features of our app each and every corner and find the gap, compare it with Hevy, and for meal MyFitnessPal, how our UI will compete, also openGym the open source project ... why people will use our app instead of theirs", and "if we make our app public on Play Store, can the videos or GIFs we have cause an issue?"

This is a review. Its proposals are **Proposed**, not accepted decisions. Competitor facts come from public pages on 2026-11-08 (sources at the end); prices and limits change, so check them again before using them in a store listing. Nothing here was tested on a phone.

## 1. What RepArc has today (from the code, v0.5.1 + this session)

| Area | Built |
|---|---|
| Gym logging | Free workout or plan day; set types; rest timer; guided coach mode with voice cues that work with the phone locked; history with corrections; Same and Pyramid fill; warm-up moves |
| Exercises | 873 exercises with start and end photos (Free Exercise DB), coached guides, body-area → muscle → group tree, 3D body map, body icons, swap for a similar move |
| Plans | Five goal roadmaps × three levels, editable, with weekdays and progression notes |
| Runs, walks, rides | GPS with Kalman smoothing, splits, climb; screen-off recording; **from this session:** distance from steps without GPS |
| Meals | Slots with times, planned vs eaten, custom foods, 171 bundled USDA foods grouped by country, recipe estimates, fibre/sugar/sodium, targets, Plan my day |
| Analytics | 7/30/90 days, heatmap, volume, muscles trained, best lifts, steps and distance, macros |
| Health | Apple Health and Health Connect read and write; **from this session:** Allow all in one sheet |
| AI | MCP connection to Claude, ChatGPT, and others; AI plans wait for approval |
| Data | Local first, encrypted backup files, JSON export, delete all, no account, no server |

## 2. Against Hevy (gym logging)

Hevy: free tier with up to 4 routines and limited custom exercises; Pro (about US$3/month or US$24/year, lifetime about US$75) for unlimited routines, all-time stats, warm-up calculator, and its trainer. Strong social feed, Apple Watch and Wear OS apps, a web app, and since September 2026 sending a workout to ChatGPT or Claude.

| | Hevy | RepArc | Gap for RepArc |
|---|---|---|---|
| Routines | 4 free, unlimited Pro | Unlimited, free | Ahead |
| Guided workout | Rest timer | Coach mode: timed sets, voice, lock screen | Ahead |
| Exercise demos | Short videos | Two photos, cross-fade; 3D Motion Lab is a prototype (D-038 Proposed) | Behind: photos look dated next to video |
| Social feed, follow friends | Yes, core feature | No | Behind (by choice: no server) |
| Watch app | Apple Watch, Wear OS | No | Behind |
| Import from other apps | Yes (Strong CSV) | No | Behind: users will not re-type years of logs |
| Supersets | Yes | Not in the live workout (only a set type in the schema) | Behind |
| Per-exercise charts and PRs | Yes | Exercise history list, best lifts | Partly behind: no e1RM or volume chart per exercise |
| Plate and warm-up calculator | Pro | Weight calculator, ramp-up sets | Level |
| AI | Send to ChatGPT/Claude | MCP: the AI reads live data and proposes plans for approval | Ahead |
| Privacy | Account and cloud | No account; data stays on the phone | Ahead |
| Runs and rides | Basic | GPS with splits; steps fallback | Ahead |

## 3. Against MyFitnessPal (meals)

MyFitnessPal: free tier with ads; Premium about US$80/year. The barcode scanner moved behind Premium (2022–2023), the most cited complaint in 1-star reviews. Very large crowd food database, recipe import, meal scan, fasting, water.

| | MyFitnessPal | RepArc | Gap for RepArc |
|---|---|---|---|
| Food database | Millions of entries, many duplicates and wrong values | 171 checked USDA foods plus recipe estimates | **Far behind.** The largest gap in the app |
| Barcode scan | Premium only | None | Behind, but a free scan would be a reason to switch |
| Ads | Yes on free | None | Ahead |
| Planned vs eaten | No | Yes | Ahead |
| Missing values | Often shown as 0 | Kept as missing | Ahead |
| Quick add calories, copy a day | Yes | Partial (copy exists in places) | Check |
| Water, fasting | Yes | No | Behind (minor) |
| Speed of logging | Search, recent, frequent, scan | Search-first Add food | Behind until the database is bigger |

## 4. Against openGym (open source)

openGym (AGPL v3): a self-hosted tracker. Docker server, web app, Android APK to sideload, no iPhone build, imports from Strong, Hevy, and FitNotes, optional AI coach. 1.5k–8k stars depending on the source.

| | openGym | RepArc |
|---|---|---|
| Setup | Needs a server (Docker) | Install and use; no server |
| Phones | Android APK only | Android and iPhone builds |
| Import | Strong, Hevy, FitNotes | None |
| Meals, GPS, health apps | Not its focus | Built |
| Source | Open (AGPL) | Closed (D-035) |

## 5. Why someone would pick RepArc

1. **One app for gym, food, and runs**, without an account, a feed, or ads. Hevy has no food; MyFitnessPal has weak gym logging; openGym needs a server.
2. **Hands-free coach mode** that runs the workout with voice and works with the phone locked. Hevy and Strong only time the rest.
3. **Nothing behind a paywall** that the others charge for: unlimited routines (Hevy Pro), no ads (MyFitnessPal Premium).
4. **Your AI, your data:** connect Claude or ChatGPT to the live log; plans need your approval.
5. **Honest numbers:** missing is not zero, estimates are marked, GPS is filtered.

It will **not** win today on: food search breadth, barcode scanning, exercise videos, friends, a watch app, or moving from another app.

## 6. Proposed next work (owner to choose)

In order of how many users each one stops from leaving:

1. **Import from Strong and Hevy CSV** (both export CSV). Small, high value: removes the main reason not to switch.
2. **Barcode scan with Open Food Facts** (open data, ODbL; needs attribution and a network call per scan; values must be marked as from Open Food Facts). Free, against MyFitnessPal's paid scan. Needs an owner decision: first network use for meals, and the licence terms.
3. **Bigger food list:** more USDA FNDDS foods per country, and recent and frequent foods at the top of Add food.
4. **Supersets in the live workout.**
5. **Per-exercise chart:** estimated 1RM and volume over time.
6. **Exercise motion:** move the Motion Lab into the app (D-038, Proposed) or render short loops from the gym model, to replace two-photo demos.
7. Later: a Wear OS and Apple Watch companion; water.

## 7. Play Store: can the pictures, "GIFs", and sounds cause problems?

RepArc ships **no video files and no GIFs**. What looks like motion is two still WebP photos per exercise, cross-faded (1,746 images, 26 MB). Other media: voice clips, body icons, the 3D body.

| Asset | Source and licence | Play risk | Action |
|---|---|---|---|
| Exercise photos (`assets/exercises/img/`) | Free Exercise DB, marked Unlicense (public domain). Its README says the data started from the "exercises.json" project; **where the photos came from is not stated**, and an open issue (#12) asks about the photos' licence with no answer | **Medium.** If a photo was copied from a commercial site, its owner can file a takedown and Play can remove the app | Before Play: confirm the photos' origin, or replace them with frames rendered from our own CC0 gym model |
| Voice clips (`assets/voice/`) | ElevenLabs **free plan**: no commercial use; credit needed | **Medium–high.** A store release, even a free one, can count as commercial use | Before Play: upgrade to a paid ElevenLabs plan and make the clips again (D-031 already says this), or record new ones |
| Body icons (`assets/body/icons/`) | Figma image generation on the owner's Education plan; the owner confirmed use (2026-10-12) | Low–medium: check that the Education plan's terms allow use in a published app | Confirm the plan terms |
| 3D body map, gym model | MakeHuman CC0 | Low | None |
| Inter font, Lucide icons | OFL, ISC | Low | Licences are in the app |

Other Play items that touch "video":

- **Location foreground service** (GPS runs): Play asks for a **short video** that shows the feature using the foreground service, in the Play Console declaration. Record it from the release build.
- **Health apps declaration:** fill it for every Health Connect type (steps, distance, active calories, weight, exercise write, nutrition write). Allow all asks for all six at once; each must still be used by a feature, as it is now.
- **Play build:** remove `REQUEST_INSTALL_PACKAGES` (D-036 already does this for the Play bundle).

## Sources

- Hevy help centre, features: https://help.hevyapp.com/hc/en-us/articles/33106320824727
- Hevy free vs Pro, third-party review: https://www.sensai.fit/blog/hevy-review-2026
- Hevy pricing comparison: https://www.sensai.fit/blog/fitness-app-pricing-free-tier-comparison
- MyFitnessPal cost: https://www.fitbudd.com/post/myfitnesspal-app-cost
- MyFitnessPal barcode complaints: https://kimola.com/reports/myfitnesspal-removes-free-barcode-scanner-feature-140890
- MyFitnessPal 1-star review analysis: https://unstar.app/blog/calorie-tracking-apps-ranked-1-star-reviews-2026
- openGym overview: https://noted.lol/opengym/ and https://selfhostedworld.com/software/opengym
- openGym release notes: https://newreleases.io/project/github/DuarteSantos8/openGym/release/v1.2.1
- Free Exercise DB: https://github.com/yuhonas/free-exercise-db and issue https://github.com/yuhonas/free-exercise-db/issues/12
- ElevenLabs publishing rules: https://elevenlabs.io/docs/help-center/legal/can-i-publish-the-content-i-generate-on-the-platform
- Play health apps: https://developer.android.com/health-and-fitness/health-connect/publish and https://support.google.com/googleplay/android-developer/answer/12991134
