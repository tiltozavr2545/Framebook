import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/foreground.dart';
import '../latest_worker.dart';
import '../library/favorite_people.dart';
import '../library/library.dart';
import '../db/database.dart';
import '../library/taste_ratings.dart';
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

/// Credit indexing streams progress, but partial network batches must not
/// rebuild every taste weight and rerank the feed while the user scrolls.
class _RecommendationCredits extends Notifier<Map<String, List<PeopleCredit>>> {
  @override
  Map<String, List<PeopleCredit>> build() {
    ref.listen(peopleIndexProvider, (_, next) {
      if (!next.running || state.isEmpty) state = next.entries;
    });
    return ref.read(peopleIndexProvider).entries;
  }
}

final recommendationCreditsProvider =
    NotifierProvider.autoDispose<
      _RecommendationCredits,
      Map<String, List<PeopleCredit>>
    >(_RecommendationCredits.new);

typedef _TasteInput = (List<RatedTitle>, Map<String, List<PeopleCredit>>);
TasteProfile _buildTaste(_TasteInput input) =>
    TasteProfile(tasteSignals(input.$1, input.$2));

final _tasteWorkerProvider =
    Provider.autoDispose<LatestWorker<_TasteInput, TasteProfile>>((ref) {
      final worker = LatestWorker<_TasteInput, TasteProfile>(
        (input) => compute(_buildTaste, input, debugLabel: 'taste profile'),
      );
      ref.onDispose(worker.dispose);
      return worker;
    });

class _TasteProfileData extends AsyncNotifier<TasteProfile> {
  @override
  FutureOr<TasteProfile> build() {
    final titles = ref.watch(tasteRatingsProvider);
    final credits = ref.watch(recommendationCreditsProvider);
    final input = (titles, credits);
    var entries = 0;
    if (titles.length <= 80) {
      for (final title in titles) {
        entries += credits[peopleIdentity(title)]?.length ?? 0;
        if (entries > 1000) break;
      }
      if (entries <= 1000) return _buildTaste(input);
    }
    return ref
        .watch(_tasteWorkerProvider)
        .run(input)
        .then((profile) => profile ?? TasteProfile(const []));
  }
}

final _tasteProfileDataProvider =
    AsyncNotifierProvider.autoDispose<_TasteProfileData, TasteProfile>(
      _TasteProfileData.new,
    );

/// Keep the previous profile visible while a large replacement is computed.
final tasteProfileProvider = Provider.autoDispose<TasteProfile>(
  (ref) => ref.watch(_tasteProfileDataProvider).value ?? TasteProfile(const []),
);

bool _sameListWork(Work? a, Work? b) =>
    identical(a, b) ||
    a != null &&
        b != null &&
        a.copyWith(snapshotUpdatedAt: 0) == b.copyWith(snapshotUpdatedAt: 0);

class _RecommendationWatchlist extends Notifier<List<WatchlistTitle>> {
  @override
  List<WatchlistTitle> build() =>
      ref.watch(watchlistTitlesProvider).value ?? const [];

  @override
  bool updateShouldNotify(
    List<WatchlistTitle> previous,
    List<WatchlistTitle> next,
  ) {
    if (previous.length != next.length) return true;
    for (var i = 0; i < next.length; i++) {
      if (previous[i].entry != next[i].entry ||
          !_sameListWork(previous[i].work, next[i].work) ||
          !_sameListWork(previous[i].series, next[i].series)) {
        return true;
      }
    }
    return false;
  }
}

final recommendationWatchlistProvider =
    NotifierProvider.autoDispose<
      _RecommendationWatchlist,
      List<WatchlistTitle>
    >(_RecommendationWatchlist.new);

final recommendationPlanProvider = Provider.autoDispose<RecommendationPlan>((
  ref,
) {
  final profile = ref.watch(tasteProfileProvider);
  final running = ref.watch(peopleIndexProvider.select((s) => s.running));
  return RecommendationPlan(
    profile: profile,
    favorites: favoriteIds(ref.watch(favoritePeopleProvider).value ?? const []),
    watchlist: {
      for (final w in ref.watch(recommendationWatchlistProvider))
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
      var finished = false;
      ref.listen(foregroundProvider, (previous, next) {
        if (!next || previous != false) return;
        if (recommendationDay(ref.read(recommendationClockProvider)()) !=
            plan.today) {
          ref.invalidate(recommendationPlanProvider);
        } else if (!finished) {
          ref.invalidateSelf();
        }
      });
      final previous = cache.poolFor(plan.signature);
      if (!ref.read(foregroundProvider)) {
        return Stream.value(previous ?? const RecommendationPool());
      }
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
          active: () => active && ref.read(foregroundProvider),
          publish: (value) {
            if (active) {
              cache.rememberPool(plan.signature, value);
              controller.add(value);
            }
          },
          trending: () => safeTrend,
          cache: cache,
          initialCandidates: previous?.candidates ?? const [],
        ).then(
          (_) async {
            finished =
                active &&
                ref.read(foregroundProvider) &&
                (cache.poolFor(plan.signature)?.failed ?? 0) == 0;
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

/// Show the first useful batch promptly, then commit the completed pass once.
/// Retrieval progress must not reshuffle every visible shelf on every response.
class _DisplayCandidates extends Notifier<List<RecommendationCandidate>> {
  @override
  List<RecommendationCandidate> build() {
    ref.listen(recommendationPoolProvider, (_, next) {
      final pool = next.value;
      if (pool != null && (!pool.running || state.isEmpty)) {
        state = pool.candidates;
      }
    });
    return ref.read(recommendationPoolProvider).value?.candidates ?? const [];
  }
}

final recommendationDisplayCandidatesProvider =
    NotifierProvider.autoDispose<
      _DisplayCandidates,
      List<RecommendationCandidate>
    >(_DisplayCandidates.new);

final _rankingInputProvider = Provider.autoDispose<_RankingInput>((ref) {
  return _RankingInput(
    ref.watch(tasteProfileProvider),
    ref.watch(recommendationDisplayCandidatesProvider),
    ref.watch(recommendationWatchlistProvider),
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
  final RecommendationFeed feed;
  if (input.candidates.length + input.watchlist.length <= 100 &&
      input.profile.signals.length <= 80) {
    feed = _rank(input);
  } else {
    feed = ref.watch(_largeFeedProvider).value ?? const RecommendationFeed();
  }
  // A previous worker result may stay visible while reranking. User exclusions
  // apply immediately, before the new result arrives.
  final rated = {
    for (final title in ref.watch(tasteRatingsProvider))
      recommendationRoot(title.key),
  };
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
