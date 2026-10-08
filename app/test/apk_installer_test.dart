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
}
