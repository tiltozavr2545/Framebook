import 'dart:convert';
import 'dart:io' show gzip;

import '../db/database.dart';
import '../work_key.dart';

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

/// The shared ratings, watchlist, snapshots, compact deletions and cleanup cutoff.
final class SyncState {
  const SyncState({
    this.works = const [],
    this.ratings = const [],
    this.watchlist = const [],
    this.purgedBefore = 0,
    this.ratingDeletions = const [],
    this.watchlistDeletions = const [],
  });

  final List<Work> works;
  final List<Rating> ratings;
  final List<WatchlistEntry> watchlist;
  final List<DeletionRecord> ratingDeletions;
  final List<DeletionRecord> watchlistDeletions;

  /// Cleanup cutoff in UTC milliseconds. Absence does not imply deletion.
  final int purgedBefore;

  SyncState withPurgedBefore(int value) => SyncState(
    works: works,
    ratings: ratings,
    watchlist: watchlist,
    purgedBefore: value,
    ratingDeletions: ratingDeletions,
    watchlistDeletions: watchlistDeletions,
  );

  bool get isEmpty =>
      works.isEmpty &&
      ratings.isEmpty &&
      watchlist.isEmpty &&
      ratingDeletions.isEmpty &&
      watchlistDeletions.isEmpty;

  /// Live ratings: what the first sign-in dialog counts.
  int get liveRatings => ratings.where((r) => r.deletedAt == null).length;
}

/// Why a file couldn't be read.
sealed class SyncFileException implements Exception {
  const SyncFileException();
}

/// Not gzip, not JSON, or rows that don't hold together. Such a file is never
/// overwritten: docs/sync.md, "Errors".
final class SyncFileBroken extends SyncFileException {
  const SyncFileBroken(this.reason);

  final String reason;

  @override
  String toString() => 'SyncFileBroken($reason)';
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
  static const formatVersion = 2;

  /// The state file in `appDataFolder`.
  static const name = 'framebook-sync.json.gz';

  static List<int> encode(
    SyncState state, {
    required int writtenAt,
    required String writtenBy,
    required String appVersion,
  }) => gzip.encode(
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
        'works': [for (final w in state.works) workToJson(w)],
        'ratings': [for (final r in state.ratings) ratingToJson(r)],
        'watchlist': [for (final w in state.watchlist) watchlistToJson(w)],
      }),
    ),
  );

  /// Throws [SyncFileException].
  static SyncState decode(List<int> bytes) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(gzip.decode(bytes)));
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
      if (version >= 2 &&
          (json['rating_deletions'] is! List ||
              json['watchlist_deletions'] is! List)) {
        throw const _BadRow('missing deletion registers');
      }
      final works = [for (final w in _list(json, 'works')) workFromJson(w)];
      final ratings = [
        for (final r in _list(json, 'ratings')) ratingFromJson(r),
      ];
      final watchlist = [
        for (final w in _list(json, 'watchlist')) watchlistFromJson(w),
      ];
      _checkReferences(works, ratings, watchlist);
      return SyncState(
        works: works,
        ratings: ratings,
        watchlist: watchlist,
        purgedBefore: purgedBefore,
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
    return Work(
      workKey: key,
      kind: parsed.kind,
      parentKey: row.stringOrNull('parent_key'),
      tmdbId: row.integer('tmdb_id'),
      seasonNumber: row.integerOrNull('season_number'),
      episodeNumber: row.integerOrNull('episode_number'),
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
    return Rating(
      workKey: row.string('work_key'),
      scoreHalf: score,
      note: row.stringOrNull('note'),
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
