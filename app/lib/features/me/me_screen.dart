import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai/ai_controller.dart';
import '../../core/distribution.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../updates/update_controller.dart';

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

    // Neutral row icons: settings rows are navigation, not data, so they
    // carry no category colour (visual review, 2026-10-09).
    Widget lead(IconData icon) => IconBadge(icon, color: p.surfaceAlt, glyph: p.ink, size: 36);

    Widget link(Widget leading, String title, String subtitle, String path) => ListTile(
      leading: leading,
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
      onTap: () => context.push(path),
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
            group('You', [
              link(
                lead(LucideIcons.personStanding),
                'Body and goals',
                s.targetsOn ? 'Targets on' : 'Weight, goal, diet, and daily targets',
                '/me/body',
              ),
            ]),
            // Rarely changed, so it sits below the user's own settings.
            const SectionHeader('Appearance', top: Space.l),
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
            group('Units', [
              ListTile(
                leading: lead(LucideIcons.weight),
                title: const Text('Weight'),
                trailing: dropdown(s.loadUnit, [for (final u in Units.loadUnits) (u, u)], (v) => repo.setLoadUnit(v!)),
              ),
              ListTile(
                leading: lead(LucideIcons.ruler),
                title: const Text('Distance'),
                trailing: dropdown(s.distanceUnit, [
                  for (final u in Units.distanceUnits) (u, u),
                ], (v) => repo.setDistanceUnit(v!)),
              ),
            ]),
            group('Training', [
              SwitchListTile(
                secondary: lead(LucideIcons.audioLines),
                title: const Text('Coach mode'),
                subtitle: const Text('Timers and a voice run your workout. The screen stays on'),
                value: s.guideOn,
                onChanged: repo.setGuideOn,
              ),
              if (s.guideOn)
                link(
                  lead(LucideIcons.slidersHorizontal),
                  'Times and voice',
                  [
                    s.finishRepSets && s.autoStartSets ? 'Runs on its own' : 'You start or end sets',
                    s.voice == 'off' ? 'Voice off' : 'Voice ${s.voice[0].toUpperCase()}${s.voice.substring(1)}',
                  ].join(' · '),
                  '/me/training',
                )
              else
                ListTile(
                  leading: lead(LucideIcons.timer),
                  title: const Text('Auto rest timer'),
                  subtitle: const Text('Starts when a set is done'),
                  trailing: dropdown<int?>(s.restAfterSetSec, [
                    (null, 'Off'),
                    (60, '60 s'),
                    (90, '90 s'),
                    (120, '2 min'),
                    (180, '3 min'),
                  ], repo.setRestAfterSet),
                ),
              SwitchListTile(
                secondary: lead(LucideIcons.flame),
                title: const Text('Show calories'),
                value: s.showEnergy,
                onChanged: repo.setShowEnergy,
              ),
            ]),
            group('Connections', [
              link(
                lead(LucideIcons.cloudUpload),
                'Backup and restore',
                s.lastBackupAt == null
                    ? 'Phone backup and encrypted backup files'
                    : 'Last backup file ${DateFormat.MMMd().format(s.lastBackupAt!.toLocal())}',
                '/me/backup',
              ),
              link(
                lead(LucideIcons.heartPulse),
                'Health apps',
                s.health.isEmpty
                    ? 'Apple Health, Health Connect. Off.'
                    : '${s.health.length} type${s.health.length == 1 ? '' : 's'} connected',
                '/me/health',
              ),
              link(
                lead(LucideIcons.sparkles),
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
                lead(LucideIcons.download),
                'Export or delete',
                'Back up all records',
                '/me/data',
              ),
              link(lead(LucideIcons.shield), 'Privacy', 'What is stored and where', '/me/privacy'),
            ]),
            group('App', [
              // Google Play delivers updates to the Play build (handbook 17.10).
              if (playBuild)
                ListTile(
                  leading: lead(LucideIcons.refreshCw),
                  title: const Text('Version'),
                  subtitle: Text(
                    '${ref.watch(installedVersionProvider).value ?? missingText}. Updates come from Google Play.',
                  ),
                )
              else
                link(
                  lead(LucideIcons.refreshCw),
                  'App updates',
                  'Version and updates',
                  '/me/updates',
                ),
              ListTile(
                leading: lead(LucideIcons.fileText),
                title: const Text('Licenses'),
                subtitle: const Text('Notices for fonts, icons, photos, and the body model'),
                trailing: Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: 'RepArc',
                  applicationLegalese: '© 2026 RepArc. All rights reserved.',
                ),
              ),
              ListTile(
                leading: lead(LucideIcons.lifeBuoy),
                title: const Text('Support'),
                subtitle: const Text('github.com/aspershupadhyay/reparc'),
                trailing: Icon(LucideIcons.externalLink, size: IconSizes.s, color: p.inkSoft),
                onTap: () => launchUrl(
                  Uri.parse('https://github.com/aspershupadhyay/reparc'),
                  mode: LaunchMode.externalApplication,
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

/// Android only: asks for "Alarms & reminders", so the countdown and other
/// short cues fire on the second while the phone is locked. Hidden when it
/// is already allowed, and on iPhone.
