import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/meal_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../domain/nutrition.dart';
import '../meal/meal_entry_sheet.dart';
import '../workout/session_clock.dart';
import '../workout/start_workout.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final today = dayOf(ref.watch(clockProvider)());
    final settings = ref.watch(currentSettingsProvider);
    final settingsLoaded = ref.watch(settingsProvider).hasValue;
    final live = ref.watch(liveSessionProvider);
    final progress = ref.watch(progressProvider((today, today)));
    final meals = ref.watch(mealDayProvider(dayKey(today)));

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            Text(fmtDayLong(today), style: t.bodyMedium?.copyWith(color: AppColors.secondaryText)),
            const SizedBox(height: Space.xs),
            Semantics(header: true, child: Text('Today', style: t.headlineSmall)),
            const SizedBox(height: Space.l),
            if (settingsLoaded && !settings.storageNoticeSeen) ...[
              const _StorageNotice(),
              const SizedBox(height: Space.l),
            ],
            _NextAction(liveId: live.value?.id, paused: live.value?.status == SessionStatus.paused),
            const SizedBox(height: Space.m),
            OutlinedButton.icon(
              onPressed: () => showMealEntrySheet(context, day: dayKey(today)),
              icon: const Icon(LucideIcons.utensils, size: IconSizes.s),
              label: const Text('Log a meal'),
            ),
            const SectionHeader('Today so far'),
            AsyncBody(
              value: progress,
              builder: (p) => Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: AppCard(
                      child: Metric(
                        label: 'Completed sets',
                        value: '${p.completedSets}',
                        note: p.sessions.isEmpty
                            ? 'No saved workout today'
                            : '${p.sessions.length} saved workout${p.sessions.length == 1 ? '' : 's'}',
                      ),
                    ),
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: AsyncBody(
                      value: meals,
                      builder: (entries) {
                        final totals = totalsOf(entries.map((e) => e.input));
                        return AppCard(
                          child: settings.showEnergy
                              ? _EnergyMetric(totals: totals)
                              : Metric(
                                  label: 'Foods eaten',
                                  value: '${totals.entries}',
                                  note: entries.isEmpty ? 'No meal logged today' : null,
                                ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: Space.m),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.go('/analytics'),
                icon: const Icon(LucideIcons.chartNoAxesColumn, size: IconSizes.s),
                label: const Text('See trends in Analytics'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnergyMetric extends StatelessWidget {
  const _EnergyMetric({required this.totals});
  final NutritionTotals totals;

  @override
  Widget build(BuildContext context) {
    final e = totals.energyKcal;
    String? note;
    if (totals.entries == 0) {
      note = 'No food marked as eaten';
    } else if (e.missing > 0) {
      note = '${e.missing} food${e.missing == 1 ? ' has' : 's have'} no energy value';
    } else if (totals.estimates > 0) {
      note = 'Includes estimates';
    }
    return Metric(
      label: 'Energy eaten',
      value: fmtNum(e.value, maxDecimals: 0),
      unit: e.value == null ? null : 'kcal',
      semanticValue: e.value == null ? missingLabel : null,
      note: note,
    );
  }
}

/// The one main action on Home (handbook 3.2).
class _NextAction extends ConsumerWidget {
  const _NextAction({required this.liveId, required this.paused});
  final String? liveId;
  final bool paused;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    final live = liveId != null;
    return AppCard(
      color: AppColors.ink,
      border: false,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            live ? (paused ? 'Workout paused' : 'Workout in progress') : 'Ready to train?',
            style: t.titleLarge?.copyWith(color: AppColors.surface),
          ),
          const SizedBox(height: Space.xs),
          if (live)
            SessionClock(
              sessionId: liveId!,
              style: t.displaySmall!.tabular.copyWith(color: AppColors.lime),
            )
          else
            Text(
              'Start an empty workout or pick a plan in Workout.',
              style: t.bodyMedium?.copyWith(color: AppColors.border),
            ),
          const SizedBox(height: Space.l),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: live ? () => context.push('/live/$liveId') : () => startWorkout(context, ref),
              icon: Icon(live ? LucideIcons.play : LucideIcons.dumbbell, size: IconSizes.s),
              label: Text(live ? 'Continue workout' : 'Start workout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageNotice extends ConsumerWidget {
  const _StorageNotice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.softSurface,
      border: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const ExcludeSemantics(child: Icon(LucideIcons.cloudOff, size: IconSizes.s)),
              const SizedBox(width: Space.s),
              Expanded(child: Text('Saved on this phone only', style: t.titleSmall)),
            ],
          ),
          const SizedBox(height: Space.s),
          Text(
            'Reparc saves your records on this phone. It does not back them up to a server. '
            'If you lose or erase this phone, you can lose your records. Export a copy from Me.',
            style: t.bodyMedium,
          ),
          const SizedBox(height: Space.s),
          Wrap(
            spacing: Space.s,
            children: [
              TextButton(
                onPressed: () => ref.read(settingsRepoProvider).setStorageNoticeSeen(),
                child: const Text('Got it'),
              ),
              TextButton(onPressed: () => context.go('/me/data'), child: const Text('Export options')),
            ],
          ),
        ],
      ),
    );
  }
}
