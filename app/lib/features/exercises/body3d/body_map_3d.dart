import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../core/motion.dart';
import '../../../core/palette.dart';
import '../../../core/tokens.dart';
import '../area_style.dart';
import '../library/library.dart';
import '../muscle_map.dart';
import '../rig/anatomy.dart';
import 'body_model.dart';
import 'body_render.dart';

/// The first step of the exercise tree, as a 3D body: turn it with a
/// sideways drag, tap a muscle to select it, then open its exercises.
///
/// Only sideways drags turn the body, so the page still scrolls with an
/// up or down swipe. The body-part cards on Exercises offer the same
/// choices for screen readers and switch access.
class BodyMap3D extends ConsumerStatefulWidget {
  const BodyMap3D({super.key, this.height = 440});

  final double height;

  @override
  ConsumerState<BodyMap3D> createState() => _BodyMap3DState();
}

class _BodyMap3DState extends ConsumerState<BodyMap3D> with SingleTickerProviderStateMixin {
  /// Degrees. 0 shows the front, 180 the back. A small turn at the start
  /// shows that the body is 3D.
  double _yaw = -18;
  static const _pitch = 5.0;
  Muscle? _selected;
  final _frame = _FrameHolder();
  late final AnimationController _turn = AnimationController.unbounded(vsync: this)
    ..addListener(() => setState(() => _yaw = _turn.value));

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  void _drag(DragUpdateDetails d) {
    _turn.stop();
    setState(() => _yaw -= d.delta.dx * 0.55);
  }

  void _dragEnd(DragEndDetails d) {
    if (reduceMotion(context)) return;
    final v = -d.velocity.pixelsPerSecond.dx * 0.55;
    if (v.abs() < 40) return;
    _turn.value = _yaw;
    _turn.animateWith(FrictionSimulation(0.08, _yaw, v));
  }

  /// Turns to [target] degrees the short way round.
  void _snap(double target) {
    var delta = (target - _yaw) % 360;
    if (delta > 180) delta -= 360;
    final to = _yaw + delta;
    if (reduceMotion(context)) {
      _turn.stop();
      setState(() => _yaw = to);
      return;
    }
    _turn.value = _yaw;
    _turn.animateTo(to, duration: Motion.expanded, curve: Curves.easeOutCubic);
  }

  void _tap(TapUpDetails d) {
    final m = _frame.value?.hit(d.localPosition - _frame.offset);
    if (m == _selected) {
      if (m != null) _open(m);
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _selected = m);
  }

  void _open(Muscle m) => context.push('/workout/muscle/${m.name}');

  /// The view the current turn is closest to.
  String get _facing {
    final y = ((_yaw % 360) + 360) % 360;
    if (y < 45 || y >= 315) return 'Front';
    if (y >= 135 && y < 225) return 'Back';
    return 'Side';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final lib = ref.watch(libraryProvider).value;
    final mesh = ref.watch(bodyMeshProvider).value;
    final sel = _selected;
    final count = sel == null || lib == null
        ? null
        : lib.moves.where((m) => m.target == sel && m.kind == MoveKind.strength).length;
    final colors = _colors(p, sel);
    return Container(
      height: widget.height,
      decoration: BoxDecoration(color: p.panel, borderRadius: Radii.large),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            child: Semantics(
              label:
                  'Body map, 3D. Facing $_facing. Drag sideways to turn it. Tap a muscle to see its exercises. '
                  'The body part cards on Exercises have the same choices.',
              child: GestureDetector(
                onHorizontalDragUpdate: _drag,
                onHorizontalDragEnd: _dragEnd,
                onTapUp: _tap,
                child: CustomPaint(
                  isComplex: true,
                  willChange: _turn.isAnimating,
                  painter: _BodyPainter(
                    mesh: mesh,
                    yaw: _yaw,
                    pitch: _pitch,
                    colors: BodyPaint(skin: _skin, muscle: colors, rim: p.brand),
                    selected: sel,
                    frame: _frame,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: Space.s,
            right: Space.s,
            child: _Views(
              facing: _facing,
              onFront: () => _snap(0),
              onSide: () => _snap(90),
              onBack: () => _snap(180),
            ),
          ),
          Positioned(
            left: Space.s,
            right: Space.s,
            bottom: Space.s,
            child: AnimatedSwitcher(
              duration: motionOf(context, Motion.standard),
              child: sel == null
                  ? _Hint(key: const ValueKey('hint'), text: 'Drag to turn · Tap a muscle', t: t, p: p)
                  : _Selection(
                      key: ValueKey(sel),
                      muscle: sel,
                      count: count,
                      color: areaColors(p, sel.area).$1,
                      onOpen: () => _open(sel),
                      onClear: () => setState(() => _selected = null),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  static const _skin = Color(0xFF58636B);

  /// Each muscle in a soft tint of its body area's colour. The selected
  /// muscle is bright; the rest of the body steps back.
  Map<Muscle, Color> _colors(Palette p, Muscle? sel) => {
    for (final m in mapMuscles)
      m: () {
        final c = areaColors(p, m.area).$1;
        if (sel == null) return Color.lerp(_skin, c, 0.62)!;
        if (m == sel) return Color.lerp(c, Colors.white, 0.12)!;
        return Color.lerp(_skin, c, m.area == sel.area ? 0.42 : 0.22)!;
      }(),
  };
}

/// How much larger than "fit the whole height" the map draws the body.
const bodyMapZoom = 1.08;

/// Space kept free above and below the body, in the map's own box.
const bodyMapInsets = EdgeInsets.only(top: 48, bottom: 60);

/// Holds the last drawn frame, for taps. Painting fills it.
class _FrameHolder {
  BodyFrame? value;

  /// Where the body's box starts inside the map.
  Offset offset = Offset.zero;
}

class _BodyPainter extends CustomPainter {
  _BodyPainter({
    required this.mesh,
    required this.yaw,
    required this.pitch,
    required this.colors,
    required this.selected,
    required this.frame,
  });

  /// Null while the mesh loads; then only the backdrop is drawn.
  final BodyMesh? mesh;
  final double yaw;
  final double pitch;
  final BodyPaint colors;
  final Muscle? selected;
  final _FrameHolder frame;

  @override
  void paint(Canvas canvas, Size size) {
    // A soft spotlight behind the figure.
    canvas.drawCircle(
      Offset(size.width / 2, size.height * 0.42),
      size.height * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [const Color(0x14FFFFFF), const Color(0x00FFFFFF)],
        ).createShader(Rect.fromCircle(center: Offset(size.width / 2, size.height * 0.42), radius: size.height * 0.5)),
    );
    // Room at the top for the view buttons and at the bottom for the
    // selection card.
    final mesh = this.mesh;
    if (mesh == null) {
      frame.value = null;
      return;
    }
    final body = Size(size.width, size.height - bodyMapInsets.vertical);
    frame.offset = bodyMapInsets.topLeft;
    canvas.save();
    canvas.translate(0, bodyMapInsets.top);
    frame.value = paintBody(canvas, body, mesh, yaw: yaw, pitch: pitch, paint: colors, zoom: bodyMapZoom);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BodyPainter o) =>
      o.mesh != mesh || o.yaw != yaw || o.pitch != pitch || o.selected != selected || o.colors.rim != colors.rim;
}

class _Views extends StatelessWidget {
  const _Views({required this.facing, required this.onFront, required this.onSide, required this.onBack});
  final String facing;
  final VoidCallback onFront;
  final VoidCallback onSide;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    Widget b(String label, VoidCallback onTap) {
      final on = facing == label;
      return Semantics(
        button: true,
        selected: on,
        label: 'Show ${label.toLowerCase()}',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 52),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: Space.m),
            decoration: BoxDecoration(
              color: on ? p.onPanel : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(label, style: t.labelMedium?.copyWith(color: on ? p.panel : p.onPanelSoft)),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: p.panelRaised, borderRadius: BorderRadius.circular(999)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [b('Front', onFront), b('Side', onSide), b('Back', onBack)]),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint({super.key, required this.text, required this.t, required this.p});
  final String text;
  final TextTheme t;
  final Palette p;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: Space.s),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.rotate3D, size: 16, color: p.onPanelSoft),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                text,
                style: t.bodySmall?.copyWith(color: p.onPanelSoft),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Selection extends StatelessWidget {
  const _Selection({
    super.key,
    required this.muscle,
    required this.count,
    required this.color,
    required this.onOpen,
    required this.onClear,
  });

  final Muscle muscle;
  final int? count;
  final Color color;
  final VoidCallback onOpen;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(Space.m, Space.s, Space.s, Space.s),
      decoration: BoxDecoration(color: p.panelRaised, borderRadius: Radii.medium),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: Space.s),
          Expanded(
            child: Semantics(
              liveRegion: true,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(muscle.label, style: t.titleSmall?.copyWith(color: p.onPanel)),
                  Text(
                    muscle.hint,
                    style: t.bodySmall?.copyWith(color: p.onPanelSoft),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: Space.s),
          FilledButton.icon(
            onPressed: onOpen,
            style: FilledButton.styleFrom(
              backgroundColor: p.energy,
              foregroundColor: p.onEnergy,
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: Space.m),
            ),
            icon: const Icon(LucideIcons.arrowRight, size: 18),
            label: Text(count == null ? 'Exercises' : '$count exercises'),
          ),
          IconButton(
            tooltip: 'Clear selection',
            onPressed: onClear,
            icon: Icon(LucideIcons.x, size: 18, color: p.onPanelSoft),
          ),
        ],
      ),
    );
  }
}
