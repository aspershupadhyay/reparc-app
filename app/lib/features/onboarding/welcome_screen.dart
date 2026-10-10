import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../domain/roadmap.dart';
import '../workout/roadmap_screens.dart' show goalIcon;
import '../workout/start_workout.dart';

/// First-run setup (launch review Block 2, owner choice 2026-10-10): goal,
/// level, and days a week pick one of the built-in plans, then the screen
/// shows the first workout. About 20 seconds, and it can be skipped.
/// Equipment is a full gym; the user can build another plan any time in
/// Workout.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  int _step = 0;
  RoadmapGoal? _goal;
  RoadmapLevel? _level;
  int? _days;
  String? _programId;
  bool _saving = false;

  static const _steps = 3;

  Future<void> _skip() async {
    await ref.read(settingsRepoProvider).setOnboarded();
    if (mounted) context.go('/home');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final plan = buildProgram(goal: _goal!, level: _level!, setup: GymSetup.fullGym, days: _days);
    final id = await guardedWrite(context, () => ref.read(programRepoProvider).adopt(plan));
    if (id != null) await ref.read(settingsRepoProvider).setOnboarded();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _programId = id;
    });
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final done = _programId != null;
    return Scaffold(
      appBar: AppBar(
        leading: _step > 0 && !done
            ? IconButton(
                tooltip: 'Back',
                onPressed: () => setState(() => _step--),
                icon: const Icon(LucideIcons.chevronLeft),
              )
            : null,
        automaticallyImplyLeading: false,
        title: done ? null : Text('Step ${_step + 1} of $_steps', style: t.labelLarge),
        actions: [if (!done) TextButton(onPressed: _skip, child: const Text('Skip'))],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
          children: done ? _result(context) : _question(context),
        ),
      ),
    );
  }

  List<Widget> _question(BuildContext context) {
    final t = Theme.of(context).textTheme;
    Widget option({
      required String title,
      required String body,
      IconData? icon,
      required bool selected,
      required VoidCallback onTap,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Semantics(
        selected: selected,
        child: AppCard(
          onTap: onTap,
          child: Row(
            children: [
              if (icon != null) ...[
                IconBadge(icon, color: context.pal.brandSoft, glyph: context.pal.brand, size: 40),
                const SizedBox(width: Space.m),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: t.titleMedium),
                    Text(body, style: t.bodySmall),
                  ],
                ),
              ),
              if (selected) const Icon(LucideIcons.circleCheck),
            ],
          ),
        ),
      ),
    );

    switch (_step) {
      case 0:
        return [
          Text('What do you want from training?', style: t.headlineSmall),
          const SizedBox(height: Space.l),
          for (final g in RoadmapGoal.values)
            option(
              title: g.label,
              body: g.summary,
              icon: goalIcon(g),
              selected: _goal == g,
              onTap: () => setState(() {
                _goal = g;
                _step = 1;
              }),
            ),
        ];
      case 1:
        return [
          Text('How long have you trained?', style: t.headlineSmall),
          const SizedBox(height: Space.l),
          for (final l in RoadmapLevel.values)
            option(
              title: l.label,
              body: l.hint,
              selected: _level == l,
              onTap: () => setState(() {
                _level = l;
                _days = _goal!.defaultDays(l);
                _step = 2;
              }),
            ),
        ];
      default:
        return [
          Text('How many days a week can you train?', style: t.headlineSmall),
          const SizedBox(height: Space.l),
          for (final d in _goal!.dayOptions)
            option(
              title: '$d days',
              body: d == _goal!.defaultDays(_level!) ? 'Suggested for you' : '',
              selected: _days == d,
              onTap: () => setState(() => _days = d),
            ),
          const SizedBox(height: Space.l),
          FilledButton(
            onPressed: _saving || _days == null ? null : _save,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            child: const Text('Make my plan'),
          ),
        ];
    }
  }

  List<Widget> _result(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final program = ref.watch(activeProgramProvider).value;
    final day = program == null || program.plan.days.isEmpty ? null : program.plan.days[program.nextDay];
    return [
      const SizedBox(height: Space.xl),
      Text('Your plan is ready', style: t.headlineSmall),
      const SizedBox(height: Space.xs),
      Text(program?.name ?? '', style: t.bodyMedium),
      const SizedBox(height: Space.xl),
      if (day != null)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('YOUR FIRST WORKOUT', style: t.labelSmall),
              const SizedBox(height: Space.xs),
              Text(day.name, style: t.titleLarge),
              Text('${day.work.length} exercises · about ${day.minutes} min', style: t.bodySmall),
            ],
          ),
        ),
      const SizedBox(height: Space.xl),
      if (day != null)
        FilledButton.icon(
          onPressed: () => startWorkout(context, ref, programId: program!.id, programDay: program.nextDay),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          icon: const Icon(LucideIcons.play),
          label: const Text('Start now'),
        ),
      const SizedBox(height: Space.s),
      OutlinedButton(
        onPressed: () => context.go('/home'),
        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        child: const Text('Later'),
      ),
      const SizedBox(height: Space.l),
      Text('You can change any part of the plan in Workout.', style: t.bodySmall, textAlign: TextAlign.center),
    ];
  }
}
