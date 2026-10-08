import 'dart:io';

import 'package:drift/drift.dart' show Value;
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
import 'package:reparc/features/workout/rest_alert.dart';
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

class FakeAlerts implements RestAlerts {
  DateTime? at;
  String? body;
  var asked = 0;
  @override
  Future<bool> askPermission() async {
    asked++;
    return true;
  }

  @override
  Future<void> schedule(DateTime at, {required String title, required String body}) async {
    this.at = at;
    this.body = body;
  }

  @override
  Future<void> cancel() async => at = null;
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
      expect(setCues(0, 15, 40), isEmpty);
      expect(setCues(19, 20, 40), [Clips.halfway]);
      expect(setCues(39, 41, 40), [Clips.time]);
      expect(setCues(41, 42, 40), isEmpty);
      expect(setCues(0, 600, 0), isEmpty, reason: 'A set with no set time says nothing');
      expect(restCues(49, 50, 60, countdown: true), [Clips.tenLeft]);
      expect(restCues(56, 57, 60, countdown: true), [Clips.three]);
      expect(restCues(57, 58, 60, countdown: true), [Clips.two]);
      expect(restCues(58, 59, 60, countdown: true), [Clips.one]);
      expect(restCues(56, 59, 60, countdown: true), [Clips.one], reason: 'A late tick says only the latest word');
      expect(restCues(59, 60, 60, countdown: true), isEmpty, reason: 'The set cue follows');
      expect(restCues(56, 59, 60, countdown: false), isEmpty);
      expect(restCues(59, 60, 60, countdown: false), [Clips.restOver]);
      expect(restCues(60, 61, 60, countdown: false), isEmpty);
      expect(restCues(10, 11, 15, countdown: true), isEmpty, reason: 'No ten-second cue in a short rest');
      expect(Clips.rest(90), 'rest_90');
      expect(Clips.rest(75), 'rest');
      expect(Clips.set(11), Clips.go);
      expect(Clips.nextUp('bench-press'), 'names/bench_press');
      expect(Clips.nextUp('lib:Barbell_Shrug'), 'names/lib_barbell_shrug');
      expect(Clips.nextUp('user:abc'), isNull, reason: 'Own exercises have no clip');
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
          restAlertsProvider.overrideWithValue(alerts),
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

    Future<void> after(int seconds) async {
      clock.advance(Duration(seconds: seconds));
      await c.read(guideProvider.notifier).tick();
    }

    Future<void> ticks(int seconds) async {
      for (var i = 0; i < seconds; i++) {
        await after(1);
      }
    }

    test('by default the user starts and ends each set; the guide times it and speaks', () async {
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
      expect(voice.said.sublist(2), ['ten_left', 'rest_over'], reason: 'No countdown when the user starts the set');
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

    test('with both switches on, sets end on time and start after a countdown', () async {
      await setting('guide.finishReps', 'true');
      await setting('guide.autoStart', 'true');
      final sessionId = await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      expect(c.read(guideProvider).targetSec, 24, reason: '8 reps × 3 s');

      await ticks(24);
      expect(voice.said, ['set_1', 'time', 'rest_60']);
      final repo = WorkoutRepository(db, clock.call);
      final sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.first.completed, isTrue);
      expect(sets.first.durationSec, isNull, reason: 'A guessed set time is not a measured value');

      await ticks(60);
      expect(voice.said.sublist(3), ['ten_left', 'three', 'two', 'one', 'last_set']);
      expect(c.read(guideProvider).phase, GuidePhase.set);
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
      await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      await after(30);
      expect(voice.said, isEmpty);
      expect(c.read(guideProvider).phase, GuidePhase.set, reason: 'The set waits for Set done');
    });

    test('a rest alert follows the rest and is asked for once', () async {
      final sessionId = await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      await after(30);
      await guide.finishSet();
      expect(alerts.asked, 1);
      await after(1);
      final start = clock().toUtc().subtract(const Duration(seconds: 1));
      expect(alerts.at, start.add(const Duration(seconds: 60)));
      expect(alerts.body, 'Next: Bench press · set 2 of 2');

      await guide.addRest(15);
      await after(1);
      expect(alerts.at, start.add(const Duration(seconds: 75)), reason: '+15 s moves the alert');

      await guide.setPaused(sessionId, true);
      await after(1);
      expect(alerts.at, isNull, reason: 'No alert while paused');
      await guide.setPaused(sessionId, false);
      await after(1);
      expect(alerts.at, isNotNull);

      await guide.startSet();
      await after(1);
      expect(alerts.at, isNull, reason: 'A new set ends the rest and its alert');
      await guide.finishSet();
      expect(alerts.asked, 1, reason: 'The permission is asked for only once');
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
