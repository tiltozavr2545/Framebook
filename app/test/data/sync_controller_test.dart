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
    GoogleAccount google,
  ) async {
    SharedPreferences.setMockInitialValues({});
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
}
