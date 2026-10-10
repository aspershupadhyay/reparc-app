import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/distribution.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';

/// The full privacy policy. Google Play and Health Connect link to the same
/// address (handbook 17.10).
const privacyPolicyUrl = 'https://aspershupadhyay.github.io/reparc/privacy.html';

/// Plain summary of the data flows in this version.
///
/// Keep this text true to the code and to site/privacy.html. Update both
/// when a data flow changes.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    const facts = [
      (LucideIcons.smartphone, 'Your workouts, meals, foods, and settings are saved in a database on this phone.'),
      (LucideIcons.cloudOff, 'RepArc has no account and no RepArc server. Nothing is sent to the RepArc project.'),
      (LucideIcons.eyeOff, 'RepArc does not send product-use analytics or crash reports.'),
      (
        LucideIcons.heartPulse,
        'Apple Health or Health Connect: RepArc asks for one data type at a time, only when you switch it on in '
            'Me → Health apps. It reads steps, active energy, or weight, and writes finished workouts and eaten meals. '
            'Health values are not copied to any server and are never used for ads.',
      ),
      (
        LucideIcons.sparkles,
        'AI connections are off until you turn one on, for a time you choose. An AI app then gets answers only from '
            'the data types you switched on. The AI provider receives those answers. AI plans are saved only if you '
            'approve them.',
      ),
      (
        LucideIcons.cloud,
        'The online gateway runs in your own Vercel account. It holds no records; questions and answers pass through '
            'it encrypted with your key and expire within a minute.',
      ),
      (
        LucideIcons.cloudUpload,
        'Backups go to your own iCloud or Google account: through the phone\'s backup, or as a file encrypted with '
            'your passphrase. AI and health switches are not restored on a new phone.',
      ),
      if (playBuild)
        (LucideIcons.refreshCw, 'Updates come from Google Play. RepArc does not check for updates itself.')
      else
        (
          LucideIcons.refreshCw,
          'Update check: once a day (you can turn it off in Me → App updates), RepArc asks GitHub for the latest '
              'release. It sends no records, account, or device data. GitHub sees your IP address, as with any website.',
        ),
      (LucideIcons.download, 'Records leave the phone only through the choices above or a file you export yourself.'),
      (
        LucideIcons.lock,
        'The database on the phone uses the phone\'s own storage protection. Protect your phone with a passcode.',
      ),
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
          const SizedBox(height: Space.m),
          OutlinedButton.icon(
            onPressed: () => launchUrl(Uri.parse(privacyPolicyUrl), mode: LaunchMode.externalApplication),
            icon: const Icon(LucideIcons.externalLink, size: IconSizes.s),
            label: const Text('Read the full privacy policy'),
          ),
          const SizedBox(height: Space.l),
          Text(
            'RepArc records fitness and food information. It is not a medical service and does not give '
            'medical or diet treatment advice.',
            style: t.bodySmall,
          ),
        ],
      ),
    );
  }
}
