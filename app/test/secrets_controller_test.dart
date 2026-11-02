import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/sync/google_account.dart';
import 'package:framebook/data/sync/secrets_controller.dart';
import 'package:framebook/data/sync/secrets_vault.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/sync/sync_actions.dart';
import 'package:framebook/data/sync/sync_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_google.dart';
import 'support/memory_key_storage.dart';
import 'support/memory_remote.dart';

class TestSync extends SyncController {
  Future<void> Function()? onDelete;
  @override
  Future<void> deleteDriveData() => onDelete?.call() ?? Future.value();
  @override
  SyncStatus build() =>
      const SyncStatus(configured: true, account: 'me@example.com');
  void account(String value) => state = state.copyWith(account: () => value);
}

class GateGoogle extends FakeGoogleAccount {
  GateGoogle(super.remote);
  Completer<void>? entered;
  Completer<void>? release;
  @override
  Future<DriveAccess> drive() async {
    final enter = entered;
    if (enter != null) {
      entered = null;
      enter.complete();
      await release!.future;
    }
    return super.drive();
  }
}

class GateRemote extends MemoryRemote {
  int listCalls = 0;
  @override
  Future<List<RemoteFile>> list() {
    listCalls++;
    return super.list();
  }

  Completer<void>? entered;
  Completer<void>? release;
  @override
  Future<List<int>> download(String id) async {
    final data = await super.download(id);
    entered?.complete();
    entered = null;
    if (release case final gate?) await gate.future;
    return data;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MemoryKeyStorage storage;
  late GateRemote remote;
  late GateGoogle google;
  late SharedPreferences prefs;
  late ProviderContainer container;
  late TestSync sync;

  Future<void> setup({bool enabled = false}) async {
    SharedPreferences.setMockInitialValues({
      'secrets_enabled.me@example.com': enabled,
    });
    prefs = await SharedPreferences.getInstance();
    storage = MemoryKeyStorage();
    remote = GateRemote();
    google = GateGoogle(remote)..signedIn = true;
    sync = TestSync();
  }

  void start() {
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialApiKeysProvider.overrideWithValue(ApiKeys.empty),
        apiKeyStoreProvider.overrideWithValue(ApiKeyStore(storage)),
        secretsStorageProvider.overrideWithValue(storage),
        googleAccountProvider.overrideWithValue(google),
        deviceIdProvider.overrideWithValue('device'),
        syncControllerProvider.overrideWith(() => sync),
      ],
    );
    container.read(secretsControllerProvider);
  }

  Future<void> settle() async {
    for (var i = 0; i < 30; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
  }

  test('first enable preserves and uploads phone-only keys', () async {
    await setup();
    final other = SecretsVault(
      remote: remote,
      storage: MemoryKeyStorage(),
      accountId: 'other',
      deviceId: 'other',
    );
    await other.unlock('password123');
    await other.save({
      'tmdb': const SecretsKey('remote', verified: true),
    }, 'imdb');
    await other.sync(createIfMissing: true);
    start();
    await settle();
    await container
        .read(apiKeysProvider.notifier)
        .save(ApiSource.omdb, const StoredKey('local', verified: true));
    await container
        .read(secretsControllerProvider.notifier)
        .enable('password123');
    final keys = container.read(apiKeysProvider);
    expect(keys[ApiSource.tmdb]?.value, 'remote');
    expect(keys[ApiSource.omdb]?.value, 'local');
    expect((await ApiKeyStore(storage).load())[ApiSource.omdb]?.value, 'local');
    final shared = await other.sync();
    expect(shared.keys['omdb']?.value, 'local');
    expect(shared.divergenceSource, 'imdb');
    container.dispose();
  });

  test(
    'deletion suspends edits, resume and overwrite until completion',
    () async {
      await setup();
      start();
      await settle();
      final controller = container.read(secretsControllerProvider.notifier);
      await controller.enable('password123');
      await controller.prepareForDeletion();
      final calls = remote.listCalls;
      await container
          .read(apiKeysProvider.notifier)
          .save(
            ApiSource.omdb,
            const StoredKey('during-delete', verified: true),
          );
      await controller.overwrite('otherpassword');
      final binding = WidgetsBinding.instance;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await settle();
      expect(remote.listCalls, calls);
      expect(container.read(secretsControllerProvider).busy, isTrue);
      controller.cancelDeletion();
      await settle();
      expect(remote.listCalls, greaterThan(calls));
      container.dispose();
    },
  );

  test(
    'coordinated deletion releases the key gate after a remote failure',
    () async {
      await setup();
      start();
      await settle();
      final secrets = container.read(secretsControllerProvider.notifier);
      await secrets.enable('password123');
      final entered = Completer<void>(), release = Completer<void>();
      sync.onDelete = () async {
        entered.complete();
        await release.future;
        throw const SyncException(SyncFailure.offline);
      };
      final actions = SyncActions(sync, secrets);
      final deletion = actions.deleteDriveData();
      final failed = expectLater(deletion, throwsA(isA<SyncException>()));
      await entered.future;
      final calls = remote.listCalls;
      await container
          .read(apiKeysProvider.notifier)
          .save(ApiSource.omdb, const StoredKey('pending', verified: true));
      await settle();
      expect(remote.listCalls, calls);
      release.complete();
      await failed;
      await settle();
      expect(container.read(secretsControllerProvider).enabled, isTrue);
      expect(container.read(secretsControllerProvider).busy, isFalse);
      expect(remote.listCalls, greaterThan(calls));
      container.dispose();
    },
  );

  test('restore with no vault never creates one', () async {
    await setup();
    start();
    await settle();
    await expectLater(
      container
          .read(secretsControllerProvider.notifier)
          .enable('password123', createIfMissing: false),
      throwsA(isA<SecretsMissing>()),
    );
    expect(remote.files, isEmpty);
    container.dispose();
  });

  test(
    'offline edit is staged and survives restarting the controller',
    () async {
      await setup();
      start();
      await settle();
      await container
          .read(secretsControllerProvider.notifier)
          .enable('password123');
      remote.failing = SyncFailure.offline;
      await container
          .read(apiKeysProvider.notifier)
          .save(
            ApiSource.tmdb,
            const StoredKey('offline-edit', verified: true),
          );
      await settle();
      container.dispose();
      remote.failing = null;
      final vault = SecretsVault(
        remote: remote,
        storage: storage,
        accountId: 'me@example.com',
        deviceId: 'device',
      );
      final snapshot = await vault.sync();
      expect(snapshot.keys['tmdb']?.value, 'offline-edit');
    },
  );

  test(
    'account switch during unlock cannot restore keys to the new account',
    () async {
      await setup();
      final vault = SecretsVault(
        remote: remote,
        storage: storage,
        accountId: 'other-device',
        deviceId: 'other',
      );
      await vault.unlock('password123');
      await vault.save({
        'tmdb': const SecretsKey('old-account-key', verified: true),
      }, null);
      await vault.sync(createIfMissing: true);
      start();
      await settle();
      remote.entered = Completer<void>();
      remote.release = Completer<void>();
      final unlocking = container
          .read(secretsControllerProvider.notifier)
          .enable('password123');
      await remote.entered!.future;
      sync.account('other@example.com');
      remote.release!.complete();
      await unlocking;
      expect(container.read(apiKeysProvider).has(ApiSource.tmdb), isFalse);
      container.dispose();
    },
  );
  test('local edit during delayed startup sync survives', () async {
    await setup(enabled: true);
    final vault = SecretsVault(
      remote: remote,
      storage: storage,
      accountId: 'me@example.com',
      deviceId: 'device',
    );
    await vault.unlock('password123');
    await vault.save({
      'tmdb': const SecretsKey('remote', verified: true),
    }, null);
    await vault.sync(createIfMissing: true);
    remote.entered = Completer<void>();
    remote.release = Completer<void>();
    start();
    await remote.entered!.future;
    await container
        .read(apiKeysProvider.notifier)
        .save(ApiSource.tmdb, const StoredKey('new-local', verified: true));
    remote.release!.complete();
    await settle();
    expect(container.read(apiKeysProvider)[ApiSource.tmdb]?.value, 'new-local');
    final snapshot = await vault.sync();
    expect(snapshot.keys['tmdb']?.value, 'new-local');
    container.dispose();
  });

  test('deletion waits for a blocked upload', () async {
    await setup();
    start();
    await settle();
    await container
        .read(secretsControllerProvider.notifier)
        .enable('password123');
    remote.entered = Completer<void>();
    remote.release = Completer<void>();
    await container
        .read(apiKeysProvider.notifier)
        .save(ApiSource.tmdb, const StoredKey('edit', verified: true));
    await remote.entered!.future;
    var ready = false;
    final prepare = container
        .read(secretsControllerProvider.notifier)
        .prepareForDeletion()
        .then((_) {
          ready = true;
        });
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(ready, isFalse);
    remote.release!.complete();
    await prepare;
    for (final file in await remote.list()) {
      await remote.delete(file.id);
    }
    await container
        .read(secretsControllerProvider.notifier)
        .resetForDeletedDrive();
    await settle();
    expect(remote.files, isEmpty);
    container.dispose();
  });

  test(
    'disabling waits for a blocked sync before clearing its cache',
    () async {
      await setup();
      start();
      await settle();
      final controller = container.read(secretsControllerProvider.notifier);
      await controller.enable('password123');
      remote.entered = Completer<void>();
      remote.release = Completer<void>();
      await container
          .read(apiKeysProvider.notifier)
          .save(ApiSource.tmdb, const StoredKey('edit', verified: true));
      await remote.entered!.future;
      var disabled = false;
      final operation = controller.disable().then((_) => disabled = true);
      await Future<void>.delayed(const Duration(milliseconds: 30));
      expect(disabled, isFalse);
      remote.release!.complete();
      await operation;
      final vault = SecretsVault(
        remote: remote,
        storage: storage,
        accountId: 'me@example.com',
        deviceId: 'device',
      );
      expect(await vault.isUnlocked, isFalse);
      expect(container.read(secretsControllerProvider).enabled, isFalse);
      container.dispose();
    },
  );
  test('preparing a failed Drive deletion keeps key sync enabled', () async {
    await setup();
    start();
    await settle();
    final controller = container.read(secretsControllerProvider.notifier);
    await controller.enable('password123');

    final account = await controller.prepareForDeletion();

    expect(account, 'me@example.com');
    expect(container.read(secretsControllerProvider).enabled, isTrue);
    expect(prefs.getBool('secrets_enabled.me@example.com'), isTrue);
    final vault = SecretsVault(
      remote: remote,
      storage: storage,
      accountId: 'me@example.com',
      deviceId: 'device',
    );
    expect(await vault.isUnlocked, isTrue);
    container.dispose();
  });

  test('account switch while acquiring Drive prevents old upload', () async {
    await setup();
    start();
    await settle();
    await container
        .read(secretsControllerProvider.notifier)
        .enable('password123');
    google.entered = Completer<void>();
    google.release = Completer<void>();
    final gate = google.entered!;
    await container
        .read(apiKeysProvider.notifier)
        .save(ApiSource.tmdb, const StoredKey('account-a', verified: true));
    await gate.future;
    final callsBefore = remote.listCalls;
    sync.account('other@example.com');
    google.release!.complete();
    await settle();
    expect(remote.listCalls, callsBefore);
    container.dispose();
  });
}
