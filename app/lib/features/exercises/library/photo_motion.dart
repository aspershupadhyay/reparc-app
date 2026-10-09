import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion.dart';
import '../../../core/palette.dart';
import '../../../core/tokens.dart';
import '../../../core/widgets.dart';

/// One phase of a demo rep.
class _Phase {
  const _Phase(this.label, this.hint, this.seconds, this.from, this.to);
  final String label;
  final String hint;
  final double seconds;

  /// Blend between the start (0) and end (1) photo.
  final double from;
  final double to;
}

/// A rep at a teaching pace: pause, move up in 1.5 s, pause, lower in
/// 2.5 s. Slow enough to follow; the slow lowering matches common coaching.
const _rep = [
  _Phase('Start position', 'Set up, brace', 1.2, 0, 0),
  _Phase('Move', 'Smooth, breathe out', 1.5, 0, 1),
  _Phase('End position', 'Pause, squeeze', 1.0, 1, 1),
  _Phase('Return', 'Slowly, 2–3 s, breathe in', 2.5, 1, 0),
];

final double _repSeconds = _rep.fold(0.0, (a, p) => a + p.seconds);

/// Start and end photos of a movement, played as a slow, steady rep.
///
/// The photos blend through the movement at a teaching tempo, with a label
/// for each phase. The user can pause, play at half speed, or drag the
/// slider to move between the two positions by hand. With reduced motion
/// it does not play; the slider and Start/End buttons still work.
class PhotoMotion extends StatefulWidget {
  const PhotoMotion({super.key, required this.photos, required this.name, this.height = 280});
  final (String, String) photos;
  final String name;
  final double height;

  @override
  State<PhotoMotion> createState() => _PhotoMotionState();
}

class _PhotoMotionState extends State<PhotoMotion> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _duration(1));
  double _speed = 1;
  double? _manual;
  bool _started = false;

  static Duration _duration(double speed) => Duration(milliseconds: (_repSeconds * 1000 / speed).round());

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!reduceMotion(context)) _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  /// Phase and blend for a point in the rep (0–1).
  (_Phase, double) _at(double v) {
    var t = v * _repSeconds;
    for (final p in _rep) {
      if (t <= p.seconds) {
        final f = p.seconds == 0 ? 1.0 : t / p.seconds;
        return (p, p.from + (p.to - p.from) * Curves.easeInOut.transform(f));
      }
      t -= p.seconds;
    }
    return (_rep.last, 0);
  }

  void _toggle() {
    setState(() {
      if (_c.isAnimating) {
        _c.stop();
      } else {
        _manual = null;
        _c.repeat();
      }
    });
  }

  void _setSpeed(double s) {
    setState(() => _speed = s);
    final running = _c.isAnimating;
    _c.duration = _duration(s);
    if (running) _c.repeat();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final reduced = reduceMotion(context);
    Widget photo(String path) => Image.asset(
      path,
      fit: BoxFit.cover,
      width: double.infinity,
      height: widget.height,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => Container(color: p.surfaceAlt),
    );
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final playing = _c.isAnimating;
        final (phase, auto) = _at(_c.value);
        final blend = _manual ?? (reduced && !playing ? 0.0 : auto);
        final label = _manual != null || (!playing && reduced)
            ? (blend < 0.5 ? 'Start position' : 'End position')
            : phase.label;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              image: true,
              label: '${widget.name}. $label photo',
              child: ClipRRect(
                borderRadius: Radii.large,
                child: GestureDetector(
                  onTap: reduced ? null : _toggle,
                  child: Stack(
                    children: [
                      photo(widget.photos.$1),
                      Opacity(opacity: blend.clamp(0.0, 1.0), child: photo(widget.photos.$2)),
                      Positioned(
                        left: Space.m,
                        right: Space.m,
                        bottom: Space.m,
                        child: Row(
                          children: [
                            Flexible(child: _Badge(label, sub: _manual == null && playing ? phase.hint : null)),
                            const Spacer(),
                            if (!reduced)
                              _Badge(playing ? 'Pause' : 'Play', icon: playing ? LucideIcons.pause : LucideIcons.play),
                          ],
                        ),
                      ),
                      // Rep progress, so the user sees where the rep is.
                      if (playing)
                        Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          child: LinearProgressIndicator(
                            value: _c.value,
                            minHeight: 3,
                            // White on the photo: lime is kept for the one
                            // main action on the page.
                            color: Colors.white70,
                            backgroundColor: Colors.black26,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: Space.s),
            Row(
              children: [
                Text('Start', style: t.labelSmall),
                Expanded(
                  child: Slider(
                    activeColor: p.brand,
                    inactiveColor: p.line,
                    value: blend.clamp(0.0, 1.0),
                    semanticFormatterCallback: (v) => v < 0.5 ? 'Near start position' : 'Near end position',
                    onChangeStart: (_) => _c.stop(),
                    onChanged: (v) => setState(() => _manual = v),
                  ),
                ),
                Text('End', style: t.labelSmall),
              ],
            ),
            if (!reduced)
              // A small, quiet control: playback speed is secondary to the
              // exercise name below it.
              Center(
                child: SizedBox(
                  width: 240,
                  child: PillTabs<double>(
                    compact: true,
                    values: const [0.5, 1.0],
                    selected: _speed,
                    label: (s) => s == 1 ? 'Normal speed' : 'Half speed',
                    onChanged: _setSpeed,
                  ),
                ),
              )
            else
              Text('Drag the slider to see the movement.', style: t.bodySmall, textAlign: TextAlign.center),
          ],
        );
      },
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.icon, this.sub});
  final String text;
  final String? sub;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4)],
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text,
                    style: t.labelSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                  if (sub != null)
                    Text(
                      sub!,
                      style: t.labelSmall?.copyWith(color: Colors.white70, fontSize: 11),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small still photo for lists and cards. Decodes at a small size to keep
/// long lists fast.
class PhotoThumb extends StatelessWidget {
  const PhotoThumb(this.path, {super.key, this.width, this.height = 120});
  final String path;
  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return ExcludeSemantics(
      child: Image.asset(
        path,
        width: width ?? double.infinity,
        height: height,
        fit: BoxFit.cover,
        cacheHeight: (height * dpr).round(),
        errorBuilder: (_, _, _) => Container(color: context.pal.surfaceAlt, width: width, height: height),
      ),
    );
  }
}
