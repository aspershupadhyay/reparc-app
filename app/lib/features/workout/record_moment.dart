import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/theme.dart';
import '../../core/tokens.dart';
import '../../domain/analytics.dart';

/// The PR moment (launch review Block 3): after a saved workout that beat
/// an earlier best, a full-screen card says so, with a strong haptic. The
/// card can be shared as an image; it holds only the lifts shown, no
/// account and no other data. Motion follows reduced-motion settings
/// (the dialog's own fade only).
Future<void> showRecordMoment(BuildContext context, List<PersonalRecord> records) async {
  if (records.isEmpty) return;
  unawaited(HapticFeedback.heavyImpact());
  await showDialog<void>(
    context: context,
    useSafeArea: true,
    builder: (_) => _RecordDialog(records: records),
  );
}

class _RecordDialog extends StatefulWidget {
  const _RecordDialog({required this.records});
  final List<PersonalRecord> records;

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  final _card = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    setState(() => _sharing = true);
    try {
      final boundary = _card.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = await getTemporaryDirectory();
      final path = '${dir.path}/reparc-new-best.png';
      await File(path).writeAsBytes(bytes!.buffer.asUint8List());
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'image/png')],
          text: recordLine(widget.records.first),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.maybeOf(context)?.showSnackBar(const SnackBar(content: Text('Could not share the card.')));
      }
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const p = Palette.dark;
    final n = widget.records.length;
    return Dialog(
      insetPadding: const EdgeInsets.all(Space.l),
      backgroundColor: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            key: _card,
            child: Container(
              padding: const EdgeInsets.all(Space.xl),
              decoration: BoxDecoration(color: p.panel, borderRadius: Radii.large),
              child: Semantics(
                liveRegion: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(LucideIcons.trophy, color: p.energy),
                        const SizedBox(width: Space.s),
                        Text(
                          n == 1 ? 'NEW BEST' : '$n NEW BESTS',
                          style: t.labelLarge?.copyWith(color: p.energy, letterSpacing: 0.8),
                        ),
                      ],
                    ),
                    const SizedBox(height: Space.l),
                    for (final r in widget.records) ...[
                      Text(r.source.exercise.name, style: t.titleMedium?.copyWith(color: p.onPanelSoft)),
                      Text(
                        _weight(r),
                        style: t.displaySmall?.tabular.copyWith(color: p.onPanel, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: Space.m),
                    ],
                    Text('RepArc', style: t.labelMedium?.copyWith(color: p.onPanelSoft)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: Space.m),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _sharing ? null : _share,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white70),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  icon: const Icon(LucideIcons.share2),
                  label: const Text('Share'),
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _weight(PersonalRecord r) {
  final s = r.source.set;
  return [fmtWithUnit(s.load, s.loadUnit, maxDecimals: 2), if (s.reps != null) '${s.reps}'].join(' × ');
}

/// "New best: Bench press 82.5 kg × 6".
String recordLine(PersonalRecord r) => 'New best: ${r.source.exercise.name} ${_weight(r)}';
