import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/clock.dart';
import '../../core/format.dart';
import '../../data/providers.dart';
import '../../domain/session_time.dart';

/// Rebuilds once per second while visible. It stops when disposed.
class Ticker1s extends StatefulWidget {
  const Ticker1s({super.key, required this.builder});
  final WidgetBuilder builder;

  @override
  State<Ticker1s> createState() => _Ticker1sState();
}

class _Ticker1sState extends State<Ticker1s> {
  Timer? _t;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context);
}

/// Elapsed session time, calculated from stored timestamps.
class SessionClock extends ConsumerWidget {
  const SessionClock({super.key, required this.sessionId, required this.style});
  final String sessionId;
  final TextStyle style;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(sessionProvider(sessionId)).value?.session;
    if (s == null) return const SizedBox.shrink();
    final clock = ref.watch(clockProvider);
    return Ticker1s(
      builder: (_) {
        final d = sessionElapsed(
          startedAt: s.startedAt,
          endedAt: s.endedAt,
          pausedAt: s.pausedAt,
          pausedMs: s.pausedMs,
          now: clock().toUtc(),
        );
        return Text(fmtClock(d), style: style, semanticsLabel: 'Elapsed ${speakDuration(d)}');
      },
    );
  }
}
