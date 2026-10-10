/// Where this build is installed from (handbook 17.10).
///
/// The GitHub APK, for testing on a phone, checks GitHub Releases and can
/// hand a checked APK to Android's installer (D-029). The Google Play
/// build is made with `--dart-define=REPARC_STORE=play`. Play delivers its
/// updates, so that build has no update check, no download, and no
/// REQUEST_INSTALL_PACKAGES permission (android/app/src/play).
const String store = String.fromEnvironment('REPARC_STORE', defaultValue: 'github');

/// True in the Google Play build.
const bool playBuild = store == 'play';
