import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/clock.dart';
import '../../core/dates.dart';
import '../../core/palette.dart';
import '../../core/tokens.dart';
import '../../core/widgets.dart';
import '../../data/backup.dart';
import '../../data/providers.dart';
import 'app_updates_screen.dart';

/// Me → Backup and restore (handbook 8.6, D-021).
///
/// Two layers, both in the user's own Apple or Google account:
/// 1. The phone's own backup (iCloud Backup, or Android backup to Google
///    Drive) includes Reparc's database. It runs by itself when the user has
///    phone backup on.
/// 2. An encrypted backup file the user saves where they choose, for
///    example iCloud Drive or Google Drive, and can restore on any phone.
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _busy = false;
  String? _status;

  Future<String?> _passphrase({required bool create}) => showDialog<String>(
    context: context,
    builder: (_) => _PassphraseDialog(create: create),
  );

  Future<void> _backup() async {
    final pass = await _passphrase(create: true);
    if (pass == null || !mounted) return;
    setState(() => (_busy = true, _status = 'Encrypting…'));
    try {
      final info = await ref.read(packageInfoProvider.future);
      final json = await ref.read(dataControlsProvider).exportJson(appVersion: '${info.version}+${info.buildNumber}');
      final bytes = await BackupCrypto.seal(json, pass);
      final day = dayKey(ref.read(clockProvider)());
      setState(() => _status = 'Choose where to save it…');
      final saved = await FilePicker.saveFile(
        dialogTitle: 'Save Reparc backup',
        fileName: 'reparc-$day.${BackupCrypto.extension}',
        bytes: bytes,
      );
      if (saved == null) {
        setState(() => _status = 'Not saved. You closed the save screen.');
        return;
      }
      await ref.read(settingsRepoProvider).setLastBackupAt(ref.read(clockProvider)());
      setState(() => _status = 'Backup saved.');
    } catch (_) {
      setState(() => _status = 'The backup failed. Your records are not changed. Try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _restore() async {
    final ok = await confirmAction(
      context,
      title: 'Restore from a backup?',
      body:
          'Every workout, plan, meal, and setting on this phone is replaced by the backup. '
          'Make a backup of this phone first if you want to keep its records.',
      confirmLabel: 'Choose file',
      destructive: true,
    );
    if (!ok || !mounted) return;
    final file = await FilePicker.pickFile(dialogTitle: 'Choose a Reparc backup');
    if (file == null || !mounted) return;
    final Uint8List bytes = await file.readAsBytes();
    final pass = await _passphrase(create: false);
    if (pass == null || !mounted) return;
    setState(() => (_busy = true, _status = 'Decrypting…'));
    try {
      final json = await BackupCrypto.open(bytes, pass);
      final n = await ref.read(dataControlsProvider).importJson(json);
      setState(() => _status = 'Restored $n records. Switch on health and AI access again if you use them.');
    } on BackupException catch (e) {
      setState(() => _status = e.message);
    } catch (_) {
      setState(() => _status = 'This backup could not be restored. Nothing on this phone was changed.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.pal;
    final t = Theme.of(context).textTheme;
    final last = ref.watch(currentSettingsProvider).lastBackupAt;
    final ios = Platform.isIOS;

    return Scaffold(
      appBar: AppBar(title: const Text('Backup and restore')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Space.l, Space.s, Space.l, Space.xxl),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    IconBadge(
                      ios ? LucideIcons.cloud : LucideIcons.hardDrive,
                      color: p.blueSoft,
                      glyph: p.blue,
                      size: 44,
                    ),
                    const SizedBox(width: Space.m),
                    Expanded(child: Text(ios ? 'iCloud Backup' : 'Google backup', style: t.titleMedium)),
                  ],
                ),
                const SizedBox(height: Space.m),
                Text(
                  ios
                      ? 'When iCloud Backup is on for this iPhone, it includes Reparc\'s records. Restore the iPhone from '
                            'iCloud, and Reparc comes back with them. Check it in Settings → your name → iCloud → iCloud Backup.'
                      : 'When Google backup is on for this phone, Android saves Reparc\'s records to your Google Drive with '
                            'your other app data, encrypted with your screen lock. Install Reparc on a new phone signed in to '
                            'the same Google account and restore during setup. Check it in Settings → Google → Backup.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: Space.s),
                StatusLine(
                  icon: LucideIcons.info,
                  text: 'This copy moves only between phones of the same kind. To move from iPhone to Android or back, use a backup file.',
                ),
              ],
            ),
          ),
          const SectionHeader('Encrypted backup file'),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Saves all your records in one file, encrypted with a passphrase you choose. Save it to '
                  '${ios ? 'iCloud Drive' : 'Google Drive'} or anywhere else, and restore it on any iPhone or Android phone.',
                  style: t.bodyMedium,
                ),
                const SizedBox(height: Space.s),
                Text(
                  last == null
                      ? 'No backup file made yet.'
                      : 'Last backup file: ${DateFormat.yMMMd().add_jm().format(last.toLocal())}',
                  style: t.bodySmall?.copyWith(color: p.inkSoft),
                ),
                const SizedBox(height: Space.m),
                FilledButton.icon(
                  onPressed: _busy ? null : _backup,
                  icon: const Icon(LucideIcons.cloudUpload, size: 18),
                  label: const Text('Back up now'),
                ),
                const SizedBox(height: Space.s),
                OutlinedButton.icon(
                  onPressed: _busy ? null : _restore,
                  icon: const Icon(LucideIcons.cloudDownload, size: 18),
                  label: const Text('Restore from a file'),
                ),
                if (_busy) ...[const SizedBox(height: Space.m), const LinearProgressIndicator()],
                if (_status != null) ...[
                  const SizedBox(height: Space.m),
                  Semantics(liveRegion: true, child: Text(_status!, style: t.bodyMedium)),
                ],
                const SizedBox(height: Space.m),
                StatusLine(
                  icon: LucideIcons.keyRound,
                  text: 'Only your passphrase opens the file: not Apple, Google, or Reparc. If you forget it, the file cannot be opened.',
                  color: p.warning,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PassphraseDialog extends StatefulWidget {
  const _PassphraseDialog({required this.create});
  final bool create;

  @override
  State<_PassphraseDialog> createState() => _PassphraseDialogState();
}

class _PassphraseDialogState extends State<_PassphraseDialog> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    super.dispose();
  }

  void _submit() {
    if (_a.text.length < BackupCrypto.minPassphrase) {
      setState(
        () => _error = 'Use at least ${BackupCrypto.minPassphrase} characters. A few unrelated words work well.',
      );
      return;
    }
    if (widget.create && _a.text != _b.text) {
      setState(() => _error = 'The two passphrases do not match.');
      return;
    }
    Navigator.pop(context, _a.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.create ? 'Choose a passphrase' : 'Enter the passphrase'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _a,
            obscureText: true,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            decoration: const InputDecoration(labelText: 'Passphrase'),
          ),
          if (widget.create)
            TextField(
              controller: _b,
              obscureText: true,
              autocorrect: false,
              enableSuggestions: false,
              decoration: const InputDecoration(labelText: 'Type it again'),
              onSubmitted: (_) => _submit(),
            ),
          if (_error != null) ...[
            const SizedBox(height: Space.s),
            Text(_error!, style: TextStyle(color: context.pal.error)),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: Text(widget.create ? 'Encrypt' : 'Open')),
      ],
    );
  }
}
