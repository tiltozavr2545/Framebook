import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/recommendations/candidates.dart';
import 'package:framebook/data/recommendations/profile.dart';
import 'package:framebook/data/recommendations/ranking.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

import 'insights_test.dart' show rated;

TitleSummary title(
  int id, {
  WorkKind kind = WorkKind.movie,
  List<int> genres = const [28],
  String? date = '2000-01-01',
  double vote = 8,
  int votes = 1000,
}) => TitleSummary(
  key: kind == WorkKind.movie ? WorkKey.movie(id) : WorkKey.tv(id),
  title: 'Title $id',
  originalTitle: null,
  releaseDate: date,
  posterPath: null,
  vote: TmdbVote(vote, votes),
  genreIds: genres,
);
TasteProfile profile(List<RatedTitle> ratedTitles) =>
    TasteProfile(tasteSignals(ratedTitles, {}));
WatchlistTitle watch(int id, {List<int> genres = const [28]}) => WatchlistTitle(
  entry: WatchlistEntry(
    workKey: 'tmdb:movie:$id',
    addedAt: 0,
    updatedAt: 0,
    updatedBy: 'a',
  ),
  work: Work(
    workKey: 'tmdb:movie:$id',
    kind: WorkKind.movie,
    tmdbId: id,
    title: 'Listed $id',
    genreIds: '[${genres.join(',')}]',
    snapshotUpdatedAt: 0,
  ),
);

RatedTitle part(int season, int? episode, int half) {
  final key = episode == null
      ? WorkKey.season(9, season)
      : WorkKey.episode(9, season, episode);
  return RatedTitle(
    rating: Rating(
      workKey: '$key',
      scoreHalf: half,
      createdAt: 0,
      scoredAt: 0,
      updatedAt: 0,
      updatedBy: 'a',
    ),
    work: Work(
      workKey: '$key',
      kind: key.kind,
      tmdbId: season * 1000 + (episode ?? 0),
      title: 'Part',
      parentKey: '${key.parent}',
      genreIds: '[]',
      snapshotUpdatedAt: 0,
    ),
    series: const Work(
      workKey: 'tmdb:tv:9',
      kind: WorkKind.tv,
      tmdbId: 9,
      title: 'Series',
      genreIds: '[18]',
      year: 2010,
      snapshotUpdatedAt: 0,
    ),
  );
}

class _Api implements TmdbApi {
  int calls = 0, active = 0, peak = 0;
  bool brokenNeighbors = false;
  Completer<void>? barrier;
  final personIds = <int>[];
  Future<List<TitleSummary>> response() async {
    calls++;
    active++;
    if (active > peak) peak = active;
    try {
      await barrier?.future;
      return [title(100 + calls)];
    } finally {
      active--;
    }
  }

  @override
  Future<List<TitleSummary>> recommendations(WorkKey key) async {
    if (brokenNeighbors) throw const SourceException(SourceFailure.failed);
    return response();
  }

  @override
  Future<List<TitleSummary>> discoverRecommendations(
    WorkKind kind, {
    int? genre,
  }) => response();
  @override
  Future<List<TitleSummary>> trending() => response();
  @override
  Future<Person> person(int id) async {
    personIds.add(id);
    return Person(
      id: id,
      name: 'Favourite $id',
      biography: null,
      birthday: null,
      deathday: null,
      placeOfBirth: null,
      profilePath: null,
      acting: const [],
      crew: [
        PersonCredit(
          title: title(500 + id),
          roles: const ['Director', 'Writer'],
        ),
        PersonCredit(title: title(500 + id), roles: const ['Producer']),
      ],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const today = '2026-11-06';
  test(
    'changing favourites reuses unchanged source jobs and retries failures',
    () async {
      final api = _Api()..brokenNeighbors = true;
      final cache = RecommendationSourceCache();
      Future<void> load(Set<int> favorites) => loadRecommendationCandidates(
        api,
        RecommendationPlan(
          profile: profile([rated(1, 18)]),
          favorites: favorites,
          watchlist: {},
          now: DateTime(2026, 11, 6),
        ),
        active: () => true,
        publish: (_) {},
        cache: cache,
      );
      await load({138});
      final calls = api.calls;
      api.brokenNeighbors = false;
      await load({138, 139});
      expect(api.calls, calls + 1); // Only the failed seed is retried.
      expect(api.personIds, [138, 139]);
      await load({139});
      expect(api.calls, calls + 1);
      expect(api.personIds, [138, 139]);
    },
  );

  test('cached bursts publish a bounded number of snapshots', () async {
    final updates = <RecommendationPool>[];
    await loadRecommendationCandidates(
      _Api(),
      RecommendationPlan(
        profile: profile([rated(1, 18)]),
        favorites: {for (var i = 1; i <= 8; i++) i},
        watchlist: {},
        now: DateTime(2026, 11, 6),
      ),
      active: () => true,
      publish: updates.add,
    );
    expect(updates.last.candidates, isNotEmpty);
    expect(updates.last.running, isFalse);
    expect(updates.length, lessThanOrEqualTo(4));
    expect(updates.any((p) => p.running && p.candidates.isNotEmpty), isTrue);
  });
  test(
    'a whole-series rating overrides parts and episode counts never multiply its weight',
    () {
      final episodes = [for (var e = 1; e <= 100; e++) part(1, e, 4)];
      final signal = tasteSignals([
        part(1, null, 16),
        ...episodes,
        part(2, 1, 20),
      ], {}).single;
      expect(signal.key, const WorkKey.tv(9));
      expect(signal.score, 9);
      expect(signal.genres, {18});
      expect(signal.year, 2010);
      final whole = rated(9, 12, kind: WorkKind.tv);
      expect(
        tasteSignals([whole, part(1, null, 20), ...episodes], {}).single.score,
        6,
      );
      final twoSeasons = tasteSignals([...episodes, part(2, 1, 20)], {}).single;
      expect(twoSeasons.score, 6);
      expect(profile([rated(1, 20), ...episodes]).signals.length, 2);
    },
  );
  test(
    'sparse genre evidence is smoothed, negative scores count and dates do not weight taste',
    () {
      final one = profile([
        rated(1, 18, genres: [28]),
      ]);
      final many = profile([
        for (var i = 1; i <= 5; i++) rated(i, 18, genres: [28]),
      ]);
      expect(
        many.genreAffinity(WorkKind.movie, 28),
        greaterThan(one.genreAffinity(WorkKind.movie, 28)),
      );
      expect(
        profile([
          rated(1, 4, genres: [18]),
        ]).genreAffinity(WorkKind.movie, 18),
        lessThan(0),
      );
      final a = profile([rated(1, 18, at: 1), rated(2, 16, at: 2)]);
      final b = profile([rated(1, 18, at: 999), rated(2, 16, at: 999)]);
      expect(a.seeds.map((s) => s.key), b.seeds.map((s) => s.key));
      expect(a.average, b.average);
    },
  );

  test(
    'learned people require three distinct works, not three jobs on one work',
    () {
      final signals = [
        for (var i = 1; i <= 3; i++)
          TasteSignal(
            key: WorkKey.movie(i),
            title: 'Film $i',
            score: 9,
            genres: {28},
            year: 2000,
            people: const [
              PeopleCredit(
                id: 138,
                name: 'Author',
                role: FilmographyRole.acting,
              ),
              PeopleCredit(
                id: 138,
                name: 'Author',
                role: FilmographyRole.directing,
              ),
              PeopleCredit(
                id: 138,
                name: 'Author',
                role: FilmographyRole.writing,
              ),
            ],
          ),
      ];
      expect(TasteProfile(signals.take(2).toList()).topPeople, isEmpty);
      expect(TasteProfile(signals).topPeople, [138]);
    },
  );

  test(
    'a watchlisted next season stays eligible after rating an earlier season',
    () {
      final season = part(2, null, 18);
      final listed = WatchlistTitle(
        entry: WatchlistEntry(
          workKey: season.work.workKey,
          addedAt: 0,
          updatedAt: 0,
          updatedBy: 'a',
        ),
        work: season.work,
        series: season.series,
      );
      final feed = rankRecommendations(
        profile: profile([part(1, null, 16)]),
        candidates: [RecommendationCandidate(title(9, kind: WorkKind.tv))],
        watchlist: [listed],
        favorites: {},
        hidden: {},
        today: today,
      );
      expect(feed.forYou, isEmpty);
      expect(feed.watchlist.single.title.key, const WorkKey.season(9, 2));
      final hidden = rankRecommendations(
        profile: profile([part(1, null, 16)]),
        candidates: [],
        watchlist: [listed],
        favorites: {},
        hidden: {const WorkKey.tv(9)},
        today: today,
      );
      expect(hidden.watchlist, isEmpty);
    },
  );
  test(
    'seed choice includes varied positives and a negative, bounded separately by kind',
    () {
      final p = profile([
        rated(1, 20, genres: [28]),
        rated(2, 19, genres: [28]),
        rated(3, 18, genres: [18]),
        rated(4, 4),
        rated(5, 18, kind: WorkKind.tv),
      ]);
      expect(
        p.seeds.map((s) => s.key),
        containsAll([
          const WorkKey.movie(1),
          const WorkKey.movie(3),
          const WorkKey.movie(4),
          const WorkKey.tv(5),
        ]),
      );
      expect(p.seeds.length, 4);
    },
  );
  test(
    'one vote cannot beat reliable quality, and future releases are excluded',
    () {
      expect(
        candidateQuality(title(1, vote: 10, votes: 1)),
        lessThan(candidateQuality(title(2))),
      );
      expect(
        releasedForRecommendations(title(1, date: '2026-11-07'), today),
        isFalse,
      );
      expect(releasedForRecommendations(title(1, date: today), today), isTrue);
      expect(releasedForRecommendations(title(1, date: null), today), isTrue);
    },
  );
  test(
    'duplicates combine independent provenance without duplicating a result',
    () {
      final merged = mergeCandidates([
        RecommendationCandidate(title(2), seeds: {const WorkKey.movie(1)}),
        RecommendationCandidate(title(2), people: {138: 'Tarantino'}),
      ]);
      expect(merged.length, 1);
      expect(merged.single.people.keys, [138]);
      expect(merged.single.seeds, {const WorkKey.movie(1)});
    },
  );
  test(
    'For you alternates 50/50 slots and explores different genres, deterministically',
    () {
      final candidates = [
        for (var i = 10; i < 50; i++)
          RecommendationCandidate(
            title(i, genres: i < 30 ? [28] : [18]),
            seeds: i < 30 ? {const WorkKey.movie(1)} : {},
          ),
      ];
      RecommendationFeed rank() => rankRecommendations(
        profile: profile([
          rated(1, 18, genres: [28]),
        ]),
        candidates: candidates,
        watchlist: [],
        favorites: {},
        hidden: {},
        today: today,
      );
      final feed = rank();
      expect(feed.forYou.length, 20);
      expect(feed.forYou.where((p) => p.exploratory).length, 10);
      expect(feed.forYou.map((p) => p.title.key).toSet().length, 20);
      expect(feed.forYou.first.title.genreIds, [28]);
      expect(feed.forYou[1].title.genreIds, [18]);
      expect(
        feed.forYou.map((p) => p.title.key),
        rank().forYou.map((p) => p.title.key),
      );
    },
  );
  test(
    'multiple positive links beat negative links with the same metadata',
    () {
      final feed = rankRecommendations(
        profile: profile([rated(1, 20), rated(2, 18), rated(3, 2)]),
        candidates: [
          RecommendationCandidate(
            title(10),
            seeds: {const WorkKey.movie(1), const WorkKey.movie(2)},
          ),
          RecommendationCandidate(title(11), seeds: {const WorkKey.movie(3)}),
        ],
        watchlist: [],
        favorites: {},
        hidden: {},
        today: today,
      );
      expect(feed.forYou.first.title.key, const WorkKey.movie(10));
      expect(feed.forYou.first.reason, RecommendationReason.similar);
    },
  );
  test(
    'rated roots, hidden titles, watchlist and future films stay out of discovery',
    () {
      final feed = rankRecommendations(
        profile: profile([rated(1, 18), part(1, 1, 18)]),
        candidates: [
          for (var i = 1; i <= 6; i++)
            RecommendationCandidate(
              title(i, date: i == 4 ? '2999-01-01' : '2000-01-01'),
            ),
          RecommendationCandidate(title(9, kind: WorkKind.tv)),
          RecommendationCandidate(title(1, kind: WorkKind.tv)),
        ],
        watchlist: [watch(3)],
        favorites: {},
        hidden: {const WorkKey.movie(2)},
        today: today,
      );
      expect(feed.forYou.map((p) => p.title.key).toSet(), {
        const WorkKey.movie(5),
        const WorkKey.movie(6),
        const WorkKey.tv(1),
      });
      expect(feed.watchlist.single.title.key, const WorkKey.movie(3));
    },
  );
  test(
    'watchlist ranks offline from all local entries and does not change them',
    () {
      final entries = [
        watch(20, genres: [18]),
        watch(21, genres: [28]),
      ];
      final feed = rankRecommendations(
        profile: profile([
          rated(1, 18, genres: [28]),
        ]),
        candidates: [],
        watchlist: entries,
        favorites: {},
        hidden: {},
        today: today,
      );
      expect(feed.watchlist.map((p) => p.title.key), [
        const WorkKey.movie(21),
        const WorkKey.movie(20),
      ]);
      expect(entries.first.entry.deletedAt, isNull);
    },
  );
  test(
    'favorite provenance works without acting and is explained by the actual person',
    () async {
      final api = _Api();
      final updates = <RecommendationPool>[];
      await loadRecommendationCandidates(
        api,
        RecommendationPlan(
          profile: profile([]),
          favorites: {138},
          watchlist: {},
          now: DateTime(2026, 11, 6),
        ),
        active: () => true,
        publish: updates.add,
      );
      final feed = rankRecommendations(
        profile: profile([]),
        candidates: updates.last.candidates,
        watchlist: [],
        favorites: {138},
        hidden: {},
        today: today,
      );
      final pick = feed.people.single;
      expect(pick.title.key, const WorkKey.movie(638));
      expect(pick.reason, RecommendationReason.person);
      expect(pick.detail, 'Favourite 138');
    },
  );
  test(
    'large favourite lists rotate within the request budget instead of permanently omitting people',
    () {
      final seen = <int>{};
      for (var day = 1; day <= 16; day++) {
        final plan = RecommendationPlan(
          profile: profile([]),
          favorites: {for (var i = 1; i <= 16; i++) i},
          watchlist: {},
          now: DateTime(2026, 11, day),
        );
        expect(plan.people.length, 8);
        seen.addAll(plan.people);
      }
      expect(seen.length, 16);
    },
  );
  test(
    'candidate loading publishes partial success even when one source fails',
    () async {
      final api = _Api()..brokenNeighbors = true;
      final updates = <RecommendationPool>[];
      await loadRecommendationCandidates(
        api,
        RecommendationPlan(
          profile: profile([rated(1, 18)]),
          favorites: {138},
          watchlist: {},
          now: DateTime(2026, 11, 6),
        ),
        active: () => true,
        publish: updates.add,
      );
      expect(updates.last.failed, greaterThan(0));
      expect(updates.last.running, isFalse);
      expect(updates.last.candidates, isNotEmpty);
      expect(updates.any((s) => s.running && s.candidates.isNotEmpty), isTrue);
    },
  );
  test(
    'candidate loading uses three workers and stops scheduling after cancellation',
    () async {
      final api = _Api()..barrier = Completer<void>();
      var active = true;
      final pass = loadRecommendationCandidates(
        api,
        RecommendationPlan(
          profile: profile([
            rated(1, 18, genres: [28]),
            rated(2, 16, genres: [18]),
          ]),
          favorites: {},
          watchlist: {},
          now: DateTime(2026, 11, 6),
        ),
        active: () => active,
        publish: (_) {},
      );
      await pumpEventQueue();
      expect(api.peak, 3);
      final calls = api.calls;
      active = false;
      api.barrier!.complete();
      await pass;
      expect(api.calls, calls);
    },
  );
}
