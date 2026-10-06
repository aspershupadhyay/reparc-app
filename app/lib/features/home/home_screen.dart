import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/meal_repository.dart';
import '../../data/providers.dart';
import '../../domain/nutrition.dart';
import '../meal/meal_entry_sheet.dart';
import '../workout/session_clock.dart';
import '../workout/start_workout.dart';

/// Home answers three questions, in this order (handbook 3.2):
/// 1. What do I do now? One main action: continue, today's roadmap day,
///    or start a workout.
/// 2. How is today's eating going? Protein, fibre, carbs, and energy.
/// 3. How is my week going? Training days, and the roadmap count.
/// Trends live in Analytics, not here.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final now = ref.watch(clockProvider)();
    final today = dayOf(now);
    final weekStart = addDays(today, -(today.weekday - 1));
    final settings = ref.watch(currentSettingsProvider);
    final week = ref.watch(progressProvider((weekStart, addDays(weekStart, 6)))).value;
    final program = ref.watch(activeProgramProvider).value;
    final greeting = now.hour < 12 ? 'Good morning' : (now.hour < 18 ? 'Good afternoon' : 'Good evening');
    final roadmapDone = program == null
        ? null
        : (week?.sessions.where((s) => s.session.programId == program.id).length ?? 0);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            ScreenTitle(greeting, subtitle: fmtDayLong(today)),
            if (ref.watch(settingsProvider).hasValue && !settings.storageNoticeSeen) ...[
              const _StorageNote(),
              const SizedBox(height: Space.m),
            ],
            const _Hero(),
            const SizedBox(height: Space.l),
            const _TodayFood(),
            const SizedBox(height: Space.l),
            _WeekCard(
              weekStart: weekStart,
              today: today,
              trained: week?.trainingDays ?? const {},
              count: week?.sessions.length ?? 0,
              roadmapDone: roadmapDone,
              roadmapPlanned: program?.plan.days.length,
            ),
            const SizedBox(height: Space.l),
            Text('Shortcuts', style: t.titleMedium),
            const SizedBox(height: Space.s),
            Row(
              children: [
                _Shortcut(
                  icon: LucideIcons.plus,
                  label: 'Log food',
                  color: p.green,
                  onTap: () => showMealEntrySheet(context, day: dayKey(today)),
                ),
                _Shortcut(
                  icon: LucideIcons.bookOpen,
                  label: 'Exercises',
                  color: p.blue,
                  onTap: () => context.go('/workout/library'),
                ),
                _Shortcut(
                  icon: LucideIcons.calculator,
                  label: 'Weight calc',
                  color: p.orange,
                  onTap: () => context.go('/workout/calculator'),
                ),
                _Shortcut(
                  icon: LucideIcons.scale,
                  label: 'Body',
                  color: p.coral,
                  onTap: () => context.go('/me/body'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Shortcut extends StatelessWidget {
  const _Shortcut({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        excludeSemantics: true,
        child: InkWell(
          borderRadius: Radii.medium,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.s),
            child: Column(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(color: p.surface, borderRadius: Radii.medium),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: t.labelSmall?.copyWith(color: p.ink),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The one main action: continue, today's roadmap day, or start.
class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final live = ref.watch(liveSessionProvider).value;
    final program = ref.watch(activeProgramProvider).value;
    final next = program == null || program.plan.days.isEmpty ? null : program.plan.days[program.nextDay];

    final (String eyebrow, String title, String? sub, String label, VoidCallback onTap) = switch ((live, next)) {
      (final l?, _) => ('Training now', '', null, 'Continue workout', () => context.push('/live/${l.id}')),
      (null, final d?) => (
        'Today on your roadmap',
        d.name,
        '${d.focus} · ${d.work.length} exercises · about ${d.minutes} min',
        'Warm up and start',
        () => context.push('/workout/roadmap/${program!.id}/day/${program.nextDay}'),
      ),
      _ => ('Train', 'Start workout', 'Add exercises as you go', 'Start workout', () => startWorkout(context, ref)),
    };

    return Semantics(
      button: true,
      label: live == null ? '$label. $title' : 'Continue workout',
      excludeSemantics: true,
      child: Material(
        color: p.panel,
        borderRadius: Radii.large,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(eyebrow.toUpperCase(), style: t.labelSmall?.copyWith(color: p.energy, letterSpacing: 0.6)),
                const SizedBox(height: Space.xs),
                if (live != null)
                  SessionClock(
                    sessionId: live.id,
                    style: t.displaySmall!.tabular.copyWith(color: p.onPanel),
                  )
                else
                  Text(title, style: t.headlineSmall?.copyWith(color: p.onPanel)),
                if (sub != null) Text(sub, style: t.bodySmall?.copyWith(color: p.onPanelSoft)),
                const SizedBox(height: Space.l),
                Wrap(
                  spacing: Space.s,
                  runSpacing: Space.s,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.m),
                      decoration: BoxDecoration(color: p.energy, borderRadius: BorderRadius.circular(999)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(live == null ? LucideIcons.play : LucideIcons.arrowRight, color: p.onEnergy, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(label, style: t.labelLarge?.copyWith(color: p.onEnergy)),
                          ),
                        ],
                      ),
                    ),
                    if (live == null && program == null)
                      TextButton(
                        onPressed: () => context.go('/workout'),
                        style: TextButton.styleFrom(foregroundColor: p.onPanelSoft),
                        child: const Text('Pick a roadmap'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Today's food: four rings that fill toward the user's own targets.
class _TodayFood extends ConsumerWidget {
  const _TodayFood();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final settings = ref.watch(currentSettingsProvider);
    final today = dayOf(ref.watch(clockProvider)());
    final meals = ref.watch(mealDayProvider(dayKey(today))).value ?? const [];
    final totals = totalsOf(meals.map((e) => e.input));
    final byN = {for (final x in settings.targets) x.nutrient: x};
    final shown = [
      (Nutrient.protein, p.coral),
      (Nutrient.fiber, p.green),
      (Nutrient.carbs, p.orange),
      if (settings.showEnergy) (Nutrient.energy, p.brand) else (Nutrient.fat, p.blue),
    ];
    return AppCard(
      onTap: () => context.go('/meal'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: Text('Today\'s food', style: t.titleMedium)),
              if (byN.isEmpty)
                TextButton(onPressed: () => context.go('/me/body'), child: const Text('Set targets'))
              else
                Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
            ],
          ),
          const SizedBox(height: Space.s),
          Row(
            children: [
              for (final (n, color) in shown)
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final v = totals.of(n).value;
                      final target = byN[n];
                      final short = switch (n) {
                        Nutrient.energy => 'kcal',
                        Nutrient.fiber => 'Fibre',
                        _ => n.label,
                      };
                      return Column(
                        children: [
                          Ring(
                            value: target?.progress(v) ?? (v == null ? 0 : 1),
                            color: color,
                            track: color.withValues(alpha: 0.15),
                            size: 64,
                            stroke: 7,
                            semanticLabel:
                                '${n.label}: ${v == null ? missingLabel : '${fmtNum(v, maxDecimals: 0)} ${n.unit}'}'
                                '${target == null ? '' : ' of ${fmtNum(target.amount, maxDecimals: 0)}'}',
                            child: Text(fmtNum(v, maxDecimals: 0), style: t.labelMedium?.tabular),
                          ),
                          const SizedBox(height: 4),
                          Text(short, style: t.labelSmall),
                          Text(
                            target == null ? n.unit : 'of ${fmtNum(target.amount, maxDecimals: 0)}',
                            style: t.labelSmall?.copyWith(fontSize: 11),
                          ),
                        ],
                      );
                    },
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Seven days. A filled day means you trained.
class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.weekStart,
    required this.today,
    required this.trained,
    required this.count,
    this.roadmapDone,
    this.roadmapPlanned,
  });
  final int? roadmapDone;
  final int? roadmapPlanned;
  final DateTime weekStart;
  final DateTime today;
  final Set<String> trained;
  final int count;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return AppCard(
      onTap: () => context.go('/analytics'),
      semanticLabel: 'This week: $count workouts on ${trained.length} days. Open Analytics',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconBadge(LucideIcons.calendarCheck, color: p.green, size: 40),
                const SizedBox(width: Space.m),
                Expanded(child: Text('This week', style: t.titleMedium)),
                if (roadmapPlanned != null) ...[
                  Text('${roadmapDone ?? 0}/$roadmapPlanned', style: t.headlineSmall?.tabular),
                  const SizedBox(width: 4),
                  Text('roadmap', style: t.bodySmall),
                ] else ...[
                  Text('$count', style: t.headlineSmall?.tabular),
                  const SizedBox(width: 4),
                  Text(count == 1 ? 'workout' : 'workouts', style: t.bodySmall),
                ],
              ],
            ),
            const SizedBox(height: Space.l),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 7; i++)
                  Builder(
                    builder: (context) {
                      final d = addDays(weekStart, i);
                      final done = trained.contains(dayKey(d));
                      final isToday = d == today;
                      return Column(
                        children: [
                          Text('MTWTFSS'[i], style: t.labelSmall?.copyWith(color: isToday ? p.ink : p.inkSoft)),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: done ? p.energy : p.surfaceAlt,
                              shape: BoxShape.circle,
                              border: isToday ? Border.all(color: p.ink, width: 2) : null,
                            ),
                            child: done ? Icon(LucideIcons.check, size: 18, color: p.onEnergy) : null,
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StorageNote extends ConsumerWidget {
  const _StorageNote();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: p.brandSoft,
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.s, Space.s),
      child: Row(
        children: [
          Icon(LucideIcons.smartphone, size: 20, color: p.brand),
          const SizedBox(width: Space.m),
          Expanded(child: Text('Saved on this phone only. Back up in Me.', style: t.bodyMedium)),
          IconButton(
            tooltip: 'Dismiss',
            onPressed: () => ref.read(settingsRepoProvider).setStorageNoticeSeen(),
            icon: Icon(LucideIcons.x, size: 18, color: p.inkSoft),
          ),
        ],
      ),
    );
  }
}
