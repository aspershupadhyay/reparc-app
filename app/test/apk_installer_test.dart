import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/updates/apk_installer.dart';
import 'package:reparc/updates/update_check.dart';

import 'update_check_test.dart' show release;

void main() {
  const good = 'aa11223344556677889900aabbccddeeff00112233445566778899aabbccddee';
  final sums =
      '$good  reparc-android.apk\n'
      '0000000000000000000000000000000000000000000000000000000000000000  reparc-ios-unsigned.ipa\n';
  late Directory tmp;
  setUp(() => tmp = Directory.systemTemp.createTempSync('reparc-apk'));
  tearDown(() => tmp.deleteSync(recursive: true));

  test('finds the APK checksum in SHA256SUMS.txt', () {
    expect(shaFor(sums, 'reparc-android.apk'), good);
    expect(shaFor('${good.toUpperCase()}  reparc-android.apk', 'reparc-android.apk'), good);
    expect(shaFor('$good *reparc-android.apk', 'reparc-android.apk'), good, reason: 'Binary-mode marker');
    expect(shaFor(sums, 'other.apk'), isNull);
    final r = ReleaseInfo.fromGitHub(release('v0.4.0'));
    expect(r.sums.toString(), 'https://example.invalid/sums');
  });

  Future<(List<ApkProgress>, String?)> run(String hash) async {
    final steps = <ApkProgress>[];
    String? opened;
    await downloadAndInstall(
      ReleaseInfo.fromGitHub(release('v0.4.0')),
      onProgress: steps.add,
      fetchText: (_) async => sums,
      saveTo: (url, file, onProgress) async {
        file.writeAsStringSync('apk bytes');
        onProgress(50, 100);
        onProgress(100, 100);
        return hash;
      },
      openInstaller: (path) async => opened = path,
      folder: () async => tmp,
    );
    return (steps, opened);
  }

  test('a matching download goes to the installer', () async {
    final (steps, opened) = await run(good);
    expect(opened, '${tmp.path}/updates/reparc-0.4.0.apk');
    expect(File(opened!).existsSync(), isTrue);
    expect(steps.whereType<ApkDownloading>().last.fraction, 1.0);
    expect(steps.whereType<ApkVerifying>(), hasLength(1));
    expect(steps.last, isA<ApkReady>());
  });

  test('a download that fails the check is deleted and never opened', () async {
    await expectLater(run('ff' * 32), throwsA(isA<ApkError>()));
    expect(File('${tmp.path}/updates/reparc-0.4.0.apk').existsSync(), isFalse);
  });

  test('a version already downloaded and still matching opens the installer without a new download', () async {
    await run(good);
    var downloads = 0;
    String? opened;
    final steps = <ApkProgress>[];
    await downloadAndInstall(
      ReleaseInfo.fromGitHub(release('v0.4.0')),
      onProgress: steps.add,
      fetchText: (_) async => sums,
      saveTo: (url, file, onProgress) async {
        downloads++;
        return good;
      },
      hashFile: (_) async => good,
      openInstaller: (path) async => opened = path,
      folder: () async => tmp,
    );
    expect(downloads, 0);
    expect(opened, '${tmp.path}/updates/reparc-0.4.0.apk');
    expect(steps.whereType<ApkDownloading>(), isEmpty);
    expect(steps.last, isA<ApkReady>());

    // A file that no longer matches is downloaded again.
    await downloadAndInstall(
      ReleaseInfo.fromGitHub(release('v0.4.0')),
      onProgress: (_) {},
      fetchText: (_) async => sums,
      saveTo: (url, file, onProgress) async {
        downloads++;
        file.writeAsStringSync('apk bytes');
        return good;
      },
      hashFile: (_) async => 'ff' * 32,
      openInstaller: (_) async {},
      folder: () async => tmp,
    );
    expect(downloads, 1);
  });

  test('a release without a checksum file is not installed', () async {
    final j = release('v0.4.0');
    (j['assets']! as List).removeLast();
    var opened = false;
    await expectLater(
      downloadAndInstall(
        ReleaseInfo.fromGitHub(j),
        onProgress: (_) {},
        openInstaller: (_) async => opened = true,
        folder: () async => tmp,
      ),
      throwsA(isA<ApkError>()),
    );
    expect(opened, isFalse);
  });

  test('a download is saved, hashed on a background isolate, and reports progress a few times', () async {
    final body = List<int>.generate(3 * 1024 * 1024, (i) => i % 251);
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((req) async {
      req.response.contentLength = body.length;
      // Many small chunks, as a real network sends them.
      for (var i = 0; i < body.length; i += 4096) {
        req.response.add(body.sublist(i, (i + 4096).clamp(0, body.length)));
      }
      await req.response.close();
    });
    final dir = await Directory.systemTemp.createTemp('reparc-dl');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/a.apk');
    var calls = 0;
    int? last;
    final hash = await httpSaveTo(Uri.parse('http://127.0.0.1:${server.port}/a.apk'), file, (got, total) {
      calls++;
      last = got;
      expect(total, body.length);
    });
    expect(await file.length(), body.length);
    expect(last, body.length, reason: 'The last report is the whole file');
    expect(calls, lessThan(20), reason: 'Not one report per network chunk (768 chunks here)');
    expect(hash, await sha256OfFile(file));
    expect(hash, hasLength(64));
  });
}
