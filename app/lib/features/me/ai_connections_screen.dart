import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../ai/ai_controller.dart';
import '../../ai/gateway_client.dart';
import '../../ai/rpc.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/models.dart';
import '../../data/providers.dart';
import '../../data/settings_repository.dart';

/// Me → AI connections (handbook 10.3, D-018, D-019).
///
/// Two ways in, both off until the user turns one on:
/// - On this Wi-Fi: an MCP server on the phone for AI apps on the same network.
/// - Online: the user's own gateway on Vercel, for AI apps anywhere.
/// The user chooses each data category. AI changes arrive as proposals.
class AiConnectionsScreen extends ConsumerStatefulWidget {
  const AiConnectionsScreen({super.key});

  @override
  ConsumerState<AiConnectionsScreen> createState() => _AiConnectionsScreenState();
}

class _AiConnectionsScreenState extends ConsumerState<AiConnectionsScreen> {
  GatewayState? _gateway;
  String? _gatewayError;
  Timer? _refresh;

  @override
  void initState() {
    super.initState();
    unawaited(_loadGateway());
    // Sign-in requests appear while the user waits on this screen.
    _refresh = Timer.periodic(const Duration(seconds: 4), (_) => _loadGateway());
  }

  @override
  void dispose() {
    _refresh?.cancel();
    super.dispose();
  }

  Future<void> _loadGateway() async {
    final api = await ref.read(aiControllerProvider.notifier).api();
    if (api == null) return;
    try {
      final s = await api.state();
      if (mounted) setState(() => (_gateway = s, _gatewayError = null));
    } on GatewayException catch (e) {
      if (mounted) setState(() => _gatewayError = e.message);
    }
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) showMessage(context, '$what copied.');
  }

  Future<Duration?> _pickDuration(String title) => showAppSheet<Duration>(
    context,
    (context) => _DurationSheet(title: title),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final ai = ref.watch(aiControllerProvider);
    final settings = ref.watch(currentSettingsProvider);
    final contract = ref.watch(toolContractProvider).value;
    final pending = ref.watch(pendingProposalsProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('AI connections')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          Text(
            'Let an AI app such as Claude, ChatGPT, or Codex read your log and suggest workout and meal plans. '
            'It works through MCP. Your records stay on this phone; the AI gets only the answers it asks for, '
            'only from the data you switch on below, and only while access is on.',
            style: t.bodyMedium?.copyWith(color: p.inkSoft),
          ),
          if (pending.isNotEmpty) ...[
            const SectionHeader('Waiting for your review', top: Space.l),
            for (final pr in pending)
              Padding(
                padding: const EdgeInsets.only(bottom: Space.s),
                child: AppCard(
                  color: p.brandSoft,
                  onTap: () => context.push('/me/ai/proposal/${pr.id}'),
                  child: Row(
                    children: [
                      IconBadge(
                        pr.kind == ProposalKind.workoutPlan ? LucideIcons.dumbbell : LucideIcons.utensils,
                        color: p.surface,
                        glyph: p.brand,
                        size: 44,
                      ),
                      const SizedBox(width: Space.m),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pr.kind == ProposalKind.workoutPlan
                                  ? 'Workout plan from ${pr.client}'
                                  : 'Meal plan from ${pr.client}',
                              style: t.titleSmall,
                            ),
                            Text(pr.summary, maxLines: 2, overflow: TextOverflow.ellipsis, style: t.bodySmall),
                          ],
                        ),
                      ),
                      Icon(LucideIcons.chevronRight, size: IconSizes.s, color: p.inkSoft),
                    ],
                  ),
                ),
              ),
          ],
          const SectionHeader('What the AI may use', top: Space.l),
          AppCard(
            padding: const EdgeInsets.symmetric(vertical: Space.xs),
            child: Column(
              children: [
                for (final scope in aiScopeNames)
                  SwitchListTile(
                    title: Text(_scopeTitle(scope)),
                    subtitle: Text(contract?.scopes[scope] ?? ''),
                    value: settings.aiScopes.contains(scope),
                    onChanged: (v) => ref.read(settingsRepoProvider).setAiScope(scope, v),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: Space.s),
            child: StatusLine(
              icon: LucideIcons.shieldCheck,
              text:
                  'All start off. The exercise library and an overview of what you share are always available. '
                  'Plans the AI sends wait for your approval; it cannot change or delete records.',
            ),
          ),
          const SectionHeader('On this Wi-Fi', top: Space.xl),
          _WifiCard(ai: ai, onCopy: _copy, pickDuration: _pickDuration),
          const SectionHeader('Online, through your own gateway', top: Space.xl),
          _OnlineCard(
            ai: ai,
            gateway: _gateway,
            error: _gatewayError,
            onCopy: _copy,
            pickDuration: _pickDuration,
            reload: _loadGateway,
          ),
          const SectionHeader('Without a connection', top: Space.xl),
          AppCard(
            onTap: () => context.push('/me/ai/file'),
            semanticLabel: 'Share a file or import a plan',
            child: ExcludeSemantics(
              child: Row(
                children: [
                  Icon(LucideIcons.fileJson, color: context.pal.brand),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Share a file or import a plan', style: Theme.of(context).textTheme.titleSmall),
                        Text(
                          'Export chosen data for any AI app or the desktop MCP server, and paste back a plan.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Icon(LucideIcons.chevronRight, size: IconSizes.s, color: context.pal.inkSoft),
                ],
              ),
            ),
          ),
          if (ai.activity.isNotEmpty) ...[
            const SectionHeader('Activity on this phone', top: Space.xl),
            AppCard(
              padding: const EdgeInsets.symmetric(vertical: Space.xs),
              child: Column(children: [for (final e in ai.activity.take(15)) _ActivityTile(e)]),
            ),
            Padding(
              padding: const EdgeInsets.only(top: Space.s),
              child: StatusLine(
                icon: LucideIcons.eyeOff,
                text: 'Only tool names and times are kept, in memory, until you close Reparc. Requests and answers are never logged.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _scopeTitle(String scope) => switch (scope) {
  'gym' => 'Workouts',
  'meal' => 'Meals',
  'health' => 'Health data',
  'plans' => 'Plan suggestions',
  _ => scope,
};

String _until(DateTime? until) => until == null ? '' : 'On until ${DateFormat.jm().format(until)}';

class _WifiCard extends ConsumerWidget {
  const _WifiCard({required this.ai, required this.onCopy, required this.pickDuration});
  final AiState ai;
  final Future<void> Function(String, String) onCopy;
  final Future<Duration?> Function(String) pickDuration;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final ctl = ref.read(aiControllerProvider.notifier);
    final url = ai.wifiUrl;
    final key = ai.wifiKey;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconBadge(
                LucideIcons.wifi,
                color: ai.wifiOn ? p.greenSoft : p.surfaceAlt,
                glyph: ai.wifiOn ? p.green : p.inkSoft,
                size: 44,
              ),
              const SizedBox(width: Space.m),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ai.wifiOn ? 'Open to this network' : 'Off', style: t.titleMedium),
                    Text(
                      ai.wifiOn ? _until(ai.wifiUntil) : 'For AI apps on a computer on the same Wi-Fi.',
                      style: t.bodySmall?.copyWith(color: p.inkSoft),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Space.m),
          if (ai.wifiError != null) ...[
            StatusLine(icon: LucideIcons.triangleAlert, text: ai.wifiError!, color: p.warning),
            const SizedBox(height: Space.m),
          ],
          if (ai.wifiOn && url != null && key != null) ...[
            _CopyRow(label: 'Server address', value: url, onCopy: () => onCopy(url, 'Address')),
            _CopyRow(label: 'Access key', value: key, secret: true, onCopy: () => onCopy(key, 'Key')),
            const SizedBox(height: Space.s),
            Text('Add it to your AI app', style: t.titleSmall),
            const SizedBox(height: Space.xs),
            Wrap(
              spacing: Space.s,
              runSpacing: Space.s,
              children: [
                for (final (name, snippet) in wifiSnippets(url, key))
                  ActionChip(
                    avatar: const Icon(LucideIcons.copy, size: 16),
                    label: Text(name),
                    onPressed: () => onCopy(snippet, '$name setup'),
                  ),
              ],
            ),
            const SizedBox(height: Space.m),
            StatusLine(
              icon: LucideIcons.info,
              text:
                  'Keep Reparc open; the screen stays on while access is on. Cloud apps such as claude.ai and ChatGPT '
                  'cannot reach a phone on your Wi-Fi; use the online gateway for those.',
            ),
            const SizedBox(height: Space.s),
            StatusLine(
              icon: LucideIcons.lock,
              text:
                  'Inside your network the connection is not encrypted. Use it only on Wi-Fi you trust, such as home. '
                  'On public Wi-Fi, use the online gateway (HTTPS).',
              color: p.warning,
            ),
            const SizedBox(height: Space.m),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await confirmAction(
                        context,
                        title: 'Make a new key?',
                        body: 'AI apps that use the current key stop working until you paste the new one.',
                        confirmLabel: 'New key',
                      );
                      if (ok) await ctl.rotateWifiKey();
                    },
                    icon: const Icon(LucideIcons.refreshCw, size: 18),
                    label: const Text('New key'),
                  ),
                ),
                const SizedBox(width: Space.s),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: ctl.stopWifi,
                    icon: const Icon(LucideIcons.power, size: 18),
                    label: const Text('Turn off'),
                  ),
                ),
              ],
            ),
          ] else
            FilledButton.icon(
              onPressed: () async {
                final d = await pickDuration('Open to this Wi-Fi for');
                if (d != null) await ctl.startWifi(d);
              },
              icon: const Icon(LucideIcons.wifi, size: 18),
              label: const Text('Turn on'),
            ),
        ],
      ),
    );
  }
}

/// Copy-ready setup for common MCP clients that run on a computer.
List<(String, String)> wifiSnippets(String url, String key) => [
  ('Claude Code', 'claude mcp add --transport http reparc $url --header "Authorization: Bearer $key"'),
  (
    'Codex',
    '# ~/.codex/config.toml\n[mcp_servers.reparc]\nurl = "$url"\nhttp_headers = { "Authorization" = "Bearer $key" }',
  ),
  (
    'Cursor / VS Code',
    '{\n  "mcpServers": {\n    "reparc": {\n      "type": "http",\n      "url": "$url",\n      "headers": { "Authorization": "Bearer $key" }\n    }\n  }\n}',
  ),
  (
    'Claude Desktop',
    '{\n  "mcpServers": {\n    "reparc": {\n      "command": "npx",\n      "args": ["-y", "mcp-remote", "$url", "--allow-http", "--header", "Authorization:Bearer $key"]\n    }\n  }\n}',
  ),
];

class _OnlineCard extends ConsumerWidget {
  const _OnlineCard({
    required this.ai,
    required this.gateway,
    required this.error,
    required this.onCopy,
    required this.pickDuration,
    required this.reload,
  });

  final AiState ai;
  final GatewayState? gateway;
  final String? error;
  final Future<void> Function(String, String) onCopy;
  final Future<Duration?> Function(String) pickDuration;
  final Future<void> Function() reload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final ctl = ref.read(aiControllerProvider.notifier);
    final mcp = ai.onlineMcpUrl;

    if (ai.gatewayUrl == null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconBadge(LucideIcons.cloud, color: p.brandSoft, glyph: p.brand, size: 44),
                const SizedBox(width: Space.m),
                Expanded(
                  child: Text(
                    'Works with AI apps anywhere, including claude.ai and ChatGPT. The gateway is yours: it runs in your '
                    'own free Vercel account, and only you hold its key. It stores no records.',
                    style: t.bodySmall,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Space.m),
            FilledButton.icon(
              onPressed: () => context.push('/me/ai/setup'),
              icon: const Icon(LucideIcons.rocket, size: 18),
              label: const Text('Set up my gateway (about 5 minutes)'),
            ),
          ],
        ),
      );
    }

    final status = switch (ai.relay) {
      RelayStatus.online => ('Connected. AI apps can ask now.', p.success, LucideIcons.circleCheck),
      RelayStatus.connecting => ('Connecting…', p.inkSoft, LucideIcons.loader),
      RelayStatus.retrying => (
        ai.relayMessage ?? 'Connection problem. Retrying.',
        p.warning,
        LucideIcons.triangleAlert,
      ),
      RelayStatus.stopped => (
        ai.relayMessage ?? 'Off. AI apps get "phone not connected".',
        ai.relayMessage == null ? p.inkSoft : p.error,
        LucideIcons.circlePause,
      ),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconBadge(
                    LucideIcons.cloud,
                    color: ai.onlineOn ? p.greenSoft : p.surfaceAlt,
                    glyph: ai.onlineOn ? p.green : p.inkSoft,
                    size: 44,
                  ),
                  const SizedBox(width: Space.m),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ai.gatewayUrl!.host, style: t.titleMedium, overflow: TextOverflow.ellipsis),
                        Text(
                          ai.onlineOn ? _until(ai.onlineUntil) : 'Your gateway',
                          style: t.bodySmall?.copyWith(color: p.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: Space.m),
              StatusLine(icon: status.$3, text: status.$1, color: status.$2),
              const SizedBox(height: Space.m),
              if (mcp != null)
                _CopyRow(label: 'MCP address for your AI app', value: mcp, onCopy: () => onCopy(mcp, 'MCP address')),
              const SizedBox(height: Space.s),
              ai.onlineOn
                  ? FilledButton.icon(
                      onPressed: ctl.stopOnline,
                      icon: const Icon(LucideIcons.power, size: 18),
                      label: const Text('Turn off'),
                    )
                  : FilledButton.icon(
                      onPressed: () async {
                        final d = await pickDuration('Allow online access for');
                        if (d != null) await ctl.startOnline(d);
                      },
                      icon: const Icon(LucideIcons.cloud, size: 18),
                      label: const Text('Turn on'),
                    ),
              const SizedBox(height: Space.s),
              StatusLine(
                icon: LucideIcons.info,
                text:
                    'In your AI app, add a custom connector or remote MCP server with this address. A browser page shows a '
                    '4-letter code; approve the same code here. Keep Reparc open while the AI works.',
              ),
            ],
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: Space.s),
          StatusLine(icon: LucideIcons.triangleAlert, text: error!, color: p.warning),
        ],
        if ((gateway?.requests ?? const []).isNotEmpty) ...[
          const SectionHeader('Sign-in requests', top: Space.l),
          for (final r in gateway!.requests)
            Padding(
              padding: const EdgeInsets.only(bottom: Space.s),
              child: AppCard(
                color: p.orangeSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('${r.client} wants to connect', style: t.titleSmall),
                    const SizedBox(height: Space.xs),
                    Text('Approve only if your browser shows this code and you started this.', style: t.bodySmall),
                    const SizedBox(height: Space.s),
                    Semantics(
                      label: 'Code ${r.match.split('').join(' ')}',
                      child: ExcludeSemantics(
                        child: Text(
                          r.match,
                          style: t.headlineMedium?.copyWith(letterSpacing: 8),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const SizedBox(height: Space.s),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final api = await ctl.api();
                              await api?.decide(r.id, approve: false);
                              await reload();
                            },
                            child: const Text('Deny'),
                          ),
                        ),
                        const SizedBox(width: Space.s),
                        Expanded(
                          child: FilledButton(
                            onPressed: () async {
                              final api = await ctl.api();
                              try {
                                await api?.decide(r.id, approve: true);
                                if (context.mounted) showMessage(context, '${r.client} is connected.');
                              } on GatewayException catch (e) {
                                if (context.mounted) showMessage(context, e.message);
                              }
                              await reload();
                            },
                            child: const Text('Approve'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
        const SectionHeader('AI apps with access', top: Space.l),
        AppCard(
          padding: const EdgeInsets.symmetric(vertical: Space.xs),
          child: Column(
            children: [
              if ((gateway?.apps ?? const []).isEmpty)
                const ListTile(title: Text('None yet'), subtitle: Text('Apps you approve appear here.')),
              for (final a in gateway?.apps ?? const <GatewayApp>[])
                ListTile(
                  leading: Icon(a.kind == 'key' ? LucideIcons.keyRound : LucideIcons.bot),
                  title: Text(a.name),
                  subtitle: Text(
                    a.lastUsedAt == null
                        ? 'Not used yet'
                        : 'Last used ${DateFormat.MMMd().add_jm().format(a.lastUsedAt!)}',
                  ),
                  trailing: TextButton(
                    style: TextButton.styleFrom(foregroundColor: p.error),
                    onPressed: () async {
                      final ok = await confirmAction(
                        context,
                        title: 'Remove ${a.name}?',
                        body: 'It loses access at once. You can connect it again later.',
                        confirmLabel: 'Remove',
                        destructive: true,
                      );
                      if (!ok) return;
                      final api = await ctl.api();
                      await api?.revoke(a.id);
                      await reload();
                    },
                    child: const Text('Remove'),
                  ),
                ),
              const Divider(),
              ListTile(
                leading: const Icon(LucideIcons.keyRound),
                title: const Text('Create a key'),
                subtitle: const Text('For an AI app that cannot sign in through a browser'),
                onTap: () async {
                  final name = await promptText(
                    context,
                    title: 'Name this key',
                    label: 'For example: Codex on laptop',
                    confirmLabel: 'Create',
                  );
                  if (name == null || name.trim().isEmpty) return;
                  final api = await ctl.api();
                  try {
                    final key = await api!.createKey(name.trim());
                    await reload();
                    if (context.mounted) await _showKey(context, key, ai.onlineMcpUrl!);
                  } on GatewayException catch (e) {
                    if (context.mounted) showMessage(context, e.message);
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: Space.s),
        TextButton(
          onPressed: () async {
            final ok = await confirmAction(
              context,
              title: 'Forget this gateway?',
              body:
                  'This phone stops using it. The Vercel project stays in your Vercel account until you delete it there. '
                  'You need the owner key from Vercel to connect again.',
              confirmLabel: 'Forget',
              destructive: true,
            );
            if (ok) await ctl.forgetGateway();
          },
          child: const Text('Forget this gateway'),
        ),
      ],
    );
  }

  Future<void> _showKey(BuildContext context, String key, String mcp) => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Copy this key now'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Reparc shows it only once. Give your AI app the address and this header:'),
          const SizedBox(height: Space.s),
          SelectableText(
            '$mcp\nAuthorization: Bearer $key',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: key)),
          child: const Text('Copy key'),
        ),
        TextButton(
          onPressed: () => Clipboard.setData(ClipboardData(text: '$mcp/$key')),
          child: const Text('Copy secret link'),
        ),
        FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
      ],
    ),
  );
}

class _CopyRow extends StatelessWidget {
  const _CopyRow({required this.label, required this.value, required this.onCopy, this.secret = false});
  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool secret;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final shown = secret ? '${value.substring(0, 8)}••••••••${value.substring(value.length - 4)}' : value;
    return Padding(
      padding: const EdgeInsets.only(bottom: Space.s),
      child: Material(
        color: p.surfaceAlt,
        borderRadius: Radii.small,
        child: InkWell(
          borderRadius: Radii.small,
          onTap: onCopy,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Space.m, vertical: Space.s),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label, style: t.labelSmall?.copyWith(color: p.inkSoft)),
                      Text(
                        shown,
                        style: t.bodyMedium?.copyWith(fontFamily: 'monospace'),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Semantics(label: 'Copy $label', button: true, child: const Icon(LucideIcons.copy, size: 18)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile(this.e);
  final ActivityEntry e;

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    return ListTile(
      dense: true,
      leading: Icon(e.ok ? LucideIcons.check : LucideIcons.ban, size: 18, color: e.ok ? p.success : p.inkSoft),
      title: Text(e.tool.replaceAll('_', ' ')),
      subtitle: Text('${e.client} · ${e.via == 'wifi' ? 'Wi-Fi' : 'online'}'),
      trailing: Text(DateFormat.jm().format(e.at)),
    );
  }
}

class _DurationSheet extends StatelessWidget {
  const _DurationSheet({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    String label(Duration d) =>
        d.inMinutes < 60 ? '${d.inMinutes} minutes' : '${d.inHours} hour${d.inHours == 1 ? '' : 's'}';
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Space.l),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: Space.xs),
            const Text('Access turns off by itself after this time. You can turn it off sooner.'),
            const SizedBox(height: Space.m),
            for (final d in accessDurations)
              ListTile(
                leading: const Icon(LucideIcons.timer),
                title: Text(label(d)),
                onTap: () => Navigator.pop(context, d),
              ),
          ],
        ),
      ),
    );
  }
}
