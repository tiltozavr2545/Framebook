import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/secrets_controller.dart';
import 'package:framebook/data/sync/sync_actions.dart';
import 'package:framebook/data/sync/sync_controller.dart';

class _Secrets extends SecretsController {
  _Secrets(this.events);
  final List<String> events;
  Completer<void>? preparing;
  bool failPrepare = false;
  bool failReset = false;

  @override
  Future<String?> prepareForDeletion() async {
    events.add('prepare');
    if (failPrepare) throw StateError('prepare failed');
    await preparing?.future;
    return 'selected-account';
  }

  @override
  Future<void> resetForDeletedDrive([String? selectedAccount]) async {
    events.add('reset:$selectedAccount');
    if (failReset) throw StateError('reset failed');
  }

  @override
  void cancelDeletion() => events.add('cancel');
}

class _Sync extends SyncController {
  _Sync(this.events);
  final List<String> events;
  bool fail = false;
  Completer<void>? deleting;

  @override
  Future<void> deleteDriveData() async {
    events.add('delete');
    if (fail) throw StateError('delete failed');
    await deleting?.future;
  }
}

void main() {
  late List<String> events;
  late _Secrets secrets;
  late _Sync sync;
  late SyncActions actions;
  setUp(() {
    events = [];
    secrets = _Secrets(events);
    sync = _Sync(events);
    actions = SyncActions(sync, secrets);
  });

  test(
    'deletion waits for key sync, then resets the selected account',
    () async {
      secrets.preparing = Completer<void>();
      sync.deleting = Completer<void>();
      final operation = actions.deleteDriveData();
      await pumpEventQueue();
      expect(events, ['prepare']);
      secrets.preparing!.complete();
      await pumpEventQueue();
      expect(events, ['prepare', 'delete']);
      sync.deleting!.complete();
      await operation;
      expect(events, ['prepare', 'delete', 'reset:selected-account']);
    },
  );

  test('repeated taps cannot start concurrent deletion', () async {
    secrets.preparing = Completer<void>();
    final operation = actions.deleteDriveData();
    await actions.deleteDriveData();
    expect(events, ['prepare']);
    secrets.preparing!.complete();
    await operation;
    await actions.deleteDriveData();
    expect(events, [
      'prepare',
      'delete',
      'reset:selected-account',
      'prepare',
      'delete',
      'reset:selected-account',
    ]);
  });

  for (final stage in ['prepare', 'delete', 'reset']) {
    test(
      'a $stage failure propagates, releases the guard and allows retry',
      () async {
        secrets.failPrepare = stage == 'prepare';
        sync.fail = stage == 'delete';
        secrets.failReset = stage == 'reset';
        await expectLater(actions.deleteDriveData(), throwsStateError);
        expect(events, [
          'prepare',
          if (stage != 'prepare') 'delete',
          if (stage == 'reset') 'reset:selected-account',
          'cancel',
        ]);
        secrets.failPrepare = sync.fail = secrets.failReset = false;
        events.clear();
        await actions.deleteDriveData();
        expect(events, ['prepare', 'delete', 'reset:selected-account']);
      },
    );
  }
}
