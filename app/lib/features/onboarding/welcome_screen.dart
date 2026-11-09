import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/brand.dart';
import '../../core/format.dart';
import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/providers.dart';
import '../../domain/nutrition.dart';
import '../../domain/roadmap.dart';
import '../../domain/targets.dart';
import '../../health/health_service.dart';
import '../../health/health_sync.dart';
import '../workout/roadmap_screens.dart' show goalIcon;
import '../workout/start_workout.dart';

/// First-run setup (owner request, 2026-11-09: "we need onboarding and it
/// must feel amazing"; replaces the three-question setup of 2026-10-10).
///
/// One question a screen, big choices that move on by themselves, and a
/// progress bar. It ends on the user's own plan and daily targets, not on
/// an empty dashboard. Every step after the first can be skipped; nothing
/// is saved until the last step, and nothing leaves the phone.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

enum _Step { hello, goal, level, days, body, food, diet, activity, health, ready }

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  _Step _step = _Step.hello;
  bool _back = false;
  RoadmapGoal? _goal;
  RoadmapLevel? _level;
  int? _days;
  Sex? _sex;
  final _age = TextEditingController();
  final _height = TextEditingController();
  final _weight = TextEditingController();
  BodyGoal? _bodyGoal;
  Diet? _diet;
  Activity? _activity;
  bool _healthAsked = false;
  bool _saving = false;
  String? _programId;

  @override
  void dispose() {
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    super.dispose();
  }

  void _go(_Step s) {
    FocusScope.of(context).unfocus();
    setState(() {
      _back = s.index < _step.index;
      _step = s;
    });
  }

  void _next() => _go(_Step.values[_step.index + 1]);

  /// Picks a choice and moves on after a beat, so the tick is seen.
  void _pick(VoidCallback set) {
    HapticFeedback.selectionClick();
    setState(set);
    Future.delayed(motionOf(context, const Duration(milliseconds: 220)), () {
      if (mounted) _next();
    });
  }

  Future<void> _skipAll() async {
    await ref.read(settingsRepoProvider).setOnboarded();
    if (mounted) context.go('/home');
  }

  double? _num(TextEditingController c) => double.tryParse(c.text.trim().replaceAll(',', '.'));

  /// Saves the plan, the profile, targets, and the first weight, then shows
  /// the result.
  Future<void> _finish() async {
    setState(() => _saving = true);
    final settings = ref.read(settingsRepoProvider);
    final unit = ref.read(currentSettingsProvider).loadUnit;
    String? id;
    if (_goal != null && _level != null) {
      final plan = buildProgram(goal: _goal!, level: _level!, setup: GymSetup.fullGym, days: _days);
      id = await guardedWrite(context, () => ref.read(programRepoProvider).adopt(plan));
    }
    final weight = _num(_weight);
    final kg = weight == null ? null : (unit == 'lb' ? weight * 0.45359237 : weight);
    final profile = Profile(
      sex: _sex,
      ageYears: _num(_age)?.round(),
      heightCm: _num(_height),
      weightKg: kg,
      activity: _activity,
      goal: _bodyGoal,
      diet: _diet,
    );
    await settings.setProfile(profile);
    if (profile.isComplete) await settings.setTargetsOn(true);
    if (weight != null && weight > 0) {
      try {
        await ref.read(bodyRepoProvider).addWeight(weight, unit);
      } catch (_) {}
    }
    await settings.setOnboarded();
    if (!mounted) return;
    setState(() {
      _saving = false;
      _programId = id;
      _back = false;
      _step = _Step.ready;
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final questions = _Step.values.length - 2;
    final shown = _step != _Step.hello && _step != _Step.ready;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: shown
                  ? Row(
                      children: [
                        IconButton(
                          tooltip: 'Back',
                          onPressed: () => _go(_Step.values[_step.index - 1]),
                          icon: const Icon(LucideIcons.chevronLeft),
                        ),
                        Expanded(
                          child: Semantics(
                            label: 'Step ${_step.index} of $questions',
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(3),
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(end: _step.index / questions),
                                duration: motionOf(context, Motion.expanded),
                                curve: Motion.change,
                                builder: (_, v, _) => LinearProgressIndicator(
                                  value: v,
                                  minHeight: 6,
                                  backgroundColor: p.line,
                                  color: p.brand,
                                ),
                              ),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _step.index >= _Step.body.index ? _next : _skipAll,
                          child: Text(_step.index >= _Step.body.index ? 'Not now' : 'Skip'),
                        ),
                      ],
                    )
                  : null,
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: motionOf(context, Motion.expanded),
                switchInCurve: Motion.enter,
                switchOutCurve: Motion.exit,
                transitionBuilder: (child, a) => FadeTransition(
                  opacity: a,
                  child: SlideTransition(
                    position: Tween(
                      begin: Offset(_back ? -0.08 : 0.08, 0),
                      end: Offset.zero,
                    ).animate(a),
                    child: child,
                  ),
                ),
                child: KeyedSubtree(key: ValueKey(_step), child: _page(context, t, p)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(BuildContext context, TextTheme t, Palette p) => switch (_step) {
    _Step.hello => _hello(t, p),
    _Step.goal => _choices(
      'What do you train for?',
      null,
      [
        for (final g in RoadmapGoal.values)
          _Choice(g.label, g.summary, goalIcon(g), _goal == g, () => _pick(() => _goal = g)),
      ],
    ),
    _Step.level => _choices(
      'How long have you trained?',
      'Sets the plan\'s volume and how fast it adds weight.',
      [
        for (final l in RoadmapLevel.values)
          _Choice(l.label, l.hint, null, _level == l, () {
            _pick(() {
              _level = l;
              if (_goal != null) _days = _goal!.defaultDays(l);
            });
          }),
      ],
    ),
    _Step.days => _choices('How many days a week?', null, [
      for (final d in (_goal ?? RoadmapGoal.values.first).dayOptions)
        _Choice(
          '$d days',
          _goal != null && _level != null && d == _goal!.defaultDays(_level!) ? 'Suggested for you' : '',
          null,
          _days == d,
          () => _pick(() => _days = d),
        ),
    ]),
    _Step.body => _body(t, p),
    _Step.food => _choices('What do you want from food?', 'Sets your daily energy and protein.', [
      for (final g in BodyGoal.values)
        _Choice(
          g.label,
          switch (g) {
            BodyGoal.lose => 'About 20% under what you burn',
            BodyGoal.maintain => 'Eat what you burn',
            BodyGoal.gain => 'About 10% over what you burn',
          },
          switch (g) {
            BodyGoal.lose => LucideIcons.trendingDown,
            BodyGoal.maintain => LucideIcons.minus,
            BodyGoal.gain => LucideIcons.trendingUp,
          },
          _bodyGoal == g,
          () => _pick(() => _bodyGoal = g),
        ),
    ]),
    _Step.diet => _choices('How do you eat?', 'Food suggestions follow this.', [
      for (final d in Diet.values) _Choice(d.label, d.hint, null, _diet == d, () => _pick(() => _diet = d)),
    ]),
    _Step.activity => _choices('How active is a normal day?', 'Include your training.', [
      for (final a in Activity.values) _Choice(a.label, a.hint, null, _activity == a, () => _pick(() => _activity = a)),
    ]),
    _Step.health => _health(t, p),
    _Step.ready => _ready(t, p),
  };

  Widget _hello(TextTheme t, Palette p) => Padding(
    padding: const EdgeInsets.fromLTRB(Space.xl, Space.xl, Space.xl, Space.xl),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(flex: 2),
        const ReparcLogo(size: 72, background: true),
        const SizedBox(height: Space.xl),
        Text('Train, eat, and move.\nOne log.', style: t.displaySmall),
        const SizedBox(height: Space.m),
        Text(
          'Seven quick questions build your plan and daily targets. Everything stays on this phone.',
          style: t.bodyLarge?.copyWith(color: p.inkSoft),
        ),
        const Spacer(flex: 3),
        FilledButton(
          onPressed: _next,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: const Text('Build my plan'),
        ),
        const SizedBox(height: Space.s),
        Center(
          child: TextButton(onPressed: _skipAll, child: const Text('Skip, I will set it up later')),
        ),
      ],
    ),
  );

  Widget _choices(String title, String? sub, List<_Choice> options) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
      children: [
        Text(title, style: t.headlineMedium),
        if (sub != null) ...[
          const SizedBox(height: Space.xs),
          Text(sub, style: t.bodyMedium?.copyWith(color: p.inkSoft)),
        ],
        const SizedBox(height: Space.xl),
        for (final o in options) ...[_ChoiceCard(o), const SizedBox(height: Space.s)],
      ],
    );
  }

  Widget _body(TextTheme t, Palette p) {
    final unit = ref.watch(currentSettingsProvider).loadUnit;
    InputDecoration field(String label, String suffix) => InputDecoration(labelText: label, suffixText: suffix);
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
      children: [
        Text('About you', style: t.headlineMedium),
        const SizedBox(height: Space.xs),
        Text('Used only to work out your daily energy.', style: t.bodyMedium?.copyWith(color: p.inkSoft)),
        const SizedBox(height: Space.xl),
        PillTabs<Sex?>(
          values: Sex.values,
          selected: _sex,
          label: (s) => s!.label,
          onChanged: (s) => setState(() => _sex = s),
        ),
        const SizedBox(height: Space.l),
        TextField(
          controller: _age,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: field('Age', 'years'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Space.m),
        TextField(
          controller: _height,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: field('Height', 'cm'),
          textInputAction: TextInputAction.next,
        ),
        const SizedBox(height: Space.m),
        TextField(
          controller: _weight,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: field('Weight', unit),
          textInputAction: TextInputAction.done,
        ),
        const SizedBox(height: Space.xl),
        FilledButton(
          onPressed: _next,
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
          child: const Text('Next'),
        ),
      ],
    );
  }

  Widget _health(TextTheme t, Palette p) {
    final health = ref.watch(healthSourceProvider);
    return FutureBuilder<HealthAvailability>(
      future: ref.read(healthSourceProvider).availability(),
      builder: (context, snap) {
        final ok = snap.data == HealthAvailability.available;
        return ListView(
          padding: const EdgeInsets.fromLTRB(Space.l, Space.l, Space.l, Space.xxl),
          children: [
            Text('Bring in your steps', style: t.headlineMedium),
            const SizedBox(height: Space.xs),
            Text(
              ok
                  ? 'Read steps, distance, active energy, and weight from ${health.platformName}. '
                        'Save your workouts and meals there. You choose each type on the next screen.'
                  : '${health.platformName} is not available on this phone. You can connect it later in Me.',
              style: t.bodyMedium?.copyWith(color: p.inkSoft),
            ),
            const SizedBox(height: Space.xl),
            for (final (icon, text) in [
              (LucideIcons.footprints, 'Steps and distance on Home'),
              (LucideIcons.flame, 'Energy burned next to energy eaten'),
              (LucideIcons.scale, 'Your latest weight for meal targets'),
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: Space.m),
                child: Row(
                  children: [
                    Icon(icon, size: IconSizes.m, color: p.brand),
                    const SizedBox(width: Space.m),
                    Expanded(child: Text(text, style: t.bodyLarge)),
                  ],
                ),
              ),
            const SizedBox(height: Space.l),
            if (ok && !_healthAsked)
              FilledButton(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _healthAsked = true);
                        try {
                          final granted = await health.requestAll(HealthFeature.values);
                          for (final f in granted) {
                            await ref.read(settingsRepoProvider).setHealth(f.name, true);
                          }
                          if (granted.any((f) => f.writes)) unawaited(ref.read(healthSyncProvider).run());
                        } catch (_) {}
                        await _finish();
                      },
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
                child: Text('Connect ${health.platformName}'),
              ),
            const SizedBox(height: Space.s),
            OutlinedButton(
              onPressed: _saving ? null : _finish,
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              child: Text(ok ? 'Not now' : 'Finish'),
            ),
          ],
        );
      },
    );
  }

  Widget _ready(TextTheme t, Palette p) {
    final program = _programId == null ? null : ref.watch(activeProgramProvider).value;
    final day = program == null || program.plan.days.isEmpty ? null : program.plan.days[program.nextDay];
    final settings = ref.watch(currentSettingsProvider);
    final targets = {for (final x in settings.targets) x.nutrient: x.amount};
    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.xl, Space.l, Space.xxl),
      children: [
        Icon(LucideIcons.circleCheck, size: 44, color: p.brand),
        const SizedBox(height: Space.m),
        Text('Your plan is ready', style: t.headlineMedium),
        if (program != null) Text(program.name, style: t.bodyLarge?.copyWith(color: p.inkSoft)),
        const SizedBox(height: Space.xl),
        if (day != null)
          Material(
            color: p.panel,
            borderRadius: Radii.large,
            child: Padding(
              padding: const EdgeInsets.all(Space.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FIRST WORKOUT',
                    style: t.labelSmall?.copyWith(color: p.energy, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: Space.xs),
                  Text(day.name, style: t.headlineSmall?.copyWith(color: p.onPanel)),
                  Text(
                    '${day.work.length} exercises · about ${day.minutes} min',
                    style: t.bodySmall?.copyWith(color: p.onPanelSoft),
                  ),
                  const SizedBox(height: Space.l),
                  FilledButton.icon(
                    onPressed: () => startWorkout(context, ref, programId: program!.id, programDay: program.nextDay),
                    style: FilledButton.styleFrom(
                      backgroundColor: p.energy,
                      foregroundColor: p.onEnergy,
                      minimumSize: const Size.fromHeight(52),
                    ),
                    icon: const Icon(LucideIcons.play),
                    label: const Text('Start now'),
                  ),
                ],
              ),
            ),
          ),
        if (targets.isNotEmpty) ...[
          const SizedBox(height: Space.m),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Each day', style: t.titleMedium),
                const SizedBox(height: Space.m),
                Row(
                  children: [
                    for (final (n, label, unit) in [
                      (Nutrient.energy, 'Energy', 'kcal'),
                      (Nutrient.protein, 'Protein', 'g'),
                      (Nutrient.fiber, 'Fibre', 'g'),
                    ])
                      if (targets[n] != null)
                        Expanded(
                          child: Metric(label: label, value: fmtNum(targets[n], maxDecimals: 0), unit: unit),
                        ),
                  ],
                ),
                const SizedBox(height: Space.s),
                Text('Change these in Me → Body and goals.', style: t.bodySmall),
              ],
            ),
          ),
        ],
        const SizedBox(height: Space.xl),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(52)),
          child: const Text('Go to Home'),
        ),
      ],
    );
  }
}

class _Choice {
  const _Choice(this.title, this.body, this.icon, this.selected, this.onTap);
  final String title;
  final String body;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;
}

/// A large choice. The chosen one gets a teal edge and a tick.
class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard(this.o);
  final _Choice o;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Semantics(
      selected: o.selected,
      button: true,
      child: AnimatedContainer(
        duration: motionOf(context, Motion.quick),
        decoration: BoxDecoration(
          color: o.selected ? p.brandSoft : p.surface,
          borderRadius: Radii.large,
          border: Border.all(color: o.selected ? p.brand : p.line, width: o.selected ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: Radii.large,
            onTap: o.onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: Space.l, vertical: Space.l),
              child: Row(
                children: [
                  if (o.icon != null) ...[
                    Icon(o.icon, size: IconSizes.m, color: p.brand),
                    const SizedBox(width: Space.l),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(o.title, style: t.titleMedium),
                        if (o.body.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(o.body, style: t.bodySmall),
                        ],
                      ],
                    ),
                  ),
                  AnimatedOpacity(
                    opacity: o.selected ? 1 : 0,
                    duration: motionOf(context, Motion.quick),
                    child: Icon(LucideIcons.check, color: p.brand),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
