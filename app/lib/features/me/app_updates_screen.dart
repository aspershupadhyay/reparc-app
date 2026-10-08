import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../updates/apk_installer.dart';
import '../../updates/update_check.dart';
import '../../updates/update_controller.dart';

export '../../updates/update_controller.dart' show packageInfoProvider;

/// Me → App updates (handbook 17.3, D-029).
///
/// Checks GitHub for a newer published build. On Android, Download and
/// install fetches the APK in the app, checks its SHA-256, and opens
/// Android's installer, which asks the user to confirm. The app never
/// installs anything by itself. iPhone opens the release page.
class AppUpdatesScreen extends ConsumerStatefulWidget {
  const AppUpdatesScreen({super.key});

  @override
  ConsumerState<AppUpdatesScreen> createState() => _AppUpdatesScreenState();
}

class _AppUpdatesScreenState extends ConsumerState<AppUpdatesScreen> {
  bool _checking = false;
  String? _message;
  ApkProgress? _progress;
  bool _failed = false;

  Future<void> _check() async {
    setState(() {
      _checking = true;
      _message = null;
    });
    final r = await ref.read(updateControllerProvider).check();
    if (!mounted) return;
    setState(() {
      _checking = false;
      _message = switch (r) {
        UpToDate(:final latest) => 'You have the latest version (${latest.version}).',
        UpdateFound(:final release) => 'Version ${release.version} is ready to install.',
        CheckFailed(:final message) => message,
      };
    });
  }

  Future<void> _download(ReleaseInfo r, {bool browser = false}) async {
    final android = defaultTargetPlatform == TargetPlatform.android;
    if (!android || browser) {
      final ok = await ref.read(updateControllerProvider).openDownload(r);
      if (!ok && mounted) setState(() => _message = 'Could not open the browser. Open ${r.page} yourself.');
      return;
    }
    setState(() {
      _message = null;
      _failed = false;
      _progress = const ApkDownloading(0, null);
    });
    try {
      await ref.read(apkInstallerProvider)(r, (p) {
        if (mounted) setState(() => _progress = p);
      });
      if (mounted) {
        setState(() => _message = "Android's installer is open. Tap Update to finish. Your data stays on the phone.");
      }
    } on ApkError catch (e) {
      if (mounted) {
        setState(() {
          _progress = null;
          _failed = true;
          _message = e.message;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _progress = null;
          _failed = true;
          _message = 'The download did not work. Try again, or use the browser.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final installed = ref.watch(installedVersionProvider);
    final settings = ref.watch(currentSettingsProvider);
    final latest = ReleaseInfo.fromJson(settings.updatesLatest);
    final update = ref.watch(availableUpdateProvider);
    final android = defaultTargetPlatform == TargetPlatform.android;
    final checked = settings.updatesCheckedAt?.toLocal();

    return Scaffold(
      appBar: AppBar(title: const Text('App updates')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Metric(
                    label: 'Installed',
                    value: installed.value ?? missingText,
                    note: 'On this phone',
                  ),
                ),
                Expanded(
                  child: Metric(
                    label: 'Latest',
                    value: latest?.version ?? missingText,
                    note: checked == null ? 'Not checked yet' : 'Checked ${_when(checked, DateTime.now())}',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          if (update != null) ...[
            _UpdateCard(
              release: update,
              android: android,
              progress: _progress,
              onDownload: () => _download(update),
              onBrowser: _failed ? () => _download(update, browser: true) : null,
            ),
            const SizedBox(height: Space.l),
          ],
          OutlinedButton.icon(
            onPressed: _checking ? null : _check,
            icon: _checking
                ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(LucideIcons.refreshCw, size: IconSizes.s),
            label: Text(_checking ? 'Checking' : 'Check for updates'),
          ),
          if (_message != null) ...[
            const SizedBox(height: Space.m),
            Semantics(
              liveRegion: true,
              child: StatusLine(icon: LucideIcons.info, text: _message!),
            ),
          ],
          const SizedBox(height: Space.l),
          AppCard(
            padding: EdgeInsets.zero,
            child: SwitchListTile(
              title: const Text('Check automatically'),
              subtitle: const Text('Once a day, when you open the app. Home tells you when a new version is out.'),
              value: settings.updatesAuto,
              onChanged: (v) => ref.read(settingsRepoProvider).setUpdatesAuto(v),
            ),
          ),
          const SectionHeader('How updates work'),
          Text(
            android
                ? 'Tap Download and install. Reparc downloads the new version, checks that the file is exactly '
                      'the published one, and opens Android\'s installer. Tap Update there. The first time, Android '
                      'asks you to allow installs from Reparc. Your workouts and meals stay, because every build is '
                      'signed with the same key.'
                : 'Tap Download to open the release page. Save the IPA and install it with AltStore or Sideloadly, '
                      'like the first time. Your workouts and meals stay on the phone.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: Space.m),
          Text(
            'A check asks GitHub for the latest release. It sends no records, account, or device data. '
            'GitHub sees your IP address, as with any website. The app never installs anything by itself: '
            'Android always asks you first.',
            style: t.bodySmall?.copyWith(color: p.inkSoft),
          ),
        ],
      ),
    );
  }
}

/// "today 6:00 PM", "yesterday", or "4 Mar": short enough for one line.
String _when(DateTime t, DateTime now) {
  final days = DateTime(now.year, now.month, now.day).difference(DateTime(t.year, t.month, t.day)).inDays;
  return switch (days) {
    0 => 'today ${fmtTime(t)}',
    1 => 'yesterday',
    _ => DateFormat('d MMM').format(t),
  };
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.release,
    required this.android,
    required this.onDownload,
    this.progress,
    this.onBrowser,
  });
  final ReleaseInfo release;
  final bool android;
  final VoidCallback onDownload;
  final ApkProgress? progress;
  final VoidCallback? onBrowser;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: p.brandSoft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(LucideIcons.sparkles, color: p.brand, size: 40),
              const SizedBox(width: Space.m),
              Expanded(child: Text('Version ${release.version} is ready', style: t.titleMedium)),
            ],
          ),
          if (release.publishedAt != null) ...[
            const SizedBox(height: Space.xs),
            Text('Published ${fmtDayShort(release.publishedAt!.toLocal())}', style: t.bodySmall),
          ],
          if (release.summary.isNotEmpty) ...[
            const SizedBox(height: Space.s),
            Text(release.summary, style: t.bodyMedium),
          ],
          const SizedBox(height: Space.l),
          if (progress case final ApkDownloading d)
            Semantics(
              liveRegion: true,
              label: d.fraction == null ? 'Downloading' : 'Downloading, ${(d.fraction! * 100).round()} percent',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: Radii.small,
                    child: LinearProgressIndicator(value: d.fraction, minHeight: 8),
                  ),
                  const SizedBox(height: Space.xs),
                  ExcludeSemantics(
                    child: Text(
                      d.total == null
                          ? 'Downloading ${_mb(d.received)}'
                          : 'Downloading ${_mb(d.received)} of ${_mb(d.total!)}',
                      style: t.bodySmall?.tabular,
                    ),
                  ),
                ],
              ),
            )
          else if (progress is ApkVerifying)
            const StatusLine(icon: LucideIcons.shieldCheck, text: 'Checking the file')
          else
            FilledButton.icon(
              onPressed: onDownload,
              icon: const Icon(LucideIcons.download, size: 20),
              label: OneLine(
                android ? (progress is ApkReady ? 'Open installer again' : 'Download and install') : 'Download',
              ),
            ),
          if (onBrowser != null) ...[
            const SizedBox(height: Space.s),
            TextButton(onPressed: onBrowser, child: const Text('Download in the browser instead')),
          ],
        ],
      ),
    );
  }
}

String _mb(int bytes) => '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
