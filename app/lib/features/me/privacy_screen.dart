import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/tokens.dart';
import '../../core/widgets.dart';

/// Plain summary of the data flows in this version.
///
/// Keep this text true to the code. Update it when a data flow changes.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const facts = [
      (LucideIcons.smartphone, 'Your workouts, meals, foods, and settings are saved in a database on this phone.'),
      (LucideIcons.cloudOff, 'Reparc has no account, no server, and no sync in this version.'),
      (LucideIcons.eyeOff, 'Reparc does not send product-use analytics or crash reports.'),
      (LucideIcons.heartPulse, 'Reparc does not request Apple Health or Health Connect access.'),
      (LucideIcons.sparkles, 'Reparc does not send records to an AI provider.'),
      (LucideIcons.download, 'Records leave the phone only when you export and share a file yourself.'),
      (LucideIcons.lock, 'Reparc does not add its own encryption to the database. Protect your phone with a passcode.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          Text('What this version does with your data', style: t.titleMedium),
          const SizedBox(height: Space.m),
          AppCard(
            child: Column(
              children: [
                for (final (icon, text) in facts)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: Space.s),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExcludeSemantics(child: Icon(icon, size: IconSizes.s)),
                        const SizedBox(width: Space.m),
                        Expanded(child: Text(text, style: t.bodyMedium)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Space.l),
          Text(
            'Reparc records fitness and food information. It is not a medical service and does not give '
            'medical or diet treatment advice.',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
