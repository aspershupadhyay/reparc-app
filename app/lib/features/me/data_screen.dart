import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import 'app_updates_screen.dart';

/// Export and delete local records (handbook 7.6).
class DataScreen extends ConsumerStatefulWidget {
  const DataScreen({super.key});

  @override
  ConsumerState<DataScreen> createState() => _DataScreenState();
}

class _DataScreenState extends ConsumerState<DataScreen> {
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final info = await ref.read(packageInfoProvider.future);
      final json = await ref.read(dataControlsProvider).exportJson(appVersion: '${info.version}+${info.buildNumber}');
      final dir = await getTemporaryDirectory();
      final day = dayKey(ref.read(clockProvider)());
      final file = File('${dir.path}/reparc-export-$day.json');
      await file.writeAsString(json, flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'Reparc export $day',
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) showMessage(context, 'Export failed. Your records are not changed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteAll() async {
    final first = await confirmAction(
      context,
      title: 'Delete all records?',
      body:
          'This deletes every workout, plan, exercise, meal, food, and setting on this phone. '
          'Reparc has no other copy. Export first if you want to keep them.',
      confirmLabel: 'Continue',
      destructive: true,
    );
    if (!first || !mounted) return;
    final typed = await promptText(
      context,
      title: 'Type DELETE to confirm',
      label: 'Type DELETE',
      confirmLabel: 'Delete all',
    );
    if (!mounted) return;
    if (typed?.trim() != 'DELETE') {
      if (typed != null) showMessage(context, 'Nothing deleted. The text did not match.');
      return;
    }
    await guardedWrite(context, () => ref.read(dataControlsProvider).deleteAll(), success: 'All records deleted.');
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Export and delete')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Export a copy', style: t.titleMedium),
                const SizedBox(height: Space.s),
                Text(
                  'Creates one JSON file with all your records. It keeps field names, units, times, sources, '
                  'and empty values. You choose where to send or save it. The file is not encrypted. '
                  'Anyone who gets it can read your records.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: Space.l),
                FilledButton.icon(
                  onPressed: _busy ? null : _export,
                  icon: const Icon(LucideIcons.download, size: IconSizes.s),
                  label: Text(_busy ? 'Preparing export' : 'Export my records'),
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Phone backups', style: t.titleMedium),
                const SizedBox(height: Space.s),
                Text(
                  'Reparc does not run its own backup. Your phone\'s system backup may or may not include '
                  'Reparc records. Do not rely on it. Export a copy to be sure.',
                  style: t.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Delete all records', style: t.titleMedium),
                const SizedBox(height: Space.s),
                Text(
                  'Removes every record from this phone. You cannot undo this. '
                  'Copies you exported earlier are not affected.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: Space.l),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _deleteAll,
                  style: OutlinedButton.styleFrom(foregroundColor: context.pal.error),
                  icon: const Icon(LucideIcons.trash2, size: IconSizes.s),
                  label: const Text('Delete all records'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
