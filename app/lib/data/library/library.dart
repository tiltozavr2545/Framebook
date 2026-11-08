import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_source.dart';
import '../db/database.dart';
import '../db/database_provider.dart';
import '../distinct_stream.dart';
import '../sync/merge.dart';
import '../sync/sync_file.dart';
import '../sync/sync_store.dart';
import '../work_key.dart';
import '../timestamps.dart';
import 'divergence.dart';
import 'library_models.dart';
import 'rating_note.dart';
import 'renumbering.dart';
import 'work_snapshot.dart';

export 'library_models.dart';
export 'library_sort.dart';

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
  static int _next(int now, int previous) => nextTimestampMillis(now, previous);

  Future<int> _deletionTime(String storageKey, String key) =>
      SyncStore(_db).deletionTime(storageKey, key);

  static void _checkScore(int scoreHalf) {
    if (scoreHalf < 2 || scoreHalf > 20) {
      throw RangeError.range(scoreHalf, 2, 20, 'scoreHalf');
    }
  }

  /// An empty or blank note is no note.
  static String? _cleanNote(String? note) {
    final trimmed = note?.trim();
    if (!validRatingNote(trimmed)) {
      throw ArgumentError('Note exceeds the code point limit');
    }
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
                updatedAt: _next(
                  now,
                  await _deletionTime(SyncStore.ratingDeletionsKey, key),
                ),
                updatedBy: deviceId,
              ),
            );
      } else {
        final revived = old.deletedAt != null;
        final rescored = revived || old.scoreHalf != scoreHalf;
        // Nothing changed — no new version that would needlessly win a
        // merge against a real edit from another device.
        if (!rescored && old.note == cleanNote) {
          await _unlist(key, now);
          return;
        }
        await (_db.update(
          _db.ratings,
        )..where((r) => r.workKey.equals(key))).write(
          RatingsCompanion(
            scoreHalf: Value(scoreHalf),
            note: Value(cleanNote),
            scoredAt: revived ? Value(now) : const Value.absent(),
            updatedAt: Value(_next(now, old.updatedAt)),
            updatedBy: Value(deviceId),
            deletedAt: const Value(null),
          ),
        );
      }
      if (lineage.last.key.kind == WorkKind.season) {
        await _unlistForSeasonRating(key, now);
      } else {
        await _unlist(key, now);
      }
    });
  }

  /// Changes the score of an already rated title (the calibration sheet's
  /// header), keeping its note and diary date.
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
          updatedAt: Value(_next(now, old.updatedAt)),
          updatedBy: Value(deviceId),
        ),
      );
      if (key.kind == WorkKind.season) await _unlistForSeasonRating(k, now);
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
      if (key.kind == WorkKind.season) await _unlistForSeasonRating(k, now);
    });
  }

  Future<void> addToWatchlist(List<WorkSnapshot> lineage) {
    final key = lineage.last.key;
    if (key.kind == WorkKind.episode) {
      throw ArgumentError.value(
        key,
        'lineage',
        'films, series and seasons only',
      );
    }
    final k = key.toString();
    return _db.transaction(() async {
      final now = _now();
      if (key.kind == WorkKind.season) {
        final rating = await _ratingRow(k);
        if (rating != null && rating.deletedAt == null) return;
      }
      final store = SyncStore(_db);
      final fences = key.kind == WorkKind.movie
          ? const <WatchlistFence>[]
          : await store.readWatchlistFences();
      final old = await _watchlistRow(k);
      if (old != null && visibleWatchlistEntry(old, fences)) {
        return;
      }
      await _putSnapshots(lineage, now, adopt: key);
      final series = key.kind == WorkKind.tv
          ? key
          : key.kind == WorkKind.season
          ? key.parent
          : null;
      var version = now;
      if (old != null && version <= old.updatedAt) {
        version = _next(version, old.updatedAt);
      }
      final deletion = await _deletionTime(SyncStore.watchlistDeletionsKey, k);
      if (version <= deletion) version = _next(version, deletion);
      if (series != null) {
        for (final fence in fences) {
          if (fence.seriesKey == series.toString() &&
              version <= fence.updatedAt) {
            version = _next(version, fence.updatedAt);
          }
        }
        final fence = WatchlistFence(
          seriesKey: series.toString(),
          season: key.kind == WorkKind.season,
          updatedAt: version,
          updatedBy: deviceId,
        );
        await store.saveFences(
          mergeStates(
            SyncState(watchlistFences: fences),
            SyncState(watchlistFences: [fence]),
          ).watchlistFences,
        );
        if (key.kind == WorkKind.season) {
          await _unlist(series.toString(), version, preserveFences: false);
        } else {
          final seasons =
              await (_db.select(_db.watchlist).join([
                    innerJoin(
                      _db.works,
                      _db.works.workKey.equalsExp(_db.watchlist.workKey),
                    ),
                  ])..where(
                    _db.works.parentKey.equals(k) &
                        _db.works.kind.equalsValue(WorkKind.season) &
                        _db.watchlist.deletedAt.isNull(),
                  ))
                  .get();
          for (final row in seasons) {
            await _unlist(
              row.readTable(_db.watchlist).workKey,
              version,
              preserveFences: false,
            );
          }
        }
      }
      if (old == null) {
        await _db
            .into(_db.watchlist)
            .insert(
              WatchlistCompanion.insert(
                workKey: k,
                addedAt: now,
                updatedAt: version,
                updatedBy: deviceId,
              ),
            );
      } else {
        await (_db.update(
          _db.watchlist,
        )..where((w) => w.workKey.equals(k))).write(
          WatchlistCompanion(
            addedAt: Value(now),
            updatedAt: Value(version),
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
  ///
  /// A rated season's or episode's own TMDB id is kept when TMDB now has
  /// another title under that number: it is how the rating finds its title
  /// again ([moveRatings]), and only the user's answer replaces it.
  Future<void> refreshSnapshots(List<WorkSnapshot> lineage) =>
      _db.transaction(() => _putSnapshots(lineage, _now(), insert: false));

  /// Refresh a translated title without adopting a renumbered part or
  /// changing the version of its rating or watchlist entry.
  Future<void> refreshLocalizedTitle(
    WorkKey key,
    String title,
    int expectedId,
    bool Function() valid,
  ) => _db.transaction(() async {
    if (!valid() || title.isEmpty) return;
    final row = await (_db.select(
      _db.works,
    )..where((w) => w.workKey.equals(key.toString()))).getSingleOrNull();
    if (!valid() ||
        row == null ||
        row.tmdbId != expectedId ||
        row.title == title) {
      return;
    }
    await (_db.update(_db.works)..where((w) => w.workKey.equals(row.workKey)))
        .write(WorksCompanion(title: Value(title)));
  });

  /// The live ratings of [series]' seasons, or of its episodes in every
  /// season ([kind]), with the TMDB ids stored with them — what renumbering
  /// is detected from (lib/data/library/renumbering.dart).
  Stream<List<RatedPart>> watchRatedParts(WorkKey series, WorkKind kind) {
    if (series.kind != WorkKind.tv ||
        (kind != WorkKind.season && kind != WorkKind.episode)) {
      throw ArgumentError('seasons or episodes of a series');
    }
    final k = series.toString();
    final query = _db.select(_db.ratings).join(
      [innerJoin(_db.works, _db.works.workKey.equalsExp(_db.ratings.workKey))],
    )..where(_db.ratings.deletedAt.isNull() & _db.works.kind.equalsValue(kind));
    query.where(
      kind == WorkKind.season
          ? _db.works.parentKey.equals(k)
          : _db.works.parentKey.like('$k:s%'),
    );
    return query.watch().map(
      (rows) => [
        for (final row in rows)
          RatedPart(
            key: WorkKey.parse(row.readTable(_db.works).workKey),
            tmdbId: row.readTable(_db.works).tmdbId,
            scoreHalf: row.readTable(_db.ratings).scoreHalf,
          ),
      ],
    );
  }

  /// Moves ratings after TMDB renumbered (the user said "Move"): each move
  /// takes its rating from `from` to the last title of `to` (a lineage,
  /// ancestors first). All moves are applied at once, so a shift or a swap
  /// works: every source is read before anything is written.
  ///
  /// The source becomes a tombstone (its snapshot stays: the tombstone
  /// refers to it) and loses its cached external ratings, which were fetched
  /// by its numbers for another title. The target gets the moved score,
  /// note, `created_at` and `scored_at`, replacing a live rating there —
  /// unless the target is in [keepExisting], when only the source is
  /// tombstoned. The target's snapshot is written with the id TMDB has now.
  Future<void> moveRatings(
    List<({WorkKey from, List<WorkSnapshot> to})> moves, {
    Set<WorkKey> keepExisting = const {},
  }) => _db.transaction(() async {
    if (moves.isEmpty) return;
    final now = _now();
    final sources = {for (final move in moves) move.from.toString()};
    final targets = {
      for (final move in moves) move.to.last.key.toString(): move,
    };
    final rows = {
      for (final rating in await (_db.select(
        _db.ratings,
      )..where((r) => r.workKey.isIn({...sources, ...targets.keys}))).get())
        rating.workKey: rating,
    };

    final sourceWorks = {
      for (final work in await (_db.select(
        _db.works,
      )..where((w) => w.workKey.isIn(sources))).get())
        work.workKey: work,
    };
    if (sources.length != moves.length || targets.length != moves.length) {
      throw ArgumentError('Renumbering sources and targets must be unique');
    }
    for (final move in moves) {
      if (move.from.kind != move.to.last.key.kind ||
          move.from.tmdbId != move.to.last.key.tmdbId) {
        throw ArgumentError('Renumbering must preserve title kind and series');
      }
      final source = move.from.toString();
      if (rows[source] == null ||
          rows[source]!.deletedAt != null ||
          sourceWorks[source]?.tmdbId != move.to.last.tmdbId) {
        throw StateError('Renumbering source changed');
      }
    }
    for (final move in moves) {
      await _putSnapshots(move.to, now, adopt: move.to.last.key);
      final source = sourceWorks[move.from.toString()];
      if (source != null &&
          source.tmdbId == move.to.last.tmdbId &&
          source.imdbId != null) {
        await (_db.update(_db.works)
              ..where((w) => w.workKey.equals(move.to.last.key.toString())))
            .write(WorksCompanion(imdbId: Value(source.imdbId)));
      }
    }
    bool live(Rating? rating) => rating != null && rating.deletedAt == null;
    for (final source in sources) {
      final old = rows[source];
      if (old == null || old.deletedAt != null) continue;
      // A shift or a swap: another rating moves in, overwritten below.
      if (targets[source] case final incoming?
          when live(rows[incoming.from.toString()])) {
        continue;
      }
      await (_db.update(
        _db.ratings,
      )..where((r) => r.workKey.equals(source))).write(
        RatingsCompanion(
          deletedAt: Value(now),
          updatedAt: Value(_next(now, old.updatedAt)),
          updatedBy: Value(deviceId),
        ),
      );
    }
    for (final MapEntry(key: target, value: move) in targets.entries) {
      final moved = rows[move.from.toString()];
      if (moved == null || moved.deletedAt != null) continue;
      final existing = rows[target];
      if (live(existing) &&
          !sources.contains(target) &&
          keepExisting.contains(move.to.last.key)) {
        continue;
      }
      if (existing == null) {
        await _db
            .into(_db.ratings)
            .insert(
              RatingsCompanion.insert(
                workKey: target,
                scoreHalf: moved.scoreHalf,
                note: Value(moved.note),
                createdAt: moved.createdAt,
                scoredAt: moved.scoredAt,
                updatedAt: _next(
                  now,
                  await _deletionTime(SyncStore.ratingDeletionsKey, target),
                ),
                updatedBy: deviceId,
              ),
            );
      } else {
        await (_db.update(
          _db.ratings,
        )..where((r) => r.workKey.equals(target))).write(
          RatingsCompanion(
            scoreHalf: Value(moved.scoreHalf),
            note: Value(moved.note),
            createdAt: Value(moved.createdAt),
            scoredAt: Value(moved.scoredAt),
            updatedAt: Value(_next(now, existing.updatedAt)),
            updatedBy: Value(deviceId),
            deletedAt: const Value(null),
          ),
        );
      }
    }
    await (_db.delete(
      _db.externalRatings,
    )..where((e) => e.workKey.isIn(sources))).go();
  });

  /// Moves visible watchlisted seasons together after a TMDB renumbering.
  /// A target already rated is not added back to the watchlist.
  Future<void> moveWatchlistedSeasons(
    List<({WorkKey from, List<WorkSnapshot> to})> moves,
  ) => _db.transaction(() async {
    if (moves.isEmpty) return;
    final series = moves.first.from.parent;
    if (series == null ||
        moves.any(
          (m) =>
              m.from.kind != WorkKind.season ||
              m.from.parent != series ||
              m.to.last.key.kind != WorkKind.season ||
              m.to.last.key.parent != series,
        )) {
      throw ArgumentError('moves must contain seasons of the same series');
    }
    final store = SyncStore(_db);
    final state = await store.read();
    final rows = {for (final row in state.watchlist) row.workKey: row};
    final sources = {
      for (final move in moves)
        if (rows[move.from.toString()] case final row?
            when visibleWatchlistEntry(row, state.watchlistFences))
          move.from.toString(): row,
    };
    final sourceWorks = {for (final work in state.works) work.workKey: work};
    for (final move in moves) {
      final source = move.from.toString();
      if (!sources.containsKey(source) ||
          sourceWorks[source]?.tmdbId != move.to.last.tmdbId) {
        throw StateError('Renumbering source changed');
      }
    }
    var previous = 0;
    for (final fence in state.watchlistFences) {
      if (fence.seriesKey == series.toString()) {
        previous = max(previous, fence.updatedAt);
      }
    }
    for (final row in state.watchlist) {
      final key = WorkKey.parse(row.workKey);
      if (key == series || key.parent == series) {
        previous = max(previous, row.updatedAt);
      }
    }
    for (final deletion in state.watchlistDeletions) {
      if (moves.any(
        (move) => move.to.last.key.toString() == deletion.workKey,
      )) {
        previous = max(previous, deletion.updatedAt);
      }
    }
    final now = _now();
    final version = _next(now, previous);
    final fence = WatchlistFence(
      seriesKey: series.toString(),
      season: true,
      updatedAt: version,
      updatedBy: deviceId,
    );
    await store.saveFences(
      mergeStates(state, SyncState(watchlistFences: [fence])).watchlistFences,
    );
    await _unlist(series.toString(), version);
    final targets = {
      for (final move in moves)
        if (sources.containsKey(move.from.toString()))
          move.to.last.key.toString(): move,
    };
    final ratedTargets = <String>{};
    for (final entry in targets.entries) {
      final rating = await _ratingRow(entry.key);
      if (rating != null && rating.deletedAt == null) {
        ratedTargets.add(entry.key);
      }
      await _putSnapshots(
        entry.value.to,
        now,
        adopt: ratedTargets.contains(entry.key)
            ? null
            : entry.value.to.last.key,
      );
    }
    for (final source in sources.keys) {
      if (targets.containsKey(source) && !ratedTargets.contains(source)) {
        continue;
      }
      await _unlist(source, version);
    }
    for (final entry in targets.entries) {
      final target = entry.key;
      if (ratedTargets.contains(target)) {
        await _unlist(target, version);
        continue;
      }
      final existing = rows[target];
      if (existing != null &&
          visibleWatchlistEntry(existing, state.watchlistFences) &&
          !sources.containsKey(target)) {
        continue;
      }
      final moved = sources[entry.value.from.toString()]!;
      await _db
          .into(_db.watchlist)
          .insertOnConflictUpdate(
            WatchlistEntry(
              workKey: target,
              addedAt: moved.addedAt,
              updatedAt: version,
              updatedBy: deviceId,
              deletedAt: null,
            ).toCompanion(false),
          );
    }
  });

  /// "Keep" after TMDB renumbered: each rating stays on its number and now
  /// belongs to the title TMDB has there, so its snapshot takes that title's
  /// id and the question doesn't come back. `null` — the title under the
  /// number isn't known on this screen (another season, or the number is
  /// gone): the series' id stands in, and the next refresh of that card
  /// takes the real one. Ratings themselves are not touched.
  Future<void> keepRatings(
    Map<WorkKey, int?> currentIds, {
    Map<WorkKey, int>? expectedIds,
  }) => _db.transaction(() async {
    final now = _now();
    for (final MapEntry(:key, value: id) in currentIds.entries) {
      final old = await (_db.select(
        _db.works,
      )..where((w) => w.workKey.equals(key.toString()))).getSingleOrNull();
      if (expectedIds != null && old?.tmdbId != expectedIds[key]) {
        throw StateError('Renumbering source changed');
      }
      await (_db.update(
        _db.works,
      )..where((w) => w.workKey.equals(key.toString()))).write(
        WorksCompanion(
          tmdbId: Value(id ?? key.tmdbId),
          imdbId: old?.tmdbId == (id ?? key.tmdbId)
              ? const Value.absent()
              : const Value(null),
          kpId: old?.tmdbId == (id ?? key.tmdbId)
              ? const Value.absent()
              : const Value(null),
          snapshotUpdatedAt: Value(
            old == null ? now : _next(now, old.snapshotUpdatedAt),
          ),
        ),
      );
      if (old?.tmdbId != (id ?? key.tmdbId)) {
        await (_db.delete(
          _db.externalRatings,
        )..where((r) => r.workKey.equals(key.toString()))).go();
      }
    }
  });

  /// The saved snapshots of [key] and its ancestors, series first; `null`
  /// when the title itself has none (never rated or listed). What a card
  /// shows offline (docs/client-architecture.md, "Title card").
  Future<List<Work>?> lineage(WorkKey key) async {
    final keys = [for (final k in key.lineage) k.toString()];
    final works = {
      for (final w in await (_db.select(
        _db.works,
      )..where((w) => w.workKey.isIn(keys))).get())
        w.workKey: w,
    };
    if (!works.containsKey(key.toString())) return null;
    return [
      for (final k in keys)
        if (works[k] case final work?) work,
    ];
  }

  Stream<Rating?> watchRating(WorkKey key) =>
      (_db.select(_db.ratings)..where(
            (r) => r.workKey.equals(key.toString()) & r.deletedAt.isNull(),
          ))
          .watchSingleOrNull();

  Stream<bool> watchInWatchlist(WorkKey key) => _db
      .customSelect(
        'SELECT 1',
        readsFrom: {_db.watchlist, _db.ratings, _db.syncState},
      )
      .watch()
      .asyncMap((_) async {
        final row = await _watchlistRow(key.toString());
        if (key.kind == WorkKind.season) {
          final rating = await _ratingRow(key.toString());
          if (rating != null && rating.deletedAt == null) return false;
        }
        return row != null &&
            visibleWatchlistEntry(row, await SyncStore(_db).fences());
      });

  /// The average over a season's rated episodes; for a series, over its
  /// rated seasons, or — if none is rated — over the rated episodes of all
  /// its seasons. `null` when nothing below is rated.
  Stream<PartsAverage?> watchPartsAverage(WorkKey key) {
    if (key.kind != WorkKind.tv && key.kind != WorkKind.season) {
      return Stream.value(null);
    }
    final k = key.toString();
    final kind = _db.works.kind;
    final count = _db.ratings.workKey.count();
    final average = _db.ratings.scoreHalf.avg();
    final query =
        _db.selectOnly(_db.ratings).join([
            innerJoin(
              _db.works,
              _db.works.workKey.equalsExp(_db.ratings.workKey),
              useColumns: false,
            ),
          ])
          ..addColumns([kind, count, average])
          ..where(_db.ratings.deletedAt.isNull())
          ..groupBy([kind]);
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
      if (rows.isEmpty) return null;
      final row = rows.firstWhere(
        (row) => row.readWithConverter(kind) == WorkKind.season,
        orElse: () => rows.first,
      );
      return PartsAverage(
        average: row.read(average)! / 2,
        count: row.read(count)!,
        parts: row.readWithConverter(kind)!,
      );
    });
  }

  /// Whether there are enough other live ratings of this kind to compare.
  Future<bool> hasCalibration(WorkKey key) async {
    final count = _db.ratings.workKey.count();
    final row =
        await (_db.selectOnly(_db.ratings).join([
                innerJoin(
                  _db.works,
                  _db.works.workKey.equalsExp(_db.ratings.workKey),
                ),
              ])
              ..addColumns([count])
              ..where(
                _db.ratings.deletedAt.isNull() &
                    _db.works.kind.equalsValue(key.kind) &
                    _db.ratings.workKey.equals(key.toString()).not(),
              ))
            .getSingle();
    final threshold = key.kind == WorkKind.movie ? 20 : 10;
    return (row.read(count) ?? 0) > threshold;
  }

  /// The calibration sheet for [key] just scored [scoreHalf]: live ratings
  /// of the same kind, without the title itself.
  Future<Calibration> calibration(WorkKey key, int scoreHalf) async {
    Expression<bool> sameKind() =>
        _db.ratings.deletedAt.isNull() &
        _db.works.kind.equalsValue(key.kind) &
        _db.ratings.workKey.equals(key.toString()).not();

    Future<List<RatedTitle>> withScore(int score) async {
      final rows =
          await (_db.select(_db.ratings).join([
                  innerJoin(
                    _db.works,
                    _db.works.workKey.equalsExp(_db.ratings.workKey),
                  ),
                ])
                ..where(sameKind() & _db.ratings.scoreHalf.equals(score))
                ..orderBy([
                  OrderingTerm.desc(_db.ratings.scoredAt),
                  OrderingTerm.asc(_db.ratings.workKey),
                ]))
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
      same: await withScore(scoreHalf),
      above: aboveScore == null ? const [] : await withScore(aboveScore),
      below: belowScore == null ? const [] : await withScore(belowScore),
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
    return distinctData(
      (_db.select(_db.ratings).join([
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
                  if (row.readTableOrNull(table) case final found?)
                    source: found,
              },
            ),
        ]),
      ),
      _sameRatings,
    );
  }

  /// Visible entries and their series snapshots, most recently added first.
  Stream<List<WatchlistTitle>> watchWatchlist() => distinctData(
    _db
        .customSelect(
          'SELECT 1',
          readsFrom: {_db.watchlist, _db.ratings, _db.works, _db.syncState},
        )
        .watch()
        .asyncMap(
          (_) => _db.transaction(() async {
            final rows =
                await (_db.select(_db.watchlist).join([
                        innerJoin(
                          _db.works,
                          _db.works.workKey.equalsExp(_db.watchlist.workKey),
                        ),
                      ])
                      ..where(_db.watchlist.deletedAt.isNull())
                      ..orderBy([OrderingTerm.desc(_db.watchlist.addedAt)]))
                    .get();
            final entries = [
              for (final row in rows) row.readTable(_db.watchlist),
            ];
            final fences = await SyncStore(_db).effectiveFences(entries);
            final bySeries = <String, List<WatchlistFence>>{};
            for (final fence in fences) {
              bySeries.putIfAbsent(fence.seriesKey, () => []).add(fence);
            }
            final seasons = {
              for (final row in rows)
                if (row.readTable(_db.works).kind == WorkKind.season)
                  row.readTable(_db.works).workKey,
            };
            final rated = <String>{};
            final parents = <String, Work>{};
            // Bound SQLite parameter counts and never materialize rating notes.
            final keys = seasons.toList();
            for (var offset = 0; offset < keys.length; offset += 400) {
              final chunk = keys.skip(offset).take(400).toList();
              final query = _db.selectOnly(_db.ratings)
                ..addColumns([_db.ratings.workKey])
                ..where(
                  _db.ratings.deletedAt.isNull() &
                      _db.ratings.workKey.isIn(chunk),
                );
              rated.addAll([
                for (final row in await query.get())
                  row.read(_db.ratings.workKey)!,
              ]);
              final series = chunk
                  .map((key) => WorkKey.parse(key).parent.toString())
                  .toSet();
              for (final work in await (_db.select(
                _db.works,
              )..where((w) => w.workKey.isIn(series))).get()) {
                parents[work.workKey] = work;
              }
            }
            return [
              for (final row in rows)
                if (row.readTable(_db.watchlist) case final entry)
                  if (!rated.contains(entry.workKey) &&
                      visibleWatchlistEntry(
                        entry,
                        bySeries[(WorkKey.parse(entry.workKey).kind ==
                                        WorkKind.tv
                                    ? WorkKey.parse(entry.workKey)
                                    : WorkKey.parse(entry.workKey).parent)
                                .toString()] ??
                            const [],
                      ))
                    WatchlistTitle(
                      entry: entry,
                      work: row.readTable(_db.works),
                      series:
                          parents[WorkKey.parse(
                            entry.workKey,
                          ).parent.toString()],
                    ),
            ];
          }),
        ),
    _sameWatchlist,
  );

  static bool _sameRatings(List<RatedTitle> previous, List<RatedTitle> next) {
    if (previous.length != next.length) return false;
    for (var i = 0; i < next.length; i++) {
      final a = previous[i], b = next[i];
      if (a.rating != b.rating ||
          a.work != b.work ||
          a.series != b.series ||
          a.season != b.season ||
          !mapEquals(a.external, b.external)) {
        return false;
      }
    }
    return true;
  }

  static bool _sameWatchlist(
    List<WatchlistTitle> previous,
    List<WatchlistTitle> next,
  ) {
    if (previous.length != next.length) return false;
    for (var i = 0; i < next.length; i++) {
      final a = previous[i], b = next[i];
      if (a.entry != b.entry || a.work != b.work || a.series != b.series) {
        return false;
      }
    }
    return true;
  }

  Future<Rating?> _ratingRow(String key) => (_db.select(
    _db.ratings,
  )..where((r) => r.workKey.equals(key))).getSingleOrNull();

  Future<WatchlistEntry?> _watchlistRow(String key) => (_db.select(
    _db.watchlist,
  )..where((w) => w.workKey.equals(key))).getSingleOrNull();

  /// Upserts the snapshots, ancestors first (the foreign keys want them);
  /// with [insert] off, only refreshes the ones that exist.
  ///
  /// A stored own TMDB id of a season or an episode survives the write when
  /// the new one is the stand-in (TMDB sent none), and when the title has a
  /// live rating and TMDB now has another title under its number — that is
  /// a renumbering waiting for the user's answer (docs/data-model.md). Only
  /// [adopt], the target of a move, takes the new id regardless.
  Future<void> _putSnapshots(
    List<WorkSnapshot> lineage,
    int now, {
    bool insert = true,
    WorkKey? adopt,
  }) async {
    for (final snapshot in lineage) {
      final k = snapshot.key.toString();
      final stored = await (_db.select(
        _db.works,
      )..where((w) => w.workKey.equals(k))).getSingleOrNull();
      var row = snapshot.toCompanion(now);
      if (stored == null) {
        if (insert) await _db.into(_db.works).insert(row);
        continue;
      }
      if (snapshot.key != adopt && await _keepsOwnId(stored, snapshot)) {
        continue;
      }
      row = row.copyWith(
        snapshotUpdatedAt: Value(_next(now, stored.snapshotUpdatedAt)),
      );
      if (stored.tmdbId != snapshot.tmdbId &&
          stored.tmdbId != snapshot.key.tmdbId) {
        row = row.copyWith(
          imdbId: Value(snapshot.imdbId),
          kpId: const Value(null),
        );
        await (_db.delete(
          _db.externalRatings,
        )..where((r) => r.workKey.equals(k))).go();
      }
      await (_db.update(
        _db.works,
      )..where((w) => w.workKey.equals(k))).write(row);
    }
  }

  Future<bool> _keepsOwnId(Work stored, WorkSnapshot incoming) async {
    final standIn = incoming.key.tmdbId;
    if (stored.tmdbId == incoming.tmdbId || stored.tmdbId == standIn) {
      return false;
    }
    if (incoming.tmdbId == standIn) return true;
    final rating = await _ratingRow(stored.workKey);
    if (rating != null && rating.deletedAt == null) return true;
    if (incoming.key.kind == WorkKind.season) {
      final listed = await _watchlistRow(stored.workKey);
      return listed != null && listed.deletedAt == null;
    }
    return false;
  }

  /// Rating or removing a season rating suppresses an older, unseen offline
  /// watchlist selection too. This tombstone is a consequence of the edit.
  Future<void> _unlistForSeasonRating(String key, int now) async {
    final old = await _watchlistRow(key);
    final compact = await _deletionTime(SyncStore.watchlistDeletionsKey, key);
    final previous = max(old?.updatedAt ?? 0, compact);
    if (old != null) {
      final store = SyncStore(_db);
      await store.saveFences(await store.readWatchlistFences());
      await (_db.update(
        _db.watchlist,
      )..where((w) => w.workKey.equals(key))).write(
        WatchlistCompanion(
          deletedAt: Value(now),
          updatedAt: Value(_next(now, previous)),
          updatedBy: Value(deviceId),
        ),
      );
    } else {
      await _db
          .into(_db.watchlist)
          .insert(
            WatchlistCompanion.insert(
              workKey: key,
              addedAt: now,
              updatedAt: _next(now, previous),
              updatedBy: deviceId,
              deletedAt: Value(now),
            ),
          );
    }
  }

  /// Takes a title off the watchlist with a tombstone, if it is on it.
  Future<void> _unlist(
    String key,
    int now, {
    bool preserveFences = true,
  }) async {
    final listed = await _watchlistRow(key);
    if (listed == null || listed.deletedAt != null) return;
    final workKey = WorkKey.parse(key);
    if (preserveFences &&
        (workKey.kind == WorkKind.tv || workKey.kind == WorkKind.season)) {
      final store = SyncStore(_db);
      await store.saveFences(await store.readWatchlistFences());
    }
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
    final ancestors = <String, Work>{};
    final keys = ancestorKeys.toList();
    for (var offset = 0; offset < keys.length; offset += 400) {
      final chunk = keys.skip(offset).take(400);
      for (final work in await (_db.select(
        _db.works,
      )..where((w) => w.workKey.isIn(chunk))).get()) {
        ancestors[work.workKey] = work;
      }
    }
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

/// The live ratings of a series' seasons or episodes with their stored TMDB
/// ids, for the renumbering notice.
final ratedPartsProvider = StreamProvider.autoDispose
    .family<List<RatedPart>, (WorkKey, WorkKind)>(
      (ref, arg) => ref.watch(libraryProvider).watchRatedParts(arg.$1, arg.$2),
    );

final partsAverageProvider = StreamProvider.autoDispose
    .family<PartsAverage?, WorkKey>(
      (ref, key) => ref.watch(libraryProvider).watchPartsAverage(key),
    );

final ratedTitlesProvider = StreamProvider.autoDispose<List<RatedTitle>>(
  (ref) => ref.watch(libraryProvider).watchRatings(),
);

/// Shelf badges share the live library instead of starting a query per tile.
final ratingScoresProvider = Provider.autoDispose<Map<WorkKey, int>>((ref) {
  final titles = ref.watch(ratedTitlesProvider).value ?? const <RatedTitle>[];
  return {for (final title in titles) title.key: title.rating.scoreHalf};
});

final myScoreHalfProvider = Provider.autoDispose.family<int?, WorkKey>(
  (ref, key) => ref.watch(ratingScoresProvider.select((scores) => scores[key])),
);

final watchlistTitlesProvider =
    StreamProvider.autoDispose<List<WatchlistTitle>>(
      (ref) => ref.watch(libraryProvider).watchWatchlist(),
    );

/// A title's saved lineage, for a card opened offline.
final savedLineageProvider = FutureProvider.autoDispose
    .family<List<Work>?, WorkKey>(
      (ref, key) => ref.watch(libraryProvider).lineage(key),
    );
