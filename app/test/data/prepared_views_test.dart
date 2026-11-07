import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/ratings_preferences.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/library/insights.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/prepared_views.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/view_computer.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/ratings/ratings_model.dart';
import 'insights_test.dart' show rated;
import 'recommendation_performance_test.dart' show waitFor;

class _Gate extends ViewComputer {
  final barrier = Completer<void>();
  int calls = 0;
  @override
  Future<O> run<I, O>(
    ComputeCallback<I, O> callback,
    I input,
    String label,
  ) async {
    calls++;
    await barrier.future;
    return compute(callback, input, debugLabel: label);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'large rating views retain previous rows and discard superseded sorts',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final updates = StreamController<List<RatedTitle>>(sync: true);
      final gate = _Gate();
      final c = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ratedTitlesProvider.overrideWith((ref) => updates.stream),
          viewComputerProvider.overrideWithValue(gate),
        ],
      );
      final sub = c.listen(ratingsPageDataProvider, (_, _) {});
      try {
        updates.add([rated(1, 16)]);
        await pumpEventQueue();
        final first = c.read(ratingsPageDataProvider).value!;
        updates.add(List.generate(500, (i) => rated(i + 1, 16)));
        expect(c.read(ratingsPageDataProvider).value, same(first));
        await pumpEventQueue();
        c.read(ratingsViewProvider.notifier).sortBy(RatingsSort.score);
        c.read(ratingsPageDataProvider);
        updates.add([
          for (var i = 1; i <= 500; i++) rated(i, i == 500 ? 20 : 16),
        ]);
        c.read(ratingsPageDataProvider);
        gate.barrier.complete();
        await waitFor(
          () =>
              c
                  .read(ratingsPageDataProvider)
                  .value
                  ?.shown
                  .first
                  .rating
                  .scoreHalf ==
              20,
        );
        final result = c.read(ratingsPageDataProvider).value!;
        expect(result.view.sort, RatingsSort.score);
        expect(result.shown.first.key, const WorkKey.movie(500));
        expect(result.shown.length, 500);
        expect(gate.calls, lessThanOrEqualTo(2));
      } finally {
        if (!gate.barrier.isCompleted) gate.barrier.complete();
        sub.close();
        c.dispose();
        await updates.close();
      }
    },
  );

  test(
    'statistics, ranked people and filmographies transfer through real workers',
    () async {
      final c = ProviderContainer();
      final computer = c.read(viewComputerProvider);
      final titles = [
        rated(1, 10, imdb: 5),
        rated(2, 16, imdb: 7),
        rated(3, 20, imdb: 9),
      ];
      final stats = await computer.run(prepareStatsKind, (
        titles,
        WorkKind.movie,
      ), 'stats test');
      expect(stats.median, 8);
      expect(stats.high.length, 2);
      expect(stats.medium.length, 1);
      expect(stats.sources[RatingSource.imdb]!.agreement, 1);
      expect(stats.sources[RatingSource.imdb]!.finds.length, 2);
      final insights = LibraryInsights(
        genres: {},
        decades: {},
        duos: [],
        covered: 3,
        people: [
          for (var i = 600; i >= 1; i--)
            PersonInsight(
              PeopleCredit(
                id: i,
                name: 'Person $i',
                role: FilmographyRole.acting,
              ),
              titles,
              {FilmographyRole.acting: titles},
            ),
        ],
      );
      final ranked = await computer.run(prepareInsights, (
        titles,
        insights,
        null,
        PeopleOrder.frequent,
      ), 'people test');
      expect(ranked.ranked.length, 600);
      expect(ranked.ranked.first.$1.person.id, 1);
      expect(ranked.ranked.last.$1.person.id, 600);
      final person = Person.fromJson(
        Json({
          'id': 1,
          'name': 'Person',
          'combined_credits': {
            'cast': [
              for (var i = 1; i <= 500; i++)
                {'id': i, 'media_type': 'movie', 'title': 'Film $i'},
            ],
            'crew': [
              {
                'id': 1,
                'media_type': 'movie',
                'title': 'Film 1',
                'job': 'Director',
              },
            ],
          },
        }),
      );
      final filmography = await computer.run(
        preparePerson,
        person,
        'filmography test',
      );
      expect(filmography.all.length, 500);
      expect(
        filmography.groups[FilmographyRole.directing]!.single.title.key,
        const WorkKey.movie(1),
      );
      expect(
        filmography.all
            .singleWhere((row) => row.title.key == const WorkKey.movie(1))
            .roles,
        contains('Director'),
      );
      c.dispose();
    },
  );
}
