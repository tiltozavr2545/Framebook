import 'dart:math';

import '../work_key.dart';
import '../db/database.dart';
import 'library_models.dart';

import 'pair_preference.dart';
export 'pair_preference.dart';

/// Canonical key order keeps a comparison independent of poster placement.
enum PairReason { scoreBoundary, comparisonChain }

final class CalibrationPair {
  factory CalibrationPair(
    RatedTitle a,
    RatedTitle b, {
    PairReason reason = PairReason.scoreBoundary,
  }) => a.work.workKey.compareTo(b.work.workKey) < 0
      ? CalibrationPair._(a, b, reason)
      : CalibrationPair._(b, a, reason);
  const CalibrationPair._(this.left, this.right, this.reason);

  final PairReason reason;

  final RatedTitle left;
  final RatedTitle right;
  String get id => '${left.work.workKey}|${right.work.workKey}';
  String get version =>
      '$id|${left.rating.scoreHalf}:${left.rating.scoredAt}'
      '|${right.rating.scoreHalf}:${right.rating.scoredAt}';
  int get gap => (left.rating.scoreHalf - right.rating.scoreHalf).abs();

  bool agrees(PairPreference preference) => switch (preference) {
    PairPreference.left => left.rating.scoreHalf > right.rating.scoreHalf,
    PairPreference.equal => left.rating.scoreHalf == right.rating.scoreHalf,
    PairPreference.right => right.rating.scoreHalf > left.rating.scoreHalf,
  };
}

typedef PairSelectionInput = ({
  List<RatedTitle> titles,
  Set<String> reviewed,
  Set<String> skipped,
  Map<String, int> appearances,
  List<PairComparison> comparisons,
});

/// Close score boundaries first, then under-reviewed films, shared genres and
/// nearby release years. Bounded cyclic neighbourhoods avoid an O(n²) pair set.
/// No external ratings, wall-clock randomness or catalog requests participate.
CalibrationPair? selectCalibrationPair(PairSelectionInput input) {
  final movies = <String, RatedTitle>{
    for (final title in input.titles)
      if (title.key.kind == WorkKind.movie && title.rating.deletedAt == null)
        title.work.workKey: title,
  };
  final genres = {
    for (final title in movies.values)
      title.work.workKey: title.genreIds.toSet(),
  };
  int appearances(RatedTitle title) =>
      input.appearances[title.work.workKey] ?? 0;
  int order(RatedTitle a, RatedTitle b) {
    final count = appearances(a).compareTo(appearances(b));
    return count != 0 ? count : a.work.workKey.compareTo(b.work.workKey);
  }

  final groups = <int?, Map<int, List<RatedTitle>>>{};
  for (final title in movies.values) {
    for (final genre in <int?>[null, ...genres[title.work.workKey]!]) {
      groups
          .putIfAbsent(genre, () => {})
          .putIfAbsent(title.rating.scoreHalf, () => [])
          .add(title);
    }
  }
  CalibrationPair? best;
  (int, int, int, int, double, int, String) priority(CalibrationPair pair) {
    final a = genres[pair.left.work.workKey]!;
    final b = genres[pair.right.work.workKey]!;
    final common = a.where(b.contains).length;
    final union = a.length + b.length - common;
    final similarity = union == 0 ? 0.0 : common / union;
    final leftCount = appearances(pair.left),
        rightCount = appearances(pair.right);
    final leftYear = pair.left.work.year, rightYear = pair.right.work.year;
    return (
      pair.reason == PairReason.comparisonChain ? 0 : 1,
      pair.gap,
      leftCount + rightCount,
      max(leftCount, rightCount),
      -similarity,
      leftYear == null || rightYear == null
          ? 10000
          : (leftYear - rightYear).abs(),
      pair.id,
    );
  }

  int compare(CalibrationPair a, CalibrationPair b) {
    final x = priority(a), y = priority(b);
    return x.$1 != y.$1
        ? x.$1.compareTo(y.$1)
        : x.$2 != y.$2
        ? x.$2.compareTo(y.$2)
        : x.$3 != y.$3
        ? x.$3.compareTo(y.$3)
        : x.$4 != y.$4
        ? x.$4.compareTo(y.$4)
        : x.$5 != y.$5
        ? x.$5.compareTo(y.$5)
        : x.$6 != y.$6
        ? x.$6.compareTo(y.$6)
        : x.$7.compareTo(y.$7);
  }

  void consider(RatedTitle a, RatedTitle b, {bool chain = false}) {
    if (a.work.workKey == b.work.workKey) return;
    final pair = CalibrationPair(
      a,
      b,
      reason: chain ? PairReason.comparisonChain : PairReason.scoreBoundary,
    );
    if (input.reviewed.contains(pair.version) ||
        input.skipped.contains(pair.version)) {
      return;
    }
    if (best == null || compare(pair, best!) < 0) best = pair;
  }

  for (final scores in groups.values) {
    final levels = scores.keys.toList()..sort();
    for (final bucket in scores.values) {
      bucket.sort(order);
      for (var i = 0; i < bucket.length; i++) {
        for (var offset = 1; offset <= min(8, bucket.length - 1); offset++) {
          consider(bucket[i], bucket[(i + offset) % bucket.length]);
        }
      }
    }
    for (var level = 0; level + 1 < levels.length; level++) {
      final a = scores[levels[level]]!, b = scores[levels[level + 1]]!;
      final larger = a.length >= b.length ? a : b;
      final smaller = identical(larger, a) ? b : a;
      for (var i = 0; i < larger.length; i++) {
        for (var offset = 0; offset < min(4, smaller.length); offset++) {
          consider(larger[i], smaller[(i + offset) % smaller.length]);
        }
      }
    }
  }
  // Two-step paths ask a useful missing question when the implied preference
  // disagrees with the numerical scale. Equality edges remain non-strict.
  final edges = <String, Map<String, bool>>{};
  void edge(String a, String b, bool strict) {
    final out = edges.putIfAbsent(a, () => {});
    out[b] = (out[b] ?? false) || strict;
  }

  for (final comparison in input.comparisons) {
    final a = movies[comparison.leftKey], b = movies[comparison.rightKey];
    if (a == null || b == null || !comparisonIsCurrent(comparison, a, b)) {
      continue;
    }
    switch (comparison.preference) {
      case PairPreference.left:
        edge(comparison.leftKey, comparison.rightKey, true);
      case PairPreference.right:
        edge(comparison.rightKey, comparison.leftKey, true);
      case PairPreference.equal:
        edge(comparison.leftKey, comparison.rightKey, false);
        edge(comparison.rightKey, comparison.leftKey, false);
    }
  }
  List<MapEntry<String, bool>> neighbours(String key) =>
      (edges[key]?.entries.toList() ?? <MapEntry<String, bool>>[])
        ..sort((a, b) => a.key.compareTo(b.key));
  for (final a in edges.keys) {
    for (final ab in neighbours(a).take(8)) {
      for (final bc in neighbours(ab.key).take(8)) {
        if (a == bc.key) continue;
        final first = movies[a]!, last = movies[bc.key]!;
        final difference = first.rating.scoreHalf - last.rating.scoreHalf;
        if ((ab.value || bc.value) ? difference <= 0 : difference != 0) {
          consider(first, last, chain: true);
        }
      }
    }
  }
  return best;
}

String comparisonResultVersion(PairComparison p) =>
    '${p.leftKey}|${p.rightKey}|${p.leftResultScoreHalf}:${p.leftResultScoredAt}'
    '|${p.rightResultScoreHalf}:${p.rightResultScoredAt}';

bool comparisonIsCurrent(PairComparison p, RatedTitle a, RatedTitle b) =>
    (a.rating.scoreHalf == p.leftResultScoreHalf &&
    a.rating.scoredAt == p.leftResultScoredAt &&
    b.rating.scoreHalf == p.rightResultScoreHalf &&
    b.rating.scoredAt == p.rightResultScoredAt);

/// Each option is an explicit score edit, expressed only in integer half points.
/// The caller confirms one option; merely answering a pair never writes scores.
List<Map<String, int>> calibrationCorrections(
  CalibrationPair pair,
  PairPreference preference,
) {
  if (pair.agrees(preference)) return const [];
  final left = pair.left.rating.scoreHalf, right = pair.right.rating.scoreHalf;
  final leftKey = pair.left.work.workKey, rightKey = pair.right.work.workKey;
  if (preference == PairPreference.equal) {
    return [
      {leftKey: right},
      {rightKey: left},
    ];
  }
  final leftWins = preference == PairPreference.left;
  final winner = leftWins ? left : right, loser = leftWins ? right : left;
  final winnerKey = leftWins ? leftKey : rightKey;
  final loserKey = leftWins ? rightKey : leftKey;
  return [
    if (loser < 20) {winnerKey: loser + 1},
    if (winner > 2) {loserKey: winner - 1},
    if (winner < loser)
      {
        winnerKey: ((winner + loser + 1) ~/ 2).clamp(3, 20),
        loserKey: ((winner + loser - 1) ~/ 2).clamp(2, 19),
      },
  ];
}
