import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cryptography/cryptography.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'update_check.dart';

/// Android only: downloads the new APK when the user taps Download and
/// install, checks it against the release's SHA256SUMS.txt, and hands it to
/// Android's package installer. The installer always asks the user to
/// confirm; the app never installs anything by itself (D-029, handbook 17.3).

/// The SHA-256 for [fileName] in a SHA256SUMS.txt file, in lower case.
/// Null when the file is not listed.
String? shaFor(String sums, String fileName) {
  for (final line in const LineSplitter().convert(sums)) {
    final m = RegExp(r'^([0-9a-fA-F]{64})\s+\*?(.+)$').firstMatch(line.trim());
    if (m != null && m.group(2)!.trim() == fileName) return m.group(1)!.toLowerCase();
  }
  return null;
}

/// Where a download stands.
sealed class ApkProgress {
  const ApkProgress();
}

class ApkDownloading extends ApkProgress {
  const ApkDownloading(this.received, this.total);
  final int received;

  /// Null when the server does not say the size.
  final int? total;
  double? get fraction => total == null || total == 0 ? null : (received / total!).clamp(0, 1);
}

class ApkVerifying extends ApkProgress {
  const ApkVerifying();
}

class ApkReady extends ApkProgress {
  const ApkReady();
}

/// A failed download, with a message the user can act on.
class ApkError implements Exception {
  const ApkError(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Fetches text, such as SHA256SUMS.txt. Swappable for tests.
typedef FetchText = Future<String> Function(Uri url);

/// Saves a download to a file and returns its SHA-256. Swappable for tests.
typedef SaveTo = Future<String> Function(Uri url, File file, void Function(int, int?) onProgress);

/// Opens Android's installer for an APK. Swappable for tests.
typedef OpenInstaller = Future<void> Function(String path);

/// The SHA-256 of a file, in lower case. Swappable for tests.
typedef HashFile = Future<String> Function(File file);

/// Runs on a background isolate, so hashing a 60 MB file does not hold up
/// the screen.
Future<String> sha256OfFile(File file) {
  final path = file.path;
  return Isolate.run(() => _sha256(File(path)));
}

Future<String> _sha256(File file) async {
  final sink = Sha256().newHashSink();
  await for (final chunk in file.openRead()) {
    sink.add(chunk);
  }
  sink.close();
  final hash = await sink.hash();
  return hash.bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

const _channel = MethodChannel('app.reparc/installer');

Future<void> openAndroidInstaller(String path) async {
  try {
    await _channel.invokeMethod<void>('install', {'path': path});
  } on PlatformException catch (e) {
    throw ApkError(e.message ?? 'Android could not open the installer.');
  }
}

HttpClient _client() => HttpClient()
  ..connectionTimeout = const Duration(seconds: 15)
  ..userAgent = 'RepArc-update';

Future<String> httpGetText(Uri url) async {
  final client = _client();
  try {
    final res = await (await client.getUrl(url)).close().timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) throw ApkError('GitHub answered ${res.statusCode}. Try again later.');
    return await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 20));
  } finally {
    client.close(force: true);
  }
}

/// Streams [url] to [file], so a 100 MB APK never sits in memory, then
/// hashes the file on a background isolate. GitHub redirects downloads;
/// HttpClient follows them. Progress is reported about four times a
/// second, not for every network chunk, so redrawing the screen does not
/// slow the download (owner report, 2026-10-11).
Future<String> httpSaveTo(Uri url, File file, void Function(int, int?) onProgress) async {
  final client = _client();
  final out = file.openWrite();
  try {
    final res = await (await client.getUrl(url)).close().timeout(const Duration(seconds: 30));
    if (res.statusCode != 200) throw ApkError('GitHub answered ${res.statusCode}. Try again later.');
    final total = res.contentLength > 0 ? res.contentLength : null;
    var received = 0;
    final clock = Stopwatch()..start();
    var shownAt = -1000;
    await for (final chunk in res.timeout(const Duration(seconds: 60))) {
      out.add(chunk);
      received += chunk.length;
      if (clock.elapsedMilliseconds - shownAt >= 250) {
        shownAt = clock.elapsedMilliseconds;
        onProgress(received, total);
      }
    }
    onProgress(received, total);
    await out.flush();
    await out.close();
    return await sha256OfFile(file);
  } finally {
    await out.close();
    client.close(force: true);
  }
}

/// Downloads, checks, and opens the installer. Reports each step to
/// [onProgress]. Throws [ApkError] with a plain message on failure; a file
/// that fails the check is deleted and never reaches the installer.
///
/// When this version was already downloaded and still matches its checksum
/// (the user closed Android's installer, or it could not open while the app
/// was in the background), the installer opens again without a new download.
Future<void> downloadAndInstall(
  ReleaseInfo r, {
  required void Function(ApkProgress) onProgress,
  FetchText fetchText = httpGetText,
  SaveTo saveTo = httpSaveTo,
  OpenInstaller openInstaller = openAndroidInstaller,
  HashFile hashFile = sha256OfFile,
  Future<Directory> Function() folder = getTemporaryDirectory,
}) async {
  final apk = r.apk;
  final sums = r.sums;
  if (apk == null) throw const ApkError('This release has no Android file.');
  if (sums == null) throw const ApkError('This release has no checksum file, so the app will not install it.');
  final name = apk.pathSegments.isEmpty ? 'reparc-android.apk' : apk.pathSegments.last;
  try {
    final expected = shaFor(await fetchText(sums), name);
    if (expected == null) throw ApkError('$name is not in the checksum file.');
    final dir = Directory('${(await folder()).path}/updates');
    final file = File('${dir.path}/reparc-${r.version}.apk');
    if (file.existsSync()) {
      onProgress(const ApkVerifying());
      if (await hashFile(file) == expected) {
        await openInstaller(file.path);
        onProgress(const ApkReady());
        return;
      }
    }
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync(recursive: true);
    onProgress(const ApkDownloading(0, null));
    final actual = await saveTo(apk, file, (got, total) => onProgress(ApkDownloading(got, total)));
    onProgress(const ApkVerifying());
    if (actual != expected) {
      if (file.existsSync()) file.deleteSync();
      throw const ApkError('The download did not match its checksum, so it was deleted. Try again.');
    }
    await openInstaller(file.path);
    onProgress(const ApkReady());
  } on SocketException {
    throw const ApkError('The connection dropped. Check your internet and try again.');
  } on TimeoutException {
    throw const ApkError('The download stalled. Try again on a stronger connection.');
  } on FileSystemException {
    throw const ApkError('The app could not save the update file. Free some space and try again.');
  }
}
