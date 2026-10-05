---
title: Product and data diagrams
status: proposed
owner: product-and-engineering
updated: 2026-10-05
---

# Product and data diagrams

These diagrams describe planned behavior. They do not show implemented code. Keep them aligned with the source chapters.

## 1. Main navigation

```mermaid
flowchart TD
    App[Open app] --> Home[Home tab]
    App --> Workout[Workout tab]
    App --> Meal[Meal tab]
    App --> Analytics[Analytics tab]
    App --> Me[Me tab]
    Workout --> Library[Exercise library]
    Workout --> Plans[Workout plans]
    Workout --> History[Workout history]
    Workout --> Active[Live workout logging]
    Active --> Pause[Pause or continue]
    Active --> Finish[Finish and review]
    Meal --> Add[Plan or log meal]
    Add --> SaveMeal[Save meal]
    Analytics --> Sources[Open source records]
    Me --> AI[AI and MCP connections]
    Me --> Controls[Privacy and data controls]
```

## 2. Workout session states

A session must not disappear when the app closes. Save each valid set locally.

```mermaid
stateDiagram-v2
    [*] --> Draft
    Draft --> Active: Start session
    Active --> Paused: Pause or leave app
    Paused --> Active: Continue session
    Active --> Finished: Finish session
    Paused --> Finished: Finish session
    Active --> Incomplete: Save incomplete
    Paused --> Incomplete: Save incomplete
    Finished --> Edited: Correct a record
    Incomplete --> Edited: Correct a record
    Edited --> [*]
```

## 3. Local-first record flow

```mermaid
flowchart LR
    User[User action] --> App[Flutter app]
    App --> Validate[Validate fields and units]
    Validate --> Local[(Local SQLite store)]
    Local --> Saved[Show saved state]
    Local -. If sync is enabled .-> Queue[Sync queue]
    Queue --> API[Account API]
    API --> Cloud[(PostgreSQL)]
    API --> Status[Show sync status]
    Local --> Export[User export]
    Local --> Delete[User delete]
```

A local save must finish before sync starts. An offline or failed sync must not block workout or meal entry.

## 4. Optional remote MCP data path

```mermaid
sequenceDiagram
    actor User
    participant Client as Compatible AI client
    participant Auth as OAuth authorization
    participant MCP as Remote MCP service
    participant Store as User data service
    User->>Client: Ask about selected data
    Client->>MCP: Request protected resource
    MCP-->>Client: Authorization required
    Client->>Auth: Ask user to grant narrow scopes
    Auth-->>Client: Short-lived token
    Client->>MCP: Call read-only tool with token
    MCP->>MCP: Check token, user, scope, and date range
    MCP->>Store: Read only approved records
    Store-->>MCP: Matching records
    MCP-->>Client: Result with source and date range
    Client-->>User: Explain result and missing data
```

The AI client receives the records needed for the answer. The app must explain this before the user connects. Revoking the token must stop later requests. The Me tab owns connection setup, access scopes, connection status, and revocation.

## 5. Product lifecycle

```mermaid
flowchart LR
    Research[Research] --> Validate[Internal screen validation]
    Validate --> Foundation[Production foundation]
    Foundation --> Alpha[Private production alpha]
    Alpha --> Sync[Optional sync]
    Sync --> Health[Health access]
    Health --> MCP[MCP pilot]
    MCP --> Release[Public release]
    Release --> Operate[Support and updates]
    Operate --> Retire[Feature end-of-life]
```

A later stage can be skipped only when the product owner records the reason. Optional sync, health access, and MCP are not required for the first release.

## 6. Production release and update flow

GitHub starts a controlled release. The app gets update information from the store or a data-only release manifest. The store installs the app binary.

```mermaid
flowchart TD
    PR[Reviewed pull request] --> CI[Required CI checks]
    CI --> Tag[Protected release tag]
    Tag --> Build[Protected signed build]
    Build --> Test[Internal store testing track]
    Test --> Gate{Release gates pass?}
    Gate -->|No| Fix[Fix and run checks again]
    Fix --> PR
    Gate -->|Yes| Review[Store review and publish]
    Review --> Notice[In-app update notice]
    Review -. User opt-in .-> Push[Optional push notice]
    Notice --> Choice{Platform install flow}
    Push --> Choice
    Choice -->|Standard iPhone release| Store[Open App Store]
    Choice -->|Android from Play| Play[Google Play in-app update]
    Store --> User[User approves install]
    Play --> User
```

Do not send notices for a branch push or an unpublished store build. Do not install executable code from GitHub.

## AI context

- **Purpose:** Give humans and AI agents a shared view of major flows.
- **Source:** Follow the detailed rules in the linked feature chapters.
- **Rule:** Update a diagram when its source flow changes.
- **Rule:** Do not treat a diagram as evidence that code exists.
- **Rule:** Update releases follow the store flow in [Production readiness and app updates](16-production-and-app-updates.md).
- **Rule:** Keep local records available when remote services fail.
