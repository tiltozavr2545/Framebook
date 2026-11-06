import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/localized_titles.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/sources/providers.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/work_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Sync extends SyncController {
  @override
  SyncStatus build() => const SyncStatus(configured: false);

  void synced(int time) => state = state.copyWith(lastSyncAt: () => time);
}

class _Api implements TmdbApi {
  _Api(this.language);
  final String language;
  final calls = <int>[];
  bool offline = false;
  Completer<void>? barrier;
  @override
  Future<MovieDetails> movie(int id) async {
    calls.add(id);
    await barrier?.future;
    if (offline) throw const SourceException(SourceFailure.offline);
    return MovieDetails(
      key: WorkKey.movie(id),
      title: '$language $id',
      originalTitle: null,
      releaseDate: null,
      posterPath: null,
      genres: const [],
      overview: null,
      tagline: null,
      runtime: null,
      imdbId: null,
      vote: const TmdbVote(null, null),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  void pauseApp() {
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  }

  void resumeApp() {
    if (binding.lifecycleState == AppLifecycleState.resumed) return;
    binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  }

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 80));

  test(
    'unchanged resumes reuse successful titles, snapshot changes and offline failures retry',
    () async {
      resumeApp();
      final db = AppDatabase(NativeDatabase.memory());
      final api = _Api('en');
      var now = DateTime.utc(2026, 11, 5);
      final library = Library(db, deviceId: 'test');
      const work = WorkSnapshot(key: WorkKey.movie(1), tmdbId: 1, title: 'old');
      await library.rate([work], scoreHalf: 16, note: 'private note');
      final container = ProviderContainer(
        overrides: [
          localizedTitlesClockProvider.overrideWithValue(() => now),
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('test'),
          initialApiKeysProvider.overrideWithValue(
            const ApiKeys({ApiSource.tmdb: StoredKey('test', verified: true)}),
          ),
          syncControllerProvider.overrideWith(_Sync.new),
          tmdbProvider.overrideWithValue(api),
        ],
      );
      try {
        container.listen(localizedTitlesProvider, (_, _) {});
        await settle();
        expect(api.calls, [1]);
        void resume() {
          pauseApp();
          resumeApp();
        }

        resume();
        await settle();
        expect(api.calls, [1]);
        // A new imported snapshot must invalidate the successful result.
        await db.customStatement(
          "UPDATE works SET title = 'imported', snapshot_updated_at = snapshot_updated_at + 1",
        );
        (container.read(syncControllerProvider.notifier) as _Sync).synced(1);
        await settle();
        expect(api.calls, [1, 1]);
        // Unsuccessful attempts must remain retryable on resume.
        api.offline = true;
        await library.addToWatchlist([
          const WorkSnapshot(
            key: WorkKey.movie(2),
            tmdbId: 2,
            title: 'offline',
          ),
        ]);
        resume();
        await settle();
        expect(api.calls, [1, 1, 2]);
        api.offline = false;
        resume();
        await settle();
        expect(api.calls, [1, 1, 2, 2]);
        now = now.add(const Duration(days: 1));
        resume();
        await settle();
        expect(api.calls, [1, 1, 2, 2, 1, 2]);
        expect((await db.select(db.ratings).getSingle()).note, 'private note');
      } finally {
        container.dispose();
        await db.close();
      }
    },
  );

  test(
    'paused refresh neither applies an in-flight title nor starts another request',
    () async {
      resumeApp();
      final db = AppDatabase(NativeDatabase.memory());
      final api = _Api('en')..barrier = Completer<void>();
      final library = Library(db, deviceId: 'test');
      for (final id in [1, 2]) {
        await library.addToWatchlist([
          WorkSnapshot(key: WorkKey.movie(id), tmdbId: id, title: 'old'),
        ]);
      }
      final container = ProviderContainer(
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('test'),
          initialApiKeysProvider.overrideWithValue(
            const ApiKeys({ApiSource.tmdb: StoredKey('test', verified: true)}),
          ),
          syncControllerProvider.overrideWith(_Sync.new),
          tmdbProvider.overrideWithValue(api),
        ],
      );
      try {
        container.listen(localizedTitlesProvider, (_, _) {});
        await settle();
        expect(api.calls, [1]);
        pauseApp();
        api.barrier!.complete();
        await settle();
        expect(api.calls, [1]);
        expect((await db.select(db.works).get()).map((w) => w.title), [
          'old',
          'old',
        ]);
        resumeApp();
        await settle();
        expect(api.calls, [1, 1, 2]);
      } finally {
        container.dispose();
        resumeApp();
        await db.close();
      }
    },
  );

  test('onboarding without a TMDB key does not create catalog work', () async {
    var created = false;
    final container = ProviderContainer(
      overrides: [
        initialApiKeysProvider.overrideWithValue(ApiKeys.empty),
        tmdbProvider.overrideWith((ref) {
          created = true;
          return _Api('en');
        }),
      ],
    );
    container.listen(localizedTitlesProvider, (_, _) {});
    await settle();
    expect(created, isFalse);
    container.dispose();
  });
  test(
    'language changes refresh rated and watchlisted titles without editing ratings',
    () async {
      SharedPreferences.setMockInitialValues({'locale': 'en'});
      final prefs = await SharedPreferences.getInstance();
      final db = AppDatabase(NativeDatabase.memory());
      final library = Library(db, deviceId: 'test');
      const first = WorkSnapshot(
        key: WorkKey.movie(1),
        tmdbId: 1,
        title: 'old',
      );
      const second = WorkSnapshot(
        key: WorkKey.movie(2),
        tmdbId: 2,
        title: 'old',
      );
      await library.rate([first], scoreHalf: 16, note: 'note');
      await library.addToWatchlist([second]);
      final before = await db.select(db.ratings).getSingle();
      final firstRowSnapshotAt = (await db.select(db.works).get())
          .firstWhere((w) => w.workKey == 'tmdb:movie:1')
          .snapshotUpdatedAt;
      final container = ProviderContainer(
        overrides: [
          initialApiKeysProvider.overrideWithValue(
            const ApiKeys({ApiSource.tmdb: StoredKey('test', verified: true)}),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('test'),
          syncControllerProvider.overrideWith(_Sync.new),
          tmdbProvider.overrideWith(
            (ref) => _Api(ref.watch(localeProvider)?.languageCode ?? 'en'),
          ),
        ],
      );
      container.listen(localizedTitlesProvider, (_, _) {});
      Future<void> waitFor(String title) async {
        for (var i = 0; i < 200; i++) {
          final rows = await db.select(db.works).get();
          if (rows.any(
            (row) => row.workKey == 'tmdb:movie:2' && row.title == title,
          )) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 10));
        }
        fail('Localized title did not update: $title');
      }

      await waitFor('en 2');
      await container.read(localeProvider.notifier).set(const Locale('ru'));
      await waitFor('ru 2');
      final works = await db.select(db.works).get();
      expect(
        works.firstWhere((w) => w.workKey == 'tmdb:movie:1').title,
        'ru 1',
      );
      final after = await db.select(db.ratings).getSingle();
      expect(after.updatedAt, before.updatedAt);
      expect(after.scoreHalf, 16);
      expect(after.note, 'note');
      expect(
        works.firstWhere((w) => w.workKey == 'tmdb:movie:1').snapshotUpdatedAt,
        firstRowSnapshotAt,
      );
      container.dispose();
      await db.close();
    },
  );
}
