// dart format width=80
import 'package:drift/drift.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:framebook/data/db/database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test(
    'v1 ratings, notes, watchlist, keys and deletion metadata survive v3',
    () async {
      final schema = await verifier.schemaAt(1);
      final oldDb = v1.DatabaseAtV1(schema.newConnection());
      await oldDb
          .into(oldDb.works)
          .insert(
            const v1.WorksData(
              workKey: 'tmdb:movie:603',
              kind: 'movie',
              tmdbId: 603,
              title: 'The Matrix',
              genreIds: '[878]',
              snapshotUpdatedAt: 10,
            ),
          );
      await oldDb
          .into(oldDb.ratings)
          .insert(
            const v1.RatingsData(
              workKey: 'tmdb:movie:603',
              scoreHalf: 17,
              note: 'Keep this note',
              createdAt: 11,
              scoredAt: 12,
              updatedAt: 13,
              updatedBy: 'device',
            ),
          );
      await oldDb
          .into(oldDb.watchlist)
          .insert(
            const v1.WatchlistData(
              workKey: 'tmdb:movie:603',
              addedAt: 14,
              updatedAt: 15,
              updatedBy: 'device',
            ),
          );
      await oldDb
          .into(oldDb.syncState)
          .insert(
            const v1.SyncStateData(
              key: 'rating_deletions',
              value: '[{"work_key":"tmdb:movie:1"}]',
            ),
          );
      await oldDb.close();
      final db = AppDatabase(schema.newConnection());
      await verifier.migrateAndValidate(db, 3);
      final rating = await db.select(db.ratings).getSingle();
      expect(
        (rating.scoreHalf, rating.note, rating.scoredAt, rating.updatedAt),
        (17, 'Keep this note', 12, 13),
      );
      expect((await db.select(db.works).getSingle()).title, 'The Matrix');
      expect((await db.select(db.watchlist).getSingle()).updatedAt, 15);
      expect(
        (await db.select(db.syncState).getSingle()).value,
        '[{"work_key":"tmdb:movie:1"}]',
      );
      expect(await db.select(db.favoritePeople).get(), isEmpty);
      await db
          .into(db.favoritePeople)
          .insert(
            FavoritePeopleCompanion.insert(
              personId: const Value(138),
              name: 'Quentin Tarantino',
              updatedAt: 16,
              updatedBy: 'device',
            ),
          );
      expect((await db.select(db.favoritePeople).getSingle()).personId, 138);
      await db.close();
    },
  );
  test('v2 data survives the comparison-history migration', () async {
    final schema = await verifier.schemaAt(2);
    final old = v2.DatabaseAtV2(schema.newConnection());
    await old
        .into(old.works)
        .insert(
          const v2.WorksData(
            workKey: 'tmdb:movie:603',
            kind: 'movie',
            tmdbId: 603,
            title: 'The Matrix',
            genreIds: '[878]',
            snapshotUpdatedAt: 10,
          ),
        );
    await old
        .into(old.ratings)
        .insert(
          const v2.RatingsData(
            workKey: 'tmdb:movie:603',
            scoreHalf: 17,
            note: 'Keep note',
            createdAt: 11,
            scoredAt: 12,
            updatedAt: 13,
            updatedBy: 'a',
          ),
        );
    await old
        .into(old.favoritePeople)
        .insert(
          const v2.FavoritePeopleData(
            personId: 138,
            name: 'Quentin Tarantino',
            updatedAt: 14,
            updatedBy: 'a',
          ),
        );
    await old.close();
    final db = AppDatabase(schema.newConnection());
    await verifier.migrateAndValidate(db, 3);
    expect((await db.select(db.ratings).getSingle()).scoreHalf, 17);
    expect((await db.select(db.ratings).getSingle()).note, 'Keep note');
    expect((await db.select(db.favoritePeople).getSingle()).personId, 138);
    expect(await db.select(db.pairComparisons).get(), isEmpty);
    await db.close();
  });
}
