import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../domain/guide.dart';
import '../workout/lock_alerts.dart';
import '../workout/voice.dart';

/// Me → Workout guide (handbook 4.13). Times first, in the order a workout
/// uses them, then the switches that make it run on its own, then the voice.
class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final s = ref.watch(currentSettingsProvider);
    final repo = ref.read(settingsRepoProvider);

    Widget group(String title, List<Widget> tiles, {String? note}) => Column(
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
        if (note != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s, Space.s, Space.s, 0),
            child: Text(note, style: Theme.of(context).textTheme.bodySmall),
          ),
      ],
    );

    Widget lead(IconData icon, Color c, Color soft) => IconBadge(icon, color: soft, glyph: c, size: 40);

    Widget dropdown<T>(T value, List<(T, String)> items, ValueChanged<T?> onChanged) => DropdownButton<T>(
      // A value no longer offered shows as the first choice, not an error.
      value: items.any((x) => x.$1 == value) ? value : items.first.$1,
      underline: const SizedBox.shrink(),
      borderRadius: Radii.medium,
      icon: pickerIcon(context),
      items: [for (final (v, l) in items) DropdownMenuItem(value: v, child: Text(l))],
      onChanged: onChanged,
    );

    Widget time(
      IconData icon,
      String title,
      String subtitle,
      int? value,
      List<(int?, String)> items,
      ValueChanged<int?> on,
    ) => ListTile(
      leading: lead(icon, p.orange, p.orangeSoft),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: dropdown<int?>(value, items, on),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Workout guide')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xxl),
        children: [
          group(
            'Times',
            [
              time(
                LucideIcons.flame,
                'Each warm-up move',
                'Timed moves keep their time. Auto: 3 s a rep',
                s.warmupSec,
                const [
                  (null, 'Auto'),
                  (20, '20 s'),
                  (30, '30 s'),
                  (45, '45 s'),
                  (60, '1 min'),
                ],
                repo.setWarmupSec,
              ),
              time(LucideIcons.coffee, 'Rest after warm-up', 'No rest between warm-up moves', s.warmupRestSec, const [
                (null, '1 min'),
                (30, '30 s'),
                (90, '1:30'),
                (120, '2 min'),
                (180, '3 min'),
              ], repo.setWarmupRestSec),
              time(LucideIcons.hourglass, 'Each set', 'Timed sets keep their time. Auto: 3 s a rep', s.setSec, const [
                (null, 'Auto'),
                (30, '30 s'),
                (45, '45 s'),
                (60, '1 min'),
                (90, '1:30'),
              ], repo.setSetSec),
              time(
                LucideIcons.timer,
                'Rest between sets',
                'Auto: the plan\'s rest, else 90 s',
                s.restAfterSetSec,
                const [
                  (null, 'Auto'),
                  (30, '30 s'),
                  (45, '45 s'),
                  (60, '1 min'),
                  (90, '1:30'),
                  (120, '2 min'),
                  (180, '3 min'),
                ],
                repo.setRestAfterSet,
              ),
              ListTile(
                leading: lead(LucideIcons.trendingUp, p.green, p.greenSoft),
                title: const Text('Next set'),
                subtitle: Text(
                  s.loadStyle == LoadStyle.pyramid
                      ? 'Pyramid: +2.5 kg (5 lb) and 2 fewer reps each set'
                      : 'Same weight and reps as the set before',
                ),
                trailing: dropdown<LoadStyle>(s.loadStyle, const [
                  (LoadStyle.same, 'Same'),
                  (LoadStyle.pyramid, 'Pyramid'),
                ], (v) => repo.setLoadStyle(v!)),
              ),
            ],
            note: 'The next set is filled in for you from the set before. Change it any time; it is not marked done.',
          ),
          group('Run on its own', [
            SwitchListTile(
              secondary: lead(LucideIcons.timerReset, p.brand, p.brandSoft),
              title: const Text('End each set on time'),
              subtitle: const Text('Off: tap Set done'),
              value: s.finishRepSets,
              onChanged: repo.setFinishRepSets,
            ),
            SwitchListTile(
              secondary: lead(LucideIcons.play, p.brand, p.brandSoft),
              title: const Text('Start the next set on its own'),
              subtitle: const Text('After a 3-2-1. Off: tap Start set'),
              value: s.autoStartSets,
              onChanged: repo.setAutoStartSets,
            ),
          ]),
          group('Voice', [
            ListTile(
              leading: lead(LucideIcons.volume2, p.blue, p.blueSoft),
              title: const Text('Voice'),
              subtitle: const Text('Says when a set or rest starts and ends'),
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
              secondary: lead(LucideIcons.lockKeyhole, p.green, p.greenSoft),
              title: const Text('Speak when locked'),
              subtitle: const Text('The same voice as notifications. Android also shows the clock'),
              value: s.lockAlerts,
              onChanged: repo.setLockAlerts,
            ),
            if (s.lockAlerts) const OnTimeTile(),
            for (final (cue, icon, title, sub) in const [
              (Cue.halfway, LucideIcons.chartPie, 'Halfway', 'In timed sets of 30 s or more'),
              (Cue.tenLeft, LucideIcons.timer, 'Ten seconds left', 'Before a rest ends'),
              (Cue.countdown, LucideIcons.listOrdered, '3-2-1 countdown', 'Before a rest or a timed set ends'),
              (Cue.end, LucideIcons.bellRing, 'End of rest and set', '"Rest is up" and "Time! Good set."'),
            ])
              SwitchListTile(
                secondary: lead(icon, p.blue, p.blueSoft),
                title: Text(title),
                subtitle: Text(sub),
                value: s.cues.contains(cue),
                onChanged: (v) => repo.setCue(cue, v),
              ),
          ]),
        ],
      ),
    );
  }
}

/// Shown only when Android does not let alerts fire on the second.
class OnTimeTile extends ConsumerStatefulWidget {
  const OnTimeTile({super.key});

  @override
  ConsumerState<OnTimeTile> createState() => _OnTimeTileState();
}

class _OnTimeTileState extends ConsumerState<OnTimeTile> {
  bool? _onTime;
  AppLifecycleListener? _life;

  @override
  void initState() {
    super.initState();
    _check();
    // The user comes back from Android's settings page.
    _life = AppLifecycleListener(onResume: _check);
  }

  @override
  void dispose() {
    _life?.dispose();
    super.dispose();
  }

  Future<void> _check() async {
    final v = await ref.read(lockAlertsProvider).onTime();
    if (mounted) setState(() => _onTime = v);
  }

  @override
  Widget build(BuildContext context) {
    if (_onTime != false) return const SizedBox.shrink();
    final p = context.pal;
    return ListTile(
      leading: IconBadge(LucideIcons.alarmClock, color: p.orangeSoft, glyph: p.orange, size: 40),
      title: const Text('On-time cues when locked'),
      subtitle: const Text('Allow "Alarms & reminders" so the countdown is not late. Else only the main cues play'),
      trailing: const Icon(LucideIcons.chevronRight),
      onTap: () => ref.read(lockAlertsProvider).askOnTime(),
    );
  }
}
