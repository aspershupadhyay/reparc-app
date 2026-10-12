import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;

import '../core/palette.dart';
import '../core/tokens.dart';
import '../domain/track.dart';

/// MapTiler key, given at build time (`--dart-define=MAPTILER_KEY=...`, from
/// the release workflow's secret). Without it, routes are drawn without map
/// tiles and no map request leaves the phone (handbook 4.14).
const mapTilerKey = String.fromEnvironment('MAPTILER_KEY');

/// A route: on MapTiler's map when the build has a key, else as a line on a
/// plain background. [follow] keeps the newest point in view while
/// recording.
class RouteMap extends StatefulWidget {
  const RouteMap({super.key, required this.points, this.follow = false, this.height = 260, this.semanticLabel});

  final List<TrackPoint> points;
  final bool follow;
  final double height;
  final String? semanticLabel;

  @override
  State<RouteMap> createState() => _RouteMapState();
}

class _RouteMapState extends State<RouteMap> {
  final _controller = MapController();
  bool _ready = false;

  @override
  void didUpdateWidget(RouteMap old) {
    super.didUpdateWidget(old);
    if (widget.follow && _ready && widget.points.isNotEmpty) {
      final last = widget.points.last;
      _controller.move(LatLng(last.lat, last.lon), _controller.camera.zoom);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final label = widget.semanticLabel ?? (widget.points.isEmpty ? 'Map. Waiting for GPS.' : 'Map of the route.');
    final Widget body;
    if (mapTilerKey.isEmpty) {
      body = CustomPaint(
        painter: RoutePainter(widget.points, line: p.brand, start: p.green, end: p.coral, grid: p.line),
        child: widget.points.length < 2
            ? Center(
                child: Text(
                  widget.points.isEmpty ? 'Waiting for GPS' : 'Start moving',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )
            : null,
      );
    } else {
      final pts = [for (final t in widget.points) LatLng(t.lat, t.lon)];
      final style = dark ? 'streets-v2-dark' : 'streets-v2';
      body = FlutterMap(
        mapController: _controller,
        options: MapOptions(
          initialCenter: pts.isEmpty ? const LatLng(20.59, 78.96) : pts.last,
          initialZoom: pts.isEmpty ? 4 : 16,
          initialCameraFit: !widget.follow && pts.length > 1
              ? CameraFit.bounds(bounds: LatLngBounds.fromPoints(pts), padding: const EdgeInsets.all(Space.xl))
              : null,
          backgroundColor: p.surfaceAlt,
          onMapReady: () => _ready = true,
          interactionOptions: const InteractionOptions(flags: InteractiveFlag.all & ~InteractiveFlag.rotate),
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://api.maptiler.com/maps/$style/256/{z}/{x}/{y}{r}.png?key=$mapTilerKey',
            retinaMode: RetinaMode.isHighDensity(context),
            userAgentPackageName: 'app.reparc.reparc',
            maxNativeZoom: 20,
          ),
          if (pts.length > 1)
            PolylineLayer(
              polylines: [
                Polyline(points: pts, strokeWidth: 5, color: p.brand, borderStrokeWidth: 1.5, borderColor: p.panel),
              ],
            ),
          if (pts.isNotEmpty)
            MarkerLayer(
              markers: [
                if (!widget.follow) Marker(point: pts.first, width: 14, height: 14, child: _Dot(p.green)),
                Marker(point: pts.last, width: 18, height: 18, child: _Dot(widget.follow ? p.brand : p.coral)),
              ],
            ),
          const RichAttributionWidget(
            attributions: [
              TextSourceAttribution('MapTiler', prependCopyright: true),
              TextSourceAttribution('OpenStreetMap contributors', prependCopyright: true),
            ],
          ),
        ],
      );
    }
    return Semantics(
      label: label,
      image: true,
      child: ClipRRect(
        borderRadius: Radii.large,
        child: SizedBox(
          height: widget.height,
          child: ColoredBox(color: p.surfaceAlt, child: body),
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot(this.color);
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white, width: 2.5),
    ),
  );
}

/// Draws a route as a line, north up, scaled to fit, for builds without map
/// tiles. The map's shape is true: east-west distances shrink with latitude.
class RoutePainter extends CustomPainter {
  RoutePainter(this.points, {required this.line, required this.start, required this.end, required this.grid});

  final List<TrackPoint> points;
  final Color line;
  final Color start;
  final Color end;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    final g = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (var x = 0.0; x < size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), g);
    }
    for (var y = 0.0; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), g);
    }
    if (points.length < 2) return;
    final k = math.cos(points.first.lat * math.pi / 180);
    var minX = double.infinity, maxX = -double.infinity, minY = double.infinity, maxY = -double.infinity;
    for (final p in points) {
      final x = p.lon * k, y = p.lat;
      minX = math.min(minX, x);
      maxX = math.max(maxX, x);
      minY = math.min(minY, y);
      maxY = math.max(maxY, y);
    }
    const pad = 24.0;
    final w = math.max(maxX - minX, 1e-9), h = math.max(maxY - minY, 1e-9);
    final scale = math.min((size.width - 2 * pad) / w, (size.height - 2 * pad) / h);
    final ox = (size.width - w * scale) / 2, oy = (size.height - h * scale) / 2;
    Offset at(TrackPoint p) => Offset(ox + (p.lon * k - minX) * scale, oy + (maxY - p.lat) * scale);
    final path = Path();
    for (final (i, p) in points.indexed) {
      final o = at(p);
      // A new segment after a pause starts a new line.
      if (i == 0 || points[i - 1].segment != p.segment) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = line
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    for (final (p, c) in [(points.first, start), (points.last, end)]) {
      canvas.drawCircle(at(p), 7, Paint()..color = Colors.white);
      canvas.drawCircle(at(p), 5, Paint()..color = c);
    }
  }

  @override
  bool shouldRepaint(RoutePainter old) => old.points.length != points.length || old.line != line;
}
