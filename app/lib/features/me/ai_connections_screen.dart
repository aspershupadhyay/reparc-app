import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tokens.dart';
import '../../core/widgets.dart';

/// Me → AI connections (handbook 10.3).
///
/// AI and MCP access need a separate approval (Stage E). This screen shows
/// the true state: there are no connections and no data leaves the phone.
class AiConnectionsScreen extends StatelessWidget {
  const AiConnectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: const Text('AI connections')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          const EmptyState(
            icon: LucideIcons.sparkles,
            title: 'No AI connections',
            body: 'Reparc does not send your records to an AI provider or MCP client.',
          ),
          const SectionHeader('How connections will work'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI connections are planned. They are not available in this version. When they are added:',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: Space.m),
                for (final line in const [
                  'You set up each connection yourself.',
                  'You choose Meal, Workout, and health data separately.',
                  'Each connection shows its provider, the data it can read, and its status.',
                  'You can disconnect at any time.',
                  'AI cannot change a record without your approval.',
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.s),
                    child: StatusLine(icon: LucideIcons.check, text: line),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
