import 'dart:math';

import '../library/library.dart';
import '../sources/tmdb/tmdb_models.dart';
import '../work_key.dart';
import 'profile.dart';

/// Evidence is kept independently of the title snapshot so duplicate candidates
/// combine reasons instead of taking extra places in the recommendations.
final class RecommendationCandidate {
  RecommendationCandidate(
    this.title, {
    Set<WorkKey>? seeds,
    Map<int, String>? people,
    this.discovered = false,
  }) : seeds = seeds ?? {},
       people = people ?? {};
  final TitleSummary title;
  final Set<WorkKey> seeds;
  final Map<int, String> people;
  final bool discovered;
}

List<RecommendationCandidate> mergeCandidates(
  Iterable<RecommendationCandidate> input,
) {
  final rows = <WorkKey, RecommendationCandidate>{};
  for (final item in input) {
    final old = rows[item.title.key];
    rows[item.title.key] = RecommendationCandidate(
      old == null || (item.title.vote.count ?? 0) > (old.title.vote.count ?? 0)
          ? item.title
          : old.title,
      seeds: {...?old?.seeds, ...item.seeds},
      people: {...?old?.people, ...item.people},
      discovered: (old?.discovered ?? false) || item.discovered,
    );
  }
  return rows.values.toList()
    ..sort((a, b) => a.title.key.toString().compareTo(b.title.key.toString()));
}

enum RecommendationReason {
  similar,
  person,
  author,
  genre,
  discovery,
  watchlist,
}

final class RecommendationPick {
  const RecommendationPick(
    this.title,
    this.reason, {
    this.detail,
    this.exploratory = false,
  });
  final TitleSummary title;
  final RecommendationReason reason;
  final String? detail;
  final bool exploratory;
}

final class RecommendationFeed {
  const RecommendationFeed({
    this.forYou = const [],
    this.people = const [],
    this.explore = const [],
    this.watchlist = const [],
  });
  final List<RecommendationPick> forYou;
  final List<RecommendationPick> people;
  final List<RecommendationPick> explore;
  final List<RecommendationPick> watchlist;
  bool get isEmpty =>
      forYou.isEmpty && people.isEmpty && explore.isEmpty && watchlist.isEmpty;
}

/// This is a ranking prior, not a predicted personal score or probability.
/// Low vote counts shrink to neutral rather than beating reliable titles.
double candidateQuality(TitleSummary title) {
  final count = max(0, title.vote.count ?? 0);
  return ((title.vote.average ?? 5.5) * count + 5.5 * 100) / (count + 100) / 10;
}

bool releasedForRecommendations(TitleSummary title, String today) =>
    title.releaseDate == null || title.releaseDate!.compareTo(today) <= 0;

RecommendationFeed rankRecommendations({
  required TasteProfile profile,
  required List<RecommendationCandidate> candidates,
  required List<WatchlistTitle> watchlist,
  required Set<int> favorites,
  required Set<WorkKey> hidden,
  required String today,
  int limit = 20,
}) {
  final merged = mergeCandidates(candidates);
  final byKey = {for (final c in merged) c.title.key: c};
  final rated = profile.signals.map((s) => s.key).toSet();
  final watchedRoots = watchlist.map((w) => recommendationRoot(w.key)).toSet();
  final signals = {for (final s in profile.signals) s.key: s};
  final used = <WorkKey>{};
  bool blocked(WorkKey key) =>
      hidden.contains(key) || hidden.contains(recommendationRoot(key));

  double neighbor(RecommendationCandidate c) {
    var sum = 0.0;
    for (final key in c.seeds) {
      final signal = signals[key];
      if (signal != null) sum += profile.preference(signal);
    }
    return (sum / 2).clamp(-1.0, 1.0);
  }

  double people(RecommendationCandidate c) {
    var best = 0.0;
    for (final id in c.people.keys) {
      best = max(
        best,
        favorites.contains(id) ? 1.0 : profile.personAffinity(id),
      );
    }
    return best;
  }

  double fit(RecommendationCandidate c) =>
      .45 * neighbor(c) +
      .25 * profile.fit(c.title) +
      .2 * people(c) +
      .05 *
          profile.decadeAffinity(
            recommendationRoot(c.title.key).kind,
            c.title.year,
          ) +
      .05 * candidateQuality(c.title);
  final liked = profile.seeds.where((s) => s.score >= 7).toList();
  double novelty(RecommendationCandidate c) {
    var familiarity = 0.0;
    for (final signal in liked) {
      if (signal.key.kind == recommendationRoot(c.title.key).kind) {
        familiarity = max(
          familiarity,
          genreSimilarity(signal.genres, c.title.genreIds.toSet()),
        );
      }
    }
    return 1 - familiarity;
  }

  double exploratoryScore(RecommendationCandidate c) =>
      .45 * novelty(c) +
      .25 * candidateQuality(c.title) +
      .2 * profile.fit(c.title) +
      .1 * people(c);

  RecommendationPick pick(
    RecommendationCandidate c, {
    bool exploring = false,
    bool fromList = false,
  }) {
    if (fromList) {
      return RecommendationPick(c.title, RecommendationReason.watchlist);
    }
    final names =
        c.people.entries.where((e) => favorites.contains(e.key)).toList()
          ..sort((a, b) => a.key.compareTo(b.key));
    if (names.isNotEmpty) {
      return RecommendationPick(
        c.title,
        RecommendationReason.person,
        detail: names.first.value,
        exploratory: exploring,
      );
    }
    final authors =
        c.people.entries
            .where((e) => profile.personAffinity(e.key) > 0)
            .toList()
          ..sort(
            (a, b) => profile
                .personAffinity(b.key)
                .compareTo(profile.personAffinity(a.key)),
          );
    if (authors.isNotEmpty) {
      return RecommendationPick(
        c.title,
        RecommendationReason.author,
        detail: authors.first.value,
        exploratory: exploring,
      );
    }
    final related =
        c.seeds.where((key) => (signals[key]?.score ?? 0) >= 7).toList()..sort(
          (a, b) => (signals[b]!.score != signals[a]!.score)
              ? signals[b]!.score.compareTo(signals[a]!.score)
              : a.toString().compareTo(b.toString()),
        );
    if (related.isNotEmpty) {
      return RecommendationPick(
        c.title,
        RecommendationReason.similar,
        detail: signals[related.first]!.title,
        exploratory: exploring,
      );
    }
    return RecommendationPick(
      c.title,
      exploring
          ? RecommendationReason.discovery
          : profile.fit(c.title) > 0
          ? RecommendationReason.genre
          : RecommendationReason.discovery,
      exploratory: exploring,
    );
  }

  // Greedy re-ranking penalizes near-identical genres and repeated people.
  // Penalties diversify a row without pretending that genre = franchise.
  RecommendationCandidate? next(
    List<RecommendationCandidate> pool,
    List<RecommendationPick> chosen, {
    bool explore = false,
  }) {
    RecommendationCandidate? best;
    var bestScore = double.negativeInfinity;
    for (final c in pool) {
      if (used.contains(c.title.key)) continue;
      var repeat = 0.0;
      for (final p in chosen.reversed.take(6)) {
        repeat = max(
          repeat,
          genreSimilarity(c.title.genreIds.toSet(), p.title.genreIds.toSet()),
        );
      }
      final recentPeople = chosen
          .map((p) => byKey[p.title.key])
          .whereType<RecommendationCandidate>()
          .expand((c) => c.people.keys)
          .toSet();
      final duplicatePerson = c.people.keys.any(recentPeople.contains);
      final score =
          (explore ? exploratoryScore(c) : fit(c)) -
          .12 * repeat -
          (duplicatePerson ? .12 : 0);
      if (score > bestScore ||
          score == bestScore &&
              c.title.key.toString().compareTo(best!.title.key.toString()) <
                  0) {
        bestScore = score;
        best = c;
      }
    }
    return best;
  }

  final available = [
    for (final c in merged)
      if (!blocked(c.title.key) &&
          !rated.contains(recommendationRoot(c.title.key)) &&
          !watchedRoots.contains(recommendationRoot(c.title.key)) &&
          releasedForRecommendations(c.title, today))
        c,
  ];
  final personal = <RecommendationPick>[];
  if (profile.signals.isNotEmpty || favorites.isNotEmpty) {
    // Equal slots alternate familiar/exploratory; an odd count differs by one.
    for (var i = 0; i < limit; i++) {
      final exploring = i.isOdd;
      final c = next(available, personal, explore: exploring);
      if (c == null) break;
      used.add(c.title.key);
      personal.add(pick(c, exploring: exploring));
    }
  }
  List<RecommendationPick> row(
    List<RecommendationCandidate> pool, {
    bool explore = false,
  }) {
    final chosen = <RecommendationPick>[];
    for (var i = 0; i < limit; i++) {
      final c = next(pool, chosen, explore: explore);
      if (c == null) break;
      used.add(c.title.key);
      chosen.add(pick(c, exploring: explore));
    }
    return chosen;
  }

  // Dedicated rows can reuse a title from For you, but never duplicate titles
  // within themselves. They answer different questions, unlike mixed slots.
  used.clear();
  final favoriteRow = row(
    available.where((c) => c.people.keys.any(favorites.contains)).toList(),
  );
  used.clear();
  final exploreRow = row(available, explore: true);
  used.clear();
  final listPool = <RecommendationCandidate>[];
  for (final item in watchlist) {
    if (blocked(item.key)) continue;
    final title = watchlistSummary(item);
    if (!releasedForRecommendations(title, today)) continue;
    final evidence = byKey[item.key] ?? byKey[recommendationRoot(item.key)];
    listPool.add(
      RecommendationCandidate(
        title,
        seeds: evidence?.seeds,
        people: evidence?.people,
      ),
    );
  }
  final list = <RecommendationPick>[];
  for (var i = 0; i < limit; i++) {
    final c = next(listPool, list);
    if (c == null) break;
    used.add(c.title.key);
    list.add(pick(c, fromList: true));
  }
  return RecommendationFeed(
    forYou: personal,
    people: favoriteRow,
    explore: exploreRow,
    watchlist: list,
  );
}
