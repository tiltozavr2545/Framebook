import '../api_source.dart';
import '../work_key.dart';
import '../sources/tmdb/tmdb_models.dart';
import 'divergence.dart';
import 'insights.dart';
import 'library.dart';
import 'stats.dart';

class SourceBreakdown {
  SourceBreakdown(List<RatedTitle> titles, RatingSource source) {
    final shared = titles
        .where((t) => t.divergenceFrom(source) != null)
        .toList();
    count = shared.length;
    higher = shared.where((t) => t.divergenceFrom(source)! >= 1).toList()
      ..sort(
        (a, b) =>
            b.divergenceFrom(source)!.compareTo(a.divergenceFrom(source)!),
      );
    lower = shared.where((t) => t.divergenceFrom(source)! <= -1).toList()
      ..sort(
        (a, b) =>
            a.divergenceFrom(source)!.compareTo(b.divergenceFrom(source)!),
      );
  }
  late final int count;
  late final List<RatedTitle> higher, lower;
}

class StatsView {
  StatsView(this.titles, {this.kind}) {
    stats = computeStats(titles);
    topRated = titles.where((t) => t.rating.scoreHalf >= 16).toList()
      ..sort(comparePersonalScores);
    favoriteGenres = stats.genres.where((g) => g.count >= 3).toList()
      ..sort((a, b) {
        final average = b.average.compareTo(a.average);
        if (average != 0) return average;
        final count = b.count.compareTo(a.count);
        return count != 0 ? count : a.key.compareTo(b.key);
      });
    sources = {
      for (final source in compareSources)
        source: SourceBreakdown(titles, source),
    };
  }
  final List<RatedTitle> titles;
  final WorkKind? kind;
  late final RatingStats stats;
  late final List<RatedTitle> topRated;
  late final List<GroupAverage> favoriteGenres;
  late final Map<RatingSource, SourceBreakdown> sources;
}

StatsView prepareStats(List<RatedTitle> titles) => StatsView(titles);
typedef StatsInput = (List<RatedTitle>, WorkKind?);
StatsView prepareStatsKind(StatsInput input) => StatsView([
  for (final title in input.$1)
    if (input.$2 == null || title.work.kind == input.$2) title,
], kind: input.$2);

int comparePersonalScores(RatedTitle a, RatedTitle b) {
  final score = b.rating.scoreHalf.compareTo(a.rating.scoreHalf);
  if (score != 0) return score;
  final date = b.rating.scoredAt.compareTo(a.rating.scoredAt);
  return date != 0 ? date : a.work.workKey.compareTo(b.work.workKey);
}

enum PeopleOrder { frequent, highest }

typedef InsightViewInput = (
  List<RatedTitle>,
  LibraryInsights,
  FilmographyRole?,
  PeopleOrder,
);

class InsightView {
  InsightView(InsightViewInput input) {
    role = input.$3;
    order = input.$4;
    ranked = [];
    for (final person in input.$2.people) {
      final profile = input.$3 == null
          ? person.profile
          : person.roles[input.$3];
      if (profile == null ||
          input.$4 != PeopleOrder.frequent && !profile.eligible) {
        continue;
      }
      ranked.add((person, profile));
    }
    ranked.sort((a, b) {
      final cmp = switch (input.$4) {
        PeopleOrder.frequent => b.$2.count.compareTo(a.$2.count),
        PeopleOrder.highest => b.$2.average.compareTo(a.$2.average),
      };
      if (cmp != 0) return cmp;
      final count = b.$2.count.compareTo(a.$2.count);
      return count != 0 ? count : a.$1.person.id.compareTo(b.$1.person.id);
    });
  }
  late final FilmographyRole? role;
  late final PeopleOrder order;
  late final List<(PersonInsight, ScoreProfile)> ranked;
}

InsightView prepareInsights(InsightViewInput input) => InsightView(input);

class PersonView {
  PersonView(this.person) {
    groups = person.filmography;
    final combined = <String, PersonCredit>{};
    for (final credit in [...person.acting, ...person.crew]) {
      final key = credit.title.key.toString();
      final old = combined[key];
      combined[key] = PersonCredit(
        title: credit.title,
        roles: {...?old?.roles, ...credit.roles}.toList(),
      );
    }
    all = combined.values.toList()
      ..sort((a, b) {
        final date = (b.title.releaseDate ?? '9999').compareTo(
          a.title.releaseDate ?? '9999',
        );
        return date != 0
            ? date
            : a.title.key.toString().compareTo(b.title.key.toString());
      });
  }
  final Person person;
  late final Map<FilmographyRole, List<PersonCredit>> groups;
  late final List<PersonCredit> all;
}

PersonView preparePerson(Person person) => PersonView(person);
