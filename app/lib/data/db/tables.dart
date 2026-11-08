// `kind.isIn(...)` inside `get kind` is drift's documented way to declare a
// column CHECK: the getter isn't called recursively here, the generator reads
// it. The linter doesn't know that.
//
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../api_source.dart';
import '../work_key.dart';
import '../library/pair_preference.dart';

// The schema is in docs/data-model.md, along with the "why". Time is UTC
// milliseconds in an int everywhere, not DateTime: the storage format must
// match the sync file byte for byte (docs/sync.md), and the driver shouldn't
// decide it for us.
//
// CHECK constraints duplicate invariants the code also keeps: a broken client
// or a bad import must fail on insert, not silently store a score of 0 or a
// kind "film".

/// A title's mini snapshot. Synced along with the rows that reference it; it
/// has no tombstone, since it is derived data.
@DataClassName('Work')
@TableIndex(name: 'works_kind', columns: {#kind})
@TableIndex(name: 'works_parent_key', columns: {#parentKey})
@TableIndex(name: 'works_year', columns: {#year})
class Works extends Table {
  TextColumn get workKey => text()();
  TextColumn get kind => textEnum<WorkKind>().check(
    kind.isIn(WorkKind.values.map((k) => k.name)),
  )();
  TextColumn get parentKey => text().nullable()();
  IntColumn get tmdbId => integer().check(tmdbId.isBiggerThanValue(0))();
  IntColumn get seasonNumber =>
      integer().nullable().check(seasonNumber.isBiggerOrEqualValue(0))();
  IntColumn get episodeNumber =>
      integer().nullable().check(episodeNumber.isBiggerThanValue(0))();
  TextColumn get imdbId => text().nullable()();
  IntColumn get kpId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get originalTitle => text().nullable()();

  /// `YYYY-MM-DD` as the API sent it, without a time zone.
  TextColumn get releaseDate => text().nullable()();
  IntColumn get year => integer().nullable()();

  /// A TMDB relative path (`/abc.jpg`), not a URL.
  TextColumn get posterPath => text().nullable()();

  /// JSON array of TMDB genre ids.
  TextColumn get genreIds => text().withDefault(const Constant('[]'))();
  IntColumn get snapshotUpdatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {workKey};
}

/// Ratings. Synced; deletion is only ever `deleted_at`.
@DataClassName('Rating')
@TableIndex(name: 'ratings_live_score', columns: {#deletedAt, #scoreHalf})
@TableIndex(name: 'ratings_scored_at', columns: {#scoredAt})
class Ratings extends Table {
  TextColumn get workKey => text().references(Works, #workKey)();

  /// Score × 2: 2…20 = 1.0…10.0. An integer, so that "the same score" in the
  /// calibration sheet compares exactly.
  IntColumn get scoreHalf =>
      integer().check(scoreHalf.isBetweenValues(2, 20))();
  TextColumn get note =>
      text().nullable().check(note.length.isSmallerOrEqualValue(10000))();
  IntColumn get createdAt => integer()();

  /// The current rating's date; edits preserve it, rating after deletion resets it.
  IntColumn get scoredAt => integer()();

  /// The last user change of any kind; merging goes by it.
  IntColumn get updatedAt => integer()();

  /// `device_id` of the last writer; breaks ties on equal `updated_at`.
  TextColumn get updatedBy => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {workKey};
}

/// Watchlist. Synced; deletion is only ever `deleted_at`.
@DataClassName('WatchlistEntry')
class Watchlist extends Table {
  TextColumn get workKey => text().references(Works, #workKey)();
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get updatedBy => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {workKey};
}

/// A favourite person as a whole, independent of their jobs. Tombstones stay
/// permanently: removing a favourite must survive an offline device's return.
@DataClassName('FavoritePerson')
class FavoritePeople extends Table {
  IntColumn get personId => integer().check(personId.isBiggerThanValue(0))();
  TextColumn get name => text()();
  TextColumn get profilePath => text().nullable()();
  IntColumn get updatedAt => integer()();
  TextColumn get updatedBy => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {personId};
}

/// Cache of external ratings. Local only; no foreign key to `works`, because
/// titles that were opened but never rated are cached too.
@DataClassName('ExternalRating')
class ExternalRatings extends Table {
  TextColumn get workKey => text()();
  TextColumn get source => textEnum<RatingSource>().check(
    source.isIn(RatingSource.values.map((s) => s.name)),
  )();
  TextColumn get status => textEnum<RatingStatus>().check(
    status.isIn(RatingStatus.values.map((s) => s.name)),
  )();
  RealColumn get value => real().nullable()();

  /// 10 or 100: RT in percent, Metacritic 0–100.
  IntColumn get scale => integer().check(scale.isIn(const [10, 100]))();
  IntColumn get votes => integer().nullable()();
  TextColumn get via => textEnum<ApiSource>().check(
    via.isIn(ApiSource.values.map((s) => s.name)),
  )();
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {workKey, source};
}

/// Daily limit spending of the external APIs.
@DataClassName('ApiBudgetRow')
class ApiBudget extends Table {
  TextColumn get source => textEnum<ApiSource>().check(
    source.isIn(ApiSource.values.map((s) => s.name)),
  )();

  /// `YYYY-MM-DD`, a UTC day.
  TextColumn get day => text()();
  IntColumn get used => integer()
      .withDefault(const Constant(0))
      .check(used.isBiggerOrEqualValue(0))();

  @override
  Set<Column<Object>> get primaryKey => {source, day};
}

/// Key-value: `device_id`, sync state.
@DataClassName('SyncStateEntry')
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Immutable comparison events. Natural keys deduplicate offline answers to the
/// same score versions; histories never require a title snapshot to survive.
@DataClassName('PairComparison')
@TableIndex(name: 'pair_comparisons_day', columns: {#day})
class PairComparisons extends Table {
  TextColumn get comparisonKey => text()();
  TextColumn get leftKey => text()();
  TextColumn get rightKey => text()();
  IntColumn get leftScoreHalf =>
      integer().check(leftScoreHalf.isBetweenValues(2, 20))();
  IntColumn get rightScoreHalf =>
      integer().check(rightScoreHalf.isBetweenValues(2, 20))();
  IntColumn get leftScoredAt => integer()();
  IntColumn get rightScoredAt => integer()();
  IntColumn get leftResultScoreHalf =>
      integer().check(leftResultScoreHalf.isBetweenValues(2, 20))();
  IntColumn get rightResultScoreHalf =>
      integer().check(rightResultScoreHalf.isBetweenValues(2, 20))();
  IntColumn get leftResultScoredAt => integer()();
  IntColumn get rightResultScoredAt => integer()();
  TextColumn get preference => textEnum<PairPreference>().check(
    preference.isIn(PairPreference.values.map((p) => p.name)),
  )();
  TextColumn get day => text()();
  IntColumn get answeredAt => integer()();
  TextColumn get answeredBy => text()();
  @override
  Set<Column<Object>> get primaryKey => {comparisonKey};
}
