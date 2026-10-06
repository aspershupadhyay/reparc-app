import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/motion.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import 'catalog/model.dart';
import 'rig/math3d.dart';
import 'rig/pose.dart';
import 'rig/render.dart';
import 'rig/skeleton.dart';

RigStyle rigStyle(Palette p) => RigStyle(
  body: const Color(0xFF8FA3A8),
  primary: p.energy,
  secondary: p.orange,
  steel: const Color(0xFFB8C4C7),
  plate: const Color(0xFF2B373B),
  pad: const Color(0xFF1E5B66),
  floor: p.panelRaised,
  floorLine: const Color(0xFF2A3A3F),
  label: p.energy,
  labelText: p.onEnergy,
);

const _labelStyle = TextStyle(fontFamily: 'Inter', fontSize: 11, fontWeight: FontWeight.w800);

/// Position in an exercise loop: the pose and the current phase name.
class LoopFrame {
  const LoopFrame(this.pose, this.label);
  final Pose pose;
  final String label;
}

double _ease(double t) => t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) * (-2 * t + 2) / 2;

/// Total loop length in seconds.
double loopSeconds(List<KeyPose> keys) => keys.fold(0.0, (a, k) => a + k.move + k.hold);

/// Pose at [seconds] into the loop. Each key moves in from the previous
/// key (the last key leads back to the first), then holds.
LoopFrame frameAt(List<KeyPose> keys, double seconds) {
  final total = loopSeconds(keys);
  var t = seconds % total;
  for (var i = 0; i < keys.length; i++) {
    final k = keys[i];
    final prev = keys[(i - 1 + keys.length) % keys.length];
    if (t < k.move) return LoopFrame(Pose.lerp(prev.pose, k.pose, _ease(t / k.move)), k.label);
    t -= k.move;
    if (t < k.hold) return LoopFrame(k.pose, k.label);
    t -= k.hold;
  }
  return LoopFrame(keys.first.pose, keys.first.label);
}

/// Camera space for the whole loop, so size stays fixed while it moves.
Fit fitFor(ExerciseDef e) {
  final pts = <V3>[];
  final total = loopSeconds(e.keys);
  for (var i = 0; i < 24; i++) {
    pts.addAll(scenePoints(solve(frameAt(e.keys, total * i / 24).pose, e.anchor), e.equip));
  }
  return Fit.of(pts);
}

final _fits = <String, Fit>{};
Fit cachedFit(ExerciseDef e) => _fits.putIfAbsent(e.id, () => fitFor(e));

class _RigPainter extends CustomPainter {
  _RigPainter({required this.e, required this.pose, required this.yaw, required this.style, required this.showAngles});
  final ExerciseDef e;
  final Pose pose;
  final double yaw;
  final RigStyle style;
  final bool showAngles;

  @override
  void paint(Canvas canvas, Size size) {
    paintRig(
      canvas,
      size,
      body: solve(pose, e.anchor),
      equip: e.equip,
      primary: e.primary,
      secondary: e.secondary,
      angles: showAngles ? e.angles : const [],
      cam: Camera(yaw, 10, cachedFit(e), size),
      style: style,
      labelStyle: _labelStyle,
    );
  }

  @override
  bool shouldRepaint(_RigPainter o) => o.pose != pose || o.yaw != yaw || o.showAngles != showAngles || o.e != e;
}

/// A still picture of an exercise for cards and lists.
class ExerciseThumb extends StatelessWidget {
  const ExerciseThumb(this.e, {super.key, this.height = 120});
  final ExerciseDef e;
  final double height;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final key = e.keys.length > 1 ? e.keys[1] : e.keys.first;
    return ExcludeSemantics(
      child: Container(
        height: height,
        color: p.panel,
        child: CustomPaint(
          size: Size.infinite,
          painter: _RigPainter(e: e, pose: key.pose, yaw: e.view, style: rigStyle(p), showAngles: false),
        ),
      ),
    );
  }
}

/// Animated body model. Drag to turn it. It respects reduced motion: it
/// starts paused and shows a still frame until the user presses play.
class ExerciseViewer extends StatefulWidget {
  const ExerciseViewer(this.e, {super.key, this.height = 360});
  final ExerciseDef e;
  final double height;

  @override
  State<ExerciseViewer> createState() => _ExerciseViewerState();
}

enum _View { front, side, angle, back }

class _ExerciseViewerState extends State<ExerciseViewer> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late double _yaw = widget.e.view;
  double _speed = 1;
  bool _angles = true;
  bool _started = false;

  double get _total => loopSeconds(widget.e.keys);

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_total * 1000).round()),
    );
  }

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

  void _toggle() {
    setState(() {
      if (_c.isAnimating) {
        _c.stop();
      } else {
        _c.repeat();
      }
    });
  }

  void _setSpeed() {
    setState(() {
      _speed = _speed == 1 ? 0.5 : 1;
      final running = _c.isAnimating;
      _c.duration = Duration(milliseconds: (_total * 1000 / _speed).round());
      if (running) _c.repeat();
    });
  }

  void _setView(_View v) => setState(
    () => _yaw = switch (v) {
      _View.front => 0,
      _View.side => 90,
      _View.angle => widget.e.view,
      _View.back => 180,
    },
  );

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final style = rigStyle(p);
    final e = widget.e;
    return Container(
      decoration: BoxDecoration(color: p.panel, borderRadius: Radii.large),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          SizedBox(
            height: widget.height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    label:
                        'Body model of ${e.name}. Drag to turn it. Main muscles: ${e.primary.map((m) => m.label).join(', ')}.',
                    child: GestureDetector(
                      onHorizontalDragUpdate: (d) => setState(() => _yaw = (_yaw - d.delta.dx * 0.6) % 360),
                      child: AnimatedBuilder(
                        animation: _c,
                        builder: (context, _) {
                          final f = frameAt(e.keys, _c.value * _total);
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: CustomPaint(
                                  painter: _RigPainter(
                                    e: e,
                                    pose: f.pose,
                                    yaw: _yaw,
                                    style: style,
                                    showAngles: _angles,
                                  ),
                                ),
                              ),
                              Positioned(
                                left: Space.l,
                                top: Space.l,
                                child: Semantics(
                                  liveRegion: false,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: p.energy,
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(f.label, style: t.labelMedium?.copyWith(color: p.onEnergy)),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: Space.s,
                  top: Space.s,
                  child: Column(
                    children: [
                      _PanelButton(
                        icon: _c.isAnimating ? LucideIcons.pause : LucideIcons.play,
                        tooltip: _c.isAnimating ? 'Pause' : 'Play',
                        onTap: _toggle,
                      ),
                      _PanelButton(
                        icon: LucideIcons.gauge,
                        tooltip: _speed == 1 ? 'Slow motion' : 'Normal speed',
                        label: _speed == 1 ? '1×' : '½×',
                        onTap: _setSpeed,
                      ),
                      _PanelButton(
                        icon: LucideIcons.ruler,
                        tooltip: _angles ? 'Hide joint angles' : 'Show joint angles',
                        active: _angles,
                        onTap: () => setState(() => _angles = !_angles),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(Space.s, 0, Space.s, Space.s),
            child: Row(
              children: [
                for (final v in _View.values)
                  Expanded(
                    child: _ViewChip(
                      label: switch (v) {
                        _View.front => 'Front',
                        _View.side => 'Side',
                        _View.angle => '3/4',
                        _View.back => 'Back',
                      },
                      selected:
                          (_yaw -
                                  switch (v) {
                                    _View.front => 0,
                                    _View.side => 90,
                                    _View.angle => e.view,
                                    _View.back => 180,
                                  })
                              .abs() <
                          1,
                      onTap: () => _setView(v),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  const _PanelButton({required this.icon, required this.tooltip, required this.onTap, this.label, this.active = false});
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final String? label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.xs),
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          button: true,
          label: tooltip,
          excludeSemantics: true,
          child: Material(
            color: active ? p.energy.withValues(alpha: 0.18) : p.panelRaised,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: label != null
                      ? Text(label!, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: p.onPanel))
                      : Icon(icon, size: 20, color: active ? p.energy : p.onPanel),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewChip extends StatelessWidget {
  const _ViewChip({required this.label, required this.selected, required this.onTap});
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label view',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: selected ? p.onPanel : p.panelRaised,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onTap,
            child: SizedBox(
              height: 44,
              child: Center(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium
                      ?.weight(FontWeight.w700)
                      .copyWith(color: selected ? p.panel : p.onPanelSoft),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
