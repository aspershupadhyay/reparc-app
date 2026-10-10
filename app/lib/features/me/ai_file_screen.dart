import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/format.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/data_controls.dart';
import '../../data/meal_repository.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../mcp/reparc_tools.dart';
import '../meal/meal_style.dart';
import 'app_updates_screen.dart';

/// Me → AI connections → Share a file (handbook 10.10).
///
/// RepArc has no background AI access. The user chooses what to share,
/// makes an export, and gives it to an AI app: either through the local MCP
/// server (tool/mcp/server.dart) or by attaching the file to a chat. Plans
/// an AI writes come back through Import, with a preview and approval.
class AiFileScreen extends ConsumerStatefulWidget {
  const AiFileScreen({super.key});

  @override
  ConsumerState<AiFileScreen> createState() => _AiFileScreenState();
}

class _AiFileScreenState extends ConsumerState<AiFileScreen> {
  final _scopes = {...DataControls.allScopes};
  bool _busy = false;

  Future<void> _export() async {
    setState(() => _busy = true);
    try {
      final info = await ref.read(packageInfoProvider.future);
      final json = await ref
          .read(dataControlsProvider)
          .exportJson(appVersion: '${info.version}+${info.buildNumber}', scopes: _scopes);
      final dir = await getTemporaryDirectory();
      final day = dayKey(ref.read(clockProvider)());
      final file = File('${dir.path}/reparc-ai-export-$day.json');
      await file.writeAsString(json, flush: true);
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/json')],
          subject: 'RepArc data for AI ($day)',
          sharePositionOrigin: box == null ? null : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) showMessage(context, 'Export failed. Nothing was shared. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _copy(String text, String what) {
    Clipboard.setData(ClipboardData(text: text));
    showMessage(context, '$what copied.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    const config =
        '{\n  "mcpServers": {\n    "reparc": {\n      "command": "/path/to/reparc-mcp",\n'
        '      "args": ["/path/to/reparc-ai-export.json"]\n    }\n  }\n}';
    final roadmapPrompt =
        'Write a training plan for me in this exact JSON format, and nothing else. '
        'Start every day with warm-up items.\n\n'
        '${const JsonEncoder.withIndent(' ').convert(importFormats['roadmap'])}';
    final mealPrompt =
        'Write one day of meals for me in this exact JSON format, and nothing else. Use values per 100 g from '
        'a food database and name the source. Leave out values you do not know.\n\n'
        '${const JsonEncoder.withIndent(' ').convert(importFormats['mealPlan'])}';
    Widget scope(String key, IconData icon, String title, String body) => SwitchListTile(
      contentPadding: EdgeInsets.zero,
      secondary: Icon(icon, color: p.brand),
      title: Text(title),
      subtitle: Text(body),
      value: _scopes.contains(key),
      onChanged: (v) => setState(() => v ? _scopes.add(key) : _scopes.remove(key)),
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Share a file or import a plan')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          AppCard(
            color: p.brandSoft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(LucideIcons.shieldCheck, color: p.brand),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Text(
                    'No live connection. RepArc never sends your records to an AI by itself. You choose what to '
                    'share, make a file, and give it to the AI app you trust. Your data stays yours, for free.',
                    style: t.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('1. Choose what to share'),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: Space.l),
            child: Column(
              children: [
                scope('workout', LucideIcons.dumbbell, 'Workouts', 'Sessions, sets, exercises, and your roadmap'),
                scope('meal', LucideIcons.utensils, 'Meals', 'Foods, amounts, and nutrients'),
                scope('body', LucideIcons.personStanding, 'Body and goals', 'Profile, targets, and weight'),
              ],
            ),
          ),
          const SectionHeader('2. Make the file'),
          FilledButton.icon(
            onPressed: _busy || _scopes.isEmpty ? null : _export,
            icon: const Icon(LucideIcons.share, size: 20),
            label: Text(_busy ? 'Preparing' : 'Export for AI'),
          ),
          const SizedBox(height: Space.s),
          Text(
            'The AI app and its provider will receive what is in the file. Check their privacy terms.',
            style: t.bodySmall,
          ),
          const SectionHeader('3. Connect an AI app'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('With MCP (Claude Desktop, and other MCP apps)', style: t.titleSmall),
                const SizedBox(height: Space.xs),
                Text(
                  'Build the RepArc MCP server once on your computer: in the project\'s app folder, run\n'
                  'dart compile exe tool/mcp/server.dart -o reparc-mcp\n'
                  'Then add it to your AI app\'s MCP settings with the path to your export file:',
                  style: t.bodySmall,
                ),
                const SizedBox(height: Space.s),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(Space.m),
                  decoration: BoxDecoration(color: p.surfaceAlt, borderRadius: Radii.small),
                  child: SelectableText(config, style: t.bodySmall?.copyWith(fontFamily: 'monospace')),
                ),
                TextButton.icon(
                  onPressed: () => _copy(config, 'Settings'),
                  icon: const Icon(LucideIcons.copy, size: 18),
                  label: const Text('Copy settings'),
                ),
                const Divider(),
                Text('Without MCP', style: t.titleSmall),
                const SizedBox(height: Space.xs),
                Text(
                  'Attach the export file to a chat in any AI app and ask your question.',
                  style: t.bodySmall,
                ),
              ],
            ),
          ),
          const SectionHeader('Ask AI for a plan'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Copy a prompt that tells the AI the exact format RepArc can import. Paste the answer back with '
                  'Import a plan.',
                  style: t.bodySmall,
                ),
                Wrap(
                  spacing: Space.s,
                  children: [
                    TextButton.icon(
                      onPressed: () => _copy(roadmapPrompt, 'Plan prompt'),
                      icon: const Icon(LucideIcons.copy, size: 18),
                      label: const Text('Plan prompt'),
                    ),
                    TextButton.icon(
                      onPressed: () => _copy(mealPrompt, 'Meal plan prompt'),
                      icon: const Icon(LucideIcons.copy, size: 18),
                      label: const Text('Meal plan prompt'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          OutlinedButton.icon(
            onPressed: () => showAppSheet<void>(context, (_) => const _ImportSheet()),
            icon: const Icon(LucideIcons.download, size: 20),
            label: const Text('Import a plan'),
          ),
          const SectionHeader('What an AI can read'),
          AppCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (final (i, tool) in reparcTools.indexed) ...[
                  if (i > 0) const Divider(indent: Space.l),
                  ListTile(
                    dense: true,
                    title: Text(tool.name, style: t.labelMedium),
                    subtitle: Text(tool.description, maxLines: 3, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: Space.m),
          for (final line in const [
            'You choose Workouts, Meals, and Body data separately.',
            'The tools only read. An AI cannot change a record.',
            'Plans from an AI are saved only after you see a preview and approve it.',
            'Remove access by deleting the file from the AI app or your computer.',
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: StatusLine(icon: LucideIcons.check, text: line),
            ),
        ],
      ),
    );
  }
}

/// Paste a plan, check it, preview it, then approve.
class _ImportSheet extends ConsumerStatefulWidget {
  const _ImportSheet();

  @override
  ConsumerState<_ImportSheet> createState() => _ImportSheetState();
}

class _ImportSheetState extends ConsumerState<_ImportSheet> {
  final _text = TextEditingController();
  List<String> _problems = const [];
  Map<String, Object?>? _plan;
  bool _saving = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _check() {
    var raw = _text.text.trim();
    // AI answers often wrap JSON in a code fence.
    final fence = RegExp(r'```(?:json)?\s*([\s\S]*?)```').firstMatch(raw);
    if (fence != null) raw = fence.group(1)!.trim();
    Object? json;
    try {
      json = jsonDecode(raw);
    } catch (_) {
      setState(() {
        _plan = null;
        _problems = ['This is not valid JSON. Copy the whole answer from the AI.'];
      });
      return;
    }
    final kind = json is Map ? json['kind'] : null;
    final problems = switch (kind) {
      'reparc-roadmap' => roadmapProblems(json),
      'reparc-meal-plan' => mealPlanProblems(json),
      _ => ['kind must be "reparc-roadmap" or "reparc-meal-plan".'],
    };
    setState(() {
      _problems = problems;
      _plan = problems.isEmpty ? (json! as Map).cast<String, Object?>() : null;
    });
  }

  Future<void> _approve() async {
    final plan = _plan!;
    setState(() => _saving = true);
    bool? ok;
    if (plan['kind'] == 'reparc-roadmap') {
      ok = await guardedWrite(context, () async {
        // Saved, not followed. The user follows it from the plan page (handbook 4.12).
        await ref.read(programRepoProvider).create(roadmapFromProposal(plan), name: 'Plan from AI');
        return true;
      }, success: 'Plan saved. Find it in Workout → Plan, and tap Follow to use it.');
    } else {
      final repo = ref.read(mealRepoProvider);
      final slots = await repo.allSlots();
      if (!mounted) return;
      final day = plan['day'] is String && _validDay(plan['day']! as String)
          ? plan['day']! as String
          : dayKey(dayOf(ref.read(clockProvider)()));
      String slotFor(String kind) => slots.firstWhere((s) => slotKind(s) == kind, orElse: () => slots.first).id;
      ok = await guardedWrite(context, () async {
        for (final m in (plan['meals']! as List).cast<Map<Object?, Object?>>()) {
          for (final f in (m['foods']! as List).cast<Map<Object?, Object?>>()) {
            final per = (f['per100g']! as Map).cast<String, Object?>();
            double? v(String k) => (per[k] as num?)?.toDouble();
            await repo.addEntry(
              day: day,
              slotId: slotFor(m['slot']! as String),
              food: FoodValues(
                name: f['name']! as String,
                servingAmount: 100,
                servingUnit: 'g',
                energyKcal: v('kcal'),
                proteinG: v('protein'),
                carbsG: v('carbs'),
                fatG: v('fat'),
                fiberG: v('fiber'),
                sugarG: v('sugar'),
                sodiumMg: v('sodium'),
                isEstimate: true,
                source: 'AI suggestion${f['source'] is String ? ': ${f['source']}' : ''}',
                note: m['name'] as String?,
              ),
              amount: (f['grams']! as num).toDouble(),
              amountUnit: 'g',
              status: MealStatus.planned,
            );
          }
        }
        return true;
      }, success: 'Added to $day as planned. Values are marked as estimates.');
    }
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok == true) Navigator.pop(context);
  }

  static bool _validDay(String s) {
    try {
      parseDayKey(s);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final plan = _plan;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Space.l, 0, Space.l, Space.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Import a plan', style: t.titleLarge),
          Text('Paste the JSON an AI wrote. Nothing is saved until you approve.', style: t.bodySmall),
          const SizedBox(height: Space.m),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 10,
            decoration: const InputDecoration(labelText: 'Plan JSON', alignLabelWithHint: true),
            onChanged: (_) => setState(() => _plan = null),
          ),
          const SizedBox(height: Space.s),
          OutlinedButton(onPressed: _check, child: const Text('Check')),
          for (final pr in _problems)
            Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: StatusLine(icon: LucideIcons.circleAlert, text: pr, color: p.error),
            ),
          if (plan != null) ...[
            const SectionHeader('Preview'),
            if (plan['kind'] == 'reparc-roadmap')
              for (final d in roadmapFromProposal(plan).days)
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: t.titleSmall),
                        for (final it in d.items)
                          Text('${it.kind.label}: ${it.name}  ${it.target}', style: t.bodySmall),
                      ],
                    ),
                  ),
                )
            else
              for (final m in (plan['meals']! as List).cast<Map<Object?, Object?>>())
                Padding(
                  padding: const EdgeInsets.only(bottom: Space.s),
                  child: AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${m['slot']}: ${m['name'] ?? ''}', style: t.titleSmall),
                        for (final f in (m['foods']! as List).cast<Map<Object?, Object?>>())
                          Text('${f['name']} · ${fmtNum(f['grams'] as num?)} g', style: t.bodySmall),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: Space.s),
            FilledButton(
              onPressed: _saving ? null : _approve,
              child: Text(
                plan['kind'] == 'reparc-roadmap' ? 'Approve and save this plan' : 'Approve and add as planned',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
