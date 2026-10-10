import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/widgets.dart' show AppLifecycleState;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/program_repository.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/guide.dart';
import 'package:reparc/domain/roadmap.dart';
import 'package:reparc/domain/session_time.dart';
import 'package:reparc/domain/voice_names.dart';
import 'package:reparc/features/workout/guide_controller.dart';
import 'package:reparc/features/workout/lock_alerts.dart';
import 'package:reparc/features/workout/voice.dart';

import 'helpers.dart';

class FakeVoice implements VoicePlayer {
  final said = <String>[];
  var silenced = 0;
  @override
  void say(String voice, String clip, {bool now = false}) {
    if (voice == 'off') return;
    if (now) silence();
    said.add(clip);
  }

  @override
  void silence() => silenced++;

  @override
  void preload(String voice) {}

  @override
  void dispose() {}
}

class FakeAlerts implements LockAlerts {
  var cues = <AlertCue>[];
  LiveCard? card;
  var asked = 0;
  var cleared = 0;
  var exact = true;

  @override
  Future<bool> askPermission() async {
    asked++;
    return true;
  }

  @override
  Future<bool> onTime() async => exact;

  @override
  Future<void> askOnTime() async {}

  @override
  Future<void> show(List<AlertCue> cues, {required String voice, LiveCard? card}) async {
    this.cues = cues;
    this.card = card;
  }

  @override
  Future<void> showCard(LiveCard card) async => this.card = card;

  @override
  Future<void> clear() async {
    cleared++;
    cues = [];
    card = null;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('rules', () {
    test('set time comes from reps, within 20–90 s', () {
      expect(estimateSetSec(null), 40);
      expect(estimateSetSec(5), 20);
      expect(estimateSetSec(10), 30);
      expect(estimateSetSec(50), 90);
    });

    test('targets and rest are read from the exercise note', () {
      expect(targetRepsFromNote('Target: 3 × 8–12 · 2 min rest · 2 reps left'), 12);
      expect(targetRepsFromNote('Target: 10 reps'), 10);
      expect(targetRepsFromNote('Target: 3 × 5'), 5);
      expect(targetRepsFromNote('Target: 3 × 45 s · 1 min rest'), isNull, reason: 'A timed target has no reps');
      expect(restFromNote('Target: 3 × 6–10 · 2:30 min rest · 2 reps left'), 150);
      expect(restFromNote('Target: 3 × 12 · 45 s rest'), 45);
      expect(restFromNote('Target: 3 × 12'), isNull);
    });

    test('cues fire once, when their time is crossed', () {
      const all = {...Cue.values};
      final set40 = setPlan(40, all);
      expect(set40.map((c) => (c.at, c.clip)), [
        (20, 'halfway'),
        (37, 'three'),
        (38, 'two'),
        (39, 'one'),
        (40, 'time'),
      ]);
      expect(cueBetween(set40, 0, 15), isNull);
      expect(cueBetween(set40, 19, 20), Clips.halfway);
      expect(cueBetween(set40, 39, 41), Clips.time);
      expect(cueBetween(set40, 41, 42), isNull);
      expect(setPlan(0, all), isEmpty, reason: 'A set with no set time says nothing');
      final rest60 = restPlan(60, all, autoStart: false);
      expect(cueBetween(rest60, 49, 50), Clips.tenLeft);
      expect(cueBetween(rest60, 56, 57), Clips.three);
      expect(cueBetween(rest60, 57, 58), Clips.two);
      expect(cueBetween(rest60, 58, 59), Clips.one);
      expect(cueBetween(rest60, 56, 59), Clips.one, reason: 'A late tick says only the latest word');
      expect(cueBetween(rest60, 59, 60), Clips.restOver);
      expect(cueBetween(rest60, 30, 65), isNull, reason: 'A tick long after the cue says nothing stale');
      expect(cueBetween(restPlan(60, all, autoStart: true), 59, 60), isNull, reason: 'The set cue follows');
      expect(restPlan(15, all, autoStart: false).map((c) => c.clip), ['three', 'two', 'one', 'rest_over']);
      expect(restPlan(60, {Cue.end}, autoStart: false).map((c) => c.clip), [
        'rest_over',
      ], reason: 'Each cue can be off');
      expect(setPlan(40, {}), isEmpty);
      expect(Clips.rest(90), 'rest_90');
      expect(Clips.rest(75), 'rest');
      expect(Clips.set(11), Clips.go);
      expect(Clips.nextUp('bench-press'), 'names/bench_press');
      expect(Clips.nextUp('lib:Barbell_Shrug'), 'names/lib_barbell_shrug');
      expect(Clips.nextUp('user:abc'), isNull, reason: 'Own exercises have no clip');
    });

    test('warm-up moves have no rest between them; the warm-up rest and set rest are the user\'s', () {
      expect(targetRepsFromNote('Warm-up · 8 reps · Move the whole spine slowly.'), 8);
      expect(targetRepsFromNote('Warm-up · 5 min · Get warm.'), isNull);
      expect(nextAim(load: 60, reps: 8, unit: 'kg'), (load: 60.0, reps: 8));
      expect(nextAim(load: 60, reps: 8, unit: 'kg', style: LoadStyle.pyramid), (load: 62.5, reps: 6));
      expect(nextAim(load: 135, reps: 2, unit: 'lb', style: LoadStyle.pyramid), (load: 140.0, reps: 1));
      expect(nextAim(reps: 1, style: LoadStyle.pyramid), (load: null, reps: 1), reason: 'Missing stays missing');
    });

    test('ramp-up sets read their share and reps from the note', () {
      const note = 'Target: 2 × 8–12 · 1:15 min rest\nRamp-up sets first: 50% × 8, 70% × 5 of your working weight';
      expect(rampUpFromNote(note, 0), (percent: 50, reps: 8));
      expect(rampUpFromNote(note, 1), (percent: 70, reps: 5));
      expect(rampUpFromNote(note, 2), isNull);
      expect(rampUpFromNote('Target: 3 × 5', 0), isNull);
    });

    test('every clip exists for every voice', () {
      for (final v in ['charlie', 'matilda']) {
        for (final c in [...Clips.all, for (final id in spokenExercises) Clips.nextUp(id)!]) {
          expect(File('assets/voice/$v/$c.mp3').existsSync(), isTrue, reason: '$v/$c');
        }
      }
    });
  });

  group('controller', () {
    late AppDatabase db;
    late FakeClock clock;
    late FakeVoice voice;
    late ProviderContainer c;
    late FakeAlerts alerts;

    setUp(() async {
      db = memoryDb();
      clock = FakeClock(DateTime.utc(2026, 3, 2, 18));
      voice = FakeVoice();
      alerts = FakeAlerts();
      c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          voicePlayerProvider.overrideWithValue(voice),
          lockAlertsProvider.overrideWithValue(alerts),
        ],
      );
      c.listen(currentSettingsProvider, (_, _) {});
    });
    tearDown(() async {
      c.dispose();
      await db.close();
    });

    Future<String> startDay({int exercises = 1}) async {
      final plan = ProgramPlan(
        days: [
          PlanDay(
            name: 'Push',
            focus: '',
            items: [
              for (var i = 0; i < exercises; i++)
                PlanItem(
                  kind: ItemKind.main,
                  exerciseId: 'bench-press',
                  name: i == 0 ? 'Bench press' : 'Incline press',
                  sets: exercises == 1 ? 2 : 1,
                  repsLow: 8,
                  repsHigh: 8,
                  restSec: 60,
                ),
            ],
          ),
        ],
      );
      final id = await ProgramRepository(db, clock.call).create(plan, name: 'Push');
      return WorkoutRepository(db, clock.call).startProgramDay(programId: id, dayIndex: 0);
    }

    Future<void> setting(String key, String value) async {
      await db.into(db.settings).insert(SettingsCompanion.insert(key: key, value: value));
      await Future<void>.delayed(Duration.zero);
    }

    /// The user starts and ends each set (both hands-free switches off).
    Future<void> manual() async {
      await setting('guide.finishReps', 'false');
      await setting('guide.autoStart', 'false');
    }

    Future<void> after(int seconds) async {
      clock.advance(Duration(seconds: seconds));
      await c.read(guideProvider.notifier).tick();
    }

    Future<void> ticks(int seconds) async {
      for (var i = 0; i < seconds; i++) {
        await after(1);
      }
    }

    test('in manual mode the user starts and ends each set; the guide times it and speaks', () async {
      await manual();
      final sessionId = await startDay();
      final guide = c.read(guideProvider.notifier);
      final repo = WorkoutRepository(db, clock.call);
      await guide.startSet();
      expect(c.read(guideProvider).phase, GuidePhase.set);
      expect(c.read(guideProvider).targetSec, 0, reason: 'A rep set has no guessed end');
      expect(c.read(guideProvider).label, 'Bench press · set 1 of 2');
      expect(voice.said, ['set_1']);

      await ticks(40);
      expect(c.read(guideProvider).phase, GuidePhase.set, reason: 'The set waits for Set done');
      expect(voice.said, ['set_1']);

      await guide.finishSet();
      expect(voice.said, ['set_1', 'rest_60']);
      var sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.first.completed, isTrue);
      expect(sets.first.durationSec, 40, reason: 'The measured set time is saved');
      expect(sets.first.reps, isNull, reason: 'The guide never invents reps');

      await ticks(60);
      expect(voice.said.sublist(2), ['ten_left', 'three', 'two', 'one', 'rest_over']);
      expect(c.read(guideProvider).phase, GuidePhase.rest, reason: 'The next set waits for the user');

      await after(20);
      await guide.startSet();
      expect(voice.said.last, 'last_set');
      sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.first.restSec, 80, reason: 'The rest really taken is saved');

      clock.advance(const Duration(seconds: 15));
      await guide.finishSet();
      expect(voice.said.last, 'last_set', reason: '"Workout complete" waits until the workout is saved');
      sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.last.durationSec, 15);
      expect(sets.every((s) => s.completed), isTrue);
      expect(c.read(guideProvider).phase, GuidePhase.idle);

      guide.workoutSaved();
      expect(voice.said.last, 'done');
    });

    test('by default sets end on time and start after a countdown', () async {
      final sessionId = await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      expect(c.read(guideProvider).targetSec, 24, reason: '8 reps × 3 s');

      await ticks(24);
      expect(voice.said, ['set_1', 'three', 'two', 'one', 'time', 'rest_60']);
      final repo = WorkoutRepository(db, clock.call);
      final sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.first.completed, isTrue);
      expect(sets.first.durationSec, isNull, reason: 'A guessed set time is not a measured value');

      await ticks(60);
      expect(voice.said.sublist(6), ['ten_left', 'three', 'two', 'one', 'last_set']);
      expect(c.read(guideProvider).phase, GuidePhase.set);
    });

    Future<String> startWarmupDay() async {
      final plan = ProgramPlan(
        days: [
          PlanDay(
            name: 'Push',
            focus: '',
            items: const [
              PlanItem(kind: ItemKind.warmup, exerciseId: 'lib:Recumbent_Bike', name: 'Easy bike', seconds: 60),
              PlanItem(kind: ItemKind.warmup, exerciseId: 'lib:Arm_Circles', name: 'Arm circles', repsLow: 10),
              PlanItem(
                kind: ItemKind.main,
                exerciseId: 'bench-press',
                name: 'Bench press',
                sets: 3,
                repsLow: 8,
                repsHigh: 8,
                restSec: 60,
              ),
            ],
          ),
        ],
      );
      final id = await ProgramRepository(db, clock.call).create(plan, name: 'Push');
      return WorkoutRepository(db, clock.call).startProgramDay(programId: id, dayIndex: 0);
    }

    test('warm-up moves run back to back, then the user\'s warm-up rest, then sets on their own', () async {
      await setting('guide.warmupRestSec', '45');
      final sessionId = await startWarmupDay();
      final guide = c.read(guideProvider.notifier);
      final repo = WorkoutRepository(db, clock.call);
      await guide.startSet();
      expect(c.read(guideProvider).label, 'Easy bike · warm-up');
      expect(c.read(guideProvider).targetSec, 60);

      await ticks(60);
      expect(c.read(guideProvider).phase, GuidePhase.set, reason: 'No rest between warm-up moves');
      expect(c.read(guideProvider).label, 'Arm circles · warm-up');
      expect(c.read(guideProvider).targetSec, 30, reason: '10 reps × 3 s');
      expect((await repo.loadSession(sessionId))!.session.restStartedAt, isNull);

      await ticks(30);
      var s = (await repo.loadSession(sessionId))!.session;
      expect(s.restTargetSec, 45, reason: 'The rest after the warm-up is the user\'s');
      expect(c.read(guideProvider).phase, GuidePhase.rest);
      expect(voice.said.last, 'rest_45');

      await ticks(45);
      expect(c.read(guideProvider).label, 'Bench press · set 1 of 3');
      expect(voice.said.last, 'set_1');
      // The user types what they lift during the set.
      final sets = (await repo.loadSession(sessionId))!.exercises.last.sets;
      await repo.updateSet(
        sets[0].id,
        const SetEntriesCompanion(load: Value(60), loadUnit: Value('kg'), reps: Value(8)),
      );
      await ticks(24);
      s = (await repo.loadSession(sessionId))!.session;
      expect(s.restTargetSec, 60, reason: 'The plan rest, when the user has not chosen one');
      final next = (await repo.loadSession(sessionId))!.exercises.last.sets[1];
      expect((next.load, next.reps, next.completed), (60.0, 8, false), reason: 'Same weight, not marked done');

      await ticks(60);
      expect(c.read(guideProvider).label, 'Bench press · set 2 of 3');
      expect(voice.said.where((x) => x == 'rest_over'), isEmpty, reason: 'The set cue ends the rest');
    });

    test('a pyramid adds weight and takes off reps; the user\'s rest wins over the plan', () async {
      await setting('guide.loadStyle', 'pyramid');
      await setting('restAfterSetSec', '90');
      final sessionId = await startDay();
      final repo = WorkoutRepository(db, clock.call);
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      final sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      await repo.updateSet(
        sets[0].id,
        const SetEntriesCompanion(load: Value(60), loadUnit: Value('kg'), reps: Value(10)),
      );
      await ticks(24);
      final after = (await repo.loadSession(sessionId))!;
      expect((after.exercises.single.sets[1].load, after.exercises.single.sets[1].reps), (62.5, 8));
      expect(after.session.restTargetSec, 90);
    });

    test('locked: the whole timed chain is set as alerts, and the record catches up on return', () async {
      final sessionId = await startDay();
      final guide = c.read(guideProvider.notifier);
      final repo = WorkoutRepository(db, clock.call);
      await guide.startSet();
      final start = clock().toUtc();
      await after(5);
      await guide.lifecycleChanged(AppLifecycleState.paused);
      final timeline = alerts.cues.map((c) => (c.at.difference(start).inSeconds, c.clip)).toList();
      expect(timeline, [
        (21, 'three'),
        (22, 'two'),
        (23, 'one'),
        (24, 'time'),
        (74, 'ten_left'),
        (81, 'three'),
        (82, 'two'),
        (83, 'one'),
        (84, 'last_set'),
        (105, 'three'),
        (106, 'two'),
        (107, 'one'),
        (108, 'time'),
      ]);

      // The phone stops the app; it wakes 95 s into the workout.
      clock.advance(const Duration(seconds: 90));
      await guide.lifecycleChanged(AppLifecycleState.resumed);
      await after(0);
      final d = (await repo.loadSession(sessionId))!;
      expect(d.exercises.single.sets.first.completedAt, start.add(const Duration(seconds: 24)));
      expect(d.exercises.single.sets.first.restSec, 60, reason: 'The rest as the alerts timed it');
      expect(c.read(guideProvider).phase, GuidePhase.set);
      expect(c.read(guideProvider).startedAt, start.add(const Duration(seconds: 84)));
      expect(voice.said, ['set_1'], reason: 'Nothing stale is said on return');
    });

    test('a running set survives the app being closed', () async {
      final sessionId = await startDay();
      await c.read(guideProvider.notifier).startSet();
      final start = clock().toUtc();
      await after(5);
      await Future<void>.delayed(Duration.zero);
      c.dispose();

      // The app opens again 30 s into the 24 s set.
      clock.advance(const Duration(seconds: 25));
      c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          voicePlayerProvider.overrideWithValue(voice),
          lockAlertsProvider.overrideWithValue(alerts),
        ],
      );
      c.listen(currentSettingsProvider, (_, _) {});
      await Future<void>.delayed(Duration.zero);
      await c.read(guideProvider.notifier).restore();
      expect(c.read(guideProvider).phase, GuidePhase.set);
      expect(c.read(guideProvider).startedAt, start);
      await after(0);
      final repo = WorkoutRepository(db, clock.call);
      final d = (await repo.loadSession(sessionId))!;
      expect(d.exercises.single.sets.first.completedAt, start.add(const Duration(seconds: 24)));
      expect(d.session.restStartedAt, start.add(const Duration(seconds: 24)), reason: 'The rest started on time');
    });

    test('a pause stops the set time and the rest', () async {
      final sessionId = await startDay();
      final guide = c.read(guideProvider.notifier);
      final repo = WorkoutRepository(db, clock.call);
      await after(0);
      await guide.startSet();
      await ticks(10);
      await guide.setPaused(sessionId, true);
      expect(voice.said.last, 'paused');
      await ticks(30);
      expect(c.read(guideProvider).elapsedAt(clock().toUtc()), 10);
      await guide.setPaused(sessionId, false);
      expect(voice.said.last, 'resumed');
      await ticks(5);
      expect(c.read(guideProvider).elapsedAt(clock().toUtc()), 15);

      await guide.finishSet();
      await ticks(20);
      await guide.setPaused(sessionId, true);
      await after(300);
      await guide.setPaused(sessionId, false);
      final s = (await repo.loadSession(sessionId))!.session;
      final left = restRemaining(restStartedAt: s.restStartedAt, restTargetSec: s.restTargetSec, now: clock().toUtc());
      expect(left, const Duration(seconds: 40), reason: 'The rest goes on from where it was');
      expect(voice.said.where((c) => c == 'paused'), hasLength(2));
      expect(voice.said, isNot(contains('rest_over')));
    });

    test('the next exercise is named before the rest ends, not on top of "Go"', () async {
      await manual();
      await startDay(exercises: 2);
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      await after(30);
      await guide.finishSet();
      await ticks(50);
      expect(voice.said, ['set_1', 'rest_60', 'ten_left', 'names/bench_press']);
      await guide.startSet();
      expect(voice.said.last, 'set_1');
      expect(voice.said.where((c) => c.startsWith('names/')), hasLength(1));
    });

    test('stop cuts off the voice and ends the rest', () async {
      await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      await guide.finishSet();
      final before = voice.silenced;
      await guide.stop();
      expect(voice.silenced, before + 1);
      expect(c.read(guideProvider).phase, GuidePhase.idle);
      await ticks(70);
      expect(voice.said, ['set_1', 'rest_60'], reason: 'No rest cues after stop');
    });

    test('voice off and guide off are respected', () async {
      await setting('guide.voice', 'off');
      await manual();
      await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      await after(30);
      expect(voice.said, isEmpty);
      expect(c.read(guideProvider).phase, GuidePhase.set, reason: 'The set waits for Set done');
    });

    test('locked during a rest: the same cues come as alerts, and the voice waits', () async {
      await manual();
      await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      await after(30);
      await guide.finishSet();
      expect(alerts.asked, 1, reason: 'Asked on the first guided rest');
      final restStart = clock().toUtc();
      await after(5);
      await guide.lifecycleChanged(AppLifecycleState.hidden);
      expect(alerts.cues.map((c) => (c.at.difference(restStart).inSeconds, c.clip)), [
        (50, 'ten_left'),
        (57, 'three'),
        (58, 'two'),
        (59, 'one'),
        (60, 'rest_over'),
      ]);
      expect(alerts.cues.last.body, 'Next: Bench press · set 2 of 2');
      expect(alerts.card?.countdownTo, restStart.add(const Duration(seconds: 60)));
      final said = voice.said.length;
      await ticks(60);
      expect(voice.said, hasLength(said), reason: 'Only the alerts speak while away');

      await guide.lifecycleChanged(AppLifecycleState.resumed);
      expect(alerts.cleared, 1);
      await ticks(3);
      expect(voice.said, hasLength(said), reason: 'Nothing stale is said on return');
      await guide.startSet();
      await guide.finishSet();
      expect(alerts.asked, 1, reason: 'Asked only once');
    });

    test('locked mid-plank: the plank and the rest after it are covered; the late end is saved right', () async {
      await manual();
      final plan = ProgramPlan(
        days: [
          PlanDay(
            name: 'Core',
            focus: '',
            items: [
              PlanItem(kind: ItemKind.main, exerciseId: 'plank', name: 'Plank', sets: 2, seconds: 45, restSec: 60),
            ],
          ),
        ],
      );
      final id = await ProgramRepository(db, clock.call).create(plan, name: 'Core');
      final repo = WorkoutRepository(db, clock.call);
      final sessionId = await repo.startProgramDay(programId: id, dayIndex: 0);
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      final start = clock().toUtc();
      await after(10);
      await guide.lifecycleChanged(AppLifecycleState.paused);
      expect(alerts.cues.map((c) => (c.at.difference(start).inSeconds, c.clip)), [
        (22, 'halfway'),
        (42, 'three'),
        (43, 'two'),
        (44, 'one'),
        (45, 'time'),
        (95, 'ten_left'),
        (102, 'three'),
        (103, 'two'),
        (104, 'one'),
        (105, 'rest_over'),
      ]);
      expect(alerts.card?.countdownTo, start.add(const Duration(seconds: 45)));

      // iPhone stops the app while locked; it wakes at 70 s.
      clock.advance(const Duration(seconds: 60));
      await guide.lifecycleChanged(AppLifecycleState.resumed);
      await after(0);
      final sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.first.durationSec, 45, reason: 'The plank time, not the time the phone woke');
      expect(sets.first.completedAt, start.add(const Duration(seconds: 45)));
      final s = (await repo.loadSession(sessionId))!.session;
      expect(s.restStartedAt, start.add(const Duration(seconds: 45)), reason: 'The rest started when the plank ended');
      expect(voice.said.where((c) => c == 'time' || c.startsWith('rest')), isEmpty, reason: 'No stale cues on wake');
    });

    test('without on-time alerts, only the end cues are set when locked', () async {
      alerts.exact = false;
      await manual();
      await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      await guide.finishSet();
      await guide.lifecycleChanged(AppLifecycleState.hidden);
      expect(alerts.cues.map((c) => c.clip), ['rest_over']);
    });

    test('a plan time is a target; only the measured time is saved', () async {
      final plan = ProgramPlan(
        days: [
          PlanDay(
            name: 'Core',
            focus: '',
            items: [
              PlanItem(kind: ItemKind.main, exerciseId: 'plank', name: 'Plank', sets: 1, seconds: 45, restSec: 60),
            ],
          ),
        ],
      );
      final id = await ProgramRepository(db, clock.call).create(plan, name: 'Core');
      final repo = WorkoutRepository(db, clock.call);
      final sessionId = await repo.startProgramDay(programId: id, dayIndex: 0);
      var set = (await repo.loadSession(sessionId))!.exercises.single.sets.single;
      expect(set.targetSec, 45);
      expect(set.durationSec, isNull, reason: 'Nothing is measured yet');

      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      expect(c.read(guideProvider).targetSec, 45);
      await ticks(45);
      set = (await repo.loadSession(sessionId))!.exercises.single.sets.single;
      expect(set.completed, isTrue);
      expect(set.durationSec, 45);
    });

    test('a tap just after the main button changes is ignored', () async {
      final sessionId = await startDay();
      final guide = c.read(guideProvider.notifier);
      final repo = WorkoutRepository(db, clock.call);
      await guide.startSet();
      await ticks(24);
      expect(c.read(guideProvider).phase, GuidePhase.rest);
      // The rest ends and the next set starts on its own. A tap meant for
      // "Skip rest" lands on "Set done" at 0:00.
      await ticks(60);
      expect(c.read(guideProvider).phase, GuidePhase.set);
      expect(await guide.tapSetDone(), isFalse);
      var sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.last.completed, isFalse, reason: 'The new set is not ticked by a late tap');

      clock.advance(const Duration(seconds: 2));
      expect(await guide.tapSetDone(), isTrue);
      sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.last.completed, isTrue);
    });

    test('a tap just after the rest starts does not skip it', () async {
      await manual();
      await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      clock.advance(const Duration(seconds: 20));
      expect(await guide.tapSetDone(), isTrue);
      expect(c.read(guideProvider).phase, GuidePhase.rest);
      expect(await guide.tapSkipRest(), isFalse, reason: 'A double tap on Set done');
      expect(c.read(guideProvider).phase, GuidePhase.rest);
      clock.advance(const Duration(seconds: 2));
      expect(await guide.tapSkipRest(), isTrue);
      expect(c.read(guideProvider).phase, GuidePhase.set);
    });

    test('the v6 upgrade moves plan targets out of the measured time', () async {
      final sessionId = await startDay();
      final repo = WorkoutRepository(db, clock.call);
      final sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      // As a v5 app saved them: a plan target in duration_sec.
      await repo.updateSet(sets[0].id, const SetEntriesCompanion(durationSec: Value(45), reps: Value(null)));
      await repo.updateSet(sets[1].id, const SetEntriesCompanion(durationSec: Value(50), reps: Value(null)));
      await repo.setCompleted(sets[1].id, true);
      await db.moveTargetTimes();
      final after = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect((after[0].targetSec, after[0].durationSec), (45, null), reason: 'An open set held a target');
      expect((after[1].targetSec, after[1].durationSec), (null, 50), reason: 'A done set keeps its time');
    });
  });
}
