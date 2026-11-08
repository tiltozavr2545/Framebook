// Optional host scheduling benchmark; this does not measure rendered frames.
import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/latest_worker.dart';
import 'package:framebook/data/library/insights.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/library/people_credit_payload.dart';
import 'package:framebook/data/library/prepared_views.dart';
import 'package:framebook/data/recommendations/profile.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/ratings/ratings_model.dart';

import '../data/insights_test.dart' show rated;

typedef _TasteInput = (List<RatedTitle>, Map<String, List<PeopleCredit>>);
TasteProfile _prepareTaste(_TasteInput input) =>
    TasteProfile(tasteSignals(input.$1, input.$2));
LibraryInsights _prepareInsights(_TasteInput input) =>
    analyzeLibrary(input.$1, input.$2);

Future<void> _measure<T>(
  String label,
  Future<T> Function() work,
  void Function(T) check,
) async {
  final elapsed = <int>[];
  final gaps = <int>[];
  for (var run = 0; run < 7; run++) {
    final clock = Stopwatch()..start();
    var previous = 0;
    var longest = 0;
    final timer = Timer.periodic(const Duration(milliseconds: 1), (_) {
      final now = clock.elapsedMicroseconds;
      longest = max(longest, now - previous);
      previous = now;
    });
    try {
      final result = await work();
      clock.stop();
      longest = max(longest, clock.elapsedMicroseconds - previous);
      check(result);
      if (run >= 2) {
        elapsed.add(clock.elapsedMicroseconds);
        gaps.add(longest);
      }
    } finally {
      timer.cancel();
    }
  }
  final ordered = [...elapsed]..sort();
  // ignore: avoid_print
  print(
    'Host worker $label: median total ${ordered[2]} us; total samples $elapsed; longest main-isolate scheduler gaps $gaps us',
  );
}

void main() {
  for (final peopleCount in [30000, 150000]) {
    test('credit transfer with $peopleCount distinct people', () async {
      final titles = [for (var id = 1; id <= 500; id++) rated(id, 2 + id % 19)];
      final credits = {
        for (var index = 0; index < titles.length; index++)
          peopleIdentity(titles[index]): [
            for (var credit = 0; credit < 300; credit++)
              PeopleCredit(
                id: (index * 300 + credit) % peopleCount + 1,
                name: 'Actor ${(index * 300 + credit) % peopleCount + 1}',
                role: FilmographyRole.acting,
              ),
          ],
      };
      final worker = LatestWorker<_TasteInput, TasteProfile>(
        (input) => compute(_prepareTaste, input),
      );
      void check(TasteProfile? profile) {
        expect(profile?.signals, hasLength(500));
        expect(
          profile!.signals.fold<int>(
            0,
            (total, signal) => total + signal.people.length,
          ),
          150000,
        );
      }

      try {
        await _measure(
          'raw taste / $peopleCount people',
          () => worker.run((titles, credits)),
          check,
        );
        await _measure('shared taste / $peopleCount people', () async {
          final payload = await sharedPeopleCreditPayload(credits);
          return worker.run((titles, payload!));
        }, check);
      } finally {
        worker.dispose();
      }
    });
  }

  test('large insight credit transfer keeps complete profiles', () async {
    final titles = [
      for (var id = 1; id <= 500; id++)
        rated(id, 2 + id % 19, genres: [18, 28]),
    ];
    final credits = {
      for (final title in titles)
        peopleIdentity(title): [
          for (var id = 1; id <= 300; id++)
            PeopleCredit(
              id: id,
              name: 'Actor $id',
              role: FilmographyRole.acting,
            ),
        ],
    };
    final worker = LatestWorker<_TasteInput, LibraryInsights>(
      (input) =>
          compute(_prepareInsights, input, debugLabel: 'benchmark insights'),
    );
    void check(LibraryInsights? result) {
      expect(result?.covered, 500);
      expect(result?.people, hasLength(300));
      expect(
        result!.people.every((person) => person.profile.count == 500),
        isTrue,
      );
    }

    try {
      await _measure(
        'raw insights / 150000 credits',
        () => worker.run((titles, credits)),
        check,
      );
      await _measure('shared insights / 150000 credits', () async {
        final payload = await sharedPeopleCreditPayload(credits);
        return worker.run((titles, payload!));
      }, check);
    } finally {
      worker.dispose();
    }
  });

  test('large view workers leave the main isolate available', () async {
    final titles = [
      for (var id = 1; id <= 10000; id++)
        rated(
          id,
          2 + id % 19,
          genres: [18, 28],
          year: 1980 + id % 45,
          at: id * 1000,
        ),
    ];
    final ratings = LatestWorker<RatingsInput, RatingsPageData>(
      (input) =>
          compute(prepareRatings, input, debugLabel: 'benchmark ratings'),
    );
    final stats = LatestWorker<StatsInput, StatsView>(
      (input) =>
          compute(prepareStatsKind, input, debugLabel: 'benchmark stats'),
    );
    final taste = LatestWorker<_TasteInput, TasteProfile>(
      (input) => compute(_prepareTaste, input, debugLabel: 'benchmark taste'),
    );
    try {
      await _measure(
        '10000 ratings',
        () => ratings.run((
          titles,
          (
            kind: null,
            sort: RatingsSort.scoredAt,
            compareWith: RatingSource.imdb,
            order: DivergenceOrder.furthest,
          ),
        )),
        (result) => expect(result?.shown, hasLength(10000)),
      );
      await _measure(
        '10000 statistics rows',
        () => stats.run((titles, WorkKind.movie)),
        (result) => expect(result?.titles, hasLength(10000)),
      );
      final tasteTitles = titles.take(500).toList();
      final credits = {
        for (final title in tasteTitles)
          peopleIdentity(title): [
            for (var id = 1; id <= 300; id++)
              PeopleCredit(
                id: id,
                name: 'Actor $id',
                role: FilmographyRole.acting,
              ),
          ],
      };
      await _measure(
        '500 taste titles / 150000 credits',
        () async {
          final payload = await sharedPeopleCreditPayload(credits);
          return taste.run((tasteTitles, payload!));
        },
        (result) => expect(result?.signals, hasLength(500)),
      );
    } finally {
      ratings.dispose();
      stats.dispose();
      taste.dispose();
    }
  });
}
