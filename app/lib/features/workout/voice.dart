import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/guide.dart';

/// Plays the bundled voice cues (handbook 4.13). Clips come from
/// `assets/voice/<voice>/`; nothing is fetched from the network.
abstract class VoicePlayer {
  /// Queues [clip] and plays it after any clip that is still playing.
  /// With [now], the clip that plays and the clips that wait are dropped
  /// first, so an old cue never plays after the user acted.
  void say(String voice, String clip, {bool now = false});

  /// Drops the clip that plays and the clips that wait.
  void silence();

  /// Loads the clips of [voice] before the first cue, so it plays on time.
  void preload(String voice);
  void dispose();
}

/// Plays clips one after another and lowers other audio, such as music,
/// while a clip plays instead of stopping it.
class AssetVoicePlayer implements VoicePlayer {
  AssetVoicePlayer();

  final _player = AudioPlayer(playerId: 'reparc-voice');
  final _queue = <String>[];
  bool _playing = false;
  StreamSubscription<void>? _done;

  static final _ctx = AudioContextConfig(
    focus: AudioContextConfigFocus.duckOthers,
    respectSilence: false,
    stayAwake: false,
  ).build();

  String? _loaded;

  @override
  void say(String voice, String clip, {bool now = false}) {
    if (voice == 'off') return;
    if (now) silence();
    _queue.add('voice/$voice/$clip.mp3');
    if (!_playing) unawaited(_next());
  }

  @override
  void silence() {
    _queue.clear();
    if (!_playing) return;
    _playing = false;
    unawaited(_player.stop().catchError((_) {}));
  }

  @override
  void preload(String voice) {
    if (voice == 'off' || voice == _loaded) return;
    _loaded = voice;
    unawaited(
      _player.audioCache.loadAll([for (final c in Clips.all) 'voice/$voice/$c.mp3']).catchError((_) => <Uri>[]),
    );
  }

  Future<void> _next() async {
    if (_queue.isEmpty) {
      _playing = false;
      return;
    }
    _playing = true;
    final path = _queue.removeAt(0);
    _done ??= _player.onPlayerComplete.listen((_) => unawaited(_next()));
    try {
      await _player.play(AssetSource(path), ctx: _ctx);
    } catch (_) {
      // A cue that cannot play must never stop the workout.
      unawaited(_next());
    }
  }

  @override
  void dispose() {
    unawaited(_done?.cancel());
    unawaited(_player.dispose());
  }
}

final voicePlayerProvider = Provider<VoicePlayer>((ref) {
  final p = AssetVoicePlayer();
  ref.onDispose(p.dispose);
  return p;
});
