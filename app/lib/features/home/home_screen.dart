import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ai/ai_controller.dart';
import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/meal_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../domain/nutrition.dart';
import '../../health/health_service.dart';
import '../../updates/update_controller.dart';
import '../me/health_screen.dart';
import '../meal/meal_entry_sheet.dart';
import '../workout/session_clock.dart';
import '../workout/start_workout.dart';

/// Home answers three questions, in this order (handbook 3.2):
/// 1. What do I do now? One main action: continue, the next roadmap day,
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
            const _UpdateBanner(),
            const _ProposalBanner(),
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
              // The weekdays the user chose. Without any, one per roadmap day.
              roadmapPlanned: program == null
                  ? null
                  : (program.plan.weekdays.isEmpty ? program.plan.days.length : program.plan.weekdays.length),
              plannedWeekdays: program?.plan.weekdays.toSet() ?? const {},
            ),
            if (settings.health.contains(HealthFeature.steps.name) ||
                settings.health.contains(HealthFeature.activeEnergy.name)) ...[
              const SizedBox(height: Space.m),
              const _HealthRow(),
            ],
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

/// Plans an AI app sent, waiting for the user's review (D-019).
/// A newer build is out (D-029). Tapping opens Me → App updates; the x
/// hides this version until the next one.
class _UpdateBanner extends ConsumerWidget {
  const _UpdateBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final update = ref.watch(availableUpdateProvider);
    if (update == null || ref.watch(currentSettingsProvider).updatesDismissed == update.version) {
      return const SizedBox.shrink();
    }
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: AppCard(
        color: p.brandSoft,
        onTap: () => context.push('/me/updates'),
        semanticLabel: 'Reparc ${update.version} is out. Open App updates',
        child: Row(
          children: [
            IconBadge(LucideIcons.download, color: p.brand, size: 40),
            const SizedBox(width: Space.m),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Update available', style: t.titleSmall),
                  Text('Version ${update.version} is ready to install.', style: t.bodySmall),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Hide until the next version',
              onPressed: () => ref.read(settingsRepoProvider).setUpdatesDismissed(update.version),
              icon: Icon(LucideIcons.x, size: IconSizes.s, color: p.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalBanner extends ConsumerWidget {
  const _ProposalBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = ref.watch(pendingProposalsProvider).value ?? const [];
    if (pending.isEmpty) return const SizedBox.shrink();
    final p = context.pal;
    final first = pending.first;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: AppCard(
        color: p.brandSoft,
        onTap: () => context.push(pending.length == 1 ? '/me/ai/proposal/${first.id}' : '/me/ai'),
        child: Row(
          children: [
            IconBadge(LucideIcons.sparkles, color: p.surface, glyph: p.brand, size: 40),
            const SizedBox(width: Space.m),
            Expanded(
              child: Text(
                pending.length == 1
                    ? '${first.client} sent a ${first.kind == ProposalKind.workoutPlan ? 'workout' : 'meal'} plan. Review it.'
                    : '${pending.length} AI plans are waiting for your review.',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
          ],
        ),
      ),
    );
  }
}

/// Steps and active energy from Apple Health or Health Connect, when the
/// user connected them. Missing data shows a dash, never zero.
class _HealthRow extends ConsumerWidget {
  const _HealthRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final s = ref.watch(currentSettingsProvider);
    final v = ref.watch(healthTodayProvider).value;
    return Row(
      children: [
        if (s.health.contains(HealthFeature.steps.name))
          Expanded(
            child: _Tile(
              icon: LucideIcons.footprints,
              color: p.green,
              soft: p.greenSoft,
              label: 'Steps',
              value: v?.steps == null ? '–' : NumberFormat.decimalPattern().format(v!.steps),
              caption: v?.steps == null ? 'No data' : 'today',
              onTap: () => context.push('/me/health'),
            ),
          ),
        if (s.health.contains(HealthFeature.steps.name) && s.health.contains(HealthFeature.activeEnergy.name))
          const SizedBox(width: Space.m),
        if (s.health.contains(HealthFeature.activeEnergy.name))
          Expanded(
            child: _Tile(
              icon: LucideIcons.zap,
              color: p.orange,
              soft: p.orangeSoft,
              label: 'Active',
              value: v?.energy == null ? '–' : '${v!.energy!.round()}',
              caption: v?.energy == null ? 'No data' : 'kcal burned',
              onTap: () => context.push('/me/health'),
            ),
          ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.color,
    required this.soft,
    required this.label,
    required this.value,
    required this.caption,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color soft;
  final String label;
  final String value;
  final String caption;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    return AppCard(
      color: soft,
      onTap: onTap,
      semanticLabel: '$label: $value $caption',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconBadge(icon, color: color, size: 40),
            const SizedBox(height: Space.l),
            Text(label, style: t.labelMedium?.copyWith(color: p.ink)),
            Text(value, style: t.headlineSmall?.tabular, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(caption, style: t.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
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

/// The one main action: continue, the next roadmap day, or start.
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
        'Next in your plan',
        d.name,
        [if (d.focus.isNotEmpty) d.focus, '${d.work.length} exercises', 'about ${d.minutes} min'].join(' · '),
        'Start workout',
        () => startWorkout(context, ref, programId: program!.id, programDay: program.nextDay),
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
                        child: const Text('Pick a plan'),
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
                        Nutrient.energy => 'Energy',
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
                            target == null ? n.unit : 'of ${fmtNum(target.amount, maxDecimals: 0)} ${n.unit}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    this.plannedWeekdays = const {},
  });

  /// Roadmap training weekdays, 1 = Monday. Shown as tinted days.
  final Set<int> plannedWeekdays;
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
      semanticLabel:
          'This week: $count workouts on ${trained.length} days'
          '${roadmapPlanned == null ? '' : ', ${roadmapDone ?? 0} of $roadmapPlanned plan days'}. Open Analytics',
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
                  Text('plan', style: t.bodySmall),
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
                      final planned = plannedWeekdays.contains(d.weekday);
                      return Column(
                        children: [
                          Text('MTWTFSS'[i], style: t.labelSmall?.copyWith(color: isToday ? p.ink : p.inkSoft)),
                          const SizedBox(height: 6),
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: done ? p.energyStrong : (planned ? p.brandSoft : p.surfaceAlt),
                              shape: BoxShape.circle,
                              border: isToday ? Border.all(color: p.ink, width: 2) : null,
                            ),
                            child: done ? Icon(LucideIcons.check, size: 18, color: p.on(p.energyStrong)) : null,
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
