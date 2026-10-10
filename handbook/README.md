---
title: Reparc Handbook
status: active-plan
updated: 2026-10-06
---

# Reparc Fitness App Handbook

This handbook plans an open-source fitness app for iPhone and Android. Its chosen working name is **Reparc**. Trademark, domain, and app-store name clearance are **To confirm**.

## Read in order

1. [Product goal](00-product.md)
2. [Scope and release stages](01-lifecycle.md)
3. [Five-tab screen map, design system, and motion](02-experience-and-design.md)
4. [Gym workout logging](03-workouts.md)
5. [Meal planning and logging](04-meals.md)
6. [Analytics and progress](05-analytics.md)
7. [Data model and offline use](06-data-and-offline.md)
8. [Accounts and sync](07-accounts-and-sync.md)
9. [HealthKit and Health Connect](08-health-data.md)
10. [Privacy, AI, MCP, and BYOK](09-privacy-ai-mcp.md)
11. [Technology stack and Flutter decision](10-technology-stack.md)
12. [Open-source license, testing, release, and support](11-open-source-release.md)
13. [Decision record](12-decisions.md)
14. [Product and data diagrams](13-diagrams.md)
15. [Feature specification template](14-feature-spec-template.md)
16. [Validated plan and open decisions](15-validated-plan.md)
17. [Production readiness and app updates](16-production-and-app-updates.md)

## Reviews

- [Launch review, 2026-10-10](reviews/2026-10-10-launch-review/index.html): Play Store readiness, design gaps, two data bugs found in a real workout, user pain points, and the open decisions. Findings and proposals only, not accepted decisions. Open the file in a browser.

## Supplied UI references

- [Meal planner reference](references/meal-ui-reference.png)
- [Workout reference](references/workout-ui-reference.png)

## Status and source of truth

This handbook describes a plan. It does not prove that a feature exists.

- **Accepted** means the user approved the section or choice. A section can still contain open items.
- **Proposed** means a choice needs approval or evidence from internal validation.
- **To confirm** means the team has not verified or approved that item.
- Update the section that owns a behavior when the behavior changes.
- Keep major choices in the decision record.
- Do not claim privacy, speed, or store compliance without evidence.

## Instructions for AI agents and contributors

Read this file, the root AGENTS.md file, and the section for the task before changing code or data. Follow the AI context block in that section. Use the [feature specification template](14-feature-spec-template.md) for new features. Do not invent product behavior, sample data, health facts, or security promises. If a **To confirm** item blocks safe work, state the choice needed. Record completed work separately from planned work.

## Writing style

Use short sentences for steps, rules, and checklists. Use common words and active voice. Give one instruction in each sentence. Use plain English for decisions and trade-offs. Keep technical names such as Flutter, HealthKit, Health Connect, and MCP. This handbook aims for about 80% of ASD-STE100. It does not claim formal compliance.

## Current status

The app is in `app/`. It covers the local-first core, AI connections over MCP (D-018, D-019), Apple Health and Health Connect (D-020), and backup and restore (D-021). The owner's own MCP gateway is in `gateway/`. The website is in `site/`. The core was tested on one real Android phone; the newer features have passed automated tests only. App Store and Google Play delivery are not set up. There is no Reparc server. See [build progress](15-validated-plan.md#1613-build-progress). Technology and product choices marked **Proposed** or **To confirm** still need validation.


## AI context

- The app foundation exists in `app/`. Check [build progress](15-validated-plan.md#1613-build-progress) before you claim a feature is built.
- Follow the five accepted tabs and shared theme.
- Read each feature's AI context and acceptance checks.
- Treat proposed stack and release stages as unapproved until verified.
- Never claim features, privacy, policy, tests, or performance without evidence.
