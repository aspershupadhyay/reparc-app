import 'dart:math' as math;

import 'package:flutter/cupertino.dart' show CupertinoAlertDialog, CupertinoDialogAction;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'motion.dart';
import 'palette.dart';
import 'theme.dart';
import 'tokens.dart';

/// Rounded surface card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color,
    this.padding = const EdgeInsets.all(Space.l),
    this.radius = Radii.large,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsets padding;
  final BorderRadius radius;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final card = Material(
      color: color ?? context.pal.surface,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (semanticLabel == null) return card;
    return Semantics(label: semanticLabel, button: onTap != null, container: true, child: card);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action, this.top = Space.xl});
  final String title;
  final Widget? action;
  final double top;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: top, bottom: Space.m),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// Screen title row used at the top of each tab.
class ScreenTitle extends StatelessWidget {
  const ScreenTitle(this.title, {super.key, this.subtitle, this.actions = const []});
  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.l),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null)
                  Text(
                    subtitle!.toUpperCase(),
                    style: t.bodySmall?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2),
                  ),
                Semantics(header: true, child: Text(title, style: t.displaySmall)),
              ],
            ),
          ),
          for (final a in actions)
            Padding(
              padding: const EdgeInsets.only(left: Space.s),
              child: a,
            ),
        ],
      ),
    );
  }
}

/// Round surface button, like the back and calendar buttons in the meal
/// reference.
class RoundButton extends StatelessWidget {
  const RoundButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.iconColor,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: color ?? p.surface,
        foregroundColor: iconColor ?? p.ink,
        fixedSize: const Size(52, 52),
      ),
      icon: Icon(icon, size: 22),
    );
  }
}

/// Solid circle with a glyph. The glyph colour is picked for contrast.
class IconBadge extends StatelessWidget {
  const IconBadge(this.icon, {super.key, required this.color, this.size = 44, this.glyph});
  final IconData icon;
  final Color color;
  final double size;
  final Color? glyph;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: size * 0.48, color: glyph ?? context.pal.on(color)),
      ),
    );
  }
}

/// A labelled value. A null value shows the missing mark, never zero.
class Metric extends StatelessWidget {
  const Metric({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.note,
    this.large = false,
    this.semanticValue,
    this.color,
    this.labelColor,
  });

  final String label;
  final String value;
  final String? unit;
  final String? note;
  final bool large;
  final String? semanticValue;
  final Color? color;
  final Color? labelColor;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    final valueStyle = (large ? t.displaySmall : t.titleLarge)!.tabular.copyWith(color: color ?? p.ink);
    return Semantics(
      label: '$label: ${semanticValue ?? [value, ?unit].join(' ')}${note == null ? '' : '. $note'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: t.bodySmall?.copyWith(color: labelColor ?? p.inkSoft)),
          const SizedBox(height: 2),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value, style: valueStyle),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: t.bodySmall?.copyWith(color: labelColor ?? p.inkSoft),
                  ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 2),
            Text(note!, style: t.bodySmall?.copyWith(color: labelColor ?? p.inkSoft)),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, this.body, this.action, this.color});

  final IconData icon;
  final String title;
  final String? body;
  final Widget? action;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final p = context.pal;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: Space.xl, vertical: Space.xxl),
      child: Column(
        children: [
          IconBadge(icon, color: color ?? p.brandSoft, glyph: p.brand, size: 64),
          const SizedBox(height: Space.l),
          Text(title, style: t.titleMedium, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: Space.xs),
            Text(
              body!,
              style: t.bodyMedium?.copyWith(color: p.inkSoft),
              textAlign: TextAlign.center,
            ),
          ],
          if (action != null) ...[const SizedBox(height: Space.l), action!],
        ],
      ),
    );
  }
}

/// A short line with an icon, so colour is never the only signal.
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.icon, required this.text, this.color});
  final IconData icon;
  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.pal.inkSoft;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ExcludeSemantics(child: Icon(icon, size: 16, color: c)),
        ),
        const SizedBox(width: Space.s),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: c)),
        ),
      ],
    );
  }
}

/// iOS-style segmented control: a grey track with a raised thumb.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
    this.icon,
  });
  final List<T> values;
  final T selected;
  final String Function(T) label;
  final IconData Function(T)? icon;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final dark = p.brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.ink.withValues(alpha: dark ? 0.16 : 0.07),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          for (final v in values)
            Expanded(
              child: Semantics(
                selected: v == selected,
                button: true,
                label: label(v),
                onTap: () => onChanged(v),
                excludeSemantics: true,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    if (v != selected) HapticFeedback.selectionClick();
                    onChanged(v);
                  },
                  child: AnimatedContainer(
                    duration: motionOf(context, Motion.standard),
                    curve: Motion.change,
                    constraints: const BoxConstraints(minHeight: 40),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: Space.s),
                    decoration: BoxDecoration(
                      color: v == selected ? (dark ? const Color(0xFF636366) : p.surface) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: v == selected && !dark
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon!(v), size: 16, color: p.ink),
                          const SizedBox(width: 6),
                        ],
                        Flexible(
                          child: Text(
                            label(v),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: (v == selected ? t.labelMedium : t.bodyMedium)?.copyWith(color: p.ink, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A ring that fills to [value] (0 to 1). Animates once when it changes.
class Ring extends StatelessWidget {
  const Ring({
    super.key,
    required this.value,
    required this.color,
    this.track,
    this.size = 64,
    this.stroke = 7,
    this.child,
    required this.semanticLabel,
  });

  final double value;
  final Color color;
  final Color? track;
  final double size;
  final double stroke;
  final Widget? child;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final v = value.isNaN ? 0.0 : value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel,
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: v),
        duration: motionOf(context, Motion.expanded),
        curve: Motion.enter,
        builder: (context, x, _) => CustomPaint(
          painter: _RingPainter(x, color, track ?? context.pal.line, stroke),
          child: SizedBox.square(
            dimension: size,
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter(this.v, this.color, this.track, this.stroke);
  final double v;
  final Color color;
  final Color track;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromLTWH(stroke / 2, stroke / 2, size.width - stroke, size.height - stroke);
    final base = Paint()
      ..color = track
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawArc(r, 0, 2 * math.pi, false, base);
    if (v > 0) {
      canvas.drawArc(
        r,
        -math.pi / 2,
        2 * math.pi * v,
        false,
        base
          ..color = color
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter o) => o.v != v || o.color != color || o.track != track;
}

/// Small rounded label.
class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color, this.textColor, this.icon});
  final String text;
  final Color? color;
  final Color? textColor;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final fg = textColor ?? p.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: color ?? p.surfaceAlt, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 14, color: fg), const SizedBox(width: 4)],
          Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// Builds a screen body from an async value with loading and error states.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.builder});
  final AsyncValue<T> value;
  final Widget Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    return switch (value) {
      AsyncData(:final value) => builder(value),
      AsyncError(:final error) => Center(
        child: Padding(
          padding: const EdgeInsets.all(Space.xl),
          child: Semantics(
            liveRegion: true,
            child: Text(
              'Could not load your records. $error',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: context.pal.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      _ => const Center(
        child: Padding(
          padding: EdgeInsets.all(Space.xl),
          child: CircularProgressIndicator(semanticsLabel: 'Loading'),
        ),
      ),
    };
  }
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => CupertinoAlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        CupertinoDialogAction(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        CupertinoDialogAction(
          onPressed: () => Navigator.pop(context, true),
          isDestructiveAction: destructive,
          isDefaultAction: !destructive,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return ok ?? false;
}

Future<String?> promptText(
  BuildContext context, {
  required String title,
  required String label,
  String initial = '',
  String confirmLabel = 'Save',
}) {
  return showDialog<String>(
    context: context,
    builder: (context) => _PromptDialog(title: title, label: label, initial: initial, confirmLabel: confirmLabel),
  );
}

class _PromptDialog extends StatefulWidget {
  const _PromptDialog({required this.title, required this.label, required this.initial, required this.confirmLabel});
  final String title;
  final String label;
  final String initial;
  final String confirmLabel;

  @override
  State<_PromptDialog> createState() => _PromptDialogState();
}

class _PromptDialogState extends State<_PromptDialog> {
  late final _c = TextEditingController(text: widget.initial);
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _submit() {
    final v = _c.text.trim();
    if (v.isEmpty) {
      setState(() => _error = 'Enter a name.');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _c,
        autofocus: true,
        maxLength: 120,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(labelText: widget.label, errorText: _error),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(onPressed: _submit, child: Text(widget.confirmLabel)),
      ],
    );
  }
}

/// Shows a short message. Screen readers announce snack bars.
void showMessage(BuildContext context, String text, {String? actionLabel, VoidCallback? onAction}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      content: Text(text),
      action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
    ),
  );
}

/// Runs a local write and shows an error if it fails.
///
/// Success is shown only after the write finishes (handbook 3.11).
Future<T?> guardedWrite<T>(BuildContext context, Future<T> Function() write, {String? success}) async {
  try {
    final r = await write();
    if (success != null && context.mounted) showMessage(context, success);
    return r;
  } catch (e) {
    if (context.mounted) showMessage(context, 'Not saved. ${_reason(e)}');
    return null;
  }
}

String _reason(Object e) => e is StateError ? e.message : 'Try again.';

/// Bottom sheet with the shared layout.
Future<T?> showAppSheet<T>(BuildContext context, WidgetBuilder builder) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: builder(context),
    ),
  );
}

/// Applies the variable-font weight in a widget tree.
extension Weighted on TextStyle? {
  TextStyle? w(FontWeight weight) => this?.weight(weight);
}
