import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/clock.dart';
import '../core/distribution.dart';
import '../data/providers.dart';
import 'apk_installer.dart';
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
  // Google Play delivers its own updates (handbook 17.10).
  if (playBuild) return null;
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

  /// Opens the download in the browser. Android uses this only as a
  /// fallback when the in-app download fails; iPhone always gets the release
  /// page, because an IPA needs AltStore or Sideloadly.
  Future<bool> openDownload(ReleaseInfo r) {
    final android = defaultTargetPlatform == TargetPlatform.android;
    final url = android ? (r.apk ?? r.page) : r.page;
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }
}

/// Android: downloads, checks, and opens the installer. Tests replace it.
final apkInstallerProvider = Provider<Future<void> Function(ReleaseInfo, void Function(ApkProgress))>(
  (ref) =>
      (r, onProgress) => downloadAndInstall(r, onProgress: onProgress),
);

/// Where the in-app update download stands. It belongs to the app, not to
/// the App updates screen, so leaving the screen (Back, another tab) does
/// not stop it or lose its progress, and a second tap cannot start a second
/// download over the first.
class ApkDownloadState {
  const ApkDownloadState({this.progress, this.message, this.failed = false});
  final ApkProgress? progress;
  final String? message;

  /// The last attempt failed; the screen offers the browser instead.
  final bool failed;

  bool get running => progress is ApkDownloading || progress is ApkVerifying;
}

class ApkDownloadController extends Notifier<ApkDownloadState> {
  @override
  ApkDownloadState build() => const ApkDownloadState();

  /// Asks GitHub for the newest release first, so a release published since
  /// the last check is the one downloaded, then downloads, checks, and opens
  /// Android's installer. [saved] is used when the check fails.
  Future<void> start(ReleaseInfo saved) async {
    if (state.running) return;
    state = const ApkDownloadState(progress: ApkDownloading(0, null));
    var release = saved;
    switch (await ref.read(updateControllerProvider).check()) {
      case UpdateFound(release: final newest):
        release = newest;
      case UpToDate(:final latest):
        state = ApkDownloadState(message: 'You have the latest version (${latest.version}).');
        return;
      case CheckFailed():
        break;
    }
    try {
      await ref.read(apkInstallerProvider)(release, (p) => state = ApkDownloadState(progress: p));
      state = const ApkDownloadState(
        progress: ApkReady(),
        message:
            "Android's installer is open. Tap Update to finish. Your data stays on the phone. "
            'If it did not open, tap Open installer.',
      );
    } on ApkError catch (e) {
      state = ApkDownloadState(failed: true, message: e.message);
    } catch (_) {
      state = const ApkDownloadState(
        failed: true,
        message: 'The download did not work. Try again, or use the browser.',
      );
    }
  }
}

final apkDownloadProvider = NotifierProvider<ApkDownloadController, ApkDownloadState>(ApkDownloadController.new);

/// Runs the quiet daily check once per app start. The shell watches it.
final autoUpdateCheckProvider = FutureProvider<void>((ref) async {
  try {
    await ref.read(updateControllerProvider).autoCheck();
  } catch (_) {
    // A failed background check is not shown; App updates can retry.
  }
});
