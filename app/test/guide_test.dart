import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reparc/core/clock.dart';
import 'package:reparc/data/database.dart';
import 'package:reparc/data/program_repository.dart';
import 'package:reparc/data/providers.dart';
import 'package:reparc/data/workout_repository.dart';
import 'package:reparc/domain/guide.dart';
import 'package:reparc/domain/roadmap.dart';
import 'package:reparc/features/workout/guide_controller.dart';
import 'package:reparc/features/workout/voice.dart';

import 'helpers.dart';

class FakeVoice implements VoicePlayer {
  final said = <String>[];
  @override
  void say(String voice, String clip) {
    if (voice != 'off') said.add(clip);
  }

  @override
  void dispose() {}
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
      expect(restCues(49, 50, 60), [Clips.tenLeft]);
      expect(restCues(56, 57, 60), [Clips.countdown]);
      expect(restCues(10, 11, 15), isEmpty, reason: 'No ten-second cue in a short rest');
      expect(Clips.rest(90), 'rest_90');
      expect(Clips.rest(75), 'rest');
      expect(Clips.set(11), Clips.go);
    });

    test('every clip exists for every voice', () {
      for (final v in ['charlie', 'matilda']) {
        for (final c in Clips.all) {
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

    setUp(() async {
      db = memoryDb();
      clock = FakeClock(DateTime.utc(2026, 3, 2, 18));
      voice = FakeVoice();
      c = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          clockProvider.overrideWithValue(clock.call),
          voicePlayerProvider.overrideWithValue(voice),
        ],
      );
      c.listen(currentSettingsProvider, (_, _) {});
    });
    tearDown(() async {
      c.dispose();
      await db.close();
    });

    Future<String> startDay() async {
      final plan = ProgramPlan(
        days: [
          PlanDay(
            name: 'Push',
            focus: '',
            items: [
              PlanItem(
                kind: ItemKind.main,
                exerciseId: 'bench-press',
                name: 'Bench press',
                sets: 2,
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

    Future<void> after(int seconds) async {
      clock.advance(Duration(seconds: seconds));
      await c.read(guideProvider.notifier).tick();
    }

    test('runs set, rest, and the next set on its own, and saves measured times', () async {
      final sessionId = await startDay();
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      expect(c.read(guideProvider).phase, GuidePhase.set);
      expect(c.read(guideProvider).targetSec, 24, reason: '8 reps × 3 s');
      expect(c.read(guideProvider).label, 'Bench press · set 1 of 2');
      expect(voice.said, ['set_1']);

      await after(10);
      await after(14);
      // Time is up: the set is done and the plan's 60 s rest starts.
      expect(voice.said, ['set_1', 'time', 'rest_60']);
      final repo = WorkoutRepository(db, clock.call);
      var sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.first.completed, isTrue);
      expect(sets.first.durationSec, 24, reason: 'The measured set time is saved');
      expect(sets.first.reps, isNull, reason: 'The guide never invents reps');
      expect((await repo.loadSession(sessionId))!.session.restTargetSec, 60);

      await after(50);
      await after(7);
      await after(3);
      expect(voice.said.sublist(3), ['ten_left', 'countdown', 'last_set']);
      expect(c.read(guideProvider).phase, GuidePhase.set);
      sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.first.restSec, 60, reason: 'The rest really taken is saved on the set before');

      // The user finishes early.
      clock.advance(const Duration(seconds: 15));
      await guide.finishSet();
      expect(voice.said.last, 'done');
      sets = (await repo.loadSession(sessionId))!.exercises.single.sets;
      expect(sets.last.durationSec, 15);
      expect(sets.every((s) => s.completed), isTrue);
      expect(c.read(guideProvider).phase, GuidePhase.idle);
    });

    test('voice off and guide off are respected', () async {
      await db.into(db.settings).insert(SettingsCompanion.insert(key: 'guide.voice', value: 'off'));
      await db.into(db.settings).insert(SettingsCompanion.insert(key: 'guide.autoFinish', value: 'false'));
      await startDay();
      await Future<void>.delayed(Duration.zero);
      final guide = c.read(guideProvider.notifier);
      await guide.startSet();
      await after(30);
      expect(voice.said, isEmpty);
      expect(c.read(guideProvider).phase, GuidePhase.set, reason: 'Without auto-finish the set waits for Done');
    });
  });
}
