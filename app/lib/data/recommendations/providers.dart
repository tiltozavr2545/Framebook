import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../library/favorite_people.dart';
import '../library/library.dart';
import '../library/people_index.dart';
import '../sources/providers.dart';
import '../sources/tmdb/tmdb_models.dart';
import 'candidates.dart';
import 'catalog.dart';
import 'hidden.dart';
import 'profile.dart';
import 'ranking.dart';

final recommendationClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final tasteProfileProvider = Provider.autoDispose<TasteProfile>((ref) {
  final titles = ref.watch(ratedTitlesProvider).value ?? const [];
  final credits = ref.watch(peopleIndexProvider).entries;
  return TasteProfile(tasteSignals(titles, credits));
});

final recommendationPlanProvider = Provider.autoDispose<RecommendationPlan>((
  ref,
) {
  final profile = ref.watch(tasteProfileProvider);
  final running = ref.watch(peopleIndexProvider).running;
  return RecommendationPlan(
    profile: profile,
    favorites: favoriteIds(ref.watch(favoritePeopleProvider).value ?? const []),
    watchlist: {
      for (final w
          in ref.watch(watchlistTitlesProvider).value ??
              const <WatchlistTitle>[])
        recommendationRoot(w.key),
    },
    now: ref.watch(recommendationClockProvider)(),
    learnedPeople: running ? const [] : profile.topPeople,
  );
});

final recommendationPoolProvider =
    StreamProvider.autoDispose<RecommendationPool>((ref) {
      final plan = ref.watch(recommendationPlanProvider);
      final api = ref.watch(tmdbProvider);
      if (!plan.enabled) return Stream.value(const RecommendationPool());
      final trend = ref.watch(trendingShelfProvider.future);
      // Attach the error handler immediately, even if preceding jobs fail first.
      final safeTrend = trend.then(
        (value) => value,
        onError: (Object _, StackTrace __) => const <TitleSummary>[],
      );
      final controller = StreamController<RecommendationPool>();
      var active = true;
      ref.onDispose(() {
        active = false;
        unawaited(controller.close());
      });
      unawaited(
        loadRecommendationCandidates(
          api,
          plan,
          active: () => active,
          publish: (value) {
            if (active) controller.add(value);
          },
          trending: () => safeTrend,
        ).then(
          (_) async {
            if (active) await controller.close();
          },
          onError: (Object error, StackTrace stack) async {
            if (active) {
              controller.addError(error, stack);
              await controller.close();
            }
          },
        ),
      );
      return controller.stream;
    });

final recommendationFeedProvider = Provider.autoDispose<RecommendationFeed>(
  (ref) => rankRecommendations(
    profile: ref.watch(tasteProfileProvider),
    candidates:
        ref.watch(recommendationPoolProvider).value?.candidates ?? const [],
    watchlist: ref.watch(watchlistTitlesProvider).value ?? const [],
    favorites: favoriteIds(ref.watch(favoritePeopleProvider).value ?? const []),
    hidden: ref.watch(hiddenRecommendationsProvider),
    today: recommendationDay(ref.watch(recommendationClockProvider)()),
  ),
);
