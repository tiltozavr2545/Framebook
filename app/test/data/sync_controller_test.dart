import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/sync/google_account.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/sync/sync_engine.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/fake_google.dart';
import '../support/memory_remote.dart';

/// A Google account whose first Drive token turns out to be expired.
final class _ExpiringGoogle extends FakeGoogleAccount {
  _ExpiringGoogle(super.remote);

  var expired = 0;

  @override
  Future<DriveAccess> drive() async {
    final access = await super.drive();
    if (expired > 0) return access;
    return (
      remote: _Unauthorized() as SyncRemote,
      expire: () async => expired++,
    );
  }
}

final class _Unauthorized extends MemoryRemote {
  @override
  SyncFailure? get failing => SyncFailure.unauthorized;
}

final class _UnavailableRestoreGoogle extends FakeGoogleAccount {
  _UnavailableRestoreGoogle(super.remote);

  var driveCalls = 0;

  @override
  Future<String?> restore() async => null;

  @override
  Future<DriveAccess> drive() async {
    driveCalls++;
    return super.drive();
  }
}

final class _BlockingRemote extends MemoryRemote {
  Completer<void>? entered;
  Completer<void>? release;

  @override
  Future<RemoteFile> update(String id, List<int> bytes) async {
    if (entered case final signal?) {
      entered = null;
      signal.complete();
      await release!.future;
    }
    return super.update(id, bytes);
  }
}

final class _FailingDeleteRemote extends MemoryRemote {
  final entered = Completer<void>();
  final release = Completer<void>();
  final uploaded = Completer<void>();

  @override
  Future<RemoteFile> update(String id, List<int> bytes) async {
    final result = await super.update(id, bytes);
    if (SyncFile.decode(bytes).liveRatings == 2 && !uploaded.isCompleted) {
      uploaded.complete();
    }
    return result;
  }

  @override
  Future<void> delete(String id) async {
    entered.complete();
    await release.future;
    throw const SyncException(SyncFailure.failed);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late List<AppDatabase> databases;

  setUp(() => databases = []);
  tearDown(() async {
    for (final db in databases) {
      await db.close();
    }
  });

  Future<(ProviderContainer, Library)> device(
    String id,
    GoogleAccount google, {
    Duration debounce = SyncController.debounce,
    String? storedAccount,
  }) async {
    SharedPreferences.setMockInitialValues({
      if (storedAccount != null) 'sync_account': storedAccount,
    });
    final db = AppDatabase(NativeDatabase.memory());
    databases.add(db);
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        deviceIdProvider.overrideWithValue(id),
        sharedPreferencesProvider.overrideWithValue(
          await SharedPreferences.getInstance(),
        ),
        googleAccountProvider.overrideWithValue(google),
        appVersionProvider.overrideWithValue('test'),
        syncDebounceProvider.overrideWithValue(debounce),
      ],
    );
    addTearDown(container.dispose);
    container.listen(syncControllerProvider, (_, _) {});
    // Let it read its last sync before the test can close the database.
    await pumpEventQueue();
    return (container, Library(db, deviceId: id));
  }

  final film = [
    const WorkSnapshot(key: WorkKey.movie(603), tmdbId: 603, title: 'Matrix'),
  ];
  final other = [
    const WorkSnapshot(key: WorkKey.movie(27205), tmdbId: 27205, title: 'Inc'),
  ];

  test('an export imports elsewhere by merging', () async {
    final (a, libraryA) = await device('a', FakeGoogleAccount(MemoryRemote()));
    final (b, libraryB) = await device('b', FakeGoogleAccount(MemoryRemote()));
    await libraryA.rate(film, scoreHalf: 17, note: 'Классика');
    await libraryB.rate(other, scoreHalf: 12, note: null);

    final bytes = await a.read(syncControllerProvider.notifier).export();
    final preview = await b
        .read(syncControllerProvider.notifier)
        .previewImport(bytes);
    expect((preview.device, preview.inFile, preview.merged), (1, 1, 2));

    await b
        .read(syncControllerProvider.notifier)
        .import(preview.file, replace: false);
    final state = await SyncStore(databases[1]).read();
    expect(state.liveRatings, 2);
    expect(
      state.ratings.firstWhere((r) => r.workKey == 'tmdb:movie:603').note,
      'Классика',
    );
  });

  test('importing with "replace everything" deletes the rest', () async {
    final (a, libraryA) = await device('a', FakeGoogleAccount(MemoryRemote()));
    final (b, libraryB) = await device('b', FakeGoogleAccount(MemoryRemote()));
    await libraryA.rate(film, scoreHalf: 17, note: null);
    await libraryB.rate(other, scoreHalf: 12, note: null);

    final bytes = await a.read(syncControllerProvider.notifier).export();
    final preview = await b
        .read(syncControllerProvider.notifier)
        .previewImport(bytes);
    await b
        .read(syncControllerProvider.notifier)
        .import(preview.file, replace: true);
    final state = await SyncStore(databases[1]).read();
    expect(
      [
        for (final r in state.ratings)
          if (r.deletedAt == null) r.workKey,
      ],
      ['tmdb:movie:603'],
    );
  });

  test('import asks again when a new conflicting row appears', () async {
    final (container, library) = await device(
      'b',
      FakeGoogleAccount(MemoryRemote()),
    );
    final controller = container.read(syncControllerProvider.notifier);
    await library.rate(film, scoreHalf: 17, note: null);
    final future = DateTime.now().millisecondsSinceEpoch + 60000;
    final file = SyncState(
      ratingDeletions: [
        DeletionRecord(
          workKey: 'tmdb:movie:603',
          updatedAt: future,
          updatedBy: 'a',
          tieBreak: '0' * 64,
        ),
        DeletionRecord(
          workKey: 'tmdb:movie:27205',
          updatedAt: future,
          updatedBy: 'a',
          tieBreak: '0' * 64,
        ),
      ],
    );
    final bytes = SyncFile.encode(
      file,
      writtenAt: future,
      writtenBy: 'a',
      appVersion: 'test',
    );
    final first = await controller.previewImport(bytes);
    expect(first.stale, 1);
    await library.rate(other, scoreHalf: 12, note: null);
    final next = await controller.import(
      first.file,
      replace: false,
      keepStale: false,
      reviewedFingerprint: first.fingerprint,
    );
    expect(next?.stale, 2);
    expect((await SyncStore(databases.single).read()).liveRatings, 2);
    final result = await controller.import(
      next!.file,
      replace: false,
      keepStale: false,
      reviewedFingerprint: next.fingerprint,
    );
    expect(result, isNull);
    expect((await SyncStore(databases.single).read()).liveRatings, 0);
  });

  test('a broken or newer import file is refused', () async {
    final (a, _) = await device('a', FakeGoogleAccount(MemoryRemote()));
    final controller = a.read(syncControllerProvider.notifier);
    await expectLater(
      controller.previewImport([1, 2, 3]),
      throwsA(isA<SyncFileBroken>()),
    );
  });

  test('a failure is kept for the screen; no connection is not', () async {
    final remote = MemoryRemote();
    final google = FakeGoogleAccount(remote);
    final (a, library) = await device('a', google);
    await library.rate(film, scoreHalf: 17, note: null);
    final controller = a.read(syncControllerProvider.notifier);
    await controller.signIn();
    expect(a.read(syncControllerProvider).error, isNull);
    expect(a.read(syncControllerProvider).lastSyncAt, isNotNull);
    expect(remote.names, [SyncFile.name]);

    remote.failing = SyncFailure.quotaExceeded;
    await controller.sync();
    expect(a.read(syncControllerProvider).error, SyncFailure.quotaExceeded);
    expect(
      await SyncStore(databases.single).stateValue('last_sync_error'),
      'quotaExceeded',
    );

    remote.failing = SyncFailure.offline;
    await controller.sync();
    // Offline is quietly put off: the screen keeps showing the last error.
    expect(a.read(syncControllerProvider).error, SyncFailure.quotaExceeded);

    remote.failing = null;
    await controller.sync();
    expect(a.read(syncControllerProvider).error, isNull);
    expect(a.read(syncControllerProvider).busy, isFalse);
  });

  test('unavailable session restore stays quiet on cold start', () async {
    final google = _UnavailableRestoreGoogle(MemoryRemote());
    final (container, _) = await device(
      'a',
      google,
      storedAccount: 'me@example.com',
    );
    await pumpEventQueue();

    expect(container.read(syncControllerProvider).account, 'me@example.com');
    expect(container.read(syncControllerProvider).error, isNull);
    expect(google.driveCalls, 0);
  });

  test('an expired token is dropped and the sync retried', () async {
    final remote = MemoryRemote();
    final google = _ExpiringGoogle(remote);
    final (a, library) = await device('a', google);
    await library.rate(film, scoreHalf: 17, note: null);
    google.signedIn = true;
    await a.read(syncControllerProvider.notifier).signIn();
    expect(google.expired, 1);
    expect(a.read(syncControllerProvider).error, isNull);
    expect(remote.names, [SyncFile.name]);
  });

  test('signing out keeps the data in both places', () async {
    final remote = MemoryRemote();
    final (a, library) = await device('a', FakeGoogleAccount(remote));
    await library.rate(film, scoreHalf: 17, note: null);
    final controller = a.read(syncControllerProvider.notifier);
    await controller.signIn();
    await controller.signOut();
    expect(a.read(syncControllerProvider).account, isNull);
    expect(remote.names, [SyncFile.name]);
    expect((await SyncStore(databases.single).read()).liveRatings, 1);
  });

  test('first sync waits for confirmation even after a local edit', () async {
    final remote = MemoryRemote();
    final (source, sourceLibrary) = await device(
      'source',
      FakeGoogleAccount(remote),
    );
    await sourceLibrary.rate(other, scoreHalf: 12, note: null);
    await source.read(syncControllerProvider.notifier).signIn();
    final (target, targetLibrary) = await device(
      'target',
      FakeGoogleAccount(remote),
      debounce: Duration.zero,
    );
    await targetLibrary.rate(film, scoreHalf: 17, note: null);
    final controller = target.read(syncControllerProvider.notifier);
    expect(await controller.signIn(), isNotNull);
    expect(
      target.read(sharedPreferencesProvider).getString('sync_account'),
      isNull,
    );
    await targetLibrary.rate(film, scoreHalf: 16, note: null);
    await controller.sync();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect((await SyncStore(databases.last).read()).liveRatings, 1);
    await controller.confirmFirstSync();
    expect(
      target.read(sharedPreferencesProvider).getString('sync_account'),
      'me@example.com',
    );
    expect((await SyncStore(databases.last).read()).liveRatings, 2);
  });

  test('a local watchlist also requires first sync confirmation', () async {
    final remote = MemoryRemote();
    final (source, sourceLibrary) = await device(
      'source',
      FakeGoogleAccount(remote),
    );
    await sourceLibrary.rate(other, scoreHalf: 12, note: null);
    await source.read(syncControllerProvider.notifier).signIn();
    final (target, targetLibrary) = await device(
      'target',
      FakeGoogleAccount(remote),
    );
    await targetLibrary.addToWatchlist(film);
    final controller = target.read(syncControllerProvider.notifier);
    expect(await controller.signIn(), isNotNull);
    expect((await SyncStore(databases.last).read()).liveRatings, 0);
    await controller.confirmFirstSync();
    expect((await SyncStore(databases.last).read()).liveRatings, 1);
  });

  test('an edit during upload triggers another sync', () async {
    final remote = _BlockingRemote();
    final (container, library) = await device(
      'a',
      FakeGoogleAccount(remote),
      debounce: Duration.zero,
    );
    await library.rate(film, scoreHalf: 17, note: null);
    final controller = container.read(syncControllerProvider.notifier);
    await controller.signIn();
    remote.entered = Completer<void>();
    remote.release = Completer<void>();
    final entered = remote.entered!.future;
    await library.rate(film, scoreHalf: 16, note: null);
    final pass = controller.sync();
    await entered;
    await library.rate(other, scoreHalf: 12, note: null);
    remote.release!.complete();
    await pass;
    for (var i = 0; i < 100; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final main = remote.files.values.firstWhere(
        (f) => f.name == SyncFile.name,
      );
      if (SyncFile.decode(main.bytes).liveRatings == 2) return;
    }
    fail('The edit made during upload was not synced');
  });

  test('deleting the data from Drive removes every file', () async {
    final remote = MemoryRemote();
    final (a, library) = await device('a', FakeGoogleAccount(remote));
    await library.rate(film, scoreHalf: 17, note: null);
    final controller = a.read(syncControllerProvider.notifier);
    await controller.signIn();
    remote.put(SyncEngine.backupName(DateTime(2026, 10, 1)), [1]);
    await controller.deleteDriveData();
    expect(remote.files, isEmpty);
    expect(a.read(syncControllerProvider).account, isNull);
  });

  test(
    'deletion waits for an in-flight upload before removing files',
    () async {
      final remote = _BlockingRemote();
      final (container, library) = await device('a', FakeGoogleAccount(remote));
      final controller = container.read(syncControllerProvider.notifier);
      await library.rate(film, scoreHalf: 17, note: null);
      await controller.signIn();
      remote.entered = Completer<void>();
      remote.release = Completer<void>();
      final entered = remote.entered!.future;
      await library.rate(film, scoreHalf: 16, note: null);
      final pass = controller.sync();
      await entered;
      final deletion = controller.deleteDriveData();
      remote.release!.complete();
      await pass;
      await deletion;
      expect(remote.files, isEmpty);
      expect(container.read(syncControllerProvider).account, isNull);
    },
  );

  test('an edit during failed deletion is still scheduled for sync', () async {
    final remote = _FailingDeleteRemote();
    final (container, library) = await device(
      'a',
      FakeGoogleAccount(remote),
      debounce: const Duration(milliseconds: 10),
    );
    final controller = container.read(syncControllerProvider.notifier);
    await library.rate(film, scoreHalf: 17, note: null);
    await controller.signIn();
    final deletion = controller.deleteDriveData();
    final failure = expectLater(deletion, throwsA(isA<SyncException>()));
    await remote.entered.future;
    await library.rate(other, scoreHalf: 12, note: null);
    await pumpEventQueue();
    remote.release.complete();
    await failure;
    await remote.uploaded.future.timeout(const Duration(seconds: 10));
  });
}
