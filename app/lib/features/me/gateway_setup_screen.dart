import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../ai/ai_controller.dart';
import '../../ai/gateway_client.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';

/// Guided setup of the owner's own gateway on Vercel (D-018).
///
/// 1. RepArc makes an owner key; the user copies it.
/// 2. Vercel's deploy page asks for it (REPARC_OWNER_KEY) and adds Upstash.
/// 3. The user pastes the new address back here, and RepArc checks it.
class GatewaySetupScreen extends ConsumerStatefulWidget {
  const GatewaySetupScreen({super.key});

  @override
  ConsumerState<GatewaySetupScreen> createState() => _GatewaySetupScreenState();
}

class _GatewaySetupScreenState extends ConsumerState<GatewaySetupScreen> {
  final _address = TextEditingController();
  final _manualKey = TextEditingController();
  String? _key;
  bool _ownKey = false;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    ref.read(aiControllerProvider.notifier).draftOwnerKey().then((k) {
      if (mounted) setState(() => _key = k);
    });
  }

  @override
  void dispose() {
    _address.dispose();
    _manualKey.dispose();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => (_busy = true, _error = null));
    try {
      final key = _ownKey ? _manualKey.text : _key!;
      await ref.read(aiControllerProvider.notifier).connectGateway(_address.text, key);
      if (!mounted) return;
      showMessage(context, 'Gateway connected.');
      Navigator.of(context).pop();
    } on GatewayException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;

    Widget step(int n, String title, List<Widget> body) => Padding(
      padding: const EdgeInsets.only(bottom: Space.m),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: p.action,
                  child: Text('$n', style: t.labelLarge?.copyWith(color: p.onAction)),
                ),
                const SizedBox(width: Space.m),
                Expanded(child: Text(title, style: t.titleMedium)),
              ],
            ),
            const SizedBox(height: Space.m),
            ...body,
          ],
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Your own gateway')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          Text(
            'The gateway is a small web service in your own free Vercel account. Your AI app talks to it over HTTPS, '
            'and it passes each question to RepArc on this phone. Nobody else runs it or holds its key.',
            style: t.bodyMedium?.copyWith(color: p.inkSoft),
          ),
          const SizedBox(height: Space.l),
          step(1, 'Copy your owner key', [
            if (!_ownKey) ...[
              Material(
                color: p.surfaceAlt,
                borderRadius: Radii.small,
                child: Padding(
                  padding: const EdgeInsets.all(Space.m),
                  child: SelectableText(_key ?? '…', style: const TextStyle(fontFamily: 'monospace', fontSize: 13)),
                ),
              ),
              const SizedBox(height: Space.s),
              FilledButton.icon(
                onPressed: _key == null
                    ? null
                    : () async {
                        await Clipboard.setData(ClipboardData(text: _key!));
                        if (context.mounted) showMessage(context, 'Owner key copied.');
                      },
                icon: const Icon(LucideIcons.copy, size: 18),
                label: const Text('Copy owner key'),
              ),
              const SizedBox(height: Space.s),
              StatusLine(
                icon: LucideIcons.keyRound,
                text:
                    'This key is the master key of your gateway. Paste it only into Vercel. RepArc keeps it in this '
                    'phone\'s secure storage.',
                color: p.warning,
              ),
            ],
          ]),
          step(2, 'Deploy on Vercel', [
            Text(
              'On the Vercel page: sign in (the free Hobby plan is enough), keep the repository private, add the '
              'Upstash Redis store (free plan), paste the key into REPARC_OWNER_KEY, then press Deploy.',
              style: t.bodyMedium,
            ),
            const SizedBox(height: Space.m),
            FilledButton.icon(
              onPressed: () => launchUrl(Uri.parse(vercelDeployUrl()), mode: LaunchMode.externalApplication),
              icon: const Icon(LucideIcons.externalLink, size: 18),
              label: const Text('Open Vercel'),
            ),
            const SizedBox(height: Space.s),
            OutlinedButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: vercelDeployUrl()));
                if (context.mounted) showMessage(context, 'Link copied. Open it on your computer.');
              },
              icon: const Icon(LucideIcons.monitor, size: 18),
              label: const Text('Copy link for a computer'),
            ),
          ]),
          step(3, 'Paste your gateway address', [
            TextField(
              controller: _address,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Address from Vercel',
                hintText: 'reparc-gateway-you.vercel.app',
              ),
            ),
            if (_ownKey) ...[
              const SizedBox(height: Space.s),
              TextField(
                controller: _manualKey,
                autocorrect: false,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Owner key (REPARC_OWNER_KEY from Vercel)'),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: Space.s),
              StatusLine(icon: LucideIcons.triangleAlert, text: _error!, color: p.error),
            ],
            const SizedBox(height: Space.m),
            FilledButton.icon(
              onPressed: _busy || _key == null ? null : _connect,
              icon: _busy
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(LucideIcons.link, size: 18),
              label: const Text('Connect this phone'),
            ),
            TextButton(
              onPressed: () => setState(() => _ownKey = !_ownKey),
              child: Text(_ownKey ? 'Use the key shown above' : 'I already have a gateway and its key'),
            ),
          ]),
          StatusLine(
            icon: LucideIcons.shieldCheck,
            text:
                'The gateway stores no workouts, meals, or health data. Questions and answers wait there for a few '
                'seconds, encrypted with your key, then expire. It is open source in the RepArc repository.',
          ),
        ],
      ),
    );
  }
}
