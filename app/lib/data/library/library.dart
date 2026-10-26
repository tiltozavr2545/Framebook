import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_source.dart';
import '../db/database.dart';
import '../db/database_provider.dart';
import '../work_key.dart';
import 'divergence.dart';
import 'work_snapshot.dart';

/// A live rating with its title's snapshot and, for a season or an episode,
/// the snapshots of its ancestors — what a list row needs to say
/// "Game of Thrones · S1E3".
final class RatedTitle {
  const RatedTitle({
    required this.rating,
    required this.work,
    this.series,
    this.season,
    this.external = const {},
  });

  final Rating rating;
  final Work work;

  /// The cached Kinopoisk and IMDb rows, of any status — what "My ratings"
  /// and the statistics compare with. Only [watchRatings] fills them.
  final Map<RatingSource, ExternalRating> external;

  /// The series of a season or an episode.
  final Work? series;

  /// The season of an episode.
  final Work? season;

  WorkKey get key => WorkKey.parse(work.workKey);

  /// A poster for the row: an episode has none of its own, so the season's
  /// or the series' is used.
  String? get posterPath =>
      work.posterPath ?? season?.posterPath ?? series?.posterPath;

  /// "Mine − theirs" against [source], `null` without a cached value.
  double? divergenceFrom(RatingSource source) =>
      divergence(rating.scoreHalf, external[source]);

  /// The genres a title counts under: a season and an episode take the
  /// series' (docs/data-model.md, `works.genre_ids`).
  List<int> get genreIds => WorkSnapshot.fromWork(series ?? work).genreIds;
}

/// A live watchlist entry with its title's snapshot (films and series only).
final class WatchlistTitle {
  const WatchlistTitle({required this.entry, required this.work});

  final WatchlistEntry entry;
  final Work work;

  WorkKey get key => WorkKey.parse(work.workKey);
}

/// The average of a series' or a season's rated parts — a hint next to its
/// own score (docs/data-model.md, "Key queries").
final class PartsAverage {
  const PartsAverage({
    required this.average,
    required this.count,
    required this.parts,
  });

  /// In points, 1.0…10.0.
  final double average;
  final int count;

  /// [WorkKind.season] or [WorkKind.episode].
  final WorkKind parts;
}

/// What the calibration sheet shows after a score is saved: titles of the
/// same kind with the same score, and the nearest existing scores above and
/// below (docs/data-model.md, "Key queries").
final class Calibration {
  const Calibration({
    required this.same,
    required this.above,
    required this.below,
  });

  /// What fits under the score reel: four of the same, two each side.
  static const sameLimit = 4;
  static const neighbourLimit = 2;

  final List<RatedTitle> same;
  final List<RatedTitle> above;
  final List<RatedTitle> below;

  bool get isEmpty => same.isEmpty && above.isEmpty && below.isEmpty;
}

/// The user's own data: ratings, notes, the watchlist. Every write keeps the
/// sync invariants (AGENTS.md): snapshots of the title and its ancestors go
/// in the same transaction, deletion is a tombstone, `updated_at` changes on
/// every user change and only then, and never goes backwards.
final class Library {
  Library(this._db, {required this.deviceId, DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final AppDatabase _db;

  /// Written as `updated_by`.
  final String deviceId;
  final DateTime Function() _clock;

  int _now() => _clock().toUtc().millisecondsSinceEpoch;

  /// A new `updated_at`: now, but never at or before the previous one — an
  /// edit on a device with a lagging clock must at least beat its own
  /// previous version (docs/sync.md, "Device clocks").
  static int _next(int now, int previous) =>
      now > previous ? now : previous + 1;

  static void _checkScore(int scoreHalf) {
    if (scoreHalf < 2 || scoreHalf > 20) {
      throw RangeError.range(scoreHalf, 2, 20, 'scoreHalf');
    }
  }

  /// An empty or blank note is no note.
  static String? _cleanNote(String? note) {
    final trimmed = note?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Rates the last title of [lineage] (its ancestors come first), with a
  /// note. Rating a title takes it off the watchlist. Rating it again after
  /// deletion revives the same row; `created_at` stays from the first time.
  Future<void> rate(
    List<WorkSnapshot> lineage, {
    required int scoreHalf,
    required String? note,
  }) {
    _checkScore(scoreHalf);
    final key = lineage.last.key.toString();
    final cleanNote = _cleanNote(note);
    return _db.transaction(() async {
      final now = _now();
      await _putSnapshots(lineage, now);
      final old = await _ratingRow(key);
      if (old == null) {
        await _db
            .into(_db.ratings)
            .insert(
              RatingsCompanion.insert(
                workKey: key,
                scoreHalf: scoreHalf,
                note: Value(cleanNote),
                createdAt: now,
                scoredAt: now,
                updatedAt: now,
                updatedBy: deviceId,
              ),
            );
      } else {
        final revived = old.deletedAt != null;
        final rescored = revived || old.scoreHalf != scoreHalf;
        // Nothing changed — no new version that would needlessly win a
        // merge against a real edit from another device.
        if (!rescored && old.note == cleanNote) return;
        await (_db.update(
          _db.ratings,
        )..where((r) => r.workKey.equals(key))).write(
          RatingsCompanion(
            scoreHalf: Value(scoreHalf),
            note: Value(cleanNote),
            scoredAt: rescored ? Value(now) : const Value.absent(),
            updatedAt: Value(_next(now, old.updatedAt)),
            updatedBy: Value(deviceId),
            deletedAt: const Value(null),
          ),
        );
      }
      await _unlist(key, now);
    });
  }

  /// Changes the score of an already rated title (the calibration sheet's
  /// header), keeping its note.
  Future<void> rescore(WorkKey key, int scoreHalf) {
    _checkScore(scoreHalf);
    final k = key.toString();
    return _db.transaction(() async {
      final old = await _ratingRow(k);
      if (old == null || old.deletedAt != null) {
        throw StateError('$key is not rated');
      }
      if (old.scoreHalf == scoreHalf) return;
      final now = _now();
      await (_db.update(_db.ratings)..where((r) => r.workKey.equals(k))).write(
        RatingsCompanion(
          scoreHalf: Value(scoreHalf),
          scoredAt: Value(now),
          updatedAt: Value(_next(now, old.updatedAt)),
          updatedBy: Value(deviceId),
        ),
      );
    });
  }

  /// A tombstone, not a deletion: otherwise sync would bring the rating back
  /// from another device.
  Future<void> deleteRating(WorkKey key) {
    final k = key.toString();
    return _db.transaction(() async {
      final old = await _ratingRow(k);
      if (old == null || old.deletedAt != null) return;
      final now = _now();
      await (_db.update(_db.ratings)..where((r) => r.workKey.equals(k))).write(
        RatingsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(_next(now, old.updatedAt)),
          updatedBy: Value(deviceId),
        ),
      );
    });
  }

  Future<void> addToWatchlist(List<WorkSnapshot> lineage) {
    final key = lineage.last.key;
    if (key.kind != WorkKind.movie && key.kind != WorkKind.tv) {
      throw ArgumentError.value(key, 'lineage', 'films and series only');
    }
    final k = key.toString();
    return _db.transaction(() async {
      final now = _now();
      await _putSnapshots(lineage, now);
      final old = await _watchlistRow(k);
      if (old == null) {
        await _db
            .into(_db.watchlist)
            .insert(
              WatchlistCompanion.insert(
                workKey: k,
                addedAt: now,
                updatedAt: now,
                updatedBy: deviceId,
              ),
            );
      } else if (old.deletedAt != null) {
        await (_db.update(
          _db.watchlist,
        )..where((w) => w.workKey.equals(k))).write(
          WatchlistCompanion(
            addedAt: Value(now),
            updatedAt: Value(_next(now, old.updatedAt)),
            updatedBy: Value(deviceId),
            deletedAt: const Value(null),
          ),
        );
      }
    });
  }

  Future<void> removeFromWatchlist(WorkKey key) =>
      _db.transaction(() => _unlist(key.toString(), _now()));

  /// Refreshes the snapshots that already exist (the card was opened) without
  /// creating new ones and without touching any user row's `updated_at`.
  Future<void> refreshSnapshots(List<WorkSnapshot> lineage) =>
      _db.transaction(() async {
        final now = _now();
        for (final snapshot in lineage) {
          await (_db.update(_db.works)
                ..where((w) => w.workKey.equals(snapshot.key.toString())))
              .write(snapshot.toCompanion(now));
        }
      });

  Stream<Rating?> watchRating(WorkKey key) =>
      (_db.select(_db.ratings)..where(
            (r) => r.workKey.equals(key.toString()) & r.deletedAt.isNull(),
          ))
          .watchSingleOrNull();

  Stream<bool> watchInWatchlist(WorkKey key) =>
      (_db.select(_db.watchlist)..where(
            (w) => w.workKey.equals(key.toString()) & w.deletedAt.isNull(),
          ))
          .watchSingleOrNull()
          .map((row) => row != null);

  /// The average over a season's rated episodes; for a series, over its
  /// rated seasons, or — if none is rated — over the rated episodes of all
  /// its seasons. `null` when nothing below is rated.
  Stream<PartsAverage?> watchPartsAverage(WorkKey key) {
    if (key.kind != WorkKind.tv && key.kind != WorkKind.season) {
      return Stream.value(null);
    }
    final k = key.toString();
    final query = _db.select(_db.ratings).join([
      innerJoin(_db.works, _db.works.workKey.equalsExp(_db.ratings.workKey)),
    ])..where(_db.ratings.deletedAt.isNull());
    if (key.kind == WorkKind.season) {
      query.where(_db.works.parentKey.equals(k));
    } else {
      // Seasons have the series as parent; episodes have one of its seasons,
      // whose keys all start with "<series key>:s".
      query.where(
        _db.works.parentKey.equals(k) | _db.works.parentKey.like('$k:s%'),
      );
    }
    return query.watch().map((rows) {
      final byKind = <WorkKind, List<int>>{};
      for (final row in rows) {
        final work = row.readTable(_db.works);
        byKind
            .putIfAbsent(work.kind, () => [])
            .add(row.readTable(_db.ratings).scoreHalf);
      }
      final parts = byKind.containsKey(WorkKind.season)
          ? WorkKind.season
          : WorkKind.episode;
      final scores = byKind[parts];
      if (scores == null || scores.isEmpty) return null;
      final sum = scores.reduce((a, b) => a + b);
      return PartsAverage(
        average: sum / scores.length / 2,
        count: scores.length,
        parts: parts,
      );
    });
  }

  /// The calibration sheet for [key] just scored [scoreHalf]: live ratings
  /// of the same kind, without the title itself.
  Future<Calibration> calibration(WorkKey key, int scoreHalf) async {
    Expression<bool> sameKind() =>
        _db.ratings.deletedAt.isNull() &
        _db.works.kind.equalsValue(key.kind) &
        _db.ratings.workKey.equals(key.toString()).not();

    Future<List<RatedTitle>> withScore(int score, int limit) async {
      final rows =
          await (_db.select(_db.ratings).join([
                  innerJoin(
                    _db.works,
                    _db.works.workKey.equalsExp(_db.ratings.workKey),
                  ),
                ])
                ..where(sameKind() & _db.ratings.scoreHalf.equals(score))
                ..orderBy([OrderingTerm.desc(_db.ratings.scoredAt)])
                ..limit(limit))
              .get();
      return _withAncestors([
        for (final row in rows)
          (row.readTable(_db.ratings), row.readTable(_db.works), const {}),
      ]);
    }

    Future<int?> nearest(bool above) async {
      final score = _db.ratings.scoreHalf;
      final pick = above ? score.min() : score.max();
      final row =
          await (_db.selectOnly(_db.ratings).join([
                  innerJoin(
                    _db.works,
                    _db.works.workKey.equalsExp(_db.ratings.workKey),
                  ),
                ])
                ..addColumns([pick])
                ..where(
                  sameKind() &
                      (above
                          ? score.isBiggerThanValue(scoreHalf)
                          : score.isSmallerThanValue(scoreHalf)),
                ))
              .getSingle();
      return row.read(pick);
    }

    final aboveScore = await nearest(true);
    final belowScore = await nearest(false);
    return Calibration(
      same: await withScore(scoreHalf, Calibration.sameLimit),
      above: aboveScore == null
          ? const []
          : await withScore(aboveScore, Calibration.neighbourLimit),
      below: belowScore == null
          ? const []
          : await withScore(belowScore, Calibration.neighbourLimit),
    );
  }

  /// Every live rating with its snapshots, for "My ratings". Sorting and
  /// filtering are [arrangeRatings], so they are testable without a database.
  ///
  /// The Kinopoisk and IMDb rows are joined in, so the list re-emits when
  /// background refresh brings a new value.
  Stream<List<RatedTitle>> watchRatings() {
    final compared = {
      for (final source in compareSources)
        source: _db.alias(_db.externalRatings, source.name),
    };
    return (_db.select(_db.ratings).join([
      innerJoin(_db.works, _db.works.workKey.equalsExp(_db.ratings.workKey)),
      for (final MapEntry(key: source, value: table) in compared.entries)
        leftOuterJoin(
          table,
          table.workKey.equalsExp(_db.ratings.workKey) &
              table.source.equalsValue(source),
        ),
    ])..where(_db.ratings.deletedAt.isNull())).watch().asyncMap(
      (rows) => _withAncestors([
        for (final row in rows)
          (
            row.readTable(_db.ratings),
            row.readTable(_db.works),
            {
              for (final MapEntry(key: source, value: table)
                  in compared.entries)
                if (row.readTableOrNull(table) case final found?) source: found,
            },
          ),
      ]),
    );
  }

  /// The live watchlist, most recently added first.
  Stream<List<WatchlistTitle>> watchWatchlist() =>
      (_db.select(_db.watchlist).join([
              innerJoin(
                _db.works,
                _db.works.workKey.equalsExp(_db.watchlist.workKey),
              ),
            ])
            ..where(_db.watchlist.deletedAt.isNull())
            ..orderBy([OrderingTerm.desc(_db.watchlist.addedAt)]))
          .watch()
          .map(
            (rows) => [
              for (final row in rows)
                WatchlistTitle(
                  entry: row.readTable(_db.watchlist),
                  work: row.readTable(_db.works),
                ),
            ],
          );

  Future<Rating?> _ratingRow(String key) => (_db.select(
    _db.ratings,
  )..where((r) => r.workKey.equals(key))).getSingleOrNull();

  Future<WatchlistEntry?> _watchlistRow(String key) => (_db.select(
    _db.watchlist,
  )..where((w) => w.workKey.equals(key))).getSingleOrNull();

  /// Upserts the snapshots, ancestors first (the foreign keys want them).
  Future<void> _putSnapshots(List<WorkSnapshot> lineage, int now) async {
    for (final snapshot in lineage) {
      await _db
          .into(_db.works)
          .insertOnConflictUpdate(snapshot.toCompanion(now));
    }
  }

  /// Takes a title off the watchlist with a tombstone, if it is on it.
  Future<void> _unlist(String key, int now) async {
    final listed = await _watchlistRow(key);
    if (listed == null || listed.deletedAt != null) return;
    await (_db.update(
      _db.watchlist,
    )..where((w) => w.workKey.equals(key))).write(
      WatchlistCompanion(
        deletedAt: Value(now),
        updatedAt: Value(_next(now, listed.updatedAt)),
        updatedBy: Value(deviceId),
      ),
    );
  }

  /// Attaches the series (and, for an episode, the season) snapshots.
  Future<List<RatedTitle>> _withAncestors(
    List<(Rating, Work, Map<RatingSource, ExternalRating>)> rows,
  ) async {
    final ancestorKeys = {
      for (final (_, work, _) in rows)
        for (final ancestor in WorkKey.parse(work.workKey).lineage)
          if (ancestor.kind != work.kind) ancestor.toString(),
    };
    final ancestors = ancestorKeys.isEmpty
        ? const <String, Work>{}
        : {
            for (final work in await (_db.select(
              _db.works,
            )..where((w) => w.workKey.isIn(ancestorKeys))).get())
              work.workKey: work,
          };
    return [
      for (final (rating, work, external) in rows)
        _rated(rating, work, external, WorkKey.parse(work.workKey), ancestors),
    ];
  }

  static RatedTitle _rated(
    Rating rating,
    Work work,
    Map<RatingSource, ExternalRating> external,
    WorkKey key,
    Map<String, Work> ancestors,
  ) => RatedTitle(
    rating: rating,
    work: work,
    external: external,
    series: key.kind == WorkKind.season || key.kind == WorkKind.episode
        ? ancestors[WorkKey.tv(key.tmdbId).toString()]
        : null,
    season: key.kind == WorkKind.episode
        ? ancestors[key.parent.toString()]
        : null,
  );
}

/// How "My ratings" is ordered.
enum RatingsSort { scoredAt, score, year, title, divergence }

/// The direction of the divergence sort.
enum DivergenceOrder {
  /// The largest gap either way first.
  furthest,

  /// Where I rate higher than [compareWith] first.
  higher,

  /// Where I rate lower first.
  lower,
}

/// Filters "My ratings" by kind (`null` — all) and sorts it. Ties are broken
/// by the most recent score, so the order is stable. Sorting by divergence
/// compares with [compareWith]; titles without its value go to the end rather
/// than dropping out (docs/data-model.md, "Key queries").
List<RatedTitle> arrangeRatings(
  Iterable<RatedTitle> titles, {
  WorkKind? kind,
  RatingsSort sort = RatingsSort.scoredAt,
  RatingSource compareWith = RatingSource.kp,
  DivergenceOrder order = DivergenceOrder.furthest,
}) {
  int byRecent(RatedTitle a, RatedTitle b) =>
      b.rating.scoredAt.compareTo(a.rating.scoredAt);
  int byDivergence(RatedTitle a, RatedTitle b) {
    final da = a.divergenceFrom(compareWith);
    final db = b.divergenceFrom(compareWith);
    if (da == null || db == null) {
      return da == db ? 0 : (da == null ? 1 : -1);
    }
    return switch (order) {
      DivergenceOrder.furthest => db.abs().compareTo(da.abs()),
      DivergenceOrder.higher => db.compareTo(da),
      DivergenceOrder.lower => da.compareTo(db),
    };
  }

  final list = [
    for (final title in titles)
      if (kind == null || title.work.kind == kind) title,
  ];
  list.sort(
    (a, b) => switch (sort) {
      RatingsSort.scoredAt => byRecent(a, b),
      RatingsSort.score => _then(
        b.rating.scoreHalf.compareTo(a.rating.scoreHalf),
        () => byRecent(a, b),
      ),
      // Newest first; titles without a year go last.
      RatingsSort.year => _then(
        _yearDescending(a.work.year, b.work.year),
        () => byRecent(a, b),
      ),
      RatingsSort.title => _then(
        sortTitle(a).compareTo(sortTitle(b)),
        () => byRecent(a, b),
      ),
      RatingsSort.divergence => _then(byDivergence(a, b), () => byRecent(a, b)),
    },
  );
  return list;
}

/// What a title sorts by: a season or an episode sorts under its series, in
/// number order.
String sortTitle(RatedTitle title) {
  final key = title.key;
  final name = (title.series?.title ?? title.work.title).toLowerCase();
  String pad(int? n) => (n ?? 0).toString().padLeft(4, '0');
  return switch (key.kind) {
    WorkKind.movie || WorkKind.tv => name,
    WorkKind.season => '$name\u0000${pad(key.season)}',
    WorkKind.episode => '$name\u0000${pad(key.season)}${pad(key.episode)}',
  };
}

int _then(int first, int Function() next) => first != 0 ? first : next();

/// Newer years first; a title without a year goes after every dated one.
int _yearDescending(int? a, int? b) {
  if (a == b) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

/// Overridden in `main()`: the id is read from the database before `runApp`.
final deviceIdProvider = Provider<String>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

final libraryProvider = Provider<Library>(
  (ref) => Library(
    ref.watch(databaseProvider),
    deviceId: ref.watch(deviceIdProvider),
  ),
);

/// The user's live rating of a title, `null` if it isn't rated.
final myRatingProvider = StreamProvider.autoDispose.family<Rating?, WorkKey>(
  (ref, key) => ref.watch(libraryProvider).watchRating(key),
);

final inWatchlistProvider = StreamProvider.autoDispose.family<bool, WorkKey>(
  (ref, key) => ref.watch(libraryProvider).watchInWatchlist(key),
);

final partsAverageProvider = StreamProvider.autoDispose
    .family<PartsAverage?, WorkKey>(
      (ref, key) => ref.watch(libraryProvider).watchPartsAverage(key),
    );

final ratedTitlesProvider = StreamProvider.autoDispose<List<RatedTitle>>(
  (ref) => ref.watch(libraryProvider).watchRatings(),
);

final watchlistTitlesProvider =
    StreamProvider.autoDispose<List<WatchlistTitle>>(
      (ref) => ref.watch(libraryProvider).watchWatchlist(),
    );
