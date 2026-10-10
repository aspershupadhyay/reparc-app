import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/brand.dart';
import '../../core/brand_wordmark.dart';
import '../../core/motion.dart';
import '../../data/providers.dart';

/// Animated logo shown over the app when it starts (D-034).
///
/// The bar loads like a lift: the small and big plates slide on from the
/// left, one bubble flows through the bar like water through a pipe, the
/// big and small plates slide on from the right, and RepArc fades in.
///
/// - First start after install: the full sequence, 2.5 s to the finished
///   logo, then a short hold and a fade (about 3.1 s in all).
/// - Later starts: the same sequence at double speed (about 1.6 s).
/// - Reduced motion: the still logo for a moment, then a fade.
/// - A tap anywhere skips it. It never blocks data entry.
/// - Follows the app's light or dark theme.
class IntroGate extends ConsumerStatefulWidget {
  const IntroGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<IntroGate> createState() => _IntroGateState();
}

/// Seconds of the full sequence, including the hold and the fade out.
const _fullSeconds = 3.1;

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
    final ms = reduced ? 700 : (_fullSeconds * 1000 * (_full ? 1 : 0.5)).round();
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
    final colors = IntroColors.of(context);
    if (_done) return widget.child;
    if (_c == null) {
      return Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          ColoredBox(color: colors.background),
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
            label: 'RepArc. Tap to skip.',
            button: true,
            child: AnimatedBuilder(
              animation: _c!,
              builder: (context, _) {
                final t = _c!.value;
                if (reduced) {
                  return Opacity(
                    opacity: t < 0.7 ? 1 : 1 - (t - 0.7) / 0.3,
                    child: IntroFrame(seconds: 2.5, colors: colors),
                  );
                }
                return IntroFrame(seconds: t * _fullSeconds, colors: colors);
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Intro colours for the current theme.
class IntroColors {
  const IntroColors(this.background, this.mark, this.word);
  final Color background;
  final Color mark;
  final Color word;

  static IntroColors of(BuildContext context) => Theme.of(context).brightness == Brightness.dark
      ? const IntroColors(BrandColors.ink, BrandColors.lime, BrandColors.white)
      : const IntroColors(BrandColors.paper, BrandColors.ink, BrandColors.ink);
}

/// Calm in and out: no snap, no bounce.
const _calm = Cubic(0.45, 0, 0.2, 1);

/// Steady flow through the bar.
const _flow = Cubic(0.4, 0, 0.6, 1);

/// Maps [t] (seconds) to 0..1 inside [a, b] (seconds) with [curve].
double _iv(double t, double a, double b, [Curve curve = Curves.linear]) =>
    curve.transform(((t - a) / (b - a)).clamp(0.0, 1.0));

/// One frame of the intro at [seconds] into the full sequence. Public so the
/// screen renderer and tests can draw any moment.
class IntroFrame extends StatelessWidget {
  const IntroFrame({super.key, required this.seconds, required this.colors});
  final double seconds;
  final IntroColors colors;

  @override
  Widget build(BuildContext context) {
    final t = seconds;
    final metric = MarkGeometry.barPath().computeMetrics().first;
    final from = (MarkGeometry.bubbleFrom - 3) / metric.length;
    final to = (metric.length - (125 - MarkGeometry.bubbleTo)) / metric.length;

    final smallLeft = _iv(t, 0.12, 0.40, _calm);
    final bigLeft = _iv(t, 0.43, 0.71, _calm);
    final form = _iv(t, 0.74, 0.90, Curves.easeOut);
    final flow = _iv(t, 0.90, 1.55, _flow);
    final bigRight = _iv(t, 1.57, 1.85, _calm);
    final smallRight = _iv(t, 1.87, 2.13, _calm);
    final word = _iv(t, 1.98, 2.42, Curves.easeOut);
    final exit = _iv(t, 2.80, 3.10, Curves.easeIn);

    final bubbleAt = from + (to - from) * flow;
    final pipe = form < 1 ? from * form : (bigRight > 0 ? bubbleAt + (1 - bubbleAt) * bigRight : bubbleAt);
    final bubble = form * (1 - bigRight);

    return Opacity(
      opacity: 1 - exit,
      child: ColoredBox(
        color: colors.background,
        child: LayoutBuilder(
          builder: (context, box) {
            // Sizes from the approved Figma layout: the wordmark is 0.71 of the
            // mark box wide, and the gap from the plates to the capitals is
            // about one capital height.
            final m = math.min(box.biggest.shortestSide * 0.52, 230.0);
            final wordW = m * 0.711;
            final wordH = wordW * wordmarkSize.height / wordmarkSize.width;
            final cap = wordW * wordmarkCapHeight / wordmarkSize.width;
            final gap = m * 0.1465;
            final inkTop = m * MarkGeometry.inkTop / 128;
            final inkBottom = m * MarkGeometry.inkBottom / 128;
            // Centre the mark and the capitals together in the middle of the
            // screen. The descender of "p" is left out, so the pair looks
            // centred. (It sat at 46% before, which read as high on tall
            // 20:9 phones.)
            final groupH = (inkBottom - inkTop) + gap + cap;
            final top = box.maxHeight * 0.5 - groupH / 2 - inkTop;
            return Stack(
              children: [
                Positioned(
                  left: (box.maxWidth - m) / 2,
                  top: top,
                  width: m,
                  height: m,
                  child: CustomPaint(
                    painter: ReparcMark(
                      color: colors.mark,
                      smallLeft: smallLeft,
                      bigLeft: bigLeft,
                      pipe: pipe,
                      bubble: bubble,
                      bubbleAt: bubbleAt,
                      bigRight: bigRight,
                      smallRight: smallRight,
                    ),
                  ),
                ),
                Positioned(
                  left: (box.maxWidth - wordW) / 2,
                  top: top + inkBottom + gap + 6 * (1 - word),
                  width: wordW,
                  height: wordH,
                  child: Opacity(
                    opacity: word,
                    child: CustomPaint(painter: WordmarkPainter(color: colors.word)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
