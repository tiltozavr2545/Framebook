import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/localized_titles.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/sources/providers.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/work_key.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Sync extends SyncController {
  @override
  SyncStatus build() => const SyncStatus(configured: false);
}

class _Api implements TmdbApi {
  _Api(this.language);
  final String language;
  @override
  Future<MovieDetails> movie(int id) async => MovieDetails(
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
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
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
      final container = ProviderContainer(
        overrides: [
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
      container.dispose();
      await db.close();
    },
  );
}
