# Audit report template

Copy this structure. Keep each finding short. Link every rule.

```markdown
# <App name> design audit, <date>

## Scope
- Build or commit: <sha or version>
- Screens: <list>
- Checked: code review | screenshots at <sizes> | light and dark | large text |
  screen reader | real phone (<model>)
- Not checked: <what and why>

## Purpose
<One sentence: who, what for, what feeling.>

## Summary
- Blockers: <n>, Must: <n>, Polish: <n>
- Fixed in this change: <n>. Proposed for the owner: <n>.

## Findings

| # | Screen | Severity | Finding | Rule (link) | Fix | Status |
|---|---|---|---|---|---|---|
| 1 | Meal | Polish | Floating "Add food" repeats each meal's "+" and covers the list | HIG Buttons: one prominent action; project rule | Remove the floating button | Fixed |

## Conflicts with project decisions
<Rule vs decision, the trade-off, and a recommendation. Do not change the
decision.>

## Checks run
<Analyzer, tests, design-rule tests, screenshots. Paste the pass/fail line.>
```

Severity:
- **Blocker:** data loss, a broken flow, a policy or privacy breach, or an
  action a screen-reader user cannot complete.
- **Must:** fails a rule with a number (contrast, target, text scaling), or
  confuses most people.
- **Polish:** clutter, inconsistency, wording, motion.
