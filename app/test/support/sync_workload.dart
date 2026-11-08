import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/work_key.dart';

SyncState syncWorkload(int version) => SyncState(
  works: [
    for (var id = 1; id <= 6000; id++)
      Work(
        workKey: 'tmdb:movie:$id',
        kind: WorkKind.movie,
        tmdbId: id,
        title: 'Film $id',
        genreIds: '[]',
        snapshotUpdatedAt: version,
      ),
  ],
  ratings: [
    for (var id = 1; id <= 3000; id++)
      Rating(
        workKey: 'tmdb:movie:$id',
        scoreHalf: 2 + id % 19,
        note: 'A note. ' * 64,
        createdAt: 1,
        scoredAt: 1,
        updatedAt: version,
        updatedBy: 'device',
      ),
  ],
  watchlist: [
    for (var id = 3001; id <= 6000; id++)
      WatchlistEntry(
        workKey: 'tmdb:movie:$id',
        addedAt: 1,
        updatedAt: version,
        updatedBy: 'device',
      ),
  ],
);
