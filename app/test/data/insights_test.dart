import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/insights.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/library/rating_days.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

RatedTitle rated(
  int id,
  int half, {
  double? imdb,
  List<int> genres = const [],
  int? year,
  int at = 0,
  WorkKind kind = WorkKind.movie,
}) {
  final key = kind == WorkKind.movie ? WorkKey.movie(id) : WorkKey.tv(id);
  return RatedTitle(
    work: Work(
      workKey: '$key',
      kind: kind,
      tmdbId: id,
      title: 'Title $id',
      genreIds: jsonEncode(genres),
      year: year,
      snapshotUpdatedAt: 0,
    ),
    rating: Rating(
      workKey: '$key',
      scoreHalf: half,
      createdAt: 0,
      scoredAt: at,
      updatedAt: at,
      updatedBy: 'a',
    ),
    external: {
      if (imdb != null)
        RatingSource.imdb: ExternalRating(
          workKey: '$key',
          source: RatingSource.imdb,
          status: RatingStatus.ok,
          scale: 10,
          value: imdb,
          via: ApiSource.omdb,
          fetchedAt: 0,
        ),
    },
  );
}

const actor = PeopleCredit(id: 1, name: 'Actor', role: FilmographyRole.acting);
const director = PeopleCredit(
  id: 2,
  name: 'Director',
  role: FilmographyRole.directing,
);

void main() {
  test(
    'profiles deduplicate titles, count high/low boundaries and population spread',
    () {
      final a = rated(1, 16), b = rated(2, 8), c = rated(3, 12);
      final profile = ScoreProfile([a, b, c, a]);
      expect(profile.count, 3);
      expect(profile.average, 6);
      expect(profile.highShare, closeTo(1 / 3, .0001));
      expect(profile.low, 1);
      expect(profile.spread, closeTo(1.632993, .00001));
      expect(profile.polarizing, isTrue);
      expect(ScoreProfile([a, b]).eligible, isFalse);
      expect(ScoreProfile([]).average, 0);
      expect(ScoreProfile([]).spread, 0);
    },
  );

  test(
    'multi-role and duplicate credits count once globally and once per role',
    () {
      final title = rated(1, 18, genres: [18, 18, 28], year: 1999);
      final insights = analyzeLibrary(
        [title],
        {
          peopleIdentity(title): [
            actor,
            actor,
            const PeopleCredit(
              id: 1,
              name: 'Actor',
              role: FilmographyRole.writing,
            ),
            director,
          ],
        },
      );
      expect(
        insights.people.singleWhere((p) => p.person.id == 1).profile.count,
        1,
      );
      final roles = insights.people.firstWhere((p) => p.person.id == 1).roles;
      expect(roles[FilmographyRole.acting]!.count, 1);
      expect(roles[FilmographyRole.writing]!.count, 1);
      expect(insights.genres[18]!.count, 1);
      expect(insights.decades.keys, [1990]);
    },
  );

  test('pairs need three shared distinct works and exclude self pairs', () {
    final titles = [rated(1, 20), rated(2, 18), rated(3, 16)];
    final credits = {
      for (final t in titles)
        peopleIdentity(t): [
          actor,
          director,
          const PeopleCredit(
            id: 2,
            name: 'Director',
            role: FilmographyRole.acting,
          ),
        ],
    };
    expect(analyzeLibrary(titles.take(2).toList(), credits).duos, isEmpty);
    final pairs = analyzeLibrary(titles, credits).duos;
    expect(pairs.length, 1);
    expect((pairs.single.director.id, pairs.single.actor.id), (2, 1));
    expect(pairs.single.profile.average, 9);
  });

  test(
    'missing and displaced credits are not counted; empty known credits are covered',
    () {
      final titles = [rated(1, 20), rated(2, 10), rated(3, 8)];
      final insights = analyzeLibrary(titles, {
        peopleIdentity(titles[0]): <PeopleCredit>[],
        '${titles[1].work.workKey}@999': [actor],
      });
      expect(insights.covered, 1);
      expect(insights.people, isEmpty);
    },
  );

  test('rank agreement is invariant to a systematic score shift', () {
    final titles = [
      rated(1, 10, imdb: 6),
      rated(2, 14, imdb: 8),
      rated(3, 16, imdb: 9),
    ];
    expect(rankAgreement(titles, RatingSource.imdb), closeTo(1, .0001));
    expect(rankAgreement(titles, RatingSource.kp), isNull);
  });
  test(
    'rank agreement handles reversed ranks, ties and undefined populations',
    () {
      expect(
        rankAgreement([
          rated(1, 10, imdb: 9),
          rated(2, 14, imdb: 7),
          rated(3, 18, imdb: 5),
        ], RatingSource.imdb),
        closeTo(-1, .0001),
      );
      expect(
        rankAgreement([
          rated(1, 10, imdb: 6),
          rated(2, 10, imdb: 7),
          rated(3, 18, imdb: 9),
        ], RatingSource.imdb),
        closeTo(.8660254, .00001),
      );
      expect(
        rankAgreement([
          rated(1, 10, imdb: 6),
          rated(2, 10, imdb: 7),
          rated(3, 10, imdb: 9),
        ], RatingSource.imdb),
        isNull,
      );
      expect(
        rankAgreement([
          rated(1, 10, imdb: 6),
          rated(2, 12, imdb: 7),
        ], RatingSource.imdb),
        isNull,
      );
    },
  );
  test('effective breadth counts memberships and rewards even coverage', () {
    expect(categoryBreadth([]), 0);
    expect(
      categoryBreadth([
        ScoreProfile([rated(1, 10)]),
      ]),
      1,
    );
    expect(
      categoryBreadth([
        ScoreProfile([rated(1, 10)]),
        ScoreProfile([rated(2, 10)]),
      ]),
      closeTo(2, .0001),
    );
    expect(
      categoryBreadth([
        ScoreProfile([rated(1, 10), rated(2, 10), rated(3, 10)]),
        ScoreProfile([rated(4, 10)]),
      ]),
      lessThan(2),
    );
  });

  test(
    'days group by local score date, with DST and month/year boundaries',
    () {
      final titles = [
        rated(1, 10, at: 4),
        rated(2, 12, at: 3),
        rated(3, 14, at: 2),
        rated(4, 16, at: 1),
      ];
      final dates = {
        4: DateTime(2026, 1, 1, 1),
        3: DateTime(2026, 1, 1, 0, 1),
        2: DateTime(2025, 12, 31, 23, 59),
        1: DateTime(2025, 10, 26),
      };
      final items = ratingDayItems(titles, toLocal: (ms) => dates[ms]!);
      expect(items.whereType<RatingDay>().map((d) => d.date), [
        DateTime(2026, 1, 1),
        DateTime(2025, 12, 31),
        DateTime(2025, 10, 26),
      ]);
      expect(items.whereType<RatingItem>().map((r) => r.title), titles);
      expect(ratingDayItems([]), isEmpty);
    },
  );
}
