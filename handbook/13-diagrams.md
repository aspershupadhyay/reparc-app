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

## 2a. Guided workout flow (handbook 4.13)

With both **Run on its own** switches on (the default), no tap is needed after **Start workout**. Every time comes from Me → Workout guide.

```mermaid
flowchart LR
    Start([Start workout]) --> W1[Warm-up move 1]
    W1 -->|no rest| W2[Warm-up move 2 ... last]
    W2 --> WR[Rest after warm-up]
    WR --> S1[Set 1]
    S1 --> R1[Rest between sets]
    R1 --> S2[Set 2]
    S2 --> R2[Rest between sets]
    R2 --> S3[Set 3]
    S3 --> R3[Rest] --> Next[Next exercise: set 1, rest, set 2, rest, set 3]
    Next --> Done([Every set done: user finishes and saves])
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

## 4. MCP data paths (D-018, D-019)

Online, through the owner's own gateway:

```mermaid
sequenceDiagram
    actor User
    participant Client as AI app
    participant GW as Owner's gateway (Vercel)
    participant Redis as Upstash Redis
    participant Phone as Reparc on the phone
    Note over Phone,GW: User turns on online access (15 min to 2 h). Phone long-polls with the owner key.
    Client->>GW: POST /mcp (no token)
    GW-->>Client: 401 with resource metadata
    Client->>GW: Register, then open /oauth/authorize (PKCE S256)
    GW-->>User: Consent page shows a 4-letter code
    Phone->>GW: Owner lists sign-in requests
    User->>Phone: Approve when the code matches
    GW-->>Client: Code, then access and refresh tokens
    Client->>GW: tools/call with token
    GW->>Redis: Sealed call (AES-256-GCM, expires in 60 s)
    Phone->>GW: Poll
    GW->>Redis: Take sealed call
    GW-->>Phone: Call
    Phone->>Phone: Check arguments and the user's data switches
    Phone->>GW: Answer from local data
    GW->>Redis: Sealed answer (expires in 60 s)
    GW-->>Client: Tool result
```

On the same Wi-Fi:

```mermaid
sequenceDiagram
    participant Client as AI app on a computer
    participant Phone as Reparc MCP server on the phone
    Client->>Phone: POST http://<phone>:8765/mcp with Bearer key
    Phone->>Phone: Private address? No Origin? Key matches? Body small?
    Phone-->>Client: Tool result from local data
```

Plan proposals:

```mermaid
flowchart LR
    AI[AI app] -->|propose_workout_plan or propose_meal_plan| P[(ai_proposals: pending)]
    P --> Review[Review screen in Me and on Home]
    Review -->|Approve| Save[Plans or planned meals saved]
    Review -->|Decline| Drop[Nothing saved]
```

The AI app receives the answers it asks for. The app explains this before the user connects. Removing an app in Reparc stops its later requests at once. The gateway keeps no records.

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
