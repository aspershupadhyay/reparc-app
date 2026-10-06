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
import '../me/health_screen.dart';
import '../exercises/catalog/catalog.dart';
import '../exercises/library/library.dart';
import '../meal/meal_entry_sheet.dart';
import '../workout/session_clock.dart';
import '../workout/start_workout.dart';

/// Home: one main action, then four tiles that each open one part of the
/// app. Short words, big numbers (handbook 3.2).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final now = ref.watch(clockProvider)();
    final today = dayOf(now);
    final weekStart = addDays(today, -(today.weekday - 1));
    final settings = ref.watch(currentSettingsProvider);
    final week = ref.watch(progressProvider((weekStart, addDays(weekStart, 6)))).value;
    final meals = ref.watch(mealDayProvider(dayKey(today))).value ?? const [];
    final totals = totalsOf(meals.map((e) => e.input));
    final eaten = meals.where((m) => m.status == MealStatus.eaten).length;
    final greeting = now.hour < 12 ? 'Good morning' : (now.hour < 18 ? 'Good afternoon' : 'Good evening');

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
            const _ProposalBanner(),
            const _Hero(),
            const SizedBox(height: Space.m),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    icon: LucideIcons.utensils,
                    color: p.orange,
                    soft: p.orangeSoft,
                    label: 'Meals',
                    value: meals.isEmpty ? '0' : '$eaten/${meals.length}',
                    caption: meals.isEmpty ? 'Nothing yet' : 'eaten',
                    onTap: () => context.go('/meal'),
                    trailing: Ring(
                      value: meals.isEmpty ? 0 : eaten / meals.length,
                      color: p.orange,
                      size: 40,
                      stroke: 5,
                      semanticLabel: '$eaten of ${meals.length} foods eaten',
                    ),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: settings.showEnergy
                      ? _Tile(
                          icon: LucideIcons.flame,
                          color: p.coral,
                          soft: p.coralSoft,
                          label: 'Energy',
                          value: fmtNum(totals.energyKcal.value, maxDecimals: 0),
                          caption: totals.energyKcal.value == null ? 'Not logged' : 'kcal eaten',
                          onTap: () => context.go('/meal'),
                        )
                      : _Tile(
                          icon: LucideIcons.clipboardList,
                          color: p.brand,
                          soft: p.brandSoft,
                          label: 'Plans',
                          value: '${ref.watch(templatesProvider).value?.length ?? 0}',
                          caption: 'saved',
                          onTap: () => context.go('/workout'),
                        ),
                ),
              ],
            ),
            const SizedBox(height: Space.m),
            _WeekCard(
              weekStart: weekStart,
              today: today,
              trained: week?.trainingDays ?? const {},
              count: week?.sessions.length ?? 0,
            ),
            if (settings.health.contains(HealthFeature.steps.name) ||
                settings.health.contains(HealthFeature.activeEnergy.name)) ...[
              const SizedBox(height: Space.m),
              const _HealthRow(),
            ],
            const SizedBox(height: Space.m),
            Row(
              children: [
                Expanded(
                  child: _Tile(
                    icon: LucideIcons.bookOpen,
                    color: p.blue,
                    soft: p.blueSoft,
                    label: 'Learn',
                    value: '${ref.watch(libraryProvider).value?.moves.length ?? catalog.length}',
                    caption: 'exercises',
                    onTap: () => context.go('/workout/library'),
                  ),
                ),
                const SizedBox(width: Space.m),
                Expanded(
                  child: _Tile(
                    icon: LucideIcons.plus,
                    color: p.green,
                    soft: p.greenSoft,
                    label: 'Food',
                    value: 'Add',
                    caption: 'log a meal',
                    onTap: () => showMealEntrySheet(context, day: dayKey(today)),
                  ),
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

/// The one main action: start or continue a workout.
class _Hero extends ConsumerWidget {
  const _Hero();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final live = ref.watch(liveSessionProvider).value;
    return Semantics(
      button: true,
      label: live == null ? 'Start workout' : 'Continue workout',
      excludeSemantics: true,
      child: Material(
        color: p.panel,
        borderRadius: Radii.large,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: live == null ? () => startWorkout(context, ref) : () => context.push('/live/${live.id}'),
          child: Padding(
            padding: const EdgeInsets.all(Space.xl),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(live == null ? 'Train' : 'Training now', style: t.bodySmall?.copyWith(color: p.onPanelSoft)),
                      const SizedBox(height: Space.xs),
                      if (live == null)
                        Text('Start workout', style: t.headlineSmall?.copyWith(color: p.onPanel))
                      else
                        SessionClock(
                          sessionId: live.id,
                          style: t.displaySmall!.tabular.copyWith(color: p.energy),
                        ),
                    ],
                  ),
                ),
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(color: p.energy, shape: BoxShape.circle),
                  child: Icon(live == null ? LucideIcons.play : LucideIcons.arrowRight, color: p.onEnergy, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),
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
    this.trailing,
  });

  final IconData icon;
  final Color color;
  final Color soft;
  final String label;
  final String value;
  final String caption;
  final VoidCallback onTap;
  final Widget? trailing;

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
            Row(
              children: [
                IconBadge(icon, color: color, size: 40),
                const Spacer(),
                ?trailing,
              ],
            ),
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

/// Seven days. A filled day means you trained.
class _WeekCard extends StatelessWidget {
  const _WeekCard({required this.weekStart, required this.today, required this.trained, required this.count});
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
                Text('$count', style: t.headlineSmall?.tabular),
                const SizedBox(width: 4),
                Text(count == 1 ? 'workout' : 'workouts', style: t.bodySmall),
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
