import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/tokens.dart';
import '../../core/widgets.dart';

final packageInfoProvider = FutureProvider((ref) => PackageInfo.fromPlatform());

/// Me → Settings → App updates (handbook 17.3).
///
/// The update metadata source is not chosen yet (To confirm). The screen
/// shows the installed version and says so. The app never downloads or
/// installs code itself. Stores install updates.
class AppUpdatesScreen extends ConsumerStatefulWidget {
  const AppUpdatesScreen({super.key});

  @override
  ConsumerState<AppUpdatesScreen> createState() => _AppUpdatesScreenState();
}

class _AppUpdatesScreenState extends ConsumerState<AppUpdatesScreen> {
  String? _result;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final info = ref.watch(packageInfoProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('App updates')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          AppCard(
            child: AsyncBody(
              value: info,
              builder: (i) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Metric(label: 'Installed version', value: i.version, note: 'Build ${i.buildNumber}'),
                  const SizedBox(height: Space.l),
                  const Metric(label: 'Latest known version', value: 'Not checked'),
                ],
              ),
            ),
          ),
          const SizedBox(height: Space.l),
          FilledButton.icon(
            onPressed: () => setState(
              () => _result =
                  'Update checks are not set up in this build yet. '
                  'Get updates from the App Store or Google Play.',
            ),
            icon: const Icon(LucideIcons.refreshCw, size: IconSizes.s),
            label: const Text('Check for updates'),
          ),
          if (_result != null) ...[
            const SizedBox(height: Space.m),
            Semantics(
              liveRegion: true,
              child: StatusLine(icon: LucideIcons.info, text: _result!),
            ),
          ],
          const SectionHeader('How updates work'),
          Text(
            'Reparc updates come only from the App Store on iPhone and from Google Play on Android. '
            'The app never downloads or installs code by itself. You approve each install in the store.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: Space.m),
          Text('Update alerts are planned. They will be optional and off by default.', style: t.bodySmall),
        ],
      ),
    );
  }
}
