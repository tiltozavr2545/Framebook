import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/sync/google_account.dart';
import '../../data/sync/sync_controller.dart';
import '../../data/sync/sync_engine.dart';
import '../../data/sync/sync_file.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';

/// Settings → Sync and backup: Google Drive, its daily copies, and export /
/// import to a file (docs/sync.md).
class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(syncControllerProvider);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsSync)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Section(l10n.syncDrive),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(l10n.syncIntro, style: muted),
          ),
          if (!status.configured)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.syncNotConfigured),
            )
          else if (status.account == null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.icon(
                  onPressed: status.busy ? null : () => _signIn(context, ref),
                  icon: const Icon(Icons.login),
                  label: Text(l10n.syncSignIn),
                ),
              ),
            )
          else ...[
            ListTile(
              leading: const Icon(Icons.account_circle_outlined),
              title: Text(l10n.syncSignedInAs(status.account!)),
              subtitle: Text(
                status.busy
                    ? l10n.syncInProgress
                    : status.lastSyncAt == null
                    ? l10n.syncNever
                    : l10n.syncLast(context.formatDateTime(status.lastSyncAt!)),
              ),
            ),
            if (status.error case final error?)
              _ErrorNote(
                failure: error,
                onSignInAgain: () => _signIn(context, ref),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: status.busy
                        ? null
                        : () =>
                              ref.read(syncControllerProvider.notifier).sync(),
                    icon: status.busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(l10n.syncNow),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        ref.read(syncControllerProvider.notifier).signOut(),
                    child: Text(l10n.syncSignOut),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: Text(l10n.syncBackups),
              subtitle: Text(l10n.syncBackupsHint),
              onTap: () => _showBackups(context, ref),
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: theme.colorScheme.error,
              ),
              title: Text(
                l10n.syncDelete,
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () => _deleteDriveData(context, ref),
            ),
          ],
          const Divider(height: 32),
          _Section(l10n.backupFile),
          ListTile(
            leading: const Icon(Icons.file_upload_outlined),
            title: Text(l10n.exportFile),
            subtitle: Text(l10n.exportFileHint),
            onTap: () => _export(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(l10n.importFile),
            onTap: () => _import(context, ref),
          ),
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String text) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(syncControllerProvider.notifier);
    try {
      final first = await controller.signIn();
      if (first == null || !context.mounted) return;
      final merge = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.syncFirstTitle),
          content: Text(
            l10n.syncFirstBody(first.device, first.drive, first.merged),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.syncMerge),
            ),
          ],
        ),
      );
      if (merge ?? false) {
        await controller.confirmFirstSync();
      } else {
        await controller.signOut();
      }
    } on SignInException catch (e) {
      if (!context.mounted || e.failure == SignInFailure.canceled) return;
      _snack(
        context,
        e.failure == SignInFailure.misconfigured
            ? l10n.syncNotConfigured
            : l10n.syncSignInFailed,
      );
    } on SyncException catch (e) {
      if (!context.mounted) return;
      _snack(context, _failureText(l10n, e.failure));
    }
  }

  Future<void> _showBackups(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(syncControllerProvider.notifier);
    final List<RemoteFile> backups;
    try {
      backups = await controller.backups();
    } on SyncException catch (e) {
      if (context.mounted) _snack(context, _failureText(l10n, e.failure));
      return;
    }
    if (!context.mounted) return;
    final chosen = await showModalBottomSheet<RemoteFile>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: backups.isEmpty
            ? Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                child: Text(l10n.syncBackupsEmpty),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  for (final backup in backups)
                    ListTile(
                      leading: const Icon(Icons.restore),
                      title: Text(_backupDate(context, backup)),
                      trailing: TextButton(
                        onPressed: () => Navigator.pop(context, backup),
                        child: Text(l10n.syncRestore),
                      ),
                    ),
                ],
              ),
      ),
    );
    if (chosen == null || !context.mounted) return;
    final confirmed = await _confirm(
      context,
      title: l10n.syncRestoreTitle(_backupDate(context, chosen)),
      body: l10n.syncRestoreBody,
      action: l10n.syncRestore,
    );
    if (!confirmed) return;
    try {
      await controller.restore(chosen);
      if (context.mounted) _snack(context, l10n.syncRestored);
    } on SyncException catch (e) {
      if (context.mounted) _snack(context, _failureText(l10n, e.failure));
    }
  }

  /// `framebook-backup-2026-10-25.json.gz` → "Oct 25, 2026".
  static String _backupDate(BuildContext context, RemoteFile backup) {
    final ymd = backup.name
        .replaceFirst(SyncEngine.backupPrefix, '')
        .replaceFirst('.json.gz', '');
    return context.formatDate(ymd) ?? ymd;
  }

  Future<void> _deleteDriveData(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await _confirm(
      context,
      title: l10n.syncDeleteTitle,
      body: l10n.syncDeleteBody,
      action: l10n.ratingDelete,
    );
    if (!confirmed) return;
    try {
      await ref.read(syncControllerProvider.notifier).deleteDriveData();
      if (context.mounted) _snack(context, l10n.syncDeleted);
    } on SyncException catch (e) {
      if (context.mounted) _snack(context, _failureText(l10n, e.failure));
    }
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final bytes = await ref.read(syncControllerProvider.notifier).export();
    final day = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final saved = await FilePicker.saveFile(
      fileName: 'framebook-export-$day.json.gz',
      bytes: Uint8List.fromList(bytes),
    );
    if (saved != null && context.mounted) _snack(context, l10n.exportDone);
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(syncControllerProvider.notifier);
    final picked = await FilePicker.pickFiles(withData: true);
    final bytes = picked?.files.singleOrNull?.bytes;
    if (bytes == null || !context.mounted) return;
    final ImportPreview preview;
    try {
      preview = await controller.previewImport(bytes);
    } on SyncFileException catch (e) {
      if (context.mounted) {
        _snack(
          context,
          e is SyncFileTooNew ? l10n.importTooNew : l10n.importBroken,
        );
      }
      return;
    }
    if (!context.mounted) return;
    final replace = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importTitle),
        content: Text(
          l10n.importBody(preview.device, preview.inFile, preview.merged),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.importReplace),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.importMerge),
          ),
        ],
      ),
    );
    if (replace == null || !context.mounted) return;
    if (replace &&
        !await _confirm(
          context,
          title: l10n.importReplaceTitle,
          body: l10n.importReplaceBody,
          action: l10n.importReplace,
        )) {
      return;
    }
    await controller.import(preview.file, replace: replace);
    if (context.mounted) _snack(context, l10n.importDone);
  }

  static Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String body,
    required String action,
  }) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(AppLocalizations.of(context).cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(action),
            ),
          ],
        ),
      ) ??
      false;

  static String _failureText(AppLocalizations l10n, SyncFailure failure) =>
      switch (failure) {
        SyncFailure.offline => l10n.syncOffline,
        SyncFailure.unauthorized => l10n.syncErrorUnauthorized,
        SyncFailure.quotaExceeded => l10n.syncErrorQuota,
        SyncFailure.broken => l10n.syncErrorBroken,
        SyncFailure.tooNew => l10n.syncErrorTooNew,
        SyncFailure.failed => l10n.syncErrorFailed,
      };
}

class _ErrorNote extends StatelessWidget {
  const _ErrorNote({required this.failure, required this.onSignInAgain});

  final SyncFailure failure;
  final VoidCallback onSignInAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            SyncScreen._failureText(l10n, failure),
            style: TextStyle(color: scheme.onErrorContainer),
          ),
          if (failure == SyncFailure.unauthorized)
            TextButton(
              onPressed: onSignInAgain,
              child: Text(l10n.syncSignInAgain),
            ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
    child: Text(
      text,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );
}
