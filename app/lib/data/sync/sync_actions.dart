import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'secrets_controller.dart';
import 'sync_controller.dart';

/// Coordinates destructive actions across rating and encrypted-key sync.
final class SyncActions {
  SyncActions(this._sync, this._secrets);
  final SyncController _sync;
  final SecretsController _secrets;
  bool _deleting = false;

  Future<void> deleteDriveData() async {
    if (_deleting) return;
    _deleting = true;
    try {
      final account = await _secrets.prepareForDeletion();
      await _sync.deleteDriveData();
      await _secrets.resetForDeletedDrive(account);
    } catch (_) {
      _secrets.cancelDeletion();
      rethrow;
    } finally {
      _deleting = false;
    }
  }
}

final syncActionsProvider = Provider<SyncActions>(
  (ref) => SyncActions(
    ref.read(syncControllerProvider.notifier),
    ref.read(secretsControllerProvider.notifier),
  ),
);
