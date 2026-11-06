import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/foreground.dart';
import '../latest_worker.dart';
import '../library/favorite_people.dart';
import '../library/library.dart';
import '../library/people_index.dart';
import '../sources/providers.dart';
import '../sources/tmdb/tmdb_models.dart';
import '../work_key.dart';
import 'candidates.dart';
import 'catalog.dart';
import 'hidden.dart';
import 'profile.dart';
import 'ranking.dart';

final recommendationClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

final _sourceCacheProvider = Provider.autoDispose<RecommendationSourceCache>((
  ref,
) {
  ref.watch(tmdbProvider);
  return RecommendationSourceCache();
});

final tasteProfileProvider = Provider.autoDispose<TasteProfile>((ref) {
  final titles = ref.watch(ratedTitlesProvider).value ?? const [];
  final credits = ref.watch(peopleIndexProvider.select((s) => s.entries));
  return TasteProfile(tasteSignals(titles, credits));
});

final recommendationPlanProvider = Provider.autoDispose<RecommendationPlan>((
  ref,
) {
  final profile = ref.watch(tasteProfileProvider);
  final running = ref.watch(peopleIndexProvider.select((s) => s.running));
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
      final cache = ref.watch(_sourceCacheProvider);
      if (!plan.enabled) return Stream.value(const RecommendationPool());
      if (!ref.watch(foregroundProvider)) return const Stream.empty();
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
          cache: cache,
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

final _rankingInputProvider = Provider.autoDispose<_RankingInput>((ref) {
  return _RankingInput(
    ref.watch(tasteProfileProvider),
    ref.watch(recommendationPoolProvider.select((s) => s.value?.candidates)) ??
        const [],
    ref.watch(watchlistTitlesProvider).value ?? const [],
    favoriteIds(ref.watch(favoritePeopleProvider).value ?? const []),
    ref.watch(hiddenRecommendationsProvider),
    recommendationDay(ref.watch(recommendationClockProvider)()),
  );
});

final class _RankingInput {
  const _RankingInput(
    this.profile,
    this.candidates,
    this.watchlist,
    this.favorites,
    this.hidden,
    this.today,
  );
  final TasteProfile profile;
  final List<RecommendationCandidate> candidates;
  final List<WatchlistTitle> watchlist;
  final Set<int> favorites;
  final Set<WorkKey> hidden;
  final String today;
}

RecommendationFeed _rank(_RankingInput input) => rankRecommendations(
  profile: input.profile,
  candidates: input.candidates,
  watchlist: input.watchlist,
  favorites: input.favorites,
  hidden: input.hidden,
  today: input.today,
);

final _rankWorkerProvider =
    Provider.autoDispose<LatestWorker<_RankingInput, RecommendationFeed>>((
      ref,
    ) {
      final worker = LatestWorker<_RankingInput, RecommendationFeed>(
        (input) => compute(_rank, input, debugLabel: 'recommendation ranking'),
      );
      ref.onDispose(worker.dispose);
      return worker;
    });

final _largeFeedProvider = FutureProvider.autoDispose<RecommendationFeed>((
  ref,
) async {
  final input = ref.watch(_rankingInputProvider);
  final worker = ref.watch(_rankWorkerProvider);
  // Coalesce cache hits and rapidly arriving candidate batches. Riverpod
  // discards a superseded result; no provider/container is sent to the worker.
  await Future<void>.delayed(const Duration(milliseconds: 80));
  if (!ref.mounted) return const RecommendationFeed();
  return await worker.run(input) ?? const RecommendationFeed();
});

final recommendationFeedProvider = Provider.autoDispose<RecommendationFeed>((
  ref,
) {
  final input = ref.watch(_rankingInputProvider);
  if (input.candidates.length + input.watchlist.length <= 100 &&
      input.profile.signals.length <= 80) {
    return _rank(input);
  }
  final feed =
      ref.watch(_largeFeedProvider).value ?? const RecommendationFeed();
  // A previous worker result may stay visible while reranking. User exclusions
  // apply immediately, before the new result arrives.
  final rated = input.profile.signals.map((s) => s.key).toSet();
  final listed = input.watchlist.map((w) => recommendationRoot(w.key)).toSet();
  final listedKeys = input.watchlist.map((w) => w.key).toSet();
  bool visible(RecommendationPick p, {bool watchlist = false}) {
    final key = p.title.key;
    final root = recommendationRoot(key);
    return !input.hidden.contains(key) &&
        !input.hidden.contains(root) &&
        releasedForRecommendations(p.title, input.today) &&
        (watchlist
            ? listedKeys.contains(key)
            : !rated.contains(root) && !listed.contains(root));
  }

  return RecommendationFeed(
    forYou: feed.forYou.where(visible).toList(),
    people: input.favorites.isEmpty
        ? const []
        : feed.people.where(visible).toList(),
    explore: feed.explore.where(visible).toList(),
    watchlist: feed.watchlist
        .where((p) => visible(p, watchlist: true))
        .toList(),
  );
});
