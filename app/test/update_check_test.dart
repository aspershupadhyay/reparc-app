import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/app/app.dart';
import 'package:reparc/app/router.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/features/exercises/library/library.dart';
import 'package:reparc/updates/apk_installer.dart';
import 'package:reparc/updates/update_check.dart';
import 'package:reparc/updates/update_controller.dart';

import 'helpers.dart';

/// The shape GitHub returns for /releases/latest (trimmed).
Map<String, Object?> release(String tag) => {
  'tag_name': tag,
  'html_url': 'https://github.com/aspershupadhyay/reparc/releases/tag/$tag',
  'published_at': '2026-10-06T15:49:38Z',
  'body': 'Reparc $tag (beta). New logo and colours.\n\n**Android:** download the APK.',
  'assets': [
    {
      'name': 'reparc-android.apk',
      'browser_download_url': 'https://github.com/aspershupadhyay/reparc/releases/download/$tag/reparc-android.apk',
    },
    {
      'name': 'reparc-ios-unsigned.ipa',
      'browser_download_url':
          'https://github.com/aspershupadhyay/reparc/releases/download/$tag/reparc-ios-unsigned.ipa',
    },
    {'name': 'SHA256SUMS.txt', 'browser_download_url': 'https://example.invalid/sums'},
  ],
};

void main() {
  test('versions compare by number, not as text', () {
    expect(parseVersion('v0.3.1'), [0, 3, 1]);
    expect(parseVersion('0.10.0+12'), [0, 10, 0]);
    expect(parseVersion('latest'), isNull);
    expect(isNewer('0.3.2', '0.3.1'), isTrue);
    expect(isNewer('v0.10.0', '0.9.9'), isTrue);
    expect(isNewer('1.0.0', '0.99.99'), isTrue);
    expect(isNewer('0.3.1', '0.3.1'), isFalse);
    expect(isNewer('0.3.0', '0.3.1'), isFalse);
    expect(isNewer('nonsense', '0.3.1'), isFalse);
  });

  test('a GitHub release gives the version, notes, and both downloads', () {
    final r = ReleaseInfo.fromGitHub(release('v0.4.0'));
    expect(r.version, '0.4.0');
    expect(r.apk.toString(), endsWith('/v0.4.0/reparc-android.apk'));
    expect(r.ipa.toString(), endsWith('/v0.4.0/reparc-ios-unsigned.ipa'));
    expect(r.summary, 'Reparc v0.4.0 (beta). New logo and colours.');
    expect(r.publishedAt, DateTime.utc(2026, 10, 6, 15, 49, 38));
    // Saved and read back the same.
    final again = ReleaseInfo.fromJson(jsonEncode(r.toJson()))!;
    expect(again.version, r.version);
    expect(again.apk, r.apk);
    expect(() => ReleaseInfo.fromGitHub({'tag_name': 'not-a-version', 'html_url': 'x'}), throwsFormatException);
  });

  test('the APK for this phone\'s processor is preferred, the full APK is the fallback', () {
    // GitHub lists the full APK first, so older apps that take the first
    // .apk still get one that installs everywhere.
    final j = release('v0.4.9');
    j['assets'] = [
      ...(j['assets']! as List),
      for (final abi in ['armeabi-v7a', 'arm64-v8a', 'x86_64'])
        {
          'name': 'reparc-android-$abi.apk',
          'browser_download_url':
              'https://github.com/aspershupadhyay/reparc/releases/download/v0.4.9/reparc-android-$abi.apk',
        },
    ];
    expect(ReleaseInfo.fromGitHub(j, abi: 'arm64-v8a').apk.toString(), endsWith('/reparc-android-arm64-v8a.apk'));
    expect(ReleaseInfo.fromGitHub(j, abi: 'armeabi-v7a').apk.toString(), endsWith('/reparc-android-armeabi-v7a.apk'));
    expect(ReleaseInfo.fromGitHub(j, abi: 'riscv64').apk.toString(), endsWith('/reparc-android.apk'));
    // A release without per-processor files still gives the full APK.
    expect(ReleaseInfo.fromGitHub(release('v0.4.8'), abi: 'arm64-v8a').apk.toString(), endsWith('/reparc-android.apk'));
    // The test machine is not Android.
    expect(ReleaseInfo.androidAbi(), isNull);
  });

  group('controller', () {
    late AppDatabase db;
    late FakeClock clock;
    late int calls;
    late Map<String, Object?> Function() answer;
    late ProviderContainer c;

    setUp(() {
      db = memoryDb();
      clock = FakeClock(DateTime(2026, 10, 6, 9));
      calls = 0;
      answer = () => release('v0.4.0');
      c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          installedVersionProvider.overrideWith((ref) async => '0.3.2'),
          fetchJsonProvider.overrideWithValue((url) async {
            calls++;
            expect(url, latestReleaseApi);
            return answer();
          }),
        ],
      );
      c.listen(currentSettingsProvider, (_, _) {});
    });
    tearDown(() async {
      c.dispose();
      await db.close();
    });

    test('a newer release is found, saved, and offered', () async {
      final r = await c.read(updateControllerProvider).check();
      expect(r, isA<UpdateFound>());
      expect((r as UpdateFound).release.version, '0.4.0');
      await pumpEventQueue();
      final s = c.read(currentSettingsProvider);
      expect(s.updatesCheckedAt, isNotNull);
      expect(c.read(availableUpdateProvider)?.version, '0.4.0');
    });

    test('the same or an older release means up to date', () async {
      answer = () => release('v0.3.2');
      expect(await c.read(updateControllerProvider).check(), isA<UpToDate>());
      await pumpEventQueue();
      expect(c.read(availableUpdateProvider), isNull);
    });

    test('a failed check says why and saves nothing', () async {
      c.updateOverrides([
        databaseProvider.overrideWithValue(db),
        clockProvider.overrideWithValue(clock.call),
        installedVersionProvider.overrideWith((ref) async => '0.3.2'),
        fetchJsonProvider.overrideWithValue((url) async => throw const UpdateCheckError('No connection.')),
      ]);
      final r = await c.read(updateControllerProvider).check();
      expect((r as CheckFailed).message, 'No connection.');
      await pumpEventQueue();
      expect(c.read(currentSettingsProvider).updatesCheckedAt, isNull);
    });

    test('a download asks GitHub first and takes the newest release, and runs once at a time', () async {
      // The last check saw 0.4.0; 0.4.1 came out since.
      answer = () => release('v0.4.1');
      final started = <String>[];
      final gate = Completer<void>();
      // A container with a fake installer, in place of the shared one.
      c.dispose();
      c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          installedVersionProvider.overrideWith((ref) async => '0.3.2'),
          fetchJsonProvider.overrideWithValue((url) async => answer()),
          apkInstallerProvider.overrideWithValue((r, onProgress) async {
            started.add(r.version);
            onProgress(const ApkDownloading(10, 100));
            await gate.future;
            onProgress(const ApkReady());
          }),
        ],
      );
      final saved = ReleaseInfo.fromGitHub(release('v0.4.0'));
      final dl = c.read(apkDownloadProvider.notifier);
      final first = dl.start(saved);
      await pumpEventQueue();
      expect(c.read(apkDownloadProvider).running, isTrue);
      // A second tap (for example after Back and coming back) does not start another.
      await dl.start(saved);
      gate.complete();
      await first;
      expect(started, ['0.4.1']);
      expect(c.read(apkDownloadProvider).progress, isA<ApkReady>());
    });

    test('a download when already up to date says so and downloads nothing', () async {
      final saved = ReleaseInfo.fromGitHub(release('v0.4.0'));
      answer = () => release('v0.3.2');
      var downloads = 0;
      // A container with a fake installer, in place of the shared one.
      c.dispose();
      c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          installedVersionProvider.overrideWith((ref) async => '0.3.2'),
          fetchJsonProvider.overrideWithValue((url) async => answer()),
          apkInstallerProvider.overrideWithValue((r, onProgress) async => downloads++),
        ],
      );
      await c.read(apkDownloadProvider.notifier).start(saved);
      expect(downloads, 0);
      expect(c.read(apkDownloadProvider).message, 'You have the latest version (0.3.2).');
    });

    test('the automatic check runs at most once a day and can be turned off', () async {
      final ctl = c.read(updateControllerProvider);
      await ctl.autoCheck();
      expect(calls, 1);
      clock.advance(const Duration(hours: 3));
      await ctl.autoCheck();
      expect(calls, 1, reason: 'Checked recently');
      clock.advance(const Duration(hours: 21));
      await ctl.autoCheck();
      expect(calls, 2);
      await c.read(settingsRepoProvider).setUpdatesAuto(false);
      clock.advance(const Duration(days: 2));
      await ctl.autoCheck();
      expect(calls, 2, reason: 'Turned off');
    });
  });

  testWidgets('Home tells the user about a new version; App updates offers the download', (tester) async {
    final db = memoryDb();
    final library = ExerciseLibrary.parse(File('assets/exercises/library.json').readAsStringSync());
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(() => DateTime(2026, 10, 6, 9)),
          libraryProvider.overrideWith((ref) async => library),
          installedVersionProvider.overrideWith((ref) async => '0.3.2'),
          fetchJsonProvider.overrideWithValue((url) async => release('v0.4.0')),
        ],
        child: ReparcApp(router: buildRouter(initialLocation: '/home')),
      ),
    );
    await tester.pumpAndSettle();
    // The daily check ran when the app opened. Its database write is real
    // I/O, so give it a real moment.
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsOneWidget);
    expect(find.text('Version 0.4.0 is ready to install.'), findsOneWidget);

    await tester.tap(find.text('Update available'));
    await tester.pumpAndSettle();
    expect(find.text('App updates'), findsOneWidget);
    expect(find.text('Version 0.4.0 is ready'), findsOneWidget);
    expect(find.text('0.3.2'), findsOneWidget);
    expect(find.text('Download and install'), findsOneWidget, reason: 'Tests run as Android');
    expect(find.text('Check automatically'), findsOneWidget);

    await tester.tap(find.text('Check for updates'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('Version 0.4.0 is ready to install.'), findsOneWidget);

    // Hiding the notice on Home lasts until the next version.
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hide until the next version'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    await tester.pumpAndSettle();
    expect(find.text('Update available'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    await tester.runAsync(db.close);
  });
}
