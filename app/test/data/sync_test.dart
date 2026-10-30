import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/sync/sync_engine.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';

import '../support/memory_remote.dart';

/// A device: its own database, library and sync engine, its own clock.
final class _Device {
  _Device(this.id, this.remote, {int start = 1000000}) : now = start {
    db = AppDatabase(NativeDatabase.memory());
    library = Library(db, deviceId: id, clock: () => _time);
    store = SyncStore(db);
    engine = SyncEngine(
      store,
      remote,
      deviceId: id,
      appVersion: 'test',
      clock: () => _time,
    );
  }

  final String id;
  final MemoryRemote remote;
  late final AppDatabase db;
  late final Library library;
  late final SyncStore store;
  late final SyncEngine engine;
  int now;

  DateTime get _time => DateTime.fromMillisecondsSinceEpoch(now, isUtc: true);

  Future<String> state() async => _canonical(await store.read());
}

String _canonical(SyncState state) => jsonEncode({
  'purged_before': state.purgedBefore,
  'rating_deletions': [for (final d in state.ratingDeletions) d.toJson()],
  'watchlist_deletions': [for (final d in state.watchlistDeletions) d.toJson()],
  'works': [for (final w in state.works) SyncFile.workToJson(w)],
  'ratings': [for (final r in state.ratings) SyncFile.ratingToJson(r)],
  'watchlist': [for (final w in state.watchlist) SyncFile.watchlistToJson(w)],
});

List<WorkSnapshot> _film(int id) => [
  WorkSnapshot(
    key: WorkKey.movie(id),
    tmdbId: id,
    title: 'Film $id',
    releaseDate: '2001-01-0${id % 9 + 1}',
    genreIds: [18, id],
  ),
];

final _episode = [
  const WorkSnapshot(key: WorkKey.tv(1399), tmdbId: 1399, title: 'Thrones'),
  WorkSnapshot(
    key: WorkKey.parse('tmdb:tv:1399:s1'),
    tmdbId: 3624,
    title: 'Season 1',
  ),
  WorkSnapshot(
    key: WorkKey.parse('tmdb:tv:1399:s1:e3'),
    tmdbId: 63058,
    title: 'Lord Snow',
    imdbId: 'tt1829962',
  ),
];

Rating _rating(
  String key, {
  int score = 14,
  int at = 1,
  String by = 'a',
  int? deletedAt,
  String? note,
}) => Rating(
  workKey: key,
  scoreHalf: score,
  note: note,
  createdAt: 1,
  scoredAt: at,
  updatedAt: at,
  updatedBy: by,
  deletedAt: deletedAt,
);

List<int> _gzipJson(Object json) => gzip.encode(utf8.encode(jsonEncode(json)));

void main() {
  // Every simulated device has a database of its own, on purpose.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  group('file format', () {
    test('every column survives a round trip, tombstones included', () async {
      final device = _Device('dev-a', MemoryRemote());
      addTearDown(device.db.close);
      await device.library.rate(_film(1), scoreHalf: 17, note: 'Классика');
      await device.library.rate(_episode, scoreHalf: 18, note: null);
      await device.library.addToWatchlist(_film(2));
      await device.library.deleteRating(const WorkKey.movie(1));

      final state = await device.store.read();
      expect(state.works, hasLength(5));
      expect(state.ratings, hasLength(2));
      expect(state.watchlist, hasLength(1));

      final bytes = SyncFile.encode(
        state,
        writtenAt: 1,
        writtenBy: 'dev-a',
        appVersion: '0.5.0+7',
      );
      expect(_canonical(SyncFile.decode(bytes)), _canonical(state));

      final json =
          jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, Object?>;
      expect(json['format_version'], 2);
      expect(json['purged_before'], state.purgedBefore);
      expect(json['written_by'], 'dev-a');
      expect(json['app_version'], '0.5.0+7');
      final film = (json['works']! as List).cast<Map<String, Object?>>().first;
      // Genres are a JSON array in the file, not a string as in the table.
      expect(film['genre_ids'], [18, 1]);
      final rating = (json['ratings']! as List)
          .cast<Map<String, Object?>>()
          .firstWhere((r) => r['work_key'] == 'tmdb:movie:1');
      expect(rating['score_half'], 17);
      expect(rating['note'], 'Классика');
      expect(rating['deleted_at'], isNotNull);
    });

    test('reads the example from docs/sync.md', () {
      final state = SyncFile.decode(
        _gzipJson({
          'format_version': 1,
          'written_at': 1760870400000,
          'written_by': '6f1c-device-uuid',
          'app_version': '0.5.0+5',
          'works': [
            {
              'work_key': 'tmdb:tv:1399',
              'kind': 'tv',
              'parent_key': null,
              'tmdb_id': 1399,
              'imdb_id': 'tt0944947',
              'kp_id': 464963,
              'title': 'Игра престолов',
              'original_title': 'Game of Thrones',
              'release_date': '2011-04-17',
              'year': 2011,
              'poster_path': '/1XS1oqL89opfnbLl8WnZY1O1uJx.jpg',
              'genre_ids': [10765, 18],
              'snapshot_updated_at': 1760870000000,
            },
          ],
          'ratings': [
            {
              'work_key': 'tmdb:tv:1399',
              'score_half': 17,
              'note': 'The first four seasons are a 9',
              'created_at': 1760000000000,
              'scored_at': 1760000000000,
              'updated_at': 1760000000000,
              'updated_by': '6f1c',
              'deleted_at': null,
            },
          ],
          'watchlist': <Object>[],
        }),
      );
      expect(state.works.single.kpId, 464963);
      expect(state.works.single.genreIds, '[10765,18]');
      expect(state.ratings.single.scoreHalf, 17);
      expect(state.liveRatings, 1);
    });

    test('a file written by a newer app is refused, not misread', () {
      expect(
        () => SyncFile.decode(_gzipJson({'format_version': 3})),
        throwsA(isA<SyncFileTooNew>()),
      );
    });

    final work = {
      'work_key': 'tmdb:movie:1',
      'kind': 'movie',
      'tmdb_id': 1,
      'title': 'Film',
      'snapshot_updated_at': 1,
    };
    final rating = SyncFile.ratingToJson(_rating('tmdb:movie:1'));
    for (final (name, bytes) in [
      ('not gzip', utf8.encode('{"format_version": 1}')),
      ('not JSON', gzip.encode(utf8.encode('{format_version'))),
      ('no version', _gzipJson({'works': <Object>[]})),
      (
        'a required field missing',
        _gzipJson({
          'format_version': 1,
          'works': [
            {...work}..remove('title'),
          ],
        }),
      ),
      (
        'a field of the wrong type',
        _gzipJson({
          'format_version': 1,
          'works': [
            {...work, 'tmdb_id': '1'},
          ],
        }),
      ),
      (
        'a score out of range',
        _gzipJson({
          'format_version': 1,
          'works': [work],
          'ratings': [
            {...rating, 'score_half': 21},
          ],
        }),
      ),
      (
        'a rating without its snapshot',
        _gzipJson({
          'format_version': 1,
          'ratings': [rating],
        }),
      ),
      (
        'a kind that contradicts the key',
        _gzipJson({
          'format_version': 1,
          'works': [
            {...work, 'kind': 'tv'},
          ],
        }),
      ),
    ]) {
      test('broken: $name', () {
        expect(() => SyncFile.decode(bytes), throwsA(isA<SyncFileBroken>()));
      });
    }
  });

  group('merge', () {
    /// A random state over few keys, times and devices, so that ties and
    /// equal versions with different content come up often.
    SyncState randomState(Random random) {
      String key() => 'tmdb:movie:${random.nextInt(4) + 1}';
      final ratings = <String, Rating>{};
      for (var i = random.nextInt(6); i > 0; i--) {
        final k = key();
        ratings[k] = _rating(
          k,
          score: random.nextInt(19) + 2,
          at: random.nextInt(4),
          by: random.nextBool() ? 'a' : 'b',
          deletedAt: random.nextInt(3) == 0 ? 5 : null,
        );
      }
      final watchlist = <String, WatchlistEntry>{};
      for (var i = random.nextInt(4); i > 0; i--) {
        final k = key();
        watchlist[k] = WatchlistEntry(
          workKey: k,
          addedAt: random.nextInt(3),
          updatedAt: random.nextInt(3),
          updatedBy: random.nextBool() ? 'a' : 'b',
          deletedAt: random.nextBool() ? null : 2,
        );
      }
      final works = <String, Work>{};
      for (var i = random.nextInt(4); i > 0; i--) {
        final k = key();
        works[k] = Work(
          workKey: k,
          kind: WorkKind.movie,
          tmdbId: 1,
          title: 'v${random.nextInt(3)}',
          kpId: random.nextBool() ? null : 7,
          genreIds: '[]',
          snapshotUpdatedAt: random.nextInt(3),
        );
      }
      return SyncState(
        works: works.values.toList(),
        ratings: ratings.values.toList(),
        watchlist: watchlist.values.toList(),
      );
    }

    test('commutative, associative and idempotent', () {
      final random = Random(42);
      for (var i = 0; i < 500; i++) {
        final a = randomState(random);
        final b = randomState(random);
        final c = randomState(random);
        expect(
          _canonical(mergeStates(a, b)),
          _canonical(mergeStates(b, a)),
          reason: 'commutative, case $i',
        );
        expect(
          _canonical(mergeStates(a, mergeStates(b, c))),
          _canonical(mergeStates(mergeStates(a, b), c)),
          reason: 'associative, case $i',
        );
        final ab = mergeStates(a, b);
        expect(
          _canonical(mergeStates(ab, ab)),
          _canonical(ab),
          reason: 'idempotent, case $i',
        );
      }
    });

    test('the remote is behind exactly when merging would change it', () {
      final random = Random(7);
      for (var i = 0; i < 500; i++) {
        final local = randomState(random);
        final remote = randomState(random);
        final merged = mergeStates(local, remote);
        expect(
          remoteBehind(local, remote),
          _canonical(merged) !=
              _canonical(mergeStates(remote, const SyncState())),
          reason: 'case $i',
        );
        expect(remoteBehind(local, merged), isFalse);
      }
    });

    test('the later edit wins; on equal times the larger device id', () {
      final older = _rating('k', score: 10, at: 5, by: 'z');
      final newer = _rating('k', score: 12, at: 6, by: 'a');
      expect(compareRatings(newer, older), greaterThan(0));
      final tieA = _rating('k', score: 10, at: 6, by: 'a');
      final tieB = _rating('k', score: 12, at: 6, by: 'b');
      expect(compareRatings(tieB, tieA), greaterThan(0));
      // A tombstone is just another version.
      final deleted = _rating('k', at: 7, by: 'a', deletedAt: 7);
      expect(compareRatings(deleted, tieB), greaterThan(0));
    });
  });

  group('the database side', () {
    late _Device device;

    setUp(() => device = _Device('dev-a', MemoryRemote()));
    tearDown(() => device.db.close());

    test('applying an older version never rolls back an edit', () async {
      await device.library.rate(_film(1), scoreHalf: 16, note: null);
      final mine = (await device.store.read()).ratings.single;
      final stale = mine.copyWith(scoreHalf: 4, updatedAt: mine.updatedAt - 1);
      final state = await device.store.read();
      expect(
        await device.store.apply(
          SyncState(works: state.works, ratings: [stale]),
        ),
        0,
      );
      expect((await device.store.read()).ratings.single.scoreHalf, 16);
    });

    test('applying lands parents before children', () async {
      final other = _Device('dev-b', MemoryRemote());
      addTearDown(other.db.close);
      await other.library.rate(_episode, scoreHalf: 18, note: null);
      final state = await other.store.read();
      // Children first in the input: apply must reorder.
      final reversed = SyncState(
        works: state.works.reversed.toList(),
        ratings: state.ratings,
      );
      expect(await device.store.apply(reversed), 4);
      expect(await device.state(), await other.state());
    });

    test('replacing everything tombstones the rest as a new version', () async {
      device.now = 1000;
      await device.library.rate(_film(1), scoreHalf: 16, note: null);
      await device.library.rate(_film(2), scoreHalf: 12, note: null);
      await device.library.addToWatchlist(_film(3));
      final backup = await device.store.read();

      device.now = 2000;
      await device.library.rate(_film(1), scoreHalf: 6, note: 'передумал');
      await device.library.rate(_film(4), scoreHalf: 20, note: null);
      await device.library.removeFromWatchlist(const WorkKey.movie(3));

      device.now = 3000;
      await device.store.replaceWith(backup, deviceId: 'dev-a', now: 3000);
      final after = {
        for (final r in (await device.store.read()).ratings) r.workKey: r,
      };
      expect(after['tmdb:movie:1']!.scoreHalf, 16);
      expect(after['tmdb:movie:1']!.note, isNull);
      expect(after['tmdb:movie:1']!.updatedAt, 3000);
      expect(after['tmdb:movie:2']!.updatedAt, 1000); // unchanged
      expect(after['tmdb:movie:4']!.deletedAt, 3000);
      expect(after['tmdb:movie:4']!.updatedAt, 3000);
      final listed = (await device.store.read()).watchlist.single;
      expect(listed.deletedAt, isNull);
      expect(listed.updatedAt, 3000);
    });
  });

  group('sync', () {
    late MemoryRemote remote;
    late _Device a;
    late _Device b;

    setUp(() {
      remote = MemoryRemote();
      a = _Device('dev-a', remote);
      b = _Device('dev-b', remote);
    });
    tearDown(() async {
      await a.db.close();
      await b.db.close();
    });

    test('nothing to share: no file is created', () async {
      final report = await a.engine.sync();
      expect(report.uploaded, isFalse);
      expect(remote.files, isEmpty);
    });

    test('a rating travels from one device to another', () async {
      await a.library.rate(_episode, scoreHalf: 18, note: 'Зима близко');
      expect((await a.engine.sync()).uploaded, isTrue);
      expect(remote.names, [SyncFile.name]);

      final report = await b.engine.sync();
      expect(report.applied, 4); // three snapshots and the rating
      expect(report.uploaded, isFalse);
      expect(await b.state(), await a.state());
    });

    test('in step: nothing is uploaded', () async {
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      await a.engine.sync();
      final before = remote.files.values.single.modified;
      final report = await a.engine.sync();
      expect(report.uploaded, isFalse);
      expect(remote.files.values.single.modified, before);
    });

    test('edits on both sides merge', () async {
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      await a.engine.sync();
      await b.engine.sync();
      a.now += 10;
      b.now += 20;
      await a.library.rescore(const WorkKey.movie(1), 12);
      await b.library.rate(_film(2), scoreHalf: 18, note: null);
      await b.library.deleteRating(const WorkKey.movie(1));
      await a.engine.sync();
      await b.engine.sync();
      await a.engine.sync();
      expect(await a.state(), await b.state());
      final ratings = {
        for (final r in (await a.store.read()).ratings) r.workKey: r,
      };
      // b deleted it later than a rescored it.
      expect(ratings['tmdb:movie:1']!.deletedAt, isNotNull);
      expect(ratings['tmdb:movie:2']!.scoreHalf, 18);
    });

    test('a write between download and upload: start over', () async {
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      await a.engine.sync();
      await b.library.rate(_film(2), scoreHalf: 12, note: null);
      await b.engine.sync();

      await a.library.rate(_film(3), scoreHalf: 14, note: null);
      var interfered = false;
      remote.afterDownload = (id) {
        if (interfered) return;
        interfered = true;
        // Another device uploads exactly now.
        remote.put(SyncFile.name, remote.files[id]!.bytes, id: id);
      };
      expect((await a.engine.sync()).uploaded, isTrue);
      expect(interfered, isTrue);
      remote.afterDownload = null;
      await b.engine.sync();
      expect(await a.state(), await b.state());
      expect((await b.store.read()).ratings, hasLength(3));
    });

    test('a file that keeps changing is given up, not overwritten', () async {
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      await a.engine.sync();
      await a.library.rate(_film(2), scoreHalf: 16, note: null);
      remote.afterDownload = (id) =>
          remote.put(SyncFile.name, remote.files[id]!.bytes, id: id);
      await expectLater(
        a.engine.sync(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.failure,
            'failure',
            SyncFailure.failed,
          ),
        ),
      );
    });

    test('two first files are merged into the oldest', () async {
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      await b.library.rate(_film(2), scoreHalf: 12, note: null);
      // Both created the file without seeing each other.
      remote.put(
        SyncFile.name,
        SyncFile.encode(
          await a.store.read(),
          writtenAt: 1,
          writtenBy: 'dev-a',
          appVersion: 'test',
        ),
      );
      remote.put(
        SyncFile.name,
        SyncFile.encode(
          await b.store.read(),
          writtenAt: 1,
          writtenBy: 'dev-b',
          appVersion: 'test',
        ),
      );
      await a.engine.sync();
      expect(remote.names.where((n) => n == SyncFile.name), hasLength(1));
      expect(
        remote.files.keys.where(
          (id) => remote.files[id]!.name == SyncFile.name,
        ),
        ['f0'],
      );
      await b.engine.sync();
      expect(await a.state(), await b.state());
      expect((await a.store.read()).ratings, hasLength(2));
    });

    test('a broken file is left alone', () async {
      remote.put(SyncFile.name, utf8.encode('garbage'));
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      await expectLater(
        a.engine.sync(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.failure,
            'failure',
            SyncFailure.broken,
          ),
        ),
      );
      expect(utf8.decode(remote.files.values.single.bytes), 'garbage');
    });

    test('a newer format stops sync and stays as it is', () async {
      final newer = _gzipJson({'format_version': 9});
      remote.put(SyncFile.name, newer);
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      await expectLater(
        a.engine.sync(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.failure,
            'failure',
            SyncFailure.tooNew,
          ),
        ),
      );
      expect(remote.files.values.single.bytes, newer);
    });

    test(
      'a daily copy before the first upload of the day, seven kept',
      () async {
        final day = DateTime.utc(2026, 10, 1, 12).millisecondsSinceEpoch;
        a.now = day;
        await a.library.rate(_film(1), scoreHalf: 16, note: null);
        await a.engine.sync(); // creates the file: nothing to copy yet
        expect(remote.names, [SyncFile.name]);

        for (var i = 0; i < 9; i++) {
          a.now = day + i * Duration.millisecondsPerDay;
          await a.library.rate(_film(1), scoreHalf: 4 + i, note: null);
          await a.engine.sync();
          // A second upload the same day makes no second copy.
          await a.library.rate(_film(2), scoreHalf: 4 + i, note: null);
          await a.engine.sync();
        }
        final copies = await a.engine.backups();
        expect(copies, hasLength(SyncEngine.backupsKept));
        expect(
          copies.first.name,
          SyncEngine.backupName(
            DateTime.fromMillisecondsSinceEpoch(
              day + 8 * Duration.millisecondsPerDay,
              isUtc: true,
            ),
          ),
        );
        // The copy holds the file as it was before that day's first upload.
        final last = await a.engine.readBackup(copies.first);
        final film1 = last.ratings.firstWhere(
          (r) => r.workKey == 'tmdb:movie:1',
        );
        expect(film1.scoreHalf, 4 + 7);
      },
    );

    test('offline is reported, nothing changes', () async {
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      remote.failing = SyncFailure.offline;
      await expectLater(a.engine.sync(), throwsA(isA<SyncException>()));
      remote.failing = null;
      expect(remote.files, isEmpty);
    });

    test('restoring a daily copy spreads to the other devices', () async {
      await a.library.rate(_film(1), scoreHalf: 16, note: null);
      await a.engine.sync();
      final good = await a.engine.peek();
      a.now += Duration.millisecondsPerDay;
      await a.library.deleteRating(const WorkKey.movie(1));
      await a.engine.sync();
      await b.engine.sync();
      expect((await b.store.read()).liveRatings, 0);

      a.now += 1000;
      await a.store.replaceWith(good!, deviceId: 'dev-a', now: a.now);
      await a.engine.sync();
      await b.engine.sync();
      expect((await b.store.read()).liveRatings, 1);
      expect(await a.state(), await b.state());
    });
  });

  group('purge watermark', () {
    test('v1 reads P=0 and v2 round trips the watermark', () {
      expect(SyncFile.decode(_gzipJson({'format_version': 1})).purgedBefore, 0);
      final bytes = SyncFile.encode(
        const SyncState(purgedBefore: 123),
        writtenAt: 124,
        writtenBy: 'a',
        appVersion: 'test',
      );
      expect(SyncFile.decode(bytes).purgedBefore, 123);
      for (final p in [null, -1, '10']) {
        expect(
          () => SyncFile.decode(
            _gzipJson({'format_version': 2, 'purged_before': p}),
          ),
          throwsA(isA<SyncFileBroken>()),
        );
      }
    });

    test('compact and full deletion merge is associative and idempotent', () {
      final old = _rating('k', at: 1);
      final deleted = _rating('k', at: 2, deletedAt: 2);
      final compact = ratingDeletion(deleted);
      final states = [
        SyncState(ratings: [old]),
        SyncState(ratings: [deleted]),
        SyncState(ratingDeletions: [compact]),
        SyncState(ratings: [_rating('k', at: 3)]),
        const SyncState(purgedBefore: 100),
      ];
      for (final a in states) {
        expect(_canonical(mergeStates(a, a)), _canonical(a));
        for (final b in states) {
          expect(_canonical(mergeStates(a, b)), _canonical(mergeStates(b, a)));
          for (final c in states) {
            expect(
              _canonical(mergeStates(mergeStates(a, b), c)),
              _canonical(mergeStates(a, mergeStates(b, c))),
            );
          }
        }
      }
      expect(
        mergeStates(
          const SyncState(purgedBefore: 100),
          SyncState(ratings: [old]),
        ).ratings,
        hasLength(1),
      );
      expect(
        mergeStates(
          SyncState(ratingDeletions: [compact]),
          SyncState(ratings: [deleted]),
        ).ratings,
        isEmpty,
      );
    });

    test('mixed rating and watchlist registers obey merge laws', () {
      final rng = Random(24680);
      SyncState randomState() {
        final ratings = <Rating>[];
        final watchlist = <WatchlistEntry>[];
        final rd = <DeletionRecord>[];
        final wd = <DeletionRecord>[];
        for (var i = 0; i < 3; i++) {
          final key = 'tmdb:movie:$i';
          final at = rng.nextInt(4) + 1;
          final by = ['a', 'b'][rng.nextInt(2)];
          final kind = rng.nextInt(4);
          final rating = _rating(
            key,
            at: at,
            by: by,
            score: 10 + rng.nextInt(3),
            deletedAt: kind >= 2 ? at : null,
          );
          final watch = WatchlistEntry(
            workKey: key,
            addedAt: 1,
            updatedAt: at,
            updatedBy: by,
            deletedAt: kind >= 2 ? at : null,
          );
          if (kind == 1 || kind == 2) {
            ratings.add(rating);
            watchlist.add(watch);
          }
          if (kind == 3) {
            rd.add(ratingDeletion(rating));
            wd.add(watchlistDeletion(watch));
          }
        }
        return SyncState(
          ratings: ratings,
          watchlist: watchlist,
          ratingDeletions: rd,
          watchlistDeletions: wd,
          purgedBefore: rng.nextInt(4),
        );
      }

      for (var i = 0; i < 1000; i++) {
        final a = randomState(), b = randomState(), c = randomState();
        expect(
          _canonical(mergeStates(a, a)),
          _canonical(a),
          reason: 'idempotence $i',
        );
        expect(
          _canonical(mergeStates(a, b)),
          _canonical(mergeStates(b, a)),
          reason: 'commutativity $i',
        );
        expect(
          _canonical(mergeStates(mergeStates(a, b), c)),
          _canonical(mergeStates(a, mergeStates(b, c))),
          reason: 'associativity $i',
        );
      }
    });

    test(
      'devices converge after a real 180-day purge and stale backup merge',
      () async {
        final remote = MemoryRemote();
        final a = _Device('a', remote), b = _Device('b', remote);
        addTearDown(() async {
          await a.db.close();
          await b.db.close();
        });
        await a.library.rate(_film(1), scoreHalf: 12, note: null);
        await a.engine.sync();
        await b.engine.sync();
        final oldBackup = await b.store.read();
        await a.library.deleteRating(const WorkKey.movie(1));
        a.now += 181 * Duration.millisecondsPerDay;
        b.now = a.now;
        await a.engine.sync();
        final review = await b.engine.sync();
        if (review.paused) {
          await b.engine.sync(
            stale: StaleChoice.discard,
            reviewedFingerprint: review.staleFingerprint,
          );
        }
        await b.store.apply(oldBackup);
        await b.engine.sync();
        await a.engine.sync();
        expect((await a.store.read()).ratingDeletions, hasLength(1));
        expect((await b.store.read()).ratings, isEmpty);
        expect(await a.state(), await b.state());
      },
    );

    test('v2 rejects absent and invalid deletion metadata', () {
      for (final entry in [
        null,
        {
          'work_key': 'bad',
          'updated_at': 1,
          'updated_by': 'a',
          'tie_break': 'a' * 64,
        },
        {
          'work_key': 'tmdb:movie:1',
          'updated_at': -1,
          'updated_by': 'a',
          'tie_break': 'a' * 64,
        },
        {
          'work_key': 'tmdb:movie:1',
          'updated_at': 1,
          'updated_by': 'a',
          'tie_break': 'bad',
        },
      ]) {
        final file = {
          'format_version': 2,
          'purged_before': 0,
          'watchlist_deletions': <Object>[],
        };
        if (entry != null) file['rating_deletions'] = [entry];
        expect(
          () => SyncFile.decode(_gzipJson(file)),
          throwsA(isA<SyncFileBroken>()),
        );
      }
    });

    test('reviewed version cannot authorize a subsequent edit', () async {
      final remote = MemoryRemote();
      final d = _Device('a', remote);
      addTearDown(d.db.close);
      await d.library.rate(_film(1), scoreHalf: 12, note: null);
      final deletion = ratingDeletion(
        _rating('tmdb:movie:1', at: d.now + 20, by: 'b', deletedAt: d.now + 20),
      );
      remote.put(
        SyncFile.name,
        SyncFile.encode(
          SyncState(ratingDeletions: [deletion]),
          writtenAt: d.now,
          writtenBy: 'b',
          appVersion: 'test',
        ),
      );
      final first = await d.engine.sync();
      await d.library.rate(_film(1), scoreHalf: 16, note: null);
      final second = await d.engine.sync(
        stale: StaleChoice.discard,
        reviewedFingerprint: first.staleFingerprint,
      );
      expect(second.paused, isTrue);
      expect(second.staleFingerprint, isNot(first.staleFingerprint));
      expect((await d.store.read()).ratings.single.scoreHalf, 16);
    });

    test('incoming watermark is bounded by half the retention age', () {
      expect(
        clampWatermark(999999999999, 200 * Duration.millisecondsPerDay),
        110 * Duration.millisecondsPerDay,
      );
      expect(clampWatermark(7, 200 * Duration.millisecondsPerDay), 7);
      expect(
        purgeWatermark(200 * Duration.millisecondsPerDay),
        20 * Duration.millisecondsPerDay,
      );
    });

    test('purging prunes orphans but retains referenced ancestors', () async {
      final d = _Device('a', MemoryRemote());
      addTearDown(d.db.close);
      await d.library.rate(_film(1), scoreHalf: 12, note: null);
      await d.library.deleteRating(const WorkKey.movie(1));
      await d.library.rate(_episode, scoreHalf: 16, note: null);
      final tombstone = (await d.store.read()).ratings.firstWhere(
        (r) => r.workKey == 'tmdb:movie:1',
      );
      expect(await d.store.purge(tombstone.updatedAt), 0);
      expect(await d.store.purge(tombstone.updatedAt + 1), 1);
      final state = await d.store.read();
      expect(state.works, hasLength(3));
      expect(state.ratings.single.workKey, 'tmdb:tv:1399:s1:e3');
      expect(await d.db.select(d.db.works).get(), hasLength(3));
    });

    test(
      'old exports cannot resurrect forgotten rows even with replace',
      () async {
        final d = _Device('a', MemoryRemote());
        addTearDown(d.db.close);
        await d.library.rate(_film(1), scoreHalf: 12, note: null);
        final backup = await d.store.read();
        await d.library.deleteRating(const WorkKey.movie(1));
        await d.store.purge(d.now + 10);
        await d.store.apply(backup);
        expect((await d.store.read()).ratings, isEmpty);
        await d.store.replaceWith(backup, deviceId: 'a', now: d.now + 100);
        expect((await d.store.read()).ratings, isEmpty);
      },
    );

    test(
      'replacement restores an older score after re-rating a compacted deletion',
      () async {
        final d = _Device('a', MemoryRemote());
        addTearDown(d.db.close);
        await d.library.rate(_film(1), scoreHalf: 12, note: null);
        final backup = await d.store.read();
        await d.library.deleteRating(const WorkKey.movie(1));
        await d.store.purge(d.now + 10);
        await d.library.rate(_film(1), scoreHalf: 18, note: null);
        await d.store.replaceWith(backup, deviceId: 'a', now: d.now + 100);
        final state = await d.store.read();
        expect(state.liveRatings, 1);
        expect(state.ratings.single.scoreHalf, 12);
      },
    );

    test('replacement can undo a recent full tombstone', () async {
      final d = _Device('a', MemoryRemote());
      addTearDown(d.db.close);
      await d.library.rate(_film(1), scoreHalf: 12, note: null);
      final backup = await d.store.read();
      await d.library.deleteRating(const WorkKey.movie(1));
      await d.store.replaceWith(backup, deviceId: 'a', now: d.now + 10);
      expect((await d.store.read()).liveRatings, 1);
    });

    test('edit at the same millisecond as last sync requires review', () {
      final live = _rating('k', at: 3);
      final deletion = ratingDeletion(_rating('k', at: 4, deletedAt: 4));
      expect(
        unsyncedDrops(
          SyncState(ratings: [live]),
          SyncState(ratingDeletions: [deletion]),
          lastSyncAt: 3,
        ).ratings,
        contains('k'),
      );
    });

    test(
      'compact deletions survive export and protect a new local edit against clock skew',
      () async {
        final d = _Device('a', MemoryRemote());
        addTearDown(d.db.close);
        await d.library.rate(_film(1), scoreHalf: 12, note: null);
        await d.library.addToWatchlist(_film(2));
        await d.library.deleteRating(const WorkKey.movie(1));
        await d.library.removeFromWatchlist(const WorkKey.movie(2));
        await d.store.purge(d.now + 10);
        final compact = await d.store.read();
        final copy = SyncFile.decode(
          SyncFile.encode(
            compact,
            writtenAt: d.now,
            writtenBy: 'a',
            appVersion: 'test',
          ),
        );
        expect(copy.ratingDeletions, hasLength(1));
        expect(copy.watchlistDeletions, hasLength(1));
        d.now -= 1000;
        await d.library.rate(_film(1), scoreHalf: 14, note: null);
        await d.library.addToWatchlist(_film(2));
        final state = await d.store.read();
        expect(
          state.ratings.single.updatedAt,
          greaterThan(copy.ratingDeletions.single.updatedAt),
        );
        expect(
          state.watchlist.single.updatedAt,
          greaterThan(copy.watchlistDeletions.single.updatedAt),
        );
        expect(mergeStates(state, copy).liveRatings, 1);
      },
    );

    test(
      'failed upload retains compact deletion and retry publishes it',
      () async {
        final remote = MemoryRemote();
        final d = _Device('a', remote);
        addTearDown(d.db.close);
        await d.library.rate(_film(1), scoreHalf: 12, note: null);
        await d.engine.sync();
        await d.library.deleteRating(const WorkKey.movie(1));
        d.now += 400 * Duration.millisecondsPerDay;
        remote.afterDownload = (_) {
          remote.failing = SyncFailure.offline;
        };
        await expectLater(d.engine.sync(), throwsA(isA<SyncException>()));
        expect((await d.store.read()).ratingDeletions, hasLength(1));
        remote.afterDownload = null;
        remote.failing = null;
        await d.engine.sync();
        final main = remote.files.values.firstWhere(
          (f) => f.name == SyncFile.name,
        );
        expect(SyncFile.decode(main.bytes).ratingDeletions, hasLength(1));
      },
    );

    test(
      'keep beats a newer full tombstone after an older compact deletion',
      () async {
        final remote = MemoryRemote();
        final d = _Device('a', remote);
        addTearDown(d.db.close);
        await d.library.rate(_film(1), scoreHalf: 12, note: null);
        final local = await d.store.read();
        final old = d.now + 100, latest = d.now + 200;
        final compact = ratingDeletion(
          _rating('tmdb:movie:1', at: old, by: 'b', deletedAt: old),
        );
        final full = _rating(
          'tmdb:movie:1',
          at: latest,
          by: 'b',
          deletedAt: latest,
        );
        remote.put(
          SyncFile.name,
          SyncFile.encode(
            SyncState(
              works: local.works,
              ratings: [full],
              ratingDeletions: [compact],
            ),
            writtenAt: d.now,
            writtenBy: 'b',
            appVersion: 'test',
          ),
        );
        final review = await d.engine.sync();
        expect(review.stale, 1);
        final result = await d.engine.sync(
          stale: StaleChoice.keep,
          reviewedFingerprint: review.staleFingerprint,
        );
        expect(result.paused, isFalse);
        final state = await d.store.read();
        expect(state.liveRatings, 1);
        expect(state.ratings.single.updatedAt, greaterThan(latest));
      },
    );

    test(
      'newer remote live version avoids a stale compact deletion warning',
      () async {
        final remote = MemoryRemote();
        final d = _Device('a', remote);
        addTearDown(d.db.close);
        await d.library.rate(_film(1), scoreHalf: 12, note: null);
        final local = await d.store.read();
        final old = d.now + 100, latest = d.now + 200;
        final compact = ratingDeletion(
          _rating('tmdb:movie:1', at: old, by: 'b', deletedAt: old),
        );
        final live = _rating('tmdb:movie:1', at: latest, by: 'b', score: 18);
        remote.put(
          SyncFile.name,
          SyncFile.encode(
            SyncState(
              works: local.works,
              ratings: [live],
              ratingDeletions: [compact],
            ),
            writtenAt: d.now,
            writtenBy: 'b',
            appVersion: 'test',
          ),
        );
        expect((await d.engine.sync()).paused, isFalse);
        expect((await d.store.read()).ratings.single.scoreHalf, 18);
      },
    );

    test(
      'keep beats the newest duplicate compact deletion for both row types',
      () async {
        final remote = MemoryRemote();
        final d = _Device('a', remote);
        addTearDown(d.db.close);
        await d.library.rate(_film(1), scoreHalf: 12, note: null);
        await d.library.addToWatchlist(_film(2));
        DeletionRecord rating(int time) => ratingDeletion(
          _rating('tmdb:movie:1', at: time, by: 'b', deletedAt: time),
        );
        DeletionRecord watch(int time) => watchlistDeletion(
          WatchlistEntry(
            workKey: 'tmdb:movie:2',
            addedAt: 1,
            updatedAt: time,
            updatedBy: 'b',
            deletedAt: time,
          ),
        );
        final latest = d.now + 200;
        remote.put(
          SyncFile.name,
          SyncFile.encode(
            SyncState(
              ratingDeletions: [rating(latest), rating(d.now + 100)],
              watchlistDeletions: [watch(latest), watch(d.now + 100)],
            ),
            writtenAt: d.now,
            writtenBy: 'b',
            appVersion: 'test',
          ),
        );
        final review = await d.engine.sync();
        expect(review.stale, 2);
        final result = await d.engine.sync(
          stale: StaleChoice.keep,
          reviewedFingerprint: review.staleFingerprint,
        );
        expect(result.paused, isFalse);
        final state = await d.store.read();
        expect(state.liveRatings, 1);
        expect(state.ratings.single.updatedAt, greaterThan(latest));
        expect(state.watchlist.single.deletedAt, isNull);
        expect(state.watchlist.single.updatedAt, greaterThan(latest));
      },
    );

    for (final choice in [StaleChoice.keep, StaleChoice.discard]) {
      test('unsynced stale rows pause before ${choice.name}', () async {
        final remote = MemoryRemote();
        final d = _Device('a', remote);
        addTearDown(d.db.close);
        await d.library.rate(_film(1), scoreHalf: 12, note: null);
        d.now += 400 * Duration.millisecondsPerDay;
        final p = purgeWatermark(d.now);
        remote.put(
          SyncFile.name,
          SyncFile.encode(
            SyncState(
              purgedBefore: p,
              ratingDeletions: [
                ratingDeletion(
                  _rating(
                    'tmdb:movie:1',
                    at: 1000001,
                    by: 'b',
                    deletedAt: 1000001,
                  ),
                ),
              ],
            ),
            writtenAt: d.now,
            writtenBy: 'b',
            appVersion: 'test',
          ),
        );
        final paused = await d.engine.sync();
        expect(paused.stale, 1);
        expect((await d.store.read()).liveRatings, 1);
        expect(await d.store.stateValue(SyncStore.lastSyncKey), isNull);
        expect(
          (await d.engine.sync(
            stale: choice,
            reviewedFingerprint: paused.staleFingerprint,
          )).paused,
          isFalse,
        );
        final state = await d.store.read();
        expect(state.liveRatings, choice == StaleChoice.keep ? 1 : 0);
        if (choice == StaleChoice.keep) {
          expect(state.ratings.single.updatedAt, greaterThan(1000001));
        }
      });
    }
  });

  group('convergence', () {
    /// Random edits on three devices with clocks that drift apart, synced in
    /// a random order; at the end every device syncs twice round the circle.
    /// Whatever happened, every device ends up with the same state.
    for (var seed = 0; seed < 15; seed++) {
      test('random edits and syncs, seed $seed', () async {
        final random = Random(seed);
        final remote = MemoryRemote();
        final devices = [
          for (final (i, id) in ['dev-a', 'dev-b', 'dev-c'].indexed)
            _Device(id, remote, start: 1000000 + i * 37),
        ];
        addTearDown(() async {
          for (final d in devices) {
            await d.db.close();
          }
        });

        for (var step = 0; step < 60; step++) {
          final d = devices[random.nextInt(devices.length)];
          // Clocks run at their own pace; sometimes two edits share a
          // millisecond.
          d.now += random.nextInt(3) * random.nextInt(50);
          final film = random.nextInt(4) + 1;
          final key = WorkKey.movie(film);
          switch (random.nextInt(7)) {
            case 0 || 1:
              await d.library.rate(
                _film(film),
                scoreHalf: random.nextInt(19) + 2,
                note: random.nextBool() ? null : 'n$step',
              );
            case 2:
              await d.library.deleteRating(key);
            case 3:
              await d.library.addToWatchlist(_film(film));
            case 4:
              await d.library.removeFromWatchlist(key);
            case 5:
              await d.library.rate(
                _episode,
                scoreHalf: random.nextInt(19) + 2,
                note: null,
              );
            default:
              await d.engine.sync();
          }
        }
        for (var round = 0; round < 2; round++) {
          for (final d in devices) {
            await d.engine.sync();
          }
        }
        final states = [for (final d in devices) await d.state()];
        expect(states[1], states[0]);
        expect(states[2], states[0]);
        // And the file says the same.
        expect(_canonical((await devices[0].engine.peek())!), states[0]);
      });
    }
  });
}
