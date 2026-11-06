// Optional host benchmark; timings do not gate CI or describe phone frames.
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/recommendations/ranking.dart';
import 'package:framebook/data/work_key.dart';

import '../data/insights_test.dart' show rated;
import '../data/recommendations_test.dart' show profile, title, watch;

void main() {
  test('rank a full recommendation pool alongside a large watchlist', () {
    final taste = profile([
      for (var i = 1; i <= 500; i++)
        rated(i, 2 + i % 19, genres: [28 + i % 5, 18]),
    ]);
    final candidates = [
      for (var i = 501; i <= 1500; i++)
        RecommendationCandidate(
          title(i, genres: [28 + i % 5, 18 + i % 3]),
          seeds: {WorkKey.movie(1 + i % 500)},
          people: {1 + i % 10: 'Person ${1 + i % 10}'},
        ),
    ];
    final listed = [for (var i = 1200; i < 2200; i++) watch(i)];
    final samples = <int>[];
    String? digest;
    for (var run = 0; run < 7; run++) {
      final timer = Stopwatch()..start();
      final result = rankRecommendations(
        profile: taste,
        candidates: candidates,
        watchlist: listed,
        favorites: {1, 2, 3, 4, 5, 6, 7, 8},
        hidden: {const WorkKey.movie(700)},
        today: '2026-11-06',
      );
      timer.stop();
      if (run >= 2) samples.add(timer.elapsedMicroseconds);
      final actual = sha256
          .convert(
            utf8.encode(
              jsonEncode([
                for (final row in [
                  result.forYou,
                  result.people,
                  result.explore,
                  result.watchlist,
                ])
                  [
                    for (final p in row)
                      [
                        '${p.title.key}',
                        p.reason.name,
                        p.detail,
                        p.exploratory,
                      ],
                  ],
              ]),
            ),
          )
          .toString();
      digest ??= actual;
      expect(actual, digest);
      expect(result.forYou, hasLength(20));
      expect(result.watchlist, hasLength(20));
    }
    samples.sort();
    // Recorded before the optimization: includes ordering, reasons and flags
    // in all four rows, not just the selected title IDs.
    expect(
      digest,
      '1d7eeee141f3ce23b3ef17e3953cebbbddeb6b40df88c0290c03794c1792dd9f',
    );
    // ignore: avoid_print
    print(
      'Host recommendation median ${samples[2]} us; samples $samples; digest $digest',
    );
  });
}
