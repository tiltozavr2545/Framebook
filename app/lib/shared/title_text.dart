import '../data/db/database.dart';
import '../data/library/library.dart';
import '../data/work_key.dart';
import '../l10n/app_localizations.dart';

/// TMDB names seasons itself ("Season 1", "Specials"), but the name can be
/// empty.
String seasonName(AppLocalizations l10n, int number, String? name) =>
    name == null || name.isEmpty
    ? (number == 0 ? l10n.seasonSpecials : l10n.seasonNumber(number))
    : name;

/// Two lines for a list row: what it is, and its context.
typedef TitleLines = ({String title, String subtitle});

/// "The Matrix" / "Film · 1999"; "Game of Thrones" / "Season 1 · 2011";
/// "Game of Thrones" / "S1 · E3 · Lord Snow". A season or an episode is named
/// after its series, so the list reads the way a person thinks of it.
TitleLines describeWork(AppLocalizations l10n, Work work, {Work? series}) {
  final key = WorkKey.parse(work.workKey);
  String join(Iterable<String?> parts) =>
      parts.whereType<String>().where((p) => p.isNotEmpty).join(' · ');
  return switch (key.kind) {
    WorkKind.movie => (
      title: work.title,
      subtitle: join([l10n.kindMovie, work.year?.toString()]),
    ),
    WorkKind.tv => (
      title: work.title,
      subtitle: join([l10n.kindTv, work.year?.toString()]),
    ),
    WorkKind.season => (
      title: series?.title ?? work.title,
      subtitle: join([
        seasonName(l10n, key.season!, work.title),
        work.year?.toString(),
      ]),
    ),
    WorkKind.episode => (
      title: series?.title ?? work.title,
      subtitle: join([
        l10n.episodeCode(key.season!, key.episode!),
        work.title.isEmpty ? null : work.title,
      ]),
    ),
  };
}

TitleLines describeRated(AppLocalizations l10n, RatedTitle title) =>
    describeWork(l10n, title.work, series: title.series);
