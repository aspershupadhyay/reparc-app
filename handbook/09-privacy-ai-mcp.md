---
title: Privacy, AI, MCP, and BYOK
status: proposed
owner: product-and-security
updated: 2026-10-06
---

# Section 10: Privacy, AI, MCP, and BYOK

## 10.1 Privacy rule
See [Product and data diagrams](13-diagrams.md) for the optional remote MCP data path.



Tell users what data the app collects, why it needs the data, where it goes, how long it stays, and how to remove it.

Use separate choices for account sync, health access, AI access, and product-use analytics. Do not bundle them into one consent.

Do not sell health or workout data. Do not put private records in ads, crash reports, or ordinary server logs.

## 10.2 MCP in simple words

MCP is a standard that lets a compatible AI client ask another service for data or tools. The AI client must support the connection. An AI subscription does not automatically connect to this app. Test each client and publish a compatibility list. Do not claim that every AI model or app can connect.

## 10.3 Where AI connections live and how they work

Put connection setup under **Me → AI connections**. Show the provider or MCP server, the data scopes it can read, the last connection state, and a clear disconnect or revoke action.

A provider key does not grant access to app records. A local key can let an app call a model provider, but the app must still send selected records for that request. The model provider may receive that data. Explain which provider receives the request and what records are included.

A remote MCP server cannot read records that exist only in the phone's local database. It needs a server-side copy, an online relay, or a direct local connection supported by the AI client and phone operating system. Do not assume that a desktop or cloud AI can reach a phone-local MCP server.

For the first release, keep AI as a later feature. If a user asks to use an external AI, offer a clear, user-initiated export or share of a selected summary. Do not send records in the background. Add remote MCP only after a separate architecture and privacy decision.

## 10.4 First MCP tools

Start with read-only tools:

- Get a workout summary for a date range.
- Get history for one exercise.
- Get meal totals for a date range.
- List personal records with their rules.

Do not allow an AI tool to change records in the first release. If write tools are added later, show a preview and ask the user to approve each change.

## 10.5 MCP access controls

- Require the user to set up the connection.
- Let the user select Meal, Gym, and health data separately.
- Use OAuth for remote access where supported.
- Use narrow access scopes.
- Use short-lived access tokens.
- Let the user revoke access.
- Limit request rate and date range.
- Tie every request to one user.
- Test that one user's token cannot read another user's records.

MCP authorization uses OAuth-based protection for remote servers. Review the current protocol before implementation: https://modelcontextprotocol.io/specification/2026-07-28/basic/authorization

## 10.6 Local and remote AI

A local MCP service can limit data sharing, but a cloud AI may not be able to reach it. A remote MCP service can serve a cloud AI, but the records requested go to that AI provider for the request.

Explain this before the user connects. Do not promise that remote MCP keeps data only on the phone.

End-to-end encryption and remote MCP may conflict. A remote server cannot answer questions about encrypted records unless a trusted component can decrypt or process them. Decide and document this before building remote MCP.

## 10.7 AI response rules

- Show the record source and date range.
- Mark missing values and estimates.
- Do not invent a value.
- Do not give medical or diet treatment advice.
- Do not change a record without user approval.
- Do not log private prompts or returned records.
- Do not claim that a model trained on user data is safe without evidence and a separate consent flow.

## 10.8 BYOK

BYOK means “bring your own key.” It lets a user provide a provider key. It does not grant the app permission to read the user's records.

If BYOK is added:

- Name the provider that receives the request.
- Store the key in operating-system secure storage where possible.
- Never write the key to logs or crash reports.
- Let the user replace or delete it.
- Do not send the key to our server unless required and clearly disclosed.
- Explain provider costs and limits.

## 10.9 AI context

- **Purpose:** Give an AI client narrow access to data the user selects.
- **Location:** Me → AI connections.
- **Status display:** Show provider, data scopes, connection status, and revoke action.
- **First release:** No background AI access. User-initiated export or share only.
- **First remote MCP release:** Read-only tools, after a separate approval.
- **Consent:** Separate access for Meal, Gym, and health data.
- **Security:** OAuth, narrow scopes, expiry, revocation, per-user checks.
- **Truth:** Keep source, date range, missing values, and estimates visible.
- **Never:** Claim every AI app is compatible or that remote data stays on-device.
- **To confirm:** MCP release timing, server placement, identity provider, and supported clients.

## 10.10 What is built (2026-10-06)

D-022. No background AI access and no network code.

1. Me → AI connections: the user turns Workouts, Meals, and Body data on or off, then taps **Export for AI**. Only the chosen data is in the file. Units and app settings that are not personal stay in.
2. The user gives the file to an AI app. With MCP: build `app/tool/mcp/server.dart` once (`dart compile exe`) and add it to the AI app's MCP settings with the file path. The server uses stdio only and opens no port. Without MCP: attach the file to a chat.
3. Tools (all read-only): `get_profile_and_targets`, `get_workout_summary`, `get_exercise_history`, `list_personal_records`, `get_roadmap`, `get_meal_totals`, `get_meal_log`, `get_body_weight`, `get_import_formats`, `check_roadmap_proposal`, `check_meal_plan_proposal`. A tool for data the user did not share is not offered.
4. Plans come back through **Import a plan**: paste, check, preview, approve. Imported foods are marked as estimates and added as planned.

Code: `app/lib/mcp/`. The AI provider receives what is in the file. Tell the user this before export (the screen does).
