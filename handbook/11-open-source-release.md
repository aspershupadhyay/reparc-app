---
title: Open-source license, testing, release, and support
status: proposed
owner: maintainers
updated: 2026-10-05
---

# Section 12: Open-source license, testing, release, and support

## 12.1 Team roles

Assign an owner for each responsibility before public release. One person can own more than one role in a small team.

- **Product owner:** Sets scope and approves user-facing behavior.
- **Product designer:** Owns screen flows, design tokens, and accessibility details.
- **Flutter engineer:** Owns the mobile app, local database, and platform builds.
- **Backend engineer:** Owns account, sync, and MCP services if the product adds them.
- **Security and privacy reviewer:** Reviews data flows, permissions, tokens, and incidents.
- **Quality owner:** Plans tests and records release evidence.
- **Release owner:** Signs builds, prepares store submissions, and manages rollout.
- **Support owner:** Answers user reports and tracks recurring problems.

**To confirm:** Names and whether roles can be combined. Do not assume that a role is staffed because it appears here.

## 12.2 Source license

Choose a source license before publishing the repository.

**To confirm:** The project owner must choose the license after reviewing patent needs, reuse goals, trademark needs, and contributor rules. Apache-2.0 is one candidate. This handbook does not make that choice.

Keep app code, brand assets, exercise text, food data, fonts, and user data rights clear. Open-source source code does not make user records public.

## 12.3 Repository files

Before public release, provide:

- README with purpose, status, setup, and supported platforms.
- LICENSE.
- Contribution guide.
- Code of conduct.
- Security report instructions.
- Support contact.
- Changelog.
- Third-party license notices.
- This handbook.

Keep secrets and real user records out of the repository.

## 12.4 Contribution rules

- Use small pull requests.
- State the user problem and behavior change.
- Add tests for changed behavior.
- Add screenshots for visible screen changes.
- Add migration notes for data changes.
- Require extra review for health, privacy, sync, and MCP changes.
- Review AI-generated code for correctness, security, and license fit.

A contributor must understand the code they submit.

## 12.5 Test plan

Use synthetic records in development and CI.

Test these behaviors:

- Workout create, edit, delete, pause, finish, and restart recovery.
- Set units, missing values, and personal-record rules.
- Meal amount, source, units, and history.
- Analytics calculations and missing data.
- Offline save and app restart.
- Database migration from each supported version.
- Export and deletion.
- Sync retry, duplicate prevention, and conflict behavior if sync exists.
- Permission grant, refusal, revocation, and service unavailable states.
- MCP scope, user isolation, expiry, and revocation if MCP exists.
- Screen reader, text scaling, reduced motion, and keyboard behavior where applicable.
- Release size, startup, and set-entry response on real devices.

Do not call a test passed if it did not run. Record device, operating-system version, app build, and result for platform tests.

## 12.6 Release gates

Do not ship until:

- No open critical data-loss or account-isolation issue remains.
- Export and deletion work.
- Sync recovery works if sync exists.
- Privacy policy matches actual data flows.
- Health declarations match actual permissions.
- No secret is in source or the app package.
- Accessibility review is complete.
- Source and asset licenses are reviewed.
- Support and security contacts work.
- Signed release builds pass the agreed device checks.
- Backup restore is tested if a cloud backup exists.
- Rollback and incident plans are ready.

## 12.7 Release process

1. Freeze release scope.
2. Review security and data-loss issues.
3. Run checks on both platforms.
4. Build signed release files.
5. Record version, source commit, dependency lock, and build source.
6. Test install and upgrade from the previous release.
7. Start a staged rollout.
8. Review crash and support reports.
9. Expand rollout only when the release is healthy.
10. Publish plain release notes.

Do not publish a release from an arbitrary push to GitHub. Create a protected, reviewed release tag. Run the release workflow after the tag passes required checks. Submit the same signed build to the store testing track. Promote it after test and review gates pass.

Re-check Apple and Google requirements before each submission. Requirements can change.

## 12.8 Release automation and app updates

See [Production readiness and app updates](16-production-and-app-updates.md) for the required CI pipeline and the user update flow.

## 12.9 Support and operations

Provide a support path before launch. Tell users what information to include. Do not ask for a workout or meal export unless needed and the user understands its contents.

If cloud services exist:

- Monitor uptime, latency, failures, and authorization errors.
- Keep private record content out of routine logs.
- Encrypt backups.
- Limit backup access.
- Test restore on a schedule.
- Define backup retention.
- Explain how deletion applies to backups.

For a suspected incident, limit access, preserve evidence safely, assess impact, follow notice rules, tell users verified facts, fix the cause, and update this handbook.

## 12.10 Feature end-of-life

Before removing a feature, explain what will change and when. Provide export where needed. State whether old records remain viewable. Stop new collection. Remove permissions and keys. Update the privacy policy and handbook. Follow applicable retention rules.

Do not delete user records without a clear reason and notice.

## 12.11 AI context

- **Purpose:** Keep the open-source project safe and supportable.
- **Roles:** Name owners before public release.
- **License:** To confirm before public source release.
- **Tests:** Use synthetic data and test user-visible behavior.
- **Release:** Use signed builds and staged rollout.
- **Support:** Publish support and security contacts before launch.
- **Do not:** Claim a test passed if it did not run.
