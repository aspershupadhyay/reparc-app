import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Plays the bundled voice cues (handbook 4.13). Clips come from
/// `assets/voice/<voice>/`; nothing is fetched from the network.
abstract class VoicePlayer {
  /// Queues [clip] and plays it after any clip that is still playing.
  void say(String voice, String clip);
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

  @override
  void say(String voice, String clip) {
    if (voice == 'off') return;
    _queue.add('voice/$voice/$clip.mp3');
    if (!_playing) unawaited(_next());
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
