import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';

class _Reads extends QueryInterceptor {
  bool observing = false;
  int notes = 0;
  int selects = 0;
  int returned = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    final rows = await super.runSelect(executor, statement, args);
    if (observing) {
      selects++;
      returned += rows.length;
      notes += rows
          .where(
            (row) =>
                row.keys.any((key) => key == 'note' || key.endsWith('.note')),
          )
          .length;
    }
    return rows;
  }
}

void main() {
  test('watchlist actions do not materialize unrelated rating notes', () async {
    final reads = _Reads();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(reads));
    addTearDown(db.close);
    final library = Library(db, deviceId: 'local');
    const film = WorkSnapshot(key: WorkKey.movie(1), tmdbId: 1, title: 'Film');
    const series = WorkSnapshot(key: WorkKey.tv(2), tmdbId: 2, title: 'Series');
    await library.rate([film], scoreHalf: 16, note: 'Private note');
    for (var season = 1; season <= 12; season++) {
      await library.addToWatchlist([
        series,
        WorkSnapshot(
          key: WorkKey.season(2, season),
          tmdbId: 100 + season,
          title: 'Season $season',
        ),
      ]);
    }
    // Simulate an older installation: live rows still imply selection fences.
    await SyncStore(db).saveFences([]);
    reads.observing = true;
    await library.addToWatchlist([film]);
    await library.addToWatchlist([series]);
    await library.removeFromWatchlist(series.key);
    expect(reads.notes, 0);
    reads.observing = false;
    expect((await library.watchWatchlist().first).map((row) => row.key), [
      film.key,
    ]);
    final fences = await SyncStore(db).fences();
    expect(fences.where((fence) => fence.season), hasLength(1));
    expect(fences.where((fence) => !fence.season), hasLength(1));
  });

  test('parts averages return aggregates without episode notes', () async {
    final reads = _Reads();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(reads));
    addTearDown(db.close);
    final library = Library(db, deviceId: 'local');
    await db.batch((batch) {
      batch.insertAll(db.works, [
        for (var episode = 1; episode <= 100; episode++)
          WorksCompanion.insert(
            workKey: '${WorkKey.episode(2, 1, episode)}',
            kind: WorkKind.episode,
            parentKey: const Value('tmdb:tv:2:s1'),
            tmdbId: 1000 + episode,
            title: 'Episode $episode',
            snapshotUpdatedAt: 1,
          ),
      ]);
      batch.insertAll(db.ratings, [
        for (var episode = 1; episode <= 100; episode++)
          RatingsCompanion.insert(
            workKey: '${WorkKey.episode(2, 1, episode)}',
            scoreHalf: episode.isEven ? 14 : 18,
            note: Value('Private note. ' * 500),
            createdAt: 1,
            scoredAt: 1,
            updatedAt: 1,
            updatedBy: 'local',
          ),
      ]);
    });
    reads.observing = true;
    final average = (await library
        .watchPartsAverage(const WorkKey.tv(2))
        .first)!;
    expect(
      (average.parts, average.count, average.average),
      (WorkKind.episode, 100, 8.0),
    );
    expect(reads.notes, 0);
    expect(reads.returned, lessThanOrEqualTo(2));
  });
}
