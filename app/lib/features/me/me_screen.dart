import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

/// Me tab. Groups settings by purpose (handbook 3.6). Account, health, and
/// AI controls are separate rows.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final s = ref.watch(currentSettingsProvider);
    final repo = ref.read(settingsRepoProvider);

    Widget group(List<Widget> tiles) => AppCard(
      padding: const EdgeInsets.symmetric(vertical: Space.xs),
      child: Column(
        children: [
          for (final (i, tile) in tiles.indexed) ...[
            if (i > 0) const Divider(indent: Space.l),
            tile,
          ],
        ],
      ),
    );

    Widget link(IconData icon, String title, String subtitle, String path) => ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(LucideIcons.chevronRight, size: IconSizes.s),
      onTap: () => context.go(path),
    );

    Widget info(IconData icon, String title, String subtitle) =>
        ListTile(leading: Icon(icon), title: Text(title), subtitle: Text(subtitle));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            Semantics(header: true, child: Text('Me', style: t.headlineSmall)),
            const SectionHeader('Units and display'),
            group([
              ListTile(
                leading: const Icon(LucideIcons.scale),
                title: const Text('Load unit for new sets'),
                subtitle: const Text('Saved sets keep the unit they were recorded in.'),
                trailing: _Segmented(
                  values: Units.loadUnits,
                  selected: s.loadUnit,
                  onChanged: repo.setLoadUnit,
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.ruler),
                title: const Text('Distance unit for new sets'),
                trailing: _Segmented(
                  values: Units.distanceUnits,
                  selected: s.distanceUnit,
                  onChanged: repo.setDistanceUnit,
                ),
              ),
              ListTile(
                leading: const Icon(LucideIcons.timer),
                title: const Text('Rest timer after a set'),
                subtitle: const Text('Starts when you mark a set done. It never blocks set entry.'),
                trailing: DropdownButton<int?>(
                  value: s.restAfterSetSec,
                  underline: const SizedBox.shrink(),
                  items: const [
                    DropdownMenuItem(value: null, child: Text('Off')),
                    DropdownMenuItem(value: 60, child: Text('60 s')),
                    DropdownMenuItem(value: 90, child: Text('90 s')),
                    DropdownMenuItem(value: 120, child: Text('2 min')),
                    DropdownMenuItem(value: 180, child: Text('3 min')),
                  ],
                  onChanged: repo.setRestAfterSet,
                ),
              ),
              SwitchListTile(
                secondary: const Icon(LucideIcons.flame),
                title: const Text('Show energy (calorie) values'),
                subtitle: const Text('Turn off to hide calorie views in Home, Meal, and Analytics.'),
                value: s.showEnergy,
                onChanged: repo.setShowEnergy,
              ),
            ]),
            const SectionHeader('Goals'),
            group([
              info(LucideIcons.flag, 'Goals', 'Not available in this version. Goals will always be optional.'),
            ]),
            const SectionHeader('Account and sync'),
            group([
              info(
                LucideIcons.cloudOff,
                'No account. No sync.',
                'Your records stay on this phone. Reparc has no server in this version. '
                    'Export a copy to keep a backup.',
              ),
            ]),
            const SectionHeader('Health connections'),
            group([
              info(
                LucideIcons.heartPulse,
                'Apple Health and Health Connect',
                'Planned. Not available in this version. Reparc does not request health permissions.',
              ),
            ]),
            const SectionHeader('AI connections'),
            group([
              link(LucideIcons.sparkles, 'AI connections', 'No connections. No data is shared with AI.', '/me/ai'),
            ]),
            const SectionHeader('Your data'),
            group([
              link(
                LucideIcons.download,
                'Export and delete',
                'Export a copy, or delete all records on this phone.',
                '/me/data',
              ),
              link(LucideIcons.shield, 'Privacy', 'What Reparc stores and where.', '/me/privacy'),
            ]),
            const SectionHeader('App'),
            group([
              link(LucideIcons.refreshCw, 'App updates', 'Version, release notes, and update check.', '/me/updates'),
              ListTile(
                leading: const Icon(LucideIcons.fileText),
                title: const Text('Licenses'),
                subtitle: const Text('Reparc uses GNU AGPL v3.0. Third-party notices are listed here.'),
                trailing: const Icon(LucideIcons.chevronRight, size: IconSizes.s),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Reparc',
                  applicationLegalese: 'Copyright the Reparc contributors.\nLicensed under GNU AGPL v3.0 only.',
                ),
              ),
              info(
                LucideIcons.lifeBuoy,
                'Support',
                'Report a problem at github.com/aspershupadhyay/reparc/issues. '
                    'Do not post your records or export file.',
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  const _Segmented({required this.values, required this.selected, required this.onChanged});
  final List<String> values;
  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: selected,
      underline: const SizedBox.shrink(),
      items: [for (final v in values) DropdownMenuItem(value: v, child: Text(v))],
      onChanged: (v) => onChanged(v!),
    );
  }
}
