import 'dart:async';
import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

/// Where RepArc builds are published (handbook 17.3, D-029).
/// Public repository that holds only the release builds. The source code
/// is private (handbook 17.9).
const releasesRepo = 'aspershupadhyay/reparc';
final latestReleaseApi = Uri.parse('https://api.github.com/repos/$releasesRepo/releases/latest');
final releasesPage = Uri.parse('https://github.com/$releasesRepo/releases/latest');

/// One published build, read from the GitHub release. The app installs
/// nothing by itself: on Android it can download the APK when the user taps,
/// check it, and hand it to Android's installer, which asks the user.
class ReleaseInfo {
  const ReleaseInfo({
    required this.version,
    required this.notes,
    required this.page,
    this.apk,
    this.ipa,
    this.sums,
    this.publishedAt,
  });

  /// For example "0.3.2", without the leading "v".
  final String version;
  final String notes;

  /// The release page on GitHub.
  final Uri page;

  /// Direct download for the Android APK, when the release has one.
  final Uri? apk;

  /// Direct download for the iPhone IPA, when the release has one.
  final Uri? ipa;

  /// SHA256SUMS.txt, used to check the APK before it reaches the installer.
  final Uri? sums;
  final DateTime? publishedAt;

  /// Reads the GitHub "latest release" response. Throws [FormatException]
  /// when it is not a usable release.
  ///
  /// Releases carry one APK per processor type (for example
  /// `reparc-android-arm64-v8a.apk`) beside the full `reparc-android.apk`.
  /// The one for this phone's [abi] is about 45% smaller, so it is
  /// preferred; the full APK is the fallback.
  factory ReleaseInfo.fromGitHub(Map<String, Object?> j, {String? abi}) {
    abi ??= androidAbi();
    final tag = j['tag_name'];
    final page = j['html_url'];
    if (tag is! String || page is! String || parseVersion(tag) == null) {
      throw const FormatException('Not a RepArc release.');
    }
    Uri? asset(String suffix) {
      for (final a in (j['assets'] as List? ?? const [])) {
        if (a is Map && (a['name'] as String? ?? '').endsWith(suffix) && a['browser_download_url'] is String) {
          return Uri.tryParse(a['browser_download_url'] as String);
        }
      }
      return null;
    }

    return ReleaseInfo(
      version: tag.replaceFirst(RegExp('^v'), ''),
      notes: (j['body'] as String? ?? '').trim(),
      page: Uri.parse(page),
      apk: (abi == null ? null : asset('-$abi.apk')) ?? asset('reparc-android.apk') ?? asset('.apk'),
      ipa: asset('.ipa'),
      sums: asset('SHA256SUMS.txt'),
      publishedAt: DateTime.tryParse(j['published_at'] as String? ?? ''),
    );
  }

  /// The Android ABI name of the running app, as in the APK file names,
  /// or null when it is not running on Android.
  static String? androidAbi() => switch (Abi.current()) {
    Abi.androidArm64 => 'arm64-v8a',
    Abi.androidArm => 'armeabi-v7a',
    Abi.androidX64 => 'x86_64',
    _ => null,
  };

  Map<String, Object?> toJson() => {
    'version': version,
    'notes': notes,
    'page': page.toString(),
    'apk': apk?.toString(),
    'ipa': ipa?.toString(),
    'sums': sums?.toString(),
    'publishedAt': publishedAt?.toIso8601String(),
  };

  static ReleaseInfo? fromJson(String? s) {
    if (s == null) return null;
    try {
      final j = jsonDecode(s) as Map<String, Object?>;
      return ReleaseInfo(
        version: j['version']! as String,
        notes: j['notes'] as String? ?? '',
        page: Uri.parse(j['page']! as String),
        apk: j['apk'] is String ? Uri.tryParse(j['apk'] as String) : null,
        ipa: j['ipa'] is String ? Uri.tryParse(j['ipa'] as String) : null,
        sums: j['sums'] is String ? Uri.tryParse(j['sums'] as String) : null,
        publishedAt: DateTime.tryParse(j['publishedAt'] as String? ?? ''),
      );
    } catch (_) {
      return null;
    }
  }

  /// Release notes without the install instructions the release adds.
  String get summary {
    final lines = notes.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return lines.isEmpty ? '' : lines.first.replaceAll('*', '');
  }
}

/// "v1.2.3", "1.2.3", or "1.2.3+4" → [1, 2, 3]. Null when it is not a version.
List<int>? parseVersion(String v) {
  final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)').firstMatch(v.trim());
  return m == null ? null : [for (var i = 1; i <= 3; i++) int.parse(m.group(i)!)];
}

/// True when [latest] is a newer version than [installed].
bool isNewer(String latest, String installed) {
  final a = parseVersion(latest), b = parseVersion(installed);
  if (a == null || b == null) return false;
  for (var i = 0; i < 3; i++) {
    if (a[i] != b[i]) return a[i] > b[i];
  }
  return false;
}

/// Gets JSON from [url]. Swappable for tests.
typedef FetchJson = Future<Map<String, Object?>> Function(Uri url);

/// Plain HTTPS GET with a short timeout. Sends no account, device, or app
/// data, only a fixed user agent that GitHub requires.
Future<Map<String, Object?>> httpGetJson(Uri url) async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final req = await client.getUrl(url);
    req.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'RepArc-update-check');
    final res = await req.close().timeout(const Duration(seconds: 15));
    final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 15));
    if (res.statusCode == 404) throw const UpdateCheckError('No published release yet.');
    if (res.statusCode == 403 || res.statusCode == 429) {
      throw const UpdateCheckError('GitHub is limiting checks right now. Try again in an hour.');
    }
    if (res.statusCode != 200) throw UpdateCheckError('GitHub answered ${res.statusCode}. Try again later.');
    return (jsonDecode(body) as Map).cast<String, Object?>();
  } on SocketException {
    throw const UpdateCheckError('No connection. Check your internet and try again.');
  } on TimeoutException {
    throw const UpdateCheckError('The check took too long. Try again.');
  } on HandshakeException {
    throw const UpdateCheckError('A secure connection to GitHub failed. Try again on another network.');
  } finally {
    client.close(force: true);
  }
}

/// A check that failed, with a message the user can act on.
class UpdateCheckError implements Exception {
  const UpdateCheckError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Fetches the latest published release.
Future<ReleaseInfo> fetchLatestRelease([FetchJson fetch = httpGetJson]) async {
  try {
    return ReleaseInfo.fromGitHub(await fetch(latestReleaseApi));
  } on FormatException {
    throw const UpdateCheckError('The release information was not readable. Try again later.');
  }
}
