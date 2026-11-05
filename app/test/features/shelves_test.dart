import 'dart:async';
import 'package:flutter/material.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:framebook/features/search/shelves.dart';
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
        releaseDate: null,
        posterPath: null,
        vote: TmdbVote(null, null),
        genreIds: [],
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  for (final scale in [1.0, 1.8, 2.0, 3.0]) {
    testWidgets('Discover shelf captions fit at text scale $scale', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(640, 1560);
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);
      const title = 'A long film title that wraps across both caption lines';
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
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            forYouShelfProvider.overrideWith((ref) async => const []),
            trendingShelfProvider.overrideWith((ref) async => titles),
            nowPlayingShelfProvider.overrideWith((ref) async => const []),
            bestShelfProvider.overrideWith((ref) async => const []),
            myRatingProvider.overrideWith((ref, key) => Stream.value(null)),
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
    });
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
      final c = ProviderContainer(
        overrides: [
          tmdbProvider.overrideWithValue(api),
          ratedTitlesProvider.overrideWith((ref) => changes.stream),
        ],
      );
      addTearDown(c.dispose);
      c.listen(forYouShelfProvider, (_, __) {});
      changes.add([rated(1, 18)]);
      await pumpEventQueue();
      expect((await c.read(forYouShelfProvider.future)).map((x) => x.key), [
        WorkKey.movie(2),
      ]);
      changes.add([rated(1, 18), rated(2, 12)]);
      await pumpEventQueue();
      expect(await c.read(forYouShelfProvider.future), isEmpty);
      changes.add([rated(1, 18)]);
      await pumpEventQueue();
      expect((await c.read(forYouShelfProvider.future)).map((x) => x.key), [
        const WorkKey.movie(2),
      ]);
      expect(api.requests, 1);
    },
  );
}
