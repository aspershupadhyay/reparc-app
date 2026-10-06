import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../updates/update_check.dart';
import '../../updates/update_controller.dart';

export '../../updates/update_controller.dart' show packageInfoProvider;

/// Me → App updates (handbook 17.3, D-029).
///
/// Checks GitHub for a newer published build and opens its download. The
/// app never downloads or installs code itself: the browser saves the file
/// and the phone's own installer asks the user to confirm.
class AppUpdatesScreen extends ConsumerStatefulWidget {
  const AppUpdatesScreen({super.key});

  @override
  ConsumerState<AppUpdatesScreen> createState() => _AppUpdatesScreenState();
}

class _AppUpdatesScreenState extends ConsumerState<AppUpdatesScreen> {
  bool _checking = false;
  String? _message;

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

  Future<void> _download(ReleaseInfo r) async {
    final ok = await ref.read(updateControllerProvider).openDownload(r);
    if (!ok && mounted) {
      setState(() => _message = 'Could not open the browser. Open ${r.page} yourself.');
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
            _UpdateCard(release: update, android: android, onDownload: () => _download(update)),
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
                ? 'Tap Download and install. Your browser saves the new APK. Open it and tap Update. '
                      'Android keeps your workouts and meals, because every build is signed with the same key. '
                      'The first time, Android may ask you to allow installs from your browser.'
                : 'Tap Download to open the release page. Save the IPA and install it with AltStore or Sideloadly, '
                      'like the first time. Your workouts and meals stay on the phone.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: Space.m),
          Text(
            'A check asks GitHub for the latest release. It sends no records, account, or device data. '
            'GitHub sees your IP address, as with any website. The app never installs anything by itself.',
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
  const _UpdateCard({required this.release, required this.android, required this.onDownload});
  final ReleaseInfo release;
  final bool android;
  final VoidCallback onDownload;

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
          FilledButton.icon(
            onPressed: onDownload,
            icon: const Icon(LucideIcons.download, size: 20),
            label: OneLine(android ? 'Download and install' : 'Download'),
          ),
        ],
      ),
    );
  }
}
