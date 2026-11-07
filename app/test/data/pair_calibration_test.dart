import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/pair_calibration.dart';
import 'package:framebook/data/work_key.dart';

import 'insights_test.dart' show rated;

CalibrationPair? select(
  List<RatedTitle> titles, {
  Set<String> reviewed = const {},
  Set<String> skipped = const {},
  Map<String, int> appearances = const {},
  List<PairComparison> comparisons = const [],
}) => selectCalibrationPair((
  titles: titles,
  reviewed: reviewed,
  skipped: skipped,
  appearances: appearances,
  comparisons: comparisons,
));

PairComparison evidence(
  CalibrationPair pair,
  PairPreference preference, {
  String day = '2026-11-07',
  int at = 100,
  String by = 'a',
}) => PairComparison(
  comparisonKey: pair.version,
  leftKey: pair.left.work.workKey,
  rightKey: pair.right.work.workKey,
  leftScoreHalf: pair.left.rating.scoreHalf,
  rightScoreHalf: pair.right.rating.scoreHalf,
  leftScoredAt: pair.left.rating.scoredAt,
  rightScoredAt: pair.right.rating.scoredAt,
  leftResultScoreHalf: pair.left.rating.scoreHalf,
  rightResultScoreHalf: pair.right.rating.scoreHalf,
  leftResultScoredAt: pair.left.rating.scoredAt,
  rightResultScoredAt: pair.right.rating.scoredAt,
  preference: preference,
  day: day,
  answeredAt: at,
  answeredBy: by,
);

void main() {
  test('inconsistent two-step chains outrank ordinary boundaries', () {
    final a = rated(1, 14), b = rated(2, 16), c = rated(3, 18);
    final history = [
      evidence(CalibrationPair(a, b), PairPreference.left),
      evidence(CalibrationPair(b, c), PairPreference.left),
    ];
    final pair = select(
      [a, b, c, rated(4, 14)],
      comparisons: history,
      reviewed: history.map((p) => p.comparisonKey).toSet(),
    )!;
    expect(pair.id, 'tmdb:movie:1|tmdb:movie:3');
    expect(pair.reason, PairReason.comparisonChain);
    final stale = [rated(1, 14, at: 1000), b, c, rated(4, 14)];
    expect(
      select(stale, comparisons: history)!.reason,
      PairReason.scoreBoundary,
    );
  });

  test('equality chains never imply a strict preference', () {
    final a = rated(1, 16), b = rated(2, 16), c = rated(3, 16);
    final history = [
      evidence(CalibrationPair(a, b), PairPreference.equal),
      evidence(CalibrationPair(b, c), PairPreference.equal),
    ];
    final pair = select(
      [a, b, c],
      comparisons: history,
      reviewed: history.map((p) => p.comparisonKey).toSet(),
    )!;
    expect(pair.id, 'tmdb:movie:1|tmdb:movie:3');
    expect(pair.reason, PairReason.scoreBoundary);
  });

  test(
    'every proposed edit respects bounds and the chosen relation, including equality',
    () {
      for (var left = 2; left <= 20; left++) {
        for (var right = 2; right <= 20; right++) {
          final pair = CalibrationPair(rated(1, left), rated(2, right));
          for (final preference in PairPreference.values) {
            final options = calibrationCorrections(pair, preference);
            if (pair.agrees(preference)) {
              expect(options, isEmpty);
              continue;
            }
            expect(options, isNotEmpty);
            for (final option in options) {
              expect(
                option.values.every((half) => half >= 2 && half <= 20),
                isTrue,
              );
              final adjusted = CalibrationPair(
                rated(1, option['tmdb:movie:1'] ?? left),
                rated(2, option['tmdb:movie:2'] ?? right),
              );
              expect(adjusted.agrees(preference), isTrue);
            }
          }
        }
      }
    },
  );

  test('only distinct live films participate, with a two-film minimum', () {
    final movie = rated(1, 16);
    expect(select([movie, movie, rated(2, 16, kind: WorkKind.tv)]), isNull);
    final deleted = rated(3, 16);
    final tombstone = RatedTitle(
      work: deleted.work,
      rating: deleted.rating.copyWith(deletedAt: const Value(1)),
    );
    expect(select([movie, tombstone]), isNull);
    expect(select([movie, rated(4, 2)])!.id, 'tmdb:movie:1|tmdb:movie:4');
  });

  test(
    'closest scores precede similarity and known genres break score ties',
    () {
      final rows = [
        rated(1, 16, genres: [18]),
        rated(2, 16, genres: [28]),
        rated(3, 17, genres: [18]),
      ];
      expect(select(rows)!.id, 'tmdb:movie:1|tmdb:movie:2');
      rows.add(rated(4, 16, genres: [18]));
      expect(select(rows)!.id, 'tmdb:movie:1|tmdb:movie:4');
      expect(select(rows.reversed.toList())!.id, select(rows)!.id);
    },
  );

  test('under-reviewed titles precede similar but over-exposed ones', () {
    final rows = [
      rated(1, 16, genres: [18]),
      rated(2, 16, genres: [18]),
      rated(3, 16, genres: [28]),
      rated(4, 16, genres: [35]),
    ];
    final first = select(rows)!;
    expect(first.id, 'tmdb:movie:1|tmdb:movie:2');
    final next = select(
      rows,
      reviewed: {first.version},
      appearances: {first.left.work.workKey: 1, first.right.work.workKey: 1},
    );
    expect(next!.id, 'tmdb:movie:3|tmdb:movie:4');
  });

  test(
    'reviewed and skipped versions are excluded; rescoring restores eligibility',
    () {
      final a = rated(1, 16, at: 10), b = rated(2, 16, at: 20);
      final pair = select([a, b])!;
      expect(select([a, b], reviewed: {pair.version}), isNull);
      expect(select([a, b], skipped: {pair.version}), isNull);
      final noteEdit = RatedTitle(
        work: a.work,
        rating: a.rating.copyWith(
          note: const Value('New note'),
          updatedAt: 100,
        ),
      );
      expect(select([noteEdit, b], reviewed: {pair.version}), isNull);
      expect(
        select([rated(1, 17, at: 30), b], reviewed: {pair.version}),
        isNotNull,
      );
      expect(
        select([rated(1, 16, at: 40), b], reviewed: {pair.version}),
        isNotNull,
      );
      expect(CalibrationPair(b, a).version, pair.version);
    },
  );

  test(
    'equal enjoyment is a real preference, distinct from strict ordering',
    () {
      final same = CalibrationPair(rated(1, 16), rated(2, 16));
      expect(same.agrees(PairPreference.equal), isTrue);
      expect(same.agrees(PairPreference.left), isFalse);
      expect(same.agrees(PairPreference.right), isFalse);
      final different = CalibrationPair(rated(1, 18), rated(2, 16));
      expect(different.agrees(PairPreference.equal), isFalse);
      expect(different.agrees(PairPreference.left), isTrue);
      expect(different.agrees(PairPreference.right), isFalse);
    },
  );

  test(
    'large same-score libraries cover fresh titles without an all-pairs set',
    () {
      final rows = [
        for (var id = 1; id <= 1000; id++) rated(id, 16, genres: [18]),
      ];
      final reviewed = <String>{}, seen = <String>{};
      final appearances = <String, int>{};
      for (var step = 0; step < 10; step++) {
        final pair = select(
          rows,
          reviewed: reviewed,
          appearances: appearances,
        )!;
        expect(seen, isNot(contains(pair.left.work.workKey)));
        expect(seen, isNot(contains(pair.right.work.workKey)));
        reviewed.add(pair.version);
        for (final title in [pair.left, pair.right]) {
          seen.add(title.work.workKey);
          appearances.update(
            title.work.workKey,
            (n) => n + 1,
            ifAbsent: () => 1,
          );
        }
      }
      expect(seen, hasLength(20));
    },
  );
}
