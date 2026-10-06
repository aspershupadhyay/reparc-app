import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/clock.dart';
import '../data/providers.dart';
import 'update_check.dart';

final packageInfoProvider = FutureProvider((ref) => PackageInfo.fromPlatform());

/// The installed version, for example "0.3.1".
final installedVersionProvider = FutureProvider<String>(
  (ref) async => (await ref.watch(packageInfoProvider.future)).version,
);

/// How the app gets JSON from GitHub. Tests replace it.
final fetchJsonProvider = Provider<FetchJson>((ref) => httpGetJson);

/// The newest release seen by the last check, when it is newer than the
/// installed build. Null when the app is up to date or never checked.
final availableUpdateProvider = Provider<ReleaseInfo?>((ref) {
  final latest = ReleaseInfo.fromJson(ref.watch(currentSettingsProvider).updatesLatest);
  final installed = ref.watch(installedVersionProvider).value;
  if (latest == null || installed == null) return null;
  return isNewer(latest.version, installed) ? latest : null;
});

/// The result of one check, for the App updates screen.
sealed class CheckResult {
  const CheckResult();
}

class UpToDate extends CheckResult {
  const UpToDate(this.latest);
  final ReleaseInfo latest;
}

class UpdateFound extends CheckResult {
  const UpdateFound(this.release);
  final ReleaseInfo release;
}

class CheckFailed extends CheckResult {
  const CheckFailed(this.message);
  final String message;
}

final updateControllerProvider = Provider((ref) => UpdateController(ref));

class UpdateController {
  UpdateController(this.ref);
  final Ref ref;

  /// Only one automatic check per day.
  static const autoInterval = Duration(hours: 20);

  /// Checks GitHub for the latest release and saves what it found.
  Future<CheckResult> check() async {
    final repo = ref.read(settingsRepoProvider);
    try {
      final latest = await fetchLatestRelease(ref.read(fetchJsonProvider));
      await repo.setUpdateResult(at: ref.read(clockProvider)(), latestJson: jsonEncode(latest.toJson()));
      final installed = await ref.read(installedVersionProvider.future);
      return isNewer(latest.version, installed) ? UpdateFound(latest) : UpToDate(latest);
    } on UpdateCheckError catch (e) {
      return CheckFailed(e.message);
    } catch (_) {
      return const CheckFailed('The check did not work. Try again later.');
    }
  }

  /// The quiet check when the app opens: only when the user allows it and
  /// the last check is old. Failures stay silent; the screen can retry.
  Future<void> autoCheck() async {
    final s = await ref.read(settingsRepoProvider).watch().first;
    if (!s.updatesAuto) return;
    final last = s.updatesCheckedAt;
    if (last != null && ref.read(clockProvider)().difference(last.toLocal()) < autoInterval) return;
    await check();
  }

  /// Opens the download in the browser. Android gets the APK file, which the
  /// system installer opens after the user taps it; iPhone gets the release
  /// page, because an IPA needs AltStore or Sideloadly. The app itself never
  /// installs anything.
  Future<bool> openDownload(ReleaseInfo r) {
    final android = defaultTargetPlatform == TargetPlatform.android;
    final url = android ? (r.apk ?? r.page) : r.page;
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// Runs the quiet daily check once per app start. The shell watches it.
final autoUpdateCheckProvider = FutureProvider<void>((ref) async {
  try {
    await ref.read(updateControllerProvider).autoCheck();
  } catch (_) {
    // A failed background check is not shown; App updates can retry.
  }
});
