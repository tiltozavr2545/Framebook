import 'dart:math';

import '../api_source.dart';
import '../sources/tmdb/tmdb_models.dart';
import 'library_models.dart';
import 'people_index.dart';

/// Every aggregate carries its contributing titles for honest counts and
/// drill-down. A multi-role person contributes only once to a title.
final class ScoreProfile {
  ScoreProfile(Iterable<RatedTitle> input)
    : titles = {for (final t in input) t.work.workKey: t}.values.toList() {
    average = count == 0
        ? 0
        : titles.fold(0, (sum, t) => sum + t.rating.scoreHalf) / count / 2;
    high = titles.where((t) => t.rating.scoreHalf >= 16).length;
    low = titles.where((t) => t.rating.scoreHalf <= 8).length;
    spread = count == 0
        ? 0
        : sqrt(
            titles.fold<double>(
                  0,
                  (sum, t) => sum + pow(t.rating.scoreHalf / 2 - average, 2),
                ) /
                count,
          );
  }
  final List<RatedTitle> titles;
  int get count => titles.length;
  late final double average;
  late final int high;
  late final int low;
  double get highShare => count == 0 ? 0 : high / count;
  late final double spread;
  bool get eligible => count >= 3;
  bool get polarizing => eligible && high > 0 && low > 0;
}

final class PersonInsight {
  PersonInsight(
    this.person,
    Iterable<RatedTitle> titles,
    Map<FilmographyRole, List<RatedTitle>> roles,
  ) : profile = ScoreProfile(titles),
      roles = {for (final e in roles.entries) e.key: ScoreProfile(e.value)};
  final PeopleCredit person;
  final ScoreProfile profile;
  final Map<FilmographyRole, ScoreProfile> roles;
}

final class DuoInsight {
  DuoInsight(this.director, this.actor, Iterable<RatedTitle> titles)
    : profile = ScoreProfile(titles);
  final PeopleCredit director;
  final PeopleCredit actor;
  final ScoreProfile profile;
}

final class LibraryInsights {
  LibraryInsights({
    required this.genres,
    required this.decades,
    required this.people,
    required this.duos,
    required this.covered,
  });
  final Map<int, ScoreProfile> genres;
  final Map<int, ScoreProfile> decades;
  final List<PersonInsight> people;
  final List<DuoInsight> duos;
  final int covered;
}

LibraryInsights analyzeLibrary(
  List<RatedTitle> titles,
  Map<String, List<PeopleCredit>> credits,
) {
  final genres = <int, List<RatedTitle>>{};
  final decades = <int, List<RatedTitle>>{};
  final people = <int, PeopleCredit>{};
  final works = <int, List<RatedTitle>>{};
  final roles = <int, Map<FilmographyRole, List<RatedTitle>>>{};
  final pairs = <(int, int), List<RatedTitle>>{};
  var covered = 0;
  for (final t in titles) {
    for (final genre in t.genreIds.toSet()) {
      genres.putIfAbsent(genre, () => []).add(t);
    }
    if (t.work.year case final year?) {
      decades.putIfAbsent(year - year % 10, () => []).add(t);
    }
    final cast = credits[peopleIdentity(t)];
    if (cast == null) continue;
    covered++;
    final ids = <int>{};
    final jobs = <(int, FilmographyRole)>{};
    final actors = <int>{};
    final directors = <int>{};
    for (final p in cast) {
      final old = people[p.id];
      if (old == null || old.profilePath == null && p.profilePath != null) {
        people[p.id] = p;
      }
      if (ids.add(p.id)) works.putIfAbsent(p.id, () => []).add(t);
      if (jobs.add((p.id, p.role))) {
        roles.putIfAbsent(p.id, () => {}).putIfAbsent(p.role, () => []).add(t);
      }
      if (p.role == FilmographyRole.acting) actors.add(p.id);
      if (p.role == FilmographyRole.directing) directors.add(p.id);
    }
    // Every credited actor is considered; pair rankings require three distinct
    // works, so one crowded ensemble cannot manufacture a favourite duo.
    for (final director in directors) {
      for (final actor in actors) {
        if (director != actor) {
          pairs.putIfAbsent((director, actor), () => []).add(t);
        }
      }
    }
  }
  final rankedPeople = [
    for (final e in works.entries)
      PersonInsight(people[e.key]!, e.value, roles[e.key]!),
  ];
  rankedPeople.sort((a, b) {
    final count = b.profile.count.compareTo(a.profile.count);
    return count != 0 ? count : a.person.id.compareTo(b.person.id);
  });
  final duos = [
    for (final e in pairs.entries)
      if (e.value.map((t) => t.work.workKey).toSet().length >= 3)
        DuoInsight(people[e.key.$1]!, people[e.key.$2]!, e.value),
  ];
  duos.sort((a, b) {
    final average = b.profile.average.compareTo(a.profile.average);
    if (average != 0) return average;
    final count = b.profile.count.compareTo(a.profile.count);
    if (count != 0) return count;
    final director = a.director.id.compareTo(b.director.id);
    return director != 0 ? director : a.actor.id.compareTo(b.actor.id);
  });
  return LibraryInsights(
    genres: {for (final e in genres.entries) e.key: ScoreProfile(e.value)},
    decades: {for (final e in decades.entries) e.key: ScoreProfile(e.value)},
    people: rankedPeople,
    duos: duos,
    covered: covered,
  );
}

/// Spearman's rank correlation, with average ranks for ties. Undefined for
/// fewer than three shared works or a constant set of scores on either side.
double? rankAgreement(List<RatedTitle> titles, RatingSource source) {
  final pairs = <(double, double)>[];
  for (final t in titles) {
    if (t.divergenceFrom(source) != null) {
      pairs.add((t.rating.scoreHalf / 2, t.external[source]!.value!));
    }
  }
  if (pairs.length < 3) return null;
  List<double> ranks(List<double> values) {
    final order = List.generate(values.length, (i) => i)
      ..sort((a, b) => values[a].compareTo(values[b]));
    final out = List.filled(values.length, 0.0);
    var start = 0;
    while (start < order.length) {
      var end = start + 1;
      while (end < order.length && values[order[end]] == values[order[start]]) {
        end++;
      }
      for (var i = start; i < end; i++) {
        out[order[i]] = (start + end - 1) / 2;
      }
      start = end;
    }
    return out;
  }

  final a = ranks([for (final p in pairs) p.$1]);
  final b = ranks([for (final p in pairs) p.$2]);
  final mean = (pairs.length - 1) / 2;
  var covariance = 0.0, aa = 0.0, bb = 0.0;
  for (var i = 0; i < a.length; i++) {
    final x = a[i] - mean, y = b[i] - mean;
    covariance += x * y;
    aa += x * x;
    bb += y * y;
  }
  return aa == 0 || bb == 0
      ? null
      : (covariance / sqrt(aa * bb)).clamp(-1.0, 1.0);
}

/// Effective number of equally common categories (exp Shannon entropy).
/// Genre membership counts can exceed the title count; normalization uses the
/// memberships themselves, so a film tagged twice is not two viewings.
double categoryBreadth(Iterable<ScoreProfile> groups) {
  final counts = groups.map((g) => g.count).where((n) => n > 0).toList();
  final total = counts.fold(0, (a, b) => a + b);
  if (total == 0) return 0;
  return exp(
    -counts.fold<double>(0, (sum, n) {
      final p = n / total;
      return sum + p * log(p);
    }),
  );
}
