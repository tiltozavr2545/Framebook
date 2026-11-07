import 'package:drift/drift.dart'
    show QueryExecutor, QueryInterceptor, ApplyInterceptor;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/work_key.dart';

class _BoundReads extends QueryInterceptor {
  int maxArguments = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (args.length > maxArguments) maxArguments = args.length;
    if (args.length > 400) throw StateError('Oversized parameter list');
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  test(
    'large season libraries load all ancestors with bounded SQL arguments',
    () async {
      final reads = _BoundReads();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(reads));
      addTearDown(db.close);
      await db.batch((batch) {
        batch.insertAll(
          db.works,
          [
            for (var i = 1; i <= 1001; i++) ...[
              Work(
                workKey: '${WorkKey.tv(i)}',
                kind: WorkKind.tv,
                tmdbId: i,
                title: 'Series $i',
                genreIds: '[]',
                snapshotUpdatedAt: 1,
              ),
              Work(
                workKey: '${WorkKey.season(i, 1)}',
                kind: WorkKind.season,
                parentKey: '${WorkKey.tv(i)}',
                seasonNumber: 1,
                tmdbId: 10000 + i,
                title: 'Season 1',
                genreIds: '[]',
                snapshotUpdatedAt: 1,
              ),
            ],
          ].map((row) => row.toCompanion(false)).toList(),
        );
        batch.insertAll(db.ratings, [
          for (var i = 1; i <= 1001; i++)
            Rating(
              workKey: '${WorkKey.season(i, 1)}',
              scoreHalf: 16,
              createdAt: 1,
              scoredAt: 1,
              updatedAt: 1,
              updatedBy: 'test',
            ).toCompanion(false),
        ]);
      });
      final rows = await Library(db, deviceId: 'test').watchRatings().first;
      expect(rows.length, 1001);
      for (final row in rows) {
        expect(row.series?.workKey, '${row.key.parent}');
        expect(row.series?.title, 'Series ${row.key.tmdbId}');
      }
      expect(reads.maxArguments, 400);
    },
  );
}
