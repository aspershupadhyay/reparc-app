import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ai/ai_controller.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../domain/guide.dart';
import '../workout/voice.dart';

/// Me tab. Settings grouped by purpose (handbook 3.6). Account, health,
/// and AI are separate rows.
class MeScreen extends ConsumerWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final s = ref.watch(currentSettingsProvider);
    final repo = ref.read(settingsRepoProvider);
    final ai = ref.watch(aiControllerProvider);

    Widget group(String title, List<Widget> tiles) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(title, top: Space.l),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              for (final (i, tile) in tiles.indexed) ...[
                if (i > 0) const Divider(indent: 72),
                tile,
              ],
            ],
          ),
        ),
      ],
    );

    Widget lead(IconData icon, Color c, Color soft) => IconBadge(icon, color: soft, glyph: c, size: 40);

    Widget link(Widget leading, String title, String subtitle, String path) => ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
      onTap: () => context.push(path),
    );

    Widget info(Widget leading, String title, String subtitle, {String? tag}) => ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: tag == null ? null : Tag(tag),
    );

    Widget dropdown<T>(T value, List<(T, String)> items, ValueChanged<T?> onChanged) => DropdownButton<T>(
      value: value,
      underline: const SizedBox.shrink(),
      borderRadius: Radii.medium,
      icon: pickerIcon(context),
      items: [for (final (v, l) in items) DropdownMenuItem(value: v, child: Text(l))],
      onChanged: onChanged,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            const ScreenTitle('Me'),
            PillTabs<String>(
              values: const ['system', 'light', 'dark'],
              selected: s.themeMode,
              label: (m) => switch (m) {
                'light' => 'Light',
                'dark' => 'Dark',
                _ => 'Auto',
              },
              icon: (m) => switch (m) {
                'light' => LucideIcons.sun,
                'dark' => LucideIcons.moon,
                _ => LucideIcons.sunMoon,
              },
              onChanged: repo.setThemeMode,
            ),
            group('You', [
              link(
                lead(LucideIcons.personStanding, p.coral, p.coralSoft),
                'Body and goals',
                s.targetsOn ? 'Targets on' : 'Weight, goal, diet, and daily targets',
                '/me/body',
              ),
            ]),
            group('Units', [
              ListTile(
                leading: lead(LucideIcons.weight, p.blue, p.blueSoft),
                title: const Text('Weight'),
                trailing: dropdown(s.loadUnit, [for (final u in Units.loadUnits) (u, u)], (v) => repo.setLoadUnit(v!)),
              ),
              ListTile(
                leading: lead(LucideIcons.ruler, p.green, p.greenSoft),
                title: const Text('Distance'),
                trailing: dropdown(s.distanceUnit, [
                  for (final u in Units.distanceUnits) (u, u),
                ], (v) => repo.setDistanceUnit(v!)),
              ),
            ]),
            group('Training', [
              SwitchListTile(
                secondary: lead(LucideIcons.audioLines, p.green, p.greenSoft),
                title: const Text('Guided workout'),
                subtitle: const Text('Set and rest timers run on their own'),
                value: s.guideOn,
                onChanged: repo.setGuideOn,
              ),
              if (s.guideOn) ...[
                ListTile(
                  leading: lead(LucideIcons.volume2, p.blue, p.blueSoft),
                  title: const Text('Voice'),
                  subtitle: const Text('Speaks when a set or rest starts and ends'),
                  trailing: dropdown(
                    s.voice,
                    const [
                      ('charlie', 'Charlie'),
                      ('matilda', 'Matilda'),
                      ('off', 'Off'),
                    ],
                    (v) {
                      repo.setVoice(v!);
                      ref.read(voicePlayerProvider).say(v, Clips.set(1));
                    },
                  ),
                ),
                SwitchListTile(
                  secondary: lead(LucideIcons.timerReset, p.orange, p.orangeSoft),
                  title: const Text('Finish sets on time'),
                  subtitle: const Text('When the set time ends, the set is done and the rest starts'),
                  value: s.autoFinishSets,
                  onChanged: repo.setAutoFinishSets,
                ),
                ListTile(
                  leading: lead(LucideIcons.hourglass, p.coral, p.coralSoft),
                  title: const Text('Set time'),
                  subtitle: const Text('Auto: about 3 s a rep'),
                  trailing: dropdown<int?>(s.setSec, const [
                    (null, 'Auto'),
                    (30, '30 s'),
                    (45, '45 s'),
                    (60, '60 s'),
                    (90, '90 s'),
                  ], repo.setSetSec),
                ),
              ],
              ListTile(
                leading: lead(LucideIcons.timer, p.orange, p.orangeSoft),
                title: Text(s.guideOn ? 'Default rest' : 'Auto rest timer'),
                subtitle: Text(s.guideOn ? 'When the plan has no rest. Auto: 90 s' : 'Starts when a set is done'),
                trailing: dropdown<int?>(s.restAfterSetSec, [
                  (null, s.guideOn ? 'Auto' : 'Off'),
                  (60, '60 s'),
                  (90, '90 s'),
                  (120, '2 min'),
                  (180, '3 min'),
                ], repo.setRestAfterSet),
              ),
              SwitchListTile(
                secondary: lead(LucideIcons.flame, p.coral, p.coralSoft),
                title: const Text('Show calories'),
                value: s.showEnergy,
                onChanged: repo.setShowEnergy,
              ),
            ]),
            group('Connections', [
              link(
                lead(LucideIcons.cloudUpload, p.brand, p.brandSoft),
                'Backup and restore',
                s.lastBackupAt == null
                    ? 'Phone backup and encrypted backup files'
                    : 'Last backup file ${DateFormat.MMMd().format(s.lastBackupAt!.toLocal())}',
                '/me/backup',
              ),
              link(
                lead(LucideIcons.heartPulse, p.coral, p.coralSoft),
                'Health apps',
                s.health.isEmpty
                    ? 'Apple Health, Health Connect. Off.'
                    : '${s.health.length} type${s.health.length == 1 ? '' : 's'} connected',
                '/me/health',
              ),
              link(
                lead(LucideIcons.sparkles, p.orange, p.orangeSoft),
                'AI connections',
                ai.anyOn
                    ? 'On${ai.wifiOn ? ' · Wi-Fi' : ''}${ai.onlineOn ? ' · online' : ''}'
                    : s.aiScopes.isEmpty
                    ? 'Off. Nothing is shared.'
                    : 'Off. ${s.aiScopes.length} data type${s.aiScopes.length == 1 ? '' : 's'} chosen.',
                '/me/ai',
              ),
            ]),
            group('Your data', [
              link(
                lead(LucideIcons.download, p.green, p.greenSoft),
                'Export or delete',
                'Back up all records',
                '/me/data',
              ),
              link(lead(LucideIcons.shield, p.blue, p.blueSoft), 'Privacy', 'What is stored and where', '/me/privacy'),
            ]),
            group('App', [
              link(
                lead(LucideIcons.refreshCw, p.brand, p.brandSoft),
                'App updates',
                'Version and updates',
                '/me/updates',
              ),
              ListTile(
                leading: lead(LucideIcons.fileText, p.inkSoft, p.surfaceAlt),
                title: const Text('Licenses'),
                subtitle: const Text('GNU AGPL v3.0 and notices'),
                trailing: Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'Reparc',
                  applicationLegalese: 'Copyright the Reparc contributors.\nLicensed under GNU AGPL v3.0 only.',
                ),
              ),
              info(lead(LucideIcons.lifeBuoy, p.inkSoft, p.surfaceAlt), 'Support', 'github.com/aspershupadhyay/reparc'),
            ]),
          ],
        ),
      ),
    );
  }
}
