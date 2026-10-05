import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme.dart';
import 'tokens.dart';

/// White card with the shared border and radius.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.color = AppColors.surface,
    this.padding = const EdgeInsets.all(Space.l),
    this.border = true,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color color;
  final EdgeInsets padding;
  final bool border;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final content = Padding(padding: padding, child: child);
    final card = Material(
      color: color,
      shape: RoundedRectangleBorder(
        borderRadius: Radii.medium,
        side: border ? const BorderSide(color: AppColors.border) : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? content : InkWell(onTap: onTap, child: content),
    );
    if (semanticLabel == null) return card;
    return Semantics(label: semanticLabel, button: onTap != null, container: true, child: card);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: Space.xl, bottom: Space.s),
      child: Row(
        children: [
          Expanded(
            child: Semantics(header: true, child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          ),
          ?action,
        ],
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
  });

  final String label;
  final String value;
  final String? unit;
  final String? note;
  final bool large;
  final String? semanticValue;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final valueStyle = (large ? t.displaySmall : t.titleLarge)!.tabular.copyWith(color: color);
    return Semantics(
      label: '$label: ${semanticValue ?? [value, ?unit].join(' ')}${note == null ? '' : '. $note'}',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: t.bodySmall?.copyWith(color: color?.withValues(alpha: 0.8))),
          const SizedBox(height: Space.xs),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(text: value, style: valueStyle),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: t.bodyMedium?.copyWith(color: color ?? AppColors.secondaryText),
                  ),
              ],
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: Space.xs),
            Text(note!, style: t.bodySmall?.copyWith(color: color?.withValues(alpha: 0.8))),
          ],
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.title, required this.body, this.action});

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AppCard(
      color: AppColors.softSurface,
      border: false,
      padding: const EdgeInsets.all(Space.xl),
      child: Column(
        children: [
          ExcludeSemantics(child: Icon(icon, size: IconSizes.m)),
          const SizedBox(height: Space.m),
          Text(title, style: t.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: Space.xs),
          Text(
            body,
            style: t.bodyMedium?.copyWith(color: AppColors.secondaryText),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: Space.l), action!],
        ],
      ),
    );
  }
}

/// A short status line with an icon and text, so color is not the only signal.
class StatusLine extends StatelessWidget {
  const StatusLine({super.key, required this.icon, required this.text, this.color = AppColors.secondaryText});
  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: ExcludeSemantics(child: Icon(icon, size: 16, color: color)),
        ),
        const SizedBox(width: Space.s),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color)),
        ),
      ],
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
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      _ => const Center(
        child: Padding(
          padding: EdgeInsets.all(Space.xl),
          child: CircularProgressIndicator(color: AppColors.ink, semanticsLabel: 'Loading'),
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
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: destructive ? TextButton.styleFrom(foregroundColor: AppColors.error) : null,
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
