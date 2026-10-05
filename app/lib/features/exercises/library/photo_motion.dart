import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion.dart';
import '../../../core/palette.dart';
import '../../../core/tokens.dart';

/// Start and end photos of a movement, shown as a slow loop.
///
/// The photos cross-fade so the change between positions is easy to see.
/// With reduced motion it does not loop; the user switches between the
/// start and end photo instead. Tap to pause or play.
class PhotoMotion extends StatefulWidget {
  const PhotoMotion({super.key, required this.photos, required this.name, this.height = 280});
  final (String, String) photos;
  final String name;
  final double height;

  @override
  State<PhotoMotion> createState() => _PhotoMotionState();
}

class _PhotoMotionState extends State<PhotoMotion> {
  static const _hold = Duration(milliseconds: 1100);
  static const _fade = Duration(milliseconds: 450);

  Timer? _timer;
  bool _end = false;
  bool _playing = false;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      if (!reduceMotion(context)) _play();
    }
  }

  void _play() {
    _timer?.cancel();
    _timer = Timer.periodic(_hold + _fade, (_) => setState(() => _end = !_end));
    setState(() => _playing = true);
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final reduced = reduceMotion(context);
    Widget photo(String path) => Image.asset(
      path,
      key: ValueKey(path),
      fit: BoxFit.cover,
      width: double.infinity,
      height: widget.height,
      errorBuilder: (_, _, _) => Container(color: p.surfaceAlt),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          image: true,
          label: '${widget.name}, ${_end ? 'end' : 'start'} position photo',
          child: ClipRRect(
            borderRadius: Radii.large,
            child: GestureDetector(
              onTap: reduced ? () => setState(() => _end = !_end) : (_playing ? _pause : _play),
              child: Stack(
                children: [
                  AnimatedSwitcher(
                    duration: reduced ? Duration.zero : _fade,
                    switchInCurve: Motion.change,
                    switchOutCurve: Motion.change,
                    layoutBuilder: (current, previous) => Stack(children: [...previous, ?current]),
                    child: photo(_end ? widget.photos.$2 : widget.photos.$1),
                  ),
                  Positioned(
                    left: Space.m,
                    bottom: Space.m,
                    child: _Badge(_end ? 'End' : 'Start'),
                  ),
                  if (!reduced)
                    Positioned(
                      right: Space.m,
                      bottom: Space.m,
                      child: _Badge(_playing ? 'Pause' : 'Play', icon: _playing ? LucideIcons.pause : LucideIcons.play),
                    ),
                ],
              ),
            ),
          ),
        ),
        if (reduced) ...[
          const SizedBox(height: Space.s),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Start')),
              ButtonSegment(value: true, label: Text('End')),
            ],
            selected: {_end},
            onSelectionChanged: (s) => setState(() => _end = s.first),
          ),
        ] else ...[
          const SizedBox(height: Space.xs),
          Text('Tap the photo to pause.', style: t.bodySmall, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.text, {this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 14, color: Colors.white), const SizedBox(width: 4)],
            Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white)),
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
