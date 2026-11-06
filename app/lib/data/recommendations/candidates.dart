import 'dart:async';

import '../source_failure.dart';
import '../sources/tmdb/tmdb_client.dart';
import '../sources/tmdb/tmdb_models.dart';
import '../work_key.dart';
import 'profile.dart';
import 'ranking.dart';

String recommendationDay(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

final class RecommendationPlan {
  RecommendationPlan({
    required this.profile,
    required Set<int> favorites,
    required this.watchlist,
    required DateTime now,
    List<int> learnedPeople = const [],
  }) : today = recommendationDay(now) {
    seeds = profile.seeds;
    final all = favorites.toList()..sort();
    final offset = all.isEmpty
        ? 0
        : DateTime.utc(now.year, now.month, now.day).millisecondsSinceEpoch ~/
              Duration.millisecondsPerDay %
              all.length;
    // Bound large favourite lists without permanently ignoring later entries.
    people = [
      for (var i = 0; i < all.length && i < 8; i++)
        all[(offset + i) % all.length],
    ];
    people.addAll(learnedPeople.where((id) => !people.contains(id)).take(2));
    genres = {
      for (final kind in [WorkKind.movie, WorkKind.tv])
        kind: profile.topGenres(kind),
    };
  }
  final TasteProfile profile;
  final Set<WorkKey> watchlist;
  final String today;
  late final List<TasteSignal> seeds;
  late final List<int> people;
  late final Map<WorkKind, List<int>> genres;
  bool get enabled =>
      profile.signals.isNotEmpty || people.isNotEmpty || watchlist.isNotEmpty;
  late final String signature =
      '$today:${enabled ? 1 : 0}:'
      '${seeds.map((s) => s.key).join(',')}:${people.join(',')}:'
      '${genres.entries.map((e) => '${e.key.name}:${e.value.join(',')}').join(';')}:'
      '${(watchlist.toList()..sort((a, b) => a.toString().compareTo(b.toString()))).join(',')}';

  // The plan is a retrieval request, not the current scoring profile. A score
  // edit with unchanged source choices reranks locally without refetching.
  @override
  bool operator ==(Object other) =>
      other is RecommendationPlan && other.signature == signature;
  @override
  int get hashCode => signature.hashCode;
}

final class RecommendationPool {
  const RecommendationPool({
    this.candidates = const [],
    this.running = false,
    this.failed = 0,
  });
  final List<RecommendationCandidate> candidates;
  final bool running;
  final int failed;
}

/// Session reuse belongs to one catalog client/language. Completed jobs and
/// in-flight work are shared across favourite/seed changes, with a bounded LRU.
final class RecommendationSourceCache {
  final _jobs = <String, Future<List<RecommendationCandidate>>>{};

  Future<List<RecommendationCandidate>> get(
    String key,
    Future<List<RecommendationCandidate>> Function() load,
  ) {
    final existing = _jobs.remove(key);
    if (existing != null) {
      _jobs[key] = existing;
      return existing;
    }
    late final Future<List<RecommendationCandidate>> job;
    job = Future.sync(load).catchError((Object error, StackTrace stack) {
      if (identical(_jobs[key], job)) _jobs.remove(key);
      Error.throwWithStackTrace(error, stack);
    });
    _jobs[key] = job;
    if (_jobs.length > 64) _jobs.remove(_jobs.keys.first);
    return job;
  }
}

/// Catalog-only requests: no scores/notes are sent. A bounded worker pool
/// publishes partial successes; one failing source cannot empty other rows.
Future<void> loadRecommendationCandidates(
  TmdbApi api,
  RecommendationPlan plan, {
  required bool Function() active,
  required void Function(RecommendationPool) publish,
  Future<List<TitleSummary>> Function()? trending,
  Duration timeout = const Duration(seconds: 8),
  Duration budget = const Duration(seconds: 45),
  RecommendationSourceCache? cache,
}) async {
  if (!plan.enabled) {
    publish(const RecommendationPool());
    return;
  }
  final jobs = <Future<List<RecommendationCandidate>> Function()>[];
  void add(String key, Future<List<RecommendationCandidate>> Function() load) {
    jobs.add(() => cache?.get('${plan.today}:$key', load) ?? load());
  }

  for (final seed in plan.seeds) {
    add(
      'seed:${seed.key}',
      () async => [
        for (final title in await api.recommendations(seed.key))
          RecommendationCandidate(title, seeds: {seed.key}),
      ],
    );
  }
  final watchlistIdentity =
      (plan.watchlist.toList()
            ..sort((a, b) => a.toString().compareTo(b.toString())))
          .join(',');
  for (final id in plan.people) {
    add('person:$id:$watchlistIdentity', () async {
      final person = await api.person(id);
      final titles = <WorkKey, TitleSummary>{
        for (final credit in [...person.acting, ...person.crew])
          if (releasedForRecommendations(credit.title, plan.today))
            credit.title.key: credit.title,
      };
      final best = titles.values.toList()
        ..sort((a, b) {
          final quality = candidateQuality(b).compareTo(candidateQuality(a));
          return quality != 0
              ? quality
              : a.key.toString().compareTo(b.key.toString());
        });
      final selected = {
        ...best.take(60),
        for (final t in best)
          if (plan.watchlist.contains(t.key)) t,
      };
      return [
        for (final title in selected)
          RecommendationCandidate(title, people: {id: person.name}),
      ];
    });
  }
  for (final kind in [WorkKind.movie, WorkKind.tv]) {
    for (final genre in <int?>[...?plan.genres[kind], null]) {
      add(
        'discover:${kind.name}:$genre',
        () async => [
          for (final title in await api.discoverRecommendations(
            kind,
            genre: genre,
          ))
            RecommendationCandidate(title, discovered: true),
        ],
      );
    }
  }
  add(
    'trending',
    () async => [
      for (final title in await (trending?.call() ?? api.trending()))
        RecommendationCandidate(title, discovered: true),
    ],
  );
  final candidates = <RecommendationCandidate>[];
  var cursor = 0, failures = 0;
  var stop = false;
  final elapsed = Stopwatch()..start();
  var lastPublished = const Duration(milliseconds: -100);
  var publishedCount = -1;
  var snapshot = const <RecommendationCandidate>[];
  void update(bool running) {
    if (active()) {
      if (running &&
          (snapshot.isNotEmpty || candidates.isEmpty) &&
          elapsed.elapsed - lastPublished < const Duration(milliseconds: 100)) {
        return;
      }
      lastPublished = elapsed.elapsed;
      if (publishedCount != candidates.length) {
        snapshot = mergeCandidates(candidates);
        publishedCount = candidates.length;
      }
      publish(
        RecommendationPool(
          candidates: snapshot,
          running: running,
          failed: failures,
        ),
      );
    }
  }

  update(true);
  Future<void> worker() async {
    while (active() &&
        !stop &&
        cursor < jobs.length &&
        elapsed.elapsed < budget) {
      final job = jobs[cursor++];
      try {
        final result = await job().timeout(timeout);
        if (!active()) return;
        candidates.addAll(result);
      } on Object catch (error) {
        failures++;
        if (error is TimeoutException ||
            error is SourceException &&
                (error.failure == SourceFailure.unauthorized ||
                    error.failure == SourceFailure.limitReached)) {
          stop = true;
        }
        // Offline errors still allow later jobs to use their stale HTTP cache.
      }
      update(true);
    }
  }

  await Future.wait(List.generate(3, (_) => worker()));
  update(false);
}
