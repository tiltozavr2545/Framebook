import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../work_key.dart';
import '../db/database_provider.dart';
import 'library.dart';
import 'pair_calibration.dart';

const dailyPairLimit = 5;
String calibrationDay(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

class CalibrationStale implements Exception {
  const CalibrationStale();
}

class CalibrationLimitReached implements Exception {
  const CalibrationLimitReached();
}

final pairCalibrationClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);
final pairComparisonsProvider = StreamProvider<List<PairComparison>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(
    db.pairComparisons,
  )..orderBy([(p) => OrderingTerm.asc(p.comparisonKey)])).watch();
});
final pairCalibrationStoreProvider = Provider<PairCalibrationStore>(
  (ref) => PairCalibrationStore(
    ref.watch(databaseProvider),
    ref.watch(libraryProvider),
    clock: ref.watch(pairCalibrationClockProvider),
  ),
);

/// Answers are immutable events keyed by both original rating versions.
/// The quota, optimistic concurrency guard, score edits and event are atomic.
class PairCalibrationStore {
  PairCalibrationStore(this.db, this.library, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;
  final AppDatabase db;
  final Library library;
  final DateTime Function() clock;

  Future<PairComparison> answer(
    CalibrationPair pair,
    PairPreference preference, {
    Map<String, int> changes = const {},
  }) => db.transaction(() async {
    if (pair.left.key.kind != WorkKind.movie ||
        pair.right.key.kind != WorkKind.movie ||
        pair.left.work.workKey.compareTo(pair.right.work.workKey) >= 0) {
      throw ArgumentError('A calibration pair requires two distinct films');
    }
    if (changes.isNotEmpty &&
        !calibrationCorrections(pair, preference).any(
          (option) =>
              option.length == changes.length &&
              option.entries.every((e) => changes[e.key] == e.value),
        )) {
      throw ArgumentError('Unsupported calibration correction');
    }
    Future<Rating> current(RatedTitle expected) async {
      final row =
          await (db.select(db.ratings)
                ..where((r) => r.workKey.equals(expected.work.workKey)))
              .getSingleOrNull();
      if (row == null ||
          row.deletedAt != null ||
          row.scoreHalf != expected.rating.scoreHalf ||
          row.scoredAt != expected.rating.scoredAt) {
        throw const CalibrationStale();
      }
      return row;
    }

    await current(pair.left);
    await current(pair.right);
    final existing =
        await (db.select(db.pairComparisons)..where(
              (p) =>
                  p.leftKey.equals(pair.left.work.workKey) &
                  p.rightKey.equals(pair.right.work.workKey),
            ))
            .get();
    if (existing.any(
      (p) =>
          p.comparisonKey == pair.version ||
          comparisonResultVersion(p) == pair.version,
    )) {
      throw const CalibrationStale();
    }
    final now = clock();
    final day = calibrationDay(now);
    final count = db.pairComparisons.comparisonKey.count();
    final used =
        await (db.selectOnly(db.pairComparisons)
              ..addColumns([count])
              ..where(db.pairComparisons.day.equals(day)))
            .map((row) => row.read(count)!)
            .getSingle();
    if (used >= dailyPairLimit) throw const CalibrationLimitReached();
    for (final title in [pair.left, pair.right]) {
      final half = changes[title.work.workKey];
      if (half != null) {
        await library.rescore(title.key, half);
      }
    }
    Future<Rating> result(RatedTitle title) => (db.select(
      db.ratings,
    )..where((r) => r.workKey.equals(title.work.workKey))).getSingle();
    final a = await result(pair.left), b = await result(pair.right);
    final event = PairComparison(
      comparisonKey: pair.version,
      leftKey: pair.left.work.workKey,
      rightKey: pair.right.work.workKey,
      leftScoreHalf: pair.left.rating.scoreHalf,
      rightScoreHalf: pair.right.rating.scoreHalf,
      leftScoredAt: pair.left.rating.scoredAt,
      rightScoredAt: pair.right.rating.scoredAt,
      leftResultScoreHalf: a.scoreHalf,
      rightResultScoreHalf: b.scoreHalf,
      leftResultScoredAt: a.scoredAt,
      rightResultScoredAt: b.scoredAt,
      preference: preference,
      day: day,
      answeredAt: now.toUtc().millisecondsSinceEpoch,
      answeredBy: library.deviceId,
    );
    await db.into(db.pairComparisons).insert(event.toCompanion(false));
    return event;
  });
}
