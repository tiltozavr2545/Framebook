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
    agreement = rankAgreement(titles, source);
    finds = shared.where((t) => t.divergenceFrom(source)! >= 1).toList()
      ..sort(
        (a, b) =>
            b.divergenceFrom(source)!.compareTo(a.divergenceFrom(source)!),
      );
    disappointments =
        shared.where((t) => t.divergenceFrom(source)! <= -1).toList()..sort(
          (a, b) =>
              a.divergenceFrom(source)!.compareTo(b.divergenceFrom(source)!),
        );
  }
  late final int count;
  late final double? agreement;
  late final List<RatedTitle> finds, disappointments;
}

class StatsView {
  StatsView(this.titles, {this.kind}) {
    stats = computeStats(titles);
    final scores = titles.map((t) => t.rating.scoreHalf).toList()..sort();
    final middle = scores.length ~/ 2;
    median = scores.isEmpty
        ? 0
        : scores.length.isOdd
        ? scores[middle] / 2
        : (scores[middle - 1] + scores[middle]) / 4;
    high = titles.where((t) => t.rating.scoreHalf >= 16).toList();
    low = titles.where((t) => t.rating.scoreHalf <= 8).toList();
    medium = titles
        .where((t) => t.rating.scoreHalf > 8 && t.rating.scoreHalf < 16)
        .toList();
    sources = {
      for (final source in compareSources)
        source: SourceBreakdown(titles, source),
    };
  }
  final List<RatedTitle> titles;
  final WorkKind? kind;
  late final RatingStats stats;
  late final double median;
  late final List<RatedTitle> high, medium, low;
  late final Map<RatingSource, SourceBreakdown> sources;
}

StatsView prepareStats(List<RatedTitle> titles) => StatsView(titles);
typedef StatsInput = (List<RatedTitle>, WorkKind?);
StatsView prepareStatsKind(StatsInput input) => StatsView([
  for (final title in input.$1)
    if (input.$2 == null || title.work.kind == input.$2) title,
], kind: input.$2);

enum PeopleOrder { frequent, highest, reliable, polarizing }

typedef InsightViewInput = (
  List<RatedTitle>,
  LibraryInsights,
  FilmographyRole?,
  PeopleOrder,
);

class InsightView {
  InsightView(InsightViewInput input) {
    titles = [...input.$1]
      ..sort((a, b) {
        final score = b.rating.scoreHalf.compareTo(a.rating.scoreHalf);
        if (score != 0) return score;
        final date = b.rating.scoredAt.compareTo(a.rating.scoredAt);
        return date != 0 ? date : a.work.workKey.compareTo(b.work.workKey);
      });
    genres = input.$2.genres.entries.where((e) => e.value.eligible).toList()
      ..sort((a, b) {
        final share = b.value.highShare.compareTo(a.value.highShare);
        return share != 0 ? share : b.value.average.compareTo(a.value.average);
      });
    ranked = [];
    for (final person in input.$2.people) {
      final profile = input.$3 == null
          ? person.profile
          : person.roles[input.$3];
      if (profile == null ||
          input.$4 != PeopleOrder.frequent && !profile.eligible ||
          input.$4 == PeopleOrder.polarizing && !profile.polarizing) {
        continue;
      }
      ranked.add((person, profile));
    }
    ranked.sort((a, b) {
      final cmp = switch (input.$4) {
        PeopleOrder.frequent => b.$2.count.compareTo(a.$2.count),
        PeopleOrder.highest => b.$2.average.compareTo(a.$2.average),
        PeopleOrder.reliable => b.$2.highShare.compareTo(a.$2.highShare),
        PeopleOrder.polarizing => b.$2.spread.compareTo(a.$2.spread),
      };
      if (cmp != 0) return cmp;
      final count = b.$2.count.compareTo(a.$2.count);
      return count != 0 ? count : a.$1.person.id.compareTo(b.$1.person.id);
    });
    genreBreadth = categoryBreadth(input.$2.genres.values);
    decadeBreadth = categoryBreadth(input.$2.decades.values);
  }
  late final List<RatedTitle> titles;
  late final List<MapEntry<int, ScoreProfile>> genres;
  late final List<(PersonInsight, ScoreProfile)> ranked;
  late final double genreBreadth, decadeBreadth;
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
