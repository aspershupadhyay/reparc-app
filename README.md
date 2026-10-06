# Reparc

Fitness app for iPhone and Android, planned with Flutter. The project is licensed under the GNU Affero General Public License v3.0 (AGPL-3.0-only).

The first local-first app foundation is in [`app/`](app/README.md). It has the five tabs in light and dark mode, workout and meal logging, a searchable library of 873 exercises with photos (public domain, from Free Exercise DB), 36 coached guides, history, analytics from saved records, export, and delete. It has not been tested on real devices or released. See [build progress](handbook/15-validated-plan.md#1613-build-progress).

## Try the Android test build

1. Open the [Actions tab](https://github.com/aspershupadhyay/reparc/actions/workflows/ci.yml) and select the newest green run on `main`.
2. Under **Artifacts**, download `app-release.apk`.
3. Open the file on an Android phone. Allow installs from your browser or file manager if Android asks.

The APK is a release-mode build signed with a test key. Install new builds the same way; the app does not update itself. Downloads expire after 14 days.

Start with the [handbook](handbook/README.md). It defines the five-tab map, product behavior, proposed technology, data and privacy rules, and release stages.

**Name status:** Reparc is the chosen working name. Trademark, domain, and app-store name clearance are still pending.

**License:** GNU Affero General Public License v3.0 (AGPL-3.0-only). See [LICENSE](LICENSE).
