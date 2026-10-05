import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/meal_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';

/// The saved records behind an Analytics summary (handbook 6.3).
class SourceRecordsScreen extends ConsumerWidget {
  const SourceRecordsScreen({super.key, required this.kind, required this.from, required this.to});
  final String kind;
  final String from;
  final String to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final progress = ref.watch(progressProvider((parseDayKey(from), parseDayKey(to))));
    final workouts = kind == 'workouts';
    final showEnergy = ref.watch(currentSettingsProvider).showEnergy;
    return Scaffold(
      appBar: AppBar(title: Text(workouts ? 'Workout records' : 'Meal records')),
      body: AsyncBody(
        value: progress,
        builder: (p) {
          final header = Padding(
            padding: const EdgeInsets.only(bottom: Space.m),
            child: Text('${fmtDayLong(p.fromDay)} to ${fmtDayLong(p.toDay)}', style: t.bodySmall),
          );
          if (workouts) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
              children: [
                header,
                if (p.sessions.isEmpty)
                  const EmptyState(
                    icon: LucideIcons.history,
                    title: 'No saved workouts',
                    body: 'No workout was saved in this range.',
                  ),
                for (final s in p.sessions)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(s.session.name),
                    subtitle: Text(
                      '${fmtDayShort(p.sessionDay(s.session))} · ${s.completedSets} sets done · ${s.session.status.label}',
                    ),
                    trailing: const Icon(LucideIcons.chevronRight, size: IconSizes.s),
                    onTap: () => context.go('/workout/session/${s.session.id}'),
                  ),
              ],
            );
          }
          final byDay = <String, List<dynamic>>{};
          for (final m in p.meals) {
            (byDay[m.day] ??= []).add(m);
          }
          final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));
          return ListView(
            padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
            children: [
              header,
              if (days.isEmpty)
                const EmptyState(
                  icon: LucideIcons.utensils,
                  title: 'No meal records',
                  body: 'No food was logged in this range.',
                ),
              for (final d in days) ...[
                SectionHeader(
                  fmtDayLong(parseDayKey(d)),
                  action: TextButton(onPressed: () => context.go('/meal?day=$d'), child: const Text('Open day')),
                ),
                for (final m in p.meals.where((m) => m.day == d))
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.name),
                    subtitle: Text(
                      [
                        fmtWithUnit(m.amount, m.amountUnit, maxDecimals: 2),
                        if (showEnergy)
                          m.input.eaten.energyKcal == null
                              ? 'energy not recorded'
                              : '${fmtNum(m.input.eaten.energyKcal, maxDecimals: 0)} kcal',
                        if (m.isEstimate) 'estimate',
                        m.status == MealStatus.eaten ? 'eaten' : 'planned, not counted',
                        m.source,
                      ].join(' · '),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}
