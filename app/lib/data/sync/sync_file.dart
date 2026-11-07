import 'dart:convert';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:drift/drift.dart' show Value;
import 'dart:io' show gzip;

import '../db/database.dart';
import '../work_key.dart';
import '../library/rating_note.dart';
import '../library/pair_preference.dart';

/// A permanent, compact version of a deleted row.
final class DeletionRecord {
  const DeletionRecord({
    required this.workKey,
    required this.updatedAt,
    required this.updatedBy,
    required this.tieBreak,
  });
  final String workKey;
  final int updatedAt;
  final String updatedBy;
  final String tieBreak;

  Map<String, Object?> toJson() => {
    'work_key': workKey,
    'updated_at': updatedAt,
    'updated_by': updatedBy,
    'tie_break': tieBreak,
  };
  static DeletionRecord fromJson(Object? raw) {
    final row = _Row(raw, 'deletions');
    final key = row.string('work_key');
    final hash = row.string('tie_break');
    final time = row.integer('updated_at');
    if (WorkKey.tryParse(key) == null ||
        time < 0 ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(hash)) {
      throw const _BadRow('invalid deletion record');
    }
    return DeletionRecord(
      workKey: key,
      updatedAt: time,
      updatedBy: row.string('updated_by'),
      tieBreak: hash,
    );
  }
}

/// Latest explicit series or season selection for a series. A permanent
/// register preserves the choice even if individual rows are later removed.
final class WatchlistFence {
  const WatchlistFence({
    required this.seriesKey,
    required this.season,
    required this.updatedAt,
    required this.updatedBy,
  });
  final String seriesKey;
  final bool season;
  final int updatedAt;
  final String updatedBy;

  Map<String, Object?> toJson() => {
    'series_key': seriesKey,
    'season': season,
    'updated_at': updatedAt,
    'updated_by': updatedBy,
  };
  static WatchlistFence fromJson(Object? raw) {
    final row = _Row(raw, 'watchlist_fences');
    final key = row.string('series_key');
    final parsed = WorkKey.tryParse(key);
    final at = row.integer('updated_at');
    final by = row.string('updated_by');
    if (parsed == null ||
        parsed.kind != WorkKind.tv ||
        at < 0 ||
        row.raw['season'] is! bool) {
      throw const _BadRow('invalid watchlist fence');
    }
    return WatchlistFence(
      seriesKey: key,
      season: row.raw['season'] as bool,
      updatedAt: at,
      updatedBy: by,
    );
  }
}

/// The shared ratings, watchlist, snapshots, compact deletions and cleanup cutoff.
final class SyncState {
  const SyncState({
    this.works = const [],
    this.ratings = const [],
    this.watchlist = const [],
    this.purgedBefore = 0,
    this.ratingDeletions = const [],
    this.watchlistDeletions = const [],
    this.watchlistFences = const [],
    this.favoritePeople = const [],
    this.pairComparisons = const [],
  });

  final List<Work> works;
  final List<Rating> ratings;
  final List<WatchlistEntry> watchlist;
  final List<DeletionRecord> ratingDeletions;
  final List<DeletionRecord> watchlistDeletions;
  final List<WatchlistFence> watchlistFences;
  final List<FavoritePerson> favoritePeople;
  final List<PairComparison> pairComparisons;

  /// Cleanup cutoff in UTC milliseconds. Absence does not imply deletion.
  final int purgedBefore;

  SyncState withPurgedBefore(int value) => SyncState(
    works: works,
    ratings: ratings,
    watchlist: watchlist,
    purgedBefore: value,
    ratingDeletions: ratingDeletions,
    watchlistDeletions: watchlistDeletions,
    watchlistFences: watchlistFences,
    favoritePeople: favoritePeople,
    pairComparisons: pairComparisons,
  );

  bool get isEmpty =>
      works.isEmpty &&
      ratings.isEmpty &&
      watchlist.isEmpty &&
      ratingDeletions.isEmpty &&
      watchlistDeletions.isEmpty &&
      watchlistFences.isEmpty &&
      favoritePeople.isEmpty &&
      pairComparisons.isEmpty;

  /// Live ratings: what the first sign-in dialog counts.
  int get liveRatings => ratings.where((r) => r.deletedAt == null).length;
}

/// Why a file couldn't be read.
sealed class SyncFileException implements Exception {
  const SyncFileException();
}

/// Not gzip, not JSON, or rows that don't hold together. Such a file is never
/// overwritten automatically: docs/sync.md, "Errors".
final class SyncFileBroken extends SyncFileException {
  const SyncFileBroken(this.reason);

  final String reason;

  @override
  String toString() => 'SyncFileBroken($reason)';
}

final class SyncFileTooLarge extends SyncFileException {
  const SyncFileTooLarge();
}

/// Written by a newer app. This one may neither merge it nor overwrite it.
final class SyncFileTooNew extends SyncFileException {
  const SyncFileTooNew(this.version);

  final int version;

  @override
  String toString() => 'SyncFileTooNew($version)';
}

/// Encoding and decoding `framebook-sync.json.gz` and export files.
///
/// [formatVersion] goes up on **any** change of the set of fields, even an
/// optional one: an old client would drop the field it doesn't know when it
/// rewrote the file (docs/sync.md, "Format rules"). Reading keeps every
/// earlier version working, for old exports: version 1 had no
/// `purged_before` and reads as 0.
abstract final class SyncFile {
  static const formatVersion = 6;
  // Supports a 10,000-title library even with 10,000-byte notes; protects
  // against accidental huge imports and excessive decompression expansion.
  static const maxCompressedBytes = 32 * 1024 * 1024;
  static const maxExpandedBytes = 128 * 1024 * 1024;

  static Future<SyncState> decodeAsync(List<int> bytes) =>
      Isolate.run(() => decode(bytes));

  static Future<List<int>> encodeAsync(
    SyncState state, {
    required int writtenAt,
    required String writtenBy,
    required String appVersion,
  }) => Isolate.run(
    () => encode(
      state,
      writtenAt: writtenAt,
      writtenBy: writtenBy,
      appVersion: appVersion,
    ),
  );

  /// The state file in `appDataFolder`.
  static const name = 'framebook-sync.json.gz';

  static List<int> encode(
    SyncState state, {
    required int writtenAt,
    required String writtenBy,
    required String appVersion,
  }) => _compress(
    utf8.encode(
      jsonEncode({
        'format_version': formatVersion,
        'written_at': writtenAt,
        'written_by': writtenBy,
        'app_version': appVersion,
        'purged_before': state.purgedBefore,
        'rating_deletions': [for (final d in state.ratingDeletions) d.toJson()],
        'watchlist_deletions': [
          for (final d in state.watchlistDeletions) d.toJson(),
        ],
        'watchlist_fences': [for (final f in state.watchlistFences) f.toJson()],
        'works': [for (final w in state.works) workToJson(w)],
        'ratings': [for (final r in state.ratings) ratingToJson(r)],
        'watchlist': [for (final w in state.watchlist) watchlistToJson(w)],
        'pair_comparisons': [
          for (final p in state.pairComparisons) comparisonToJson(p),
        ],
        'favorite_people': [
          for (final p in state.favoritePeople) personToJson(p),
        ],
      }),
    ),
  );

  static List<int> _compress(List<int> bytes) {
    if (bytes.length > maxExpandedBytes) throw const SyncFileTooLarge();
    final compressed = gzip.encode(bytes);
    if (compressed.length > maxCompressedBytes) throw const SyncFileTooLarge();
    return compressed;
  }

  /// Throws [SyncFileException].
  static SyncState decode(
    List<int> bytes, {
    int compressedLimit = maxCompressedBytes,
    int expandedLimit = maxExpandedBytes,
  }) {
    if (bytes.length > compressedLimit) throw const SyncFileTooLarge();
    final Object? json;
    try {
      final output = _BoundedBytes(expandedLimit);
      final decoder = gzip.decoder.startChunkedConversion(output);
      decoder.add(bytes);
      decoder.close();
      json = jsonDecode(utf8.decode(output.bytes.takeBytes()));
    } on FormatException catch (e) {
      throw SyncFileBroken(e.message);
    }
    if (json is! Map<String, Object?>) {
      throw const SyncFileBroken('not an object');
    }
    final version = json['format_version'];
    if (version is! int || version < 1) {
      throw const SyncFileBroken('no format_version');
    }
    if (version > formatVersion) throw SyncFileTooNew(version);
    final purgedBefore = switch (json['purged_before']) {
      _ when version < 2 => 0,
      final int p when p >= 0 => p,
      _ => throw const SyncFileBroken('no purged_before'),
    };
    try {
      if (json['works'] is! List ||
          json['ratings'] is! List ||
          json['watchlist'] is! List) {
        throw const _BadRow('missing state tables');
      }
      if (version >= 2 &&
          (json['rating_deletions'] is! List ||
              json['watchlist_deletions'] is! List)) {
        throw const _BadRow('missing deletion registers');
      }
      if (version >= 3 && json['watchlist_fences'] is! List) {
        throw const _BadRow('missing watchlist fences');
      }
      if (version >= 5 && json['favorite_people'] is! List) {
        throw const _BadRow('missing favorite people');
      }
      if (version >= 6 && json['pair_comparisons'] is! List) {
        throw const _BadRow('missing pair comparisons');
      }
      final comparisons = version >= 6
          ? [
              for (final p in _list(json, 'pair_comparisons'))
                comparisonFromJson(p),
            ]
          : <PairComparison>[];
      if (comparisons.map((p) => p.comparisonKey).toSet().length !=
          comparisons.length) {
        throw const _BadRow('duplicate pair comparison');
      }
      final people = version >= 5
          ? [for (final p in _list(json, 'favorite_people')) personFromJson(p)]
          : <FavoritePerson>[];
      if (people.map((p) => p.personId).toSet().length != people.length) {
        throw const _BadRow('duplicate favorite person');
      }
      final works = [for (final w in _list(json, 'works')) workFromJson(w)];
      // Legacy clients could attach an ID from a displaced numbered part.
      // These are derived identifiers; rediscover them rather than trust them.
      if (version < 4) {
        for (var i = 0; i < works.length; i++) {
          if (works[i].kind == WorkKind.season ||
              works[i].kind == WorkKind.episode) {
            works[i] = works[i].copyWith(
              imdbId: const Value(null),
              kpId: const Value(null),
            );
          }
        }
      }
      final ratings = [
        for (final r in _list(json, 'ratings')) ratingFromJson(r),
      ];
      final watchlist = [
        for (final w in _list(json, 'watchlist')) watchlistFromJson(w),
      ];
      _checkReferences(works, ratings, watchlist);
      final fences = version >= 3
          ? [
              for (final f in _list(json, 'watchlist_fences'))
                WatchlistFence.fromJson(f),
            ]
          : [
              for (final w in watchlist)
                if (w.deletedAt == null &&
                    WorkKey.tryParse(w.workKey)?.kind == WorkKind.tv)
                  WatchlistFence(
                    seriesKey: w.workKey,
                    season: false,
                    updatedAt: w.updatedAt,
                    updatedBy: w.updatedBy,
                  ),
            ];
      if (version >= 3) {
        for (final w in watchlist) {
          if (w.deletedAt != null) continue;
          final key = WorkKey.parse(w.workKey);
          if (key.kind != WorkKind.tv && key.kind != WorkKind.season) continue;
          final series = key.kind == WorkKind.tv ? key : key.parent!;
          final exists = fences.any(
            (f) =>
                f.seriesKey == series.toString() &&
                f.season == (key.kind == WorkKind.season) &&
                (f.updatedAt > w.updatedAt ||
                    (f.updatedAt == w.updatedAt &&
                        f.updatedBy.compareTo(w.updatedBy) >= 0)),
          );
          if (!exists) throw const _BadRow('watchlist selection without fence');
        }
      }
      return SyncState(
        favoritePeople: people,
        pairComparisons: comparisons,
        works: works,
        ratings: ratings,
        watchlist: watchlist,
        purgedBefore: purgedBefore,
        watchlistFences: fences,
        ratingDeletions: [
          for (final d in _list(json, 'rating_deletions'))
            DeletionRecord.fromJson(d),
        ],
        watchlistDeletions: [
          for (final d in _list(json, 'watchlist_deletions'))
            DeletionRecord.fromJson(d),
        ],
      );
    } on _BadRow catch (e) {
      throw SyncFileBroken(e.reason);
    }
  }

  static Map<String, Object?> comparisonToJson(PairComparison p) => {
    'comparison_key': p.comparisonKey,
    'left_key': p.leftKey,
    'right_key': p.rightKey,
    'left_score_half': p.leftScoreHalf,
    'right_score_half': p.rightScoreHalf,
    'left_scored_at': p.leftScoredAt,
    'right_scored_at': p.rightScoredAt,
    'left_result_score_half': p.leftResultScoreHalf,
    'right_result_score_half': p.rightResultScoreHalf,
    'left_result_scored_at': p.leftResultScoredAt,
    'right_result_scored_at': p.rightResultScoredAt,
    'preference': p.preference.name,
    'day': p.day,
    'answered_at': p.answeredAt,
    'answered_by': p.answeredBy,
  };

  static PairComparison comparisonFromJson(Object? raw) {
    final r = _Row(raw, 'pair_comparisons');
    final left = r.string('left_key'), right = r.string('right_key');
    int score(String key) {
      final v = r.integer(key);
      if (v < 2 || v > 20) throw const _BadRow('invalid comparison score');
      return v;
    }

    int time(String key) {
      final v = r.integer(key);
      if (v < 0) throw const _BadRow('invalid comparison time');
      return v;
    }

    final l = score('left_score_half'), rr = score('right_score_half');
    final la = time('left_scored_at'), ra = time('right_scored_at');
    final key = r.string('comparison_key'), day = r.string('day');
    final date = DateTime.tryParse(day);
    final preference = PairPreference.values
        .where((p) => p.name == r.string('preference'))
        .firstOrNull;
    if (WorkKey.tryParse(left)?.kind != WorkKind.movie ||
        WorkKey.tryParse(right)?.kind != WorkKind.movie ||
        left.compareTo(right) >= 0 ||
        key != '$left|$right|$l:$la|$rr:$ra' ||
        preference == null ||
        !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) ||
        date == null ||
        date.toIso8601String().substring(0, 10) != day ||
        r.string('answered_by').isEmpty) {
      throw const _BadRow('invalid pair comparison');
    }
    return PairComparison(
      comparisonKey: key,
      leftKey: left,
      rightKey: right,
      leftScoreHalf: l,
      rightScoreHalf: rr,
      leftScoredAt: la,
      rightScoredAt: ra,
      leftResultScoreHalf: score('left_result_score_half'),
      rightResultScoreHalf: score('right_result_score_half'),
      leftResultScoredAt: time('left_result_scored_at'),
      rightResultScoredAt: time('right_result_scored_at'),
      preference: preference,
      day: day,
      answeredAt: time('answered_at'),
      answeredBy: r.string('answered_by'),
    );
  }

  static Map<String, Object?> personToJson(FavoritePerson p) => {
    'person_id': p.personId,
    'name': p.name,
    'profile_path': p.profilePath,
    'updated_at': p.updatedAt,
    'updated_by': p.updatedBy,
    'deleted_at': p.deletedAt,
  };

  static FavoritePerson personFromJson(Object? raw) {
    final row = _Row(raw, 'favorite_people');
    final id = row.integer('person_id');
    final name = row.string('name');
    final at = row.integer('updated_at');
    final by = row.string('updated_by');
    final deleted = row.integerOrNull('deleted_at');
    final path = row.stringOrNull('profile_path');
    if (id <= 0 ||
        name.trim().isEmpty ||
        at < 0 ||
        by.isEmpty ||
        (deleted != null && deleted < 0) ||
        (path != null && !path.startsWith('/'))) {
      throw const _BadRow('invalid favorite person');
    }
    return FavoritePerson(
      personId: id,
      name: name,
      profilePath: path,
      updatedAt: at,
      updatedBy: by,
      deletedAt: deleted,
    );
  }

  static Map<String, Object?> workToJson(Work w) => {
    'work_key': w.workKey,
    'kind': w.kind.name,
    'parent_key': w.parentKey,
    'tmdb_id': w.tmdbId,
    'season_number': w.seasonNumber,
    'episode_number': w.episodeNumber,
    'imdb_id': w.imdbId,
    'kp_id': w.kpId,
    'title': w.title,
    'original_title': w.originalTitle,
    'release_date': w.releaseDate,
    'year': w.year,
    'poster_path': w.posterPath,
    'genre_ids': _genreIds(w.genreIds),
    'snapshot_updated_at': w.snapshotUpdatedAt,
  };

  static Map<String, Object?> ratingToJson(Rating r) => {
    'work_key': r.workKey,
    'score_half': r.scoreHalf,
    'note': r.note,
    'created_at': r.createdAt,
    'scored_at': r.scoredAt,
    'updated_at': r.updatedAt,
    'updated_by': r.updatedBy,
    'deleted_at': r.deletedAt,
  };

  static Map<String, Object?> watchlistToJson(WatchlistEntry w) => {
    'work_key': w.workKey,
    'added_at': w.addedAt,
    'updated_at': w.updatedAt,
    'updated_by': w.updatedBy,
    'deleted_at': w.deletedAt,
  };

  static Work workFromJson(Object? raw) {
    final row = _Row(raw, 'works');
    final key = row.string('work_key');
    final parsed = WorkKey.tryParse(key);
    if (parsed == null) throw _BadRow('works: bad work_key $key');
    final kind = row.string('kind');
    if (kind != parsed.kind.name) {
      throw _BadRow('works: kind $kind for $key');
    }
    final parent = row.stringOrNull('parent_key');
    final tmdbId = row.integer('tmdb_id');
    final season = row.integerOrNull('season_number');
    final episode = row.integerOrNull('episode_number');
    if (parent != parsed.parent?.toString() ||
        tmdbId <= 0 ||
        ((parsed.kind == WorkKind.movie || parsed.kind == WorkKind.tv) &&
            tmdbId != parsed.tmdbId) ||
        season != parsed.season ||
        episode != parsed.episode) {
      throw _BadRow('works: inconsistent snapshot for $key');
    }
    return Work(
      workKey: key,
      kind: parsed.kind,
      parentKey: parent,
      tmdbId: tmdbId,
      seasonNumber: season,
      episodeNumber: episode,
      imdbId: row.stringOrNull('imdb_id'),
      kpId: row.integerOrNull('kp_id'),
      title: row.string('title'),
      originalTitle: row.stringOrNull('original_title'),
      releaseDate: row.stringOrNull('release_date'),
      year: row.integerOrNull('year'),
      posterPath: row.stringOrNull('poster_path'),
      genreIds: jsonEncode(row.integers('genre_ids')),
      snapshotUpdatedAt: row.integer('snapshot_updated_at'),
    );
  }

  static Rating ratingFromJson(Object? raw) {
    final row = _Row(raw, 'ratings');
    final score = row.integer('score_half');
    if (score < 2 || score > 20) throw _BadRow('ratings: score_half $score');
    final note = row.stringOrNull('note');
    if (!validRatingNote(note)) {
      throw const _BadRow('ratings: note too long');
    }
    return Rating(
      workKey: row.string('work_key'),
      scoreHalf: score,
      note: note,
      createdAt: row.integer('created_at'),
      scoredAt: row.integer('scored_at'),
      updatedAt: row.integer('updated_at'),
      updatedBy: row.string('updated_by'),
      deletedAt: row.integerOrNull('deleted_at'),
    );
  }

  static WatchlistEntry watchlistFromJson(Object? raw) {
    final row = _Row(raw, 'watchlist');
    return WatchlistEntry(
      workKey: row.string('work_key'),
      addedAt: row.integer('added_at'),
      updatedAt: row.integer('updated_at'),
      updatedBy: row.string('updated_by'),
      deletedAt: row.integerOrNull('deleted_at'),
    );
  }

  /// A row without its snapshot, or a snapshot without its parent, would fail
  /// the foreign keys halfway through applying the file.
  static void _checkReferences(
    List<Work> works,
    List<Rating> ratings,
    List<WatchlistEntry> watchlist,
  ) {
    final keys = {for (final w in works) w.workKey};
    for (final w in works) {
      if (w.parentKey case final parent? when !keys.contains(parent)) {
        throw _BadRow('works: ${w.workKey} without its parent $parent');
      }
    }
    for (final key in [
      for (final r in ratings) r.workKey,
      for (final w in watchlist) w.workKey,
    ]) {
      if (!keys.contains(key)) throw _BadRow('$key has no snapshot');
    }
  }

  static List<Object?> _list(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value == null) return const [];
    if (value is! List<Object?>) throw _BadRow('$key is not a list');
    return value;
  }

  static List<int> _genreIds(String json) {
    final decoded = jsonDecode(json);
    return decoded is List<Object?> ? decoded.whereType<int>().toList() : [];
  }
}

final class _BadRow implements Exception {
  const _BadRow(this.reason);

  final String reason;
}

/// Strict reading of one row: a missing or mistyped required field makes
/// the whole file broken rather than silently becoming a default.
extension type _Row._(Map<String, Object?> raw) {
  factory _Row(Object? value, String table) {
    if (value is! Map<String, Object?>) throw _BadRow('$table: not an object');
    return _Row._(value);
  }

  String string(String key) => switch (raw[key]) {
    final String s => s,
    _ => throw _BadRow('$key is missing'),
  };

  String? stringOrNull(String key) => switch (raw[key]) {
    null => null,
    final String s => s,
    _ => throw _BadRow('$key is not a string'),
  };

  int integer(String key) => switch (raw[key]) {
    final int i => i,
    _ => throw _BadRow('$key is missing'),
  };

  int? integerOrNull(String key) => switch (raw[key]) {
    null => null,
    final int i => i,
    _ => throw _BadRow('$key is not an integer'),
  };

  List<int> integers(String key) => switch (raw[key]) {
    null => const [],
    final List<Object?> list when list.every((e) => e is int) =>
      list.cast<int>(),
    _ => throw _BadRow('$key is not a list of integers'),
  };
}

/// The decompressor cannot accumulate more than the supported expanded size.
final class _BoundedBytes implements Sink<List<int>> {
  _BoundedBytes(this.limit);
  final int limit;
  final bytes = BytesBuilder(copy: false);
  @override
  void add(List<int> data) {
    if (bytes.length + data.length > limit) throw const SyncFileTooLarge();
    bytes.add(data);
  }

  @override
  void close() {}
}

/// Bound a stream before retaining its bytes in memory.
Future<List<int>> readSyncBytes(
  Stream<List<int>> stream, {
  int limit = SyncFile.maxCompressedBytes,
}) async {
  final output = _BoundedBytes(limit);
  try {
    await for (final chunk in stream) {
      output.add(chunk);
    }
    return output.bytes.takeBytes();
  } finally {
    output.close();
  }
}
