import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/dates.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../health/health_service.dart';
import '../../health/health_sync.dart';

final healthAvailabilityProvider = FutureProvider.autoDispose(
  (ref) => ref.watch(healthSourceProvider).availability(),
);

/// Today's values for the types the user switched on. Read live from the
/// platform; Reparc does not copy them into its database.
final healthTodayProvider = FutureProvider.autoDispose<({int? steps, double? energy, WeightReading? weight})>((
  ref,
) async {
  final s = ref.watch(currentSettingsProvider);
  final h = ref.watch(healthSourceProvider);
  final today = dayOf(DateTime.now());
  final key = dayKey(today);
  int? steps;
  double? energy;
  WeightReading? weight;
  try {
    if (s.health.contains(HealthFeature.steps.name)) steps = (await h.dailySteps(today, today))[key];
    if (s.health.contains(HealthFeature.activeEnergy.name)) energy = (await h.dailyActiveEnergy(today, today))[key];
    if (s.health.contains(HealthFeature.weight.name)) weight = await h.latestWeight(addDays(today, 1));
  } catch (_) {
    // Shown as "no data"; never as zero.
  }
  return (steps: steps, energy: energy, weight: weight);
});

/// Me → Health apps (handbook section 9, D-020).
class HealthScreen extends ConsumerWidget {
  const HealthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final health = ref.watch(healthSourceProvider);
    final s = ref.watch(currentSettingsProvider);
    final availability = ref.watch(healthAvailabilityProvider);
    final today = ref.watch(healthTodayProvider);

    Future<void> toggle(HealthFeature f, bool on) async {
      final repo = ref.read(settingsRepoProvider);
      if (!on) {
        await repo.setHealth(f.name, false);
        if (context.mounted) {
          showMessage(
            context,
            'Reparc stopped ${f.writes ? 'writing' : 'reading'} ${f.label.toLowerCase()}. '
            'To remove the permission too, open ${health.platformName}.',
          );
        }
        return;
      }
      final go = await confirmAction(
        context,
        title: '${f.access} ${f.label.toLowerCase()}?',
        body:
            '${f.purpose}\n\n${health.platformName} will ask you next. Allow only "${f.label}". '
            'You can turn this off here or in ${health.platformName} at any time.',
        confirmLabel: 'Continue',
      );
      if (!go) return;
      try {
        await health.request(f);
        await repo.setHealth(f.name, true);
        ref.invalidate(healthTodayProvider);
        if (f.writes) unawaited(ref.read(healthSyncProvider).run());
      } catch (_) {
        if (context.mounted) showMessage(context, '${health.platformName} could not open. Try again.');
      }
    }

    String num(Object? v, String unit) => v == null ? 'No data' : '$v $unit';

    return Scaffold(
      appBar: AppBar(title: const Text('Health apps')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          Text(
            'Connect ${health.platformName} one data type at a time. Reparc asks only for the types you switch on, '
            'reads them when a screen needs them, and does not copy them to any server. Logging works without any of this.',
            style: t.bodyMedium?.copyWith(color: p.inkSoft),
          ),
          const SizedBox(height: Space.l),
          availability.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, _) => const SizedBox.shrink(),
            data: (a) => switch (a) {
              HealthAvailability.available => const SizedBox.shrink(),
              HealthAvailability.needsInstall => AppCard(
                color: p.orangeSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Install or update Health Connect', style: t.titleSmall),
                    const SizedBox(height: Space.xs),
                    const Text('Android needs the Health Connect app before Reparc can connect.'),
                    const SizedBox(height: Space.s),
                    FilledButton(onPressed: health.install, child: const Text('Open Play Store')),
                  ],
                ),
              ),
              HealthAvailability.unsupported => EmptyState(
                icon: LucideIcons.heartOff,
                title: '${health.platformName} is not available',
                body: Platform.isAndroid
                    ? 'Health Connect needs Android 9 or later with Google Play services.'
                    : 'This device has no Health app.',
              ),
            },
          ),
          if (availability.value == HealthAvailability.available) ...[
            const SectionHeader('Read from health', top: Space.s),
            _card(
              context,
              ref,
              [
                for (final f in HealthFeature.values)
                  if (!f.writes) f,
              ],
              s.health,
              toggle,
            ),
            const SectionHeader('Write to health'),
            _card(
              context,
              ref,
              [
                for (final f in HealthFeature.values)
                  if (f.writes) f,
              ],
              s.health,
              toggle,
            ),
            const SizedBox(height: Space.s),
            StatusLine(
              icon: LucideIcons.info,
              text:
                  'Only workouts you finish and meals you mark as eaten after you switch writing on are written, once each. '
                  'Edits made later are not sent; change them in ${health.platformName}.',
            ),
            if (s.health.any((h) => !HealthFeature.values.byName(h).writes)) ...[
              const SectionHeader('Today'),
              AppCard(
                child: today.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (_, _) => const Text('Could not read health data.'),
                  data: (v) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (s.health.contains('steps')) Text('Steps: ${num(v.steps, '')}', style: t.bodyLarge),
                      if (s.health.contains('activeEnergy'))
                        Text('Active energy: ${num(v.energy?.round(), 'kcal')}', style: t.bodyLarge),
                      if (s.health.contains('weight'))
                        Text(
                          'Weight: ${v.weight == null ? 'No data in the last 90 days' : '${v.weight!.kg.toStringAsFixed(1)} kg · ${v.weight!.source}'}',
                          style: t.bodyLarge,
                        ),
                      const SizedBox(height: Space.s),
                      StatusLine(
                        icon: LucideIcons.eye,
                        text:
                            '"No data" can also mean that access was not allowed. ${health.platformName} does not tell apps.',
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: Space.l),
            OutlinedButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(
                  Platform.isIOS ? 'x-apple-health://' : 'market://details?id=com.google.android.apps.healthdata',
                ),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(LucideIcons.settings2, size: 18),
              label: Text('Manage permissions in ${health.platformName}'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _card(
    BuildContext context,
    WidgetRef ref,
    List<HealthFeature> features,
    Set<String> on,
    Future<void> Function(HealthFeature, bool) toggle,
  ) => AppCard(
    padding: const EdgeInsets.symmetric(vertical: Space.xs),
    child: Column(
      children: [
        for (final f in features)
          SwitchListTile(
            title: Row(
              children: [
                Flexible(child: Text(f.label)),
                const SizedBox(width: Space.s),
                Tag(f.access),
              ],
            ),
            subtitle: Text(f.purpose),
            value: on.contains(f.name),
            onChanged: (v) => toggle(f, v),
          ),
      ],
    ),
  );
}
