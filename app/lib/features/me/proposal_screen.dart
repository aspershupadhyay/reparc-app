import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ai/ai_controller.dart';
import '../../core/dates.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/database.dart';
import '../../data/models.dart';

/// Review of a plan an AI app sent (handbook 10.4, D-019). Nothing is
/// saved until the user taps Approve.
class ProposalScreen extends ConsumerWidget {
  const ProposalScreen({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(proposalProvider(id));
    return Scaffold(
      appBar: AppBar(title: const Text('Review plan')),
      body: AsyncBody<AiProposal?>(
        value: value,
        builder: (p) => p == null
            ? const Padding(
                padding: EdgeInsets.all(Space.l),
                child: EmptyState(icon: LucideIcons.fileX, title: 'This proposal no longer exists'),
              )
            : _Body(p),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body(this.p);
  final AiProposal p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pal = context.pal;
    final t = Theme.of(context).textTheme;
    final payload = jsonDecode(p.payload) as Map<String, dynamic>;
    final repo = ref.read(proposalRepoProvider);
    final isPlan = p.kind == ProposalKind.workoutPlan;

    return ListView(
      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
      children: [
        AppCard(
          color: pal.brandSoft,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(LucideIcons.sparkles, color: pal.brand),
                  const SizedBox(width: Space.s),
                  Expanded(
                    child: Text(
                      '${isPlan ? 'Workout plan' : 'Meal plan'} from ${p.client}',
                      style: t.titleMedium,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.s),
              Text(p.summary, style: t.bodyMedium),
              const SizedBox(height: Space.s),
              Text(
                'Sent ${DateFormat.MMMd().add_jm().format(p.createdAt.toLocal())} · ${p.via == 'wifi' ? 'over Wi-Fi' : 'online'}',
                style: t.bodySmall?.copyWith(color: pal.inkSoft),
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s),
        StatusLine(
          icon: LucideIcons.info,
          text: isPlan
              ? 'Approving adds these as new plans in Workout. Your existing plans and history do not change.'
              : 'Approving adds these as planned meals, marked as AI estimates. Check the values; AI can be wrong. '
                    'Nothing counts as eaten until you mark it.',
        ),
        if (isPlan)
          for (final plan in (payload['plans'] as List).cast<Map<String, dynamic>>()) ...[
            SectionHeader(plan['name'] as String, top: Space.l),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (plan['note'] != null)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, 0),
                      child: Text(plan['note'] as String, style: t.bodySmall?.copyWith(color: pal.inkSoft)),
                    ),
                  for (final e in (plan['exercises'] as List).cast<Map<String, dynamic>>())
                    ListTile(
                      leading: Icon(e['library_id'] != null ? LucideIcons.bookOpen : LucideIcons.dumbbell, size: 20),
                      title: Text(e['name'] as String),
                      subtitle: e['note'] == null ? null : Text(e['note'] as String),
                      trailing: Text(_target(e), style: t.titleSmall),
                    ),
                ],
              ),
            ),
          ]
        else
          ..._meals(context, (payload['meals'] as List).cast<Map<String, dynamic>>()),
        const SizedBox(height: Space.xl),
        if (p.status == ProposalStatus.pending)
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await guardedWrite(context, () => repo.decline(p.id), success: 'Declined. Nothing was saved.');
                    if (context.mounted) context.pop();
                  },
                  icon: const Icon(LucideIcons.x, size: 18),
                  label: const Text('Decline'),
                ),
              ),
              const SizedBox(width: Space.s),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () async {
                    final ok = await guardedWrite(
                      context,
                      () => repo.approve(p.id),
                      success: isPlan ? 'Plans saved in Workout.' : 'Meals added to your plan.',
                    );
                    if (ok != null && context.mounted) context.pop();
                  },
                  icon: const Icon(LucideIcons.check, size: 18),
                  label: const Text('Approve'),
                ),
              ),
            ],
          )
        else
          StatusLine(
            icon: p.status == ProposalStatus.approved ? LucideIcons.circleCheck : LucideIcons.circleX,
            text: p.status == ProposalStatus.approved ? 'You approved this.' : 'You declined this.',
          ),
      ],
    );
  }

  static String _target(Map<String, dynamic> e) {
    final sets = e['sets'], reps = e['reps'];
    if (sets != null && reps != null) return '$sets × $reps';
    if (sets != null) return '$sets sets';
    if (reps != null) return '$reps reps';
    return '';
  }

  static List<Widget> _meals(BuildContext context, List<Map<String, dynamic>> meals) {
    final t = Theme.of(context).textTheme;
    final byDay = <String, List<Map<String, dynamic>>>{};
    for (final m in meals) {
      (byDay[m['date'] as String] ??= []).add(m);
    }
    String amount(Object? v, String unit) => v == null ? '' : '${(v as num).round()} $unit';
    return [
      for (final day in byDay.keys.toList()..sort()) ...[
        SectionHeader(DateFormat.MMMEd().format(parseDayKey(day)), top: Space.l),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              for (final m in byDay[day]!)
                ListTile(
                  title: Text(m['name'] as String),
                  subtitle: Text(
                    [
                      _slot(m['slot'] as String),
                      if (m['amount'] != null) '${m['amount']} ${m['unit'] ?? 'serving'}',
                      amount(m['protein_g'], 'g protein'),
                      amount(m['carbs_g'], 'g carbs'),
                      amount(m['fat_g'], 'g fat'),
                    ].where((s) => s.isNotEmpty).join(' · '),
                  ),
                  trailing: Text(
                    m['energy_kcal'] == null ? '–' : amount(m['energy_kcal'], 'kcal'),
                    style: t.titleSmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    ];
  }

  static String _slot(String s) => s[0].toUpperCase() + s.substring(1);
}
