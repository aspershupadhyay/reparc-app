# Reparc MCP server

A small Model Context Protocol server that lets an AI app read one Reparc export file. It is read-only, uses stdio, and opens no network port. See handbook section 10.10 and decision D-027.

## 1. Export your data

In the app: **Me → AI connections**. Turn on the data you want to share (Workouts, Meals, Body and goals), then tap **Export for AI**. Save the file on your computer.

The AI app and its provider receive what is in the file.

## 2. Build the server once

Needs the Dart SDK (it comes with Flutter). From the `app/` folder:

```sh
dart compile exe tool/mcp/server.dart -o reparc-mcp
```

You can also run it without building: `dart run tool/mcp/server.dart <export.json>`. A built file starts faster and prints nothing extra.

## 3. Add it to your AI app

Example for Claude Desktop (`claude_desktop_config.json`):

```json
{
  "mcpServers": {
    "reparc": {
      "command": "/full/path/to/reparc-mcp",
      "args": ["/full/path/to/reparc-ai-export.json"]
    }
  }
}
```

Other MCP apps use the same command and argument. Restart the AI app after you change its settings.

## Tools

| Tool | What it returns |
|---|---|
| `get_profile_and_targets` | Profile and daily targets, each with its rule and source |
| `get_workout_summary` | Workouts, training days, working sets, reps, volume (kg), active time, sets per exercise |
| `get_exercise_history` | Every completed set of one exercise, with estimated one-rep max |
| `list_personal_records` | Heaviest load and best estimated one-rep max, per exercise and unit |
| `get_roadmap` | The active training roadmap |
| `get_meal_totals` | Nutrients per day, averages, and days on target |
| `get_meal_log` | Foods on one day |
| `get_body_weight` | Weight check-ins |
| `get_import_formats` | The JSON formats Reparc can import |
| `check_roadmap_proposal` | Checks an AI-written roadmap. Saves nothing |
| `check_meal_plan_proposal` | Checks an AI-written meal plan and compares it with targets. Saves nothing |

Tools for data you did not share are not offered. `null` means not recorded; it is never zero.

## Bring a plan back

Ask the AI to write a roadmap or meal plan in the format from `get_import_formats`. In the app, open **Me → AI connections → Import a plan**, paste it, check the preview, and approve. Nothing changes until you approve.

## Update the data

The server reads the file once. Export again and restart the AI app to share newer records. To stop sharing, delete the file.
