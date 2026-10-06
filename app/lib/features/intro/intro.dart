import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brand.dart';
import '../../core/motion.dart';
import '../../data/providers.dart';

/// Animated logo shown over the app when it starts (owner request, D-022).
///
/// - First start after install: the full 2.2 s sequence.
/// - Later starts: a 1 s version.
/// - Reduced motion: the still logo for a moment, then a fade.
/// - A tap anywhere skips it. It never blocks data entry.
class IntroGate extends ConsumerStatefulWidget {
  const IntroGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends ConsumerState<IntroGate> with SingleTickerProviderStateMixin {
  AnimationController? _c;
  bool _done = false;
  bool _full = true;

  @override
  void initState() {
    super.initState();
    _start();
  }

  /// Waits for settings (at most a moment) so the first start gets the full
  /// sequence. The splash colour stays on screen meanwhile, so nothing flashes.
  Future<void> _start() async {
    bool seen;
    try {
      seen = (await ref.read(settingsRepoProvider).watch().first.timeout(const Duration(milliseconds: 800))).introSeen;
    } catch (_) {
      seen = true;
    }
    if (!mounted || _done) return;
    final reduced = reduceMotion(context);
    _full = !seen;
    final ms = reduced ? 700 : (_full ? 2200 : 1000);
    setState(() {
      _c =
          AnimationController(
              vsync: this,
              duration: Duration(milliseconds: ms),
            )
            ..addStatusListener((s) {
              if (s == AnimationStatus.completed) _finish();
            })
            ..forward();
    });
  }

  void _finish() {
    if (_done) return;
    if (_full) ref.read(settingsRepoProvider).setIntroSeen();
    setState(() => _done = true);
    _c?.dispose();
    _c = null;
  }

  @override
  void dispose() {
    _c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return widget.child;
    if (_c == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          const ColoredBox(color: BrandColors.ink),
        ],
      );
    }
    final reduced = reduceMotion(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _finish,
          child: Semantics(
            label: 'Reparc. Tap to skip.',
            button: true,
            child: AnimatedBuilder(
              animation: _c!,
              builder: (context, _) => reduced ? _still(_c!.value) : _IntroFrame(t: _c!.value, full: _full),
            ),
          ),
        ),
      ],
    );
  }

  Widget _still(double t) => Opacity(
    opacity: t < 0.7 ? 1 : 1 - (t - 0.7) / 0.3,
    child: const ColoredBox(
      color: BrandColors.ink,
      child: Center(child: _Wordmark(letters: 1, tagline: 1, logo: true)),
    ),
  );
}

/// Interval helper: maps [t] to 0..1 inside [a, b] with [curve].
double _iv(double t, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

class _IntroFrame extends StatelessWidget {
  const _IntroFrame({required this.t, required this.full});
  final double t;
  final bool full;

  @override
  Widget build(BuildContext context) {
    // The short version runs the mark faster and skips the wordmark.
    final k = full ? 1.0 : 1.6;
    double at(double v) => (v * k).clamp(0.0, 1.0);
    final arc = _iv(at(t), 0.0, 0.30, Curves.easeOutCubic);
    final inner = _iv(at(t), 0.12, 0.42, Curves.easeOutCubic);
    final needle = _iv(at(t), 0.24, 0.55, Curves.elasticOut);
    final hub = _iv(at(t), 0.26, 0.50, Curves.elasticOut);
    final burst = _iv(at(t), 0.42, 0.80);
    final glow = math.sin(_iv(at(t), 0.25, 0.75) * math.pi);
    final letters = full ? _iv(t, 0.45, 0.70) : 0.0;
    final tagline = full ? _iv(t, 0.62, 0.78, Curves.easeOut) : 0.0;
    final exitStart = full ? 0.82 : 0.70;
    final exit = _iv(t, exitStart, 1.0, Curves.easeIn);
    final size = math.min(MediaQuery.sizeOf(context).shortestSide * 0.46, 240.0);

    return Opacity(
      opacity: 1 - exit,
      child: ColoredBox(
        color: BrandColors.ink,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Ripples and particle burst behind the mark.
            Positioned.fill(
              child: CustomPaint(
                painter: _Ripples(t: at(t), burst: burst, size: size, lift: full ? 48 : 0),
              ),
            ),
            Transform.scale(
              scale: 1 + 0.08 * exit,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox.square(
                    dimension: size,
                    child: CustomPaint(
                      painter: ReparcMark(arc: arc, inner: inner, needle: needle, hub: hub, glow: glow),
                    ),
                  ),
                  if (full) _Wordmark(letters: letters, tagline: tagline),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.letters, required this.tagline, this.logo = false});
  final double letters;
  final double tagline;
  final bool logo;

  static const word = 'REPARC';

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.headlineMedium?.copyWith(
      color: BrandColors.white,
      fontWeight: FontWeight.w800,
      letterSpacing: 6,
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (logo) const ReparcLogo(size: 160),
        const SizedBox(height: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < word.length; i++)
              Builder(
                builder: (_) {
                  // Each letter rises in turn.
                  final v = Curves.easeOutBack.transform(
                    ((letters * (word.length + 2) - i) / 3).clamp(0.0, 1.0),
                  );
                  return Opacity(
                    opacity: v.clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, 18 * (1 - v)),
                      child: Text(word[i], style: base),
                    ),
                  );
                },
              ),
          ],
        ),
        const SizedBox(height: 10),
        // Lime underline sweeps under the word.
        Container(
          width: 150 * tagline,
          height: 3,
          decoration: BoxDecoration(color: BrandColors.lime, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 12),
        Opacity(
          opacity: tagline,
          child: Text(
            'Train. Eat. Own your data.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: BrandColors.white.withValues(alpha: 0.7)),
          ),
        ),
      ],
    );
  }
}

/// Expanding rings and a burst of "rep" particles when the needle lands.
class _Ripples extends CustomPainter {
  _Ripples({required this.t, required this.burst, required this.size, required this.lift});
  final double t;
  final double burst;
  final double size;

  /// How far the wordmark lifts the mark above the screen centre.
  final double lift;

  static final _angles = List.generate(28, (i) => (i * 137.508) * math.pi / 180);

  @override
  void paint(Canvas canvas, Size canvasSize) {
    // The hub sits 6% below the centre of the mark's box.
    final c = canvasSize.center(Offset(0, size * 0.06 - lift));
    for (var i = 0; i < 3; i++) {
      final v = _iv(t, 0.06 + i * 0.07, 0.62 + i * 0.07, Curves.easeOutCubic);
      if (v <= 0 || v >= 1) continue;
      canvas.drawCircle(
        c,
        size * (0.2 + 1.3 * v),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 6 * (1 - v)
          ..color = (i.isEven ? BrandColors.teal : BrandColors.lime).withValues(alpha: 0.28 * (1 - v)),
      );
    }
    if (burst > 0 && burst < 1) {
      final e = Curves.easeOutCubic.transform(burst);
      for (final (i, a) in _angles.indexed) {
        final dist = size * (0.35 + (0.55 + (i % 5) * 0.12) * e);
        final p = c + Offset(math.cos(a), math.sin(a)) * dist;
        canvas.drawCircle(
          p,
          (2.5 + (i % 3)) * (1 - burst * 0.6),
          Paint()..color = (i % 3 == 0 ? BrandColors.teal : BrandColors.lime).withValues(alpha: 1 - burst),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_Ripples old) => old.t != t || old.burst != burst || old.size != size || old.lift != lift;
}
