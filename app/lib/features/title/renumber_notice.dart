import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library/library.dart';
import '../../data/library/renumbering.dart';
import '../../data/library/work_snapshot.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/title_text.dart';

/// The question after TMDB renumbered a rated season or episode: "Your
/// rating of S1 · E5 was for an episode that is now S1 · E3. Move it?"
/// (docs/client-architecture.md, "Title card").
///
/// Built from what the screen already loaded ([current]) and the stored
/// ratings; it asks nothing of the network. One question at a time: once it
/// is answered, the next one, if any, takes its place. Nothing to ask —
/// nothing shown.
class RenumberNotice extends ConsumerWidget {
  const RenumberNotice({
    super.key,
    required this.series,
    required this.kind,
    required this.current,
    required this.lineageOf,
    this.about,
  });

  /// On a season card (all its episodes) or an episode card ([about]):
  /// rated episodes of the series whose titles are now in this season.
  factory RenumberNotice.episodes(
    TvDetails tv,
    SeasonDetails season, {
    WorkKey? about,
  }) => RenumberNotice(
    series: tv.key,
    kind: WorkKind.episode,
    current: {for (final e in season.episodes) e.key: e.tmdbId},
    lineageOf: (key) => [
      WorkSnapshot.tv(tv),
      WorkSnapshot.season(season),
      WorkSnapshot.episode(season.episodes.firstWhere((e) => e.key == key)),
    ],
    about: about,
  );

  /// On a series card: rated seasons whose titles TMDB now numbers
  /// differently.
  factory RenumberNotice.seasons(TvDetails tv) => RenumberNotice(
    series: tv.key,
    kind: WorkKind.season,
    current: {for (final s in tv.seasons) s.key: s.tmdbId},
    lineageOf: (key) => [
      WorkSnapshot.tv(tv),
      WorkSnapshot.seasonSummary(tv.seasons.firstWhere((s) => s.key == key)),
    ],
  );

  final WorkKey series;

  /// [WorkKind.season] on a series card, [WorkKind.episode] on a season or
  /// an episode card.
  final WorkKind kind;

  /// What TMDB has now under each number the screen loaded: key → own id.
  final Map<WorkKey, int?> current;

  /// The lineage of a key in [current], series first: what a moved rating is
  /// saved with.
  final List<WorkSnapshot> Function(WorkKey key) lineageOf;

  /// On a title's own card, only questions about that title.
  final WorkKey? about;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rated = ref.watch(ratedPartsProvider((series, kind))).value;
    if (rated == null) return const SizedBox.shrink();
    final question = proposeRenumbering(
      rated: rated,
      current: current,
    ).where((r) => about == null || r.touches(about!)).firstOrNull;
    if (question == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    final library = ref.read(libraryProvider);
    final scores = {for (final part in rated) part.key: part.scoreHalf};
    String name(WorkKey key) => switch (key.kind) {
      WorkKind.season => seasonName(l10n, key.season!, null),
      _ => l10n.episodeCode(key.season!, key.episode!),
    };
    final episodes = kind == WorkKind.episode;

    final String text;
    final List<(String, VoidCallback)> actions;
    if (question.conflicts.firstOrNull case final target?) {
      // A live rating already sits on the target: which score stays there.
      final move = question.moveTo(target);
      final moved = formatMyScore(scores[move.from]!);
      final existing = formatMyScore(scores[target]!);
      text =
          (episodes
          ? l10n.renumberConflictEpisode
          : l10n.renumberConflictSeason)(
            moved,
            name(move.from),
            name(target),
            existing,
          );
      void resolve({required bool keepMoved}) => library.moveRatings([
        (from: move.from, to: lineageOf(target)),
      ], keepExisting: keepMoved ? const {} : {target});
      actions = [
        (l10n.renumberKeepScore(moved), () => resolve(keepMoved: true)),
        (l10n.renumberKeepScore(existing), () => resolve(keepMoved: false)),
      ];
    } else {
      final moves = question.moves;
      if (moves.length == 1) {
        final (from, to) = (name(moves.single.from), name(moves.single.to));
        text = episodes
            ? l10n.renumberEpisode(from, to)
            : l10n.renumberSeason(from, to);
      } else {
        final list = moves
            .map((m) => '${name(m.from)} → ${name(m.to)}')
            .join(', ');
        text = episodes
            ? l10n.renumberManyEpisodes(list)
            : l10n.renumberManySeasons(list);
      }
      actions = [
        (
          l10n.renumberKeep,
          () => library.keepRatings({
            for (final move in moves) move.from: current[move.from],
          }),
        ),
        (
          l10n.renumberMove,
          () => library.moveRatings([
            for (final move in moves) (from: move.from, to: lineageOf(move.to)),
          ]),
        ),
      ];
    }
    return _Notice(text: text, actions: actions);
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text, required this.actions});

  final String text;
  final List<(String, VoidCallback)> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.swap_vert,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
              ],
            ),
          ),
          Wrap(
            alignment: WrapAlignment.end,
            children: [
              for (final (label, onPressed) in actions)
                TextButton(onPressed: onPressed, child: Text(label)),
            ],
          ),
        ],
      ),
    );
  }
}
