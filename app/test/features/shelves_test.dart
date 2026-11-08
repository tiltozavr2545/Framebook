import 'dart:async';
import 'package:flutter/material.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:framebook/features/search/shelves.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/library/favorite_people.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/recommendations/candidates.dart';
import 'package:framebook/data/recommendations/hidden.dart';
import 'package:framebook/data/recommendations/providers.dart';
import 'package:framebook/data/recommendations/ranking.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/data/sources/providers.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';

class Api implements TmdbApi {
  int requests = 0;
  final String label;
  Api(this.label);
  @override
  Future<SearchPage> search(String query, {int page = 1}) async => SearchPage(
    [
      TitleSummary(
        key: WorkKey.movie(page),
        title: label,
        originalTitle: null,
        releaseDate: null,
        posterPath: null,
        vote: TmdbVote(null, null),
        genreIds: [],
      ),
    ],
    page: page,
    pages: 2,
  );
  @override
  Future<List<TitleSummary>> recommendations(WorkKey key) async {
    requests++;
    return [
      TitleSummary(
        key: WorkKey.movie(2),
        title: 'recommended',
        originalTitle: null,
        releaseDate: '2000-01-01',
        posterPath: null,
        vote: TmdbVote(null, null),
        genreIds: [],
      ),
    ];
  }

  @override
  Future<List<TitleSummary>> discoverRecommendations(
    WorkKind kind, {
    int? genre,
    int page = 1,
  }) async => [];
  @override
  Future<List<TitleSummary>> trending() async => [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Index extends PeopleIndex {
  @override
  PeopleIndexState build() => const PeopleIndexState();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'candidate progress preserves the displayed batch until completion',
    () async {
      final batches = StreamController<RecommendationPool>();
      final c = ProviderContainer(
        overrides: [
          tmdbProvider.overrideWithValue(Api('test')),
          recommendationPoolProvider.overrideWith((ref) => batches.stream),
        ],
      );
      final sub = c.listen(recommendationDisplayCandidatesProvider, (_, _) {});
      final first = <RecommendationCandidate>[];
      // Distinct batches need not contain real API data to verify publication.
      final title = TitleSummary(
        key: const WorkKey.movie(1),
        title: 'First',
        originalTitle: null,
        releaseDate: null,
        posterPath: null,
        vote: const TmdbVote(null, null),
        genreIds: const [],
      );
      first.add(RecommendationCandidate(title, discovered: true));
      final second = [
        ...first,
        RecommendationCandidate(title, discovered: true),
      ];
      batches.add(RecommendationPool(candidates: first, running: true));
      await pumpEventQueue();
      expect(c.read(recommendationDisplayCandidatesProvider), same(first));
      batches.add(RecommendationPool(candidates: second, running: true));
      await pumpEventQueue();
      expect(c.read(recommendationDisplayCandidatesProvider), same(first));
      batches.add(RecommendationPool(candidates: second));
      await pumpEventQueue();
      expect(c.read(recommendationDisplayCandidatesProvider), same(second));
      // A new retrieval pass keeps the completed result while in progress.
      batches.add(RecommendationPool(candidates: first, running: true));
      await pumpEventQueue();
      expect(c.read(recommendationDisplayCandidatesProvider), same(second));
      sub.close();
      c.dispose();
      await batches.close();
    },
  );
  for (final scale in [1.0, 1.8, 2.0, 3.0]) {
    for (final withReason in [false, true]) {
      testWidgets(
        'Discover shelf captions fit at text scale $scale, reason $withReason',
        (tester) async {
          tester.view.physicalSize = const Size(640, 1560);
          tester.view.devicePixelRatio = 2;
          addTearDown(tester.view.reset);
          const title =
              'A long film title that wraps across both caption lines';
          final titles = [
            TitleSummary(
              key: const WorkKey.movie(1),
              title: title,
              originalTitle: null,
              releaseDate: '2000-01-01',
              posterPath: null,
              vote: const TmdbVote(null, null),
              genreIds: const [],
            ),
          ];
          SharedPreferences.setMockInitialValues({});
          final prefs = await SharedPreferences.getInstance();
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                recommendationFeedProvider.overrideWith(
                  (ref) => RecommendationFeed(
                    forYou: withReason
                        ? [
                            RecommendationPick(
                              titles.single,
                              RecommendationReason.similar,
                              detail:
                                  'A favourite title with a long explanation',
                            ),
                          ]
                        : const [],
                  ),
                ),
                recommendationPoolProvider.overrideWith(
                  (ref) => Stream.value(const RecommendationPool()),
                ),
                sharedPreferencesProvider.overrideWithValue(prefs),
                trendingShelfProvider.overrideWith(
                  (ref) async => withReason ? const [] : titles,
                ),
                nowPlayingShelfProvider.overrideWith((ref) async => const []),
                bestShelfProvider.overrideWith((ref) async => const []),
                ratedTitlesProvider.overrideWith((ref) => Stream.value([])),
              ],
              child: MaterialApp(
                theme: FramebookTheme.light,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const Scaffold(body: Shelves()),
              ),
            ),
          );
          try {
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(find.text(title), findsOneWidget);
            expect(find.text('2000'), findsOneWidget);
            final bounds = tester.getRect(find.byType(ListView).last);
            expect(
              tester.getRect(find.text('2000')).bottom,
              lessThanOrEqualTo(bounds.bottom),
            );
          } finally {
            await tester.pumpWidget(const SizedBox());
            await tester.pump();
          }
        },
      );
    }
  }

  test(
    'rating and deleting a recommendation updates exclusions without requests',
    () async {
      final changes = StreamController<List<RatedTitle>>();
      addTearDown(changes.close);
      RatedTitle rated(int id, int half) => RatedTitle(
        rating: Rating(
          workKey: 'tmdb:movie:$id',
          scoreHalf: half,
          createdAt: 1,
          scoredAt: 1,
          updatedAt: 1,
          updatedBy: 'a',
        ),
        work: Work(
          workKey: 'tmdb:movie:$id',
          kind: WorkKind.movie,
          tmdbId: id,
          title: 'Film',
          genreIds: '[]',
          snapshotUpdatedAt: 1,
        ),
      );
      final api = Api('RU');
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final c = ProviderContainer(
        overrides: [
          tmdbProvider.overrideWithValue(api),
          ratedTitlesProvider.overrideWith((ref) => changes.stream),
          favoritePeopleProvider.overrideWith((ref) => Stream.value([])),
          watchlistTitlesProvider.overrideWith((ref) => Stream.value([])),
          peopleIndexProvider.overrideWith(_Index.new),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(c.dispose);
      c.listen(recommendationFeedProvider, (_, __) {});
      var badgeUpdates = 0;
      c.listen(myScoreHalfProvider(const WorkKey.movie(2)), (_, _) {
        badgeUpdates++;
      });
      changes.add([rated(1, 18)]);
      for (
        var i = 0;
        i < 50 && c.read(recommendationFeedProvider).forYou.isEmpty;
        i++
      ) {
        await pumpEventQueue();
      }
      expect(
        c.read(recommendationFeedProvider).forYou.map((x) => x.title.key),
        [WorkKey.movie(2)],
      );
      expect(c.read(myScoreHalfProvider(const WorkKey.movie(2))), isNull);
      final unchangedBadgeUpdates = badgeUpdates;
      changes.add([rated(1, 16)]);
      await pumpEventQueue();
      expect(badgeUpdates, unchangedBadgeUpdates);
      changes.add([rated(1, 18), rated(2, 12)]);
      await pumpEventQueue();
      expect(c.read(recommendationFeedProvider).forYou, isEmpty);
      expect(c.read(myScoreHalfProvider(const WorkKey.movie(2))), 12);
      changes.add([rated(1, 18)]);
      await pumpEventQueue();
      expect(
        c.read(recommendationFeedProvider).forYou.map((x) => x.title.key),
        [const WorkKey.movie(2)],
      );
      expect(c.read(myScoreHalfProvider(const WorkKey.movie(2))), isNull);
      expect(api.requests, 1);
      await c
          .read(hiddenRecommendationsProvider.notifier)
          .hide(const WorkKey.movie(2));
      expect(c.read(recommendationFeedProvider).forYou, isEmpty);
      await c
          .read(hiddenRecommendationsProvider.notifier)
          .restore(const WorkKey.movie(2));
      expect(
        c.read(recommendationFeedProvider).forYou.single.title.key,
        const WorkKey.movie(2),
      );
      expect(api.requests, 1);
    },
  );
}
