import 'dart:math';

import '../db/database.dart';
import '../library/library.dart';
import '../library/people_index.dart';
import '../library/work_snapshot.dart';
import '../sources/tmdb/tmdb_models.dart';
import '../work_key.dart';

WorkKey recommendationRoot(WorkKey key) =>
    key.kind == WorkKind.movie ? key : WorkKey.tv(key.tmdbId);

final class TasteSignal {
  const TasteSignal({
    required this.key,
    required this.title,
    required this.score,
    required this.genres,
    required this.year,
    this.people = const [],
  });
  final WorkKey key;
  final String title;
  final double score;
  final Set<int> genres;
  final int? year;
  final List<PeopleCredit> people;
}

/// One contribution per film/series. A series score takes precedence; otherwise
/// each season contributes its score or its episodes' mean, once per season.
List<TasteSignal> tasteSignals(
  List<RatedTitle> rated,
  Map<String, List<PeopleCredit>> credits,
) {
  final groups = <WorkKey, List<RatedTitle>>{};
  for (final title in rated) {
    if (title.rating.deletedAt == null) {
      groups.putIfAbsent(recommendationRoot(title.key), () => []).add(title);
    }
  }
  final signals = <TasteSignal>[];
  for (final entry in groups.entries) {
    final rows = entry.value;
    final whole = rows.where((t) => t.key == entry.key).firstOrNull;
    double mean(Iterable<RatedTitle> list) {
      final items = list.toList();
      return items.fold(0, (sum, t) => sum + t.rating.scoreHalf) /
          items.length /
          2;
    }

    final seasons = <int, List<RatedTitle>>{};
    for (final row in rows) {
      if (row.key.season case final season?) {
        seasons.putIfAbsent(season, () => []).add(row);
      }
    }
    final scores = [
      for (final group in seasons.values)
        if (group.where((r) => r.key.kind == WorkKind.season).firstOrNull
            case final season?)
          season.rating.scoreHalf / 2
        else
          mean(group),
    ];
    final score = whole != null
        ? whole.rating.scoreHalf / 2
        : scores.reduce((a, b) => a + b) / scores.length;
    final snapshot = whole?.work ?? rows.first.series ?? rows.first.work;
    final people = <(int, FilmographyRole), PeopleCredit>{};
    final parentCredits = credits['${entry.key}@${snapshot.tmdbId}'];
    for (final person
        in parentCredits ??
            [for (final row in rows) ...?credits[peopleIdentity(row)]]) {
      people[(person.id, person.role)] = person;
    }
    signals.add(
      TasteSignal(
        key: entry.key,
        title: snapshot.title,
        score: score,
        genres: rows.first.genreIds.toSet(),
        year: snapshot.year,
        people: people.values.toList(),
      ),
    );
  }
  signals.sort((a, b) => a.key.toString().compareTo(b.key.toString()));
  return signals;
}

/// Shrink sparse evidence towards neutral. Absolute scores and the user's
/// own baseline both matter, including a uniformly generous/strict library.
final class TasteProfile {
  TasteProfile(this.signals) {
    average = signals.isEmpty
        ? 5.5
        : signals.fold<double>(0, (s, t) => s + t.score) / signals.length;
    for (final signal in signals) {
      final weight = preference(signal);
      for (final genre in signal.genres) {
        final key = (signal.key.kind, genre);
        _genres[key] =
            (_genres[key] ?? 0) + weight / sqrt(max(1, signal.genres.length));
        _genreCounts[key] = (_genreCounts[key] ?? 0) + 1;
      }
      final seenPeople = <int>{};
      for (final person in signal.people) {
        if (!seenPeople.add(person.id)) continue;
        _people[person.id] = (_people[person.id] ?? 0) + weight;
        _peopleCounts[person.id] = (_peopleCounts[person.id] ?? 0) + 1;
      }
      if (signal.year case final year?) {
        final key = (signal.key.kind, year - year % 10);
        _decades[key] = (_decades[key] ?? 0) + weight;
        _decadeCounts[key] = (_decadeCounts[key] ?? 0) + 1;
      }
    }
    _peoplePool = List.unmodifiable(_computePeople());
    _topPeople = List.unmodifiable(_peoplePool.take(2));
    _genrePools = {
      for (final kind in WorkKind.values)
        kind: List.unmodifiable(_computeGenres(kind)),
    };
    _topGenres = {
      for (final entry in _genrePools.entries)
        entry.key: List.unmodifiable(entry.value.take(2)),
    };
    _seedPools = {
      for (final kind in [WorkKind.movie, WorkKind.tv])
        for (final positive in [true, false])
          (kind, positive): _computeSeedPool(kind, positive),
    };
    _seeds = List.unmodifiable(seedsForRotation(0));
  }
  late final List<int> _peoplePool;
  late final Map<WorkKind, List<int>> _genrePools;
  late final Map<(WorkKind, bool), List<TasteSignal>> _seedPools;
  late final List<int> _topPeople;
  late final List<TasteSignal> _seeds;
  late final Map<WorkKind, List<int>> _topGenres;
  final List<TasteSignal> signals;
  late final double average;
  final _genres = <(WorkKind, int), double>{};
  final _genreCounts = <(WorkKind, int), int>{};
  final _people = <int, double>{};
  final _peopleCounts = <int, int>{};
  final _decades = <(WorkKind, int), double>{};
  final _decadeCounts = <(WorkKind, int), int>{};

  double preference(TasteSignal signal) =>
      (.65 * (signal.score - 5.5) / 4.5 + .35 * (signal.score - average) / 4.5)
          .clamp(-1.0, 1.0);
  double genreAffinity(WorkKind kind, int id) =>
      (_genres[(kind, id)] ?? 0) / ((_genreCounts[(kind, id)] ?? 0) + 3);
  double personAffinity(int id) =>
      (_people[id] ?? 0) / ((_peopleCounts[id] ?? 0) + 3);
  List<int> get topPeople => _topPeople;

  List<int> _computePeople() {
    final ids =
        _people.keys
            .where(
              (id) => (_peopleCounts[id] ?? 0) >= 3 && personAffinity(id) > 0,
            )
            .toList()
          ..sort((a, b) {
            final score = personAffinity(b).compareTo(personAffinity(a));
            return score != 0 ? score : a.compareTo(b);
          });
    return ids;
  }

  List<int> peopleForRotation(int rotation) => [
    for (var i = 0; i < min(2, _peoplePool.length); i++)
      _peoplePool[(rotation + i) % _peoplePool.length],
  ];

  double decadeAffinity(WorkKind kind, int? year) => year == null
      ? 0
      : (_decades[(kind, year - year % 10)] ?? 0) /
            ((_decadeCounts[(kind, year - year % 10)] ?? 0) + 3);
  double fit(TitleSummary title) {
    final kind = recommendationRoot(title.key).kind;
    final genres = title.genreIds.toSet();
    return genres.isEmpty
        ? 0
        : genres.fold<double>(0, (s, id) => s + genreAffinity(kind, id)) /
              genres.length;
  }

  List<int> topGenres(WorkKind kind) => _topGenres[kind]!;

  List<int> _computeGenres(WorkKind kind) {
    final ids =
        _genreCounts.keys
            .where((k) => k.$1 == kind && genreAffinity(kind, k.$2) > 0)
            .map((k) => k.$2)
            .toList()
          ..sort((a, b) {
            final score = genreAffinity(
              kind,
              b,
            ).compareTo(genreAffinity(kind, a));
            return score != 0 ? score : a.compareTo(b);
          });
    return ids;
  }

  /// Keep the strongest genre, rotating the second through positive evidence.
  List<int> genresForRotation(WorkKind kind, int rotation) {
    final pool = _genrePools[kind]!;
    return [
      if (pool.isNotEmpty) pool.first,
      if (pool.length > 1) pool[1 + rotation % (pool.length - 1)],
    ];
  }

  /// At most two varied positive seeds and one negative seed of each kind.
  /// Dates never weight preference: imported libraries often share one date.
  List<TasteSignal> get seeds => _seeds;

  List<TasteSignal> _computeSeedPool(WorkKind kind, bool positive) {
    return signals
        .where(
          (s) => s.key.kind == kind && (positive ? s.score >= 7 : s.score <= 4),
        )
        .toList()
      ..sort((a, b) {
        final score = positive
            ? b.score.compareTo(a.score)
            : a.score.compareTo(b.score);
        return score != 0
            ? score
            : a.key.toString().compareTo(b.key.toString());
      });
  }

  /// Sorted pools are prepared with the profile, including in its worker.
  /// Daily selection scans at most twelve neighbours per kind on the UI isolate.
  List<TasteSignal> seedsForRotation(int rotation) {
    final out = <TasteSignal>[];
    for (final kind in [WorkKind.movie, WorkKind.tv]) {
      final positive = _seedPools[(kind, true)]!;
      if (positive.isNotEmpty) {
        final offset = rotation % positive.length;
        final first = positive[offset];
        out.add(first);
        TasteSignal? second;
        double value(TasteSignal s) =>
            s.score / 10 - .3 * genreSimilarity(first.genres, s.genres);
        for (var i = 1; i < min(positive.length, 13); i++) {
          final candidate = positive[(offset + i) % positive.length];
          if (second == null || value(candidate) > value(second)) {
            second = candidate;
          }
        }
        if (second != null) out.add(second);
      }
      final negative = _seedPools[(kind, false)]!;
      if (negative.isNotEmpty) out.add(negative[rotation % negative.length]);
    }
    return out;
  }
}

double genreSimilarity(Set<int> a, Set<int> b) {
  if (a.isEmpty || b.isEmpty) return 0;
  var common = 0;
  final smaller = a.length <= b.length ? a : b;
  final larger = identical(smaller, a) ? b : a;
  for (final id in smaller) {
    if (larger.contains(id)) common++;
  }
  return common / (a.length + b.length - common);
}

TitleSummary watchlistSummary(WatchlistTitle item) {
  final work = item.work;
  final parent = item.series;
  final name = parent == null
      ? work.title
      : '${parent.title} · ${work.title.isEmpty ? 'S${item.key.season}' : work.title}';
  return TitleSummary(
    key: item.key,
    title: name,
    originalTitle: work.originalTitle,
    releaseDate: work.releaseDate,
    posterPath: work.posterPath ?? parent?.posterPath,
    vote: const TmdbVote(null, null),
    genreIds: WorkSnapshot.fromWork(parent ?? work).genreIds,
  );
}

Set<int> favoriteIds(List<FavoritePerson> people) => {
  for (final p in people)
    if (p.deletedAt == null) p.personId,
};
