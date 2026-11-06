import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/library/favorite_people.dart';
import 'package:framebook/data/library/insights_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/recommendations/candidates.dart';
import 'package:framebook/data/recommendations/hidden.dart';
import 'package:framebook/data/recommendations/providers.dart';
import 'package:framebook/data/recommendations/ranking.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'insights_test.dart' show rated;
import 'recommendations_test.dart' show title;

class _Index extends PeopleIndex {
  @override
  PeopleIndexState build() => PeopleIndexState(
    entries: {
      for (var i = 1; i <= 100; i++)
        'tmdb:movie:$i@$i': const [
          PeopleCredit(
            id: 138,
            name: 'Author',
            role: FilmographyRole.directing,
          ),
        ],
    },
  );
}

Future<void> waitFor(bool Function() condition) async {
  for (var i = 0; i < 1500; i++) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
  fail('Worker did not publish the latest result');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'large ranking runs in a worker and applies exclusions during recomputation',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final ratings = StreamController<List<RatedTitle>>();
      final pool = StreamController<RecommendationPool>();
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          ratedTitlesProvider.overrideWith((ref) => ratings.stream),
          watchlistTitlesProvider.overrideWith((ref) => Stream.value([])),
          favoritePeopleProvider.overrideWith((ref) => Stream.value([])),
          peopleIndexProvider.overrideWith(_Index.new),
          recommendationPoolProvider.overrideWith((ref) => pool.stream),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await ratings.close();
        await pool.close();
      });
      container.listen(recommendationFeedProvider, (_, _) {});
      ratings.add([rated(1, 18)]);
      pool.add(
        RecommendationPool(
          candidates: [
            for (var i = 1000; i < 1200; i++) RecommendationCandidate(title(i)),
          ],
        ),
      );
      await waitFor(
        () => container.read(recommendationFeedProvider).forYou.isNotEmpty,
      );
      final pick = container
          .read(recommendationFeedProvider)
          .forYou
          .first
          .title
          .key;
      await container.read(hiddenRecommendationsProvider.notifier).hide(pick);
      expect(
        container
            .read(recommendationFeedProvider)
            .forYou
            .any((p) => p.title.key == pick),
        isFalse,
      );
      // A newer pool replaces an older worker result, even during its debounce.
      pool.add(
        RecommendationPool(
          candidates: [
            for (var i = 2000; i < 2200; i++) RecommendationCandidate(title(i)),
          ],
        ),
      );
      pool.add(
        RecommendationPool(
          candidates: [
            for (var i = 3000; i < 3200; i++) RecommendationCandidate(title(i)),
          ],
        ),
      );
      await waitFor(
        () =>
            container.read(recommendationFeedProvider).forYou.isNotEmpty &&
            container
                .read(recommendationFeedProvider)
                .forYou
                .every((p) => p.title.key.tmdbId >= 3000),
      );
      final ratedPick = container
          .read(recommendationFeedProvider)
          .forYou
          .first
          .title
          .key;
      ratings.add([rated(1, 18), rated(ratedPick.tmdbId, 16)]);
      await pumpEventQueue();
      expect(
        container
            .read(recommendationFeedProvider)
            .forYou
            .any((p) => p.title.key == ratedPick),
        isFalse,
      );
    },
  );

  test(
    'large insight input and drill-down profiles survive isolate transfer',
    () async {
      final container = ProviderContainer(
        overrides: [
          ratedTitlesProvider.overrideWith(
            (ref) => Stream.value([
              for (var i = 1; i <= 100; i++) rated(i, 16, genres: [28]),
            ]),
          ),
          peopleIndexProvider.overrideWith(_Index.new),
        ],
      );
      addTearDown(container.dispose);
      container.listen(libraryInsightsProvider(WorkKind.movie), (_, _) {});
      await container.read(ratedTitlesProvider.future);
      final insights = await container.read(
        libraryInsightsProvider(WorkKind.movie).future,
      );
      expect(insights.genres[28]!.count, 100);
      expect(insights.genres[28]!.average, 8);
      expect(insights.people.single.profile.count, 100);
      expect(
        insights.people.single.roles[FilmographyRole.directing]!.average,
        8,
      );
    },
  );
}
