import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/source_failure.dart';
import '../../data/work_key.dart';
import '../../shared/failure_view.dart';
import '../person/person_screen.dart';
import 'episode_screen.dart';
import 'movie_screen.dart';
import 'season_screen.dart';
import 'tv_screen.dart';

/// Cards nest inside the branch of the tab they were opened from:
/// `…/movie/603`, `…/tv/1399`, `…/tv/1399/s/1`, `…/tv/1399/s/1/e/3`. The bottom
/// navigation stays in place, and back leads to the season, the series, the
/// list, in that order. The same routes hang under Search, My ratings and
/// Watchlist.
abstract final class TitleRoutes {
  /// Path to a title of any kind relative to the branch. Opening an episode
  /// from a list builds the whole stack: series → season → episode.
  static String path(WorkKey key) => switch (key.kind) {
    WorkKind.movie => 'movie/${key.tmdbId}',
    WorkKind.tv => 'tv/${key.tmdbId}',
    WorkKind.season => 'tv/${key.tmdbId}/${seasonSegment(key.season!)}',
    WorkKind.episode =>
      'tv/${key.tmdbId}/${seasonSegment(key.season!)}/'
          '${episodeSegment(key.episode!)}',
  };

  /// The tab a screen lives in — `/search`, `/ratings`… — for opening a
  /// person or a title from it without leaving the tab.
  static String branchOf(BuildContext context) =>
      '/${GoRouterState.of(context).uri.pathSegments.first}';

  static String seasonSegment(int season) => 's/$season';
  static String episodeSegment(int episode) => 'e/$episode';

  static List<RouteBase> routes() => [
    // A person and a title link to each other without end, so a person is
    // not nested under a card: it sits at the tab's level and is pushed,
    // and back walks the pushes.
    GoRoute(
      path: 'person/:id',
      builder: (context, state) =>
          switch (int.tryParse(state.pathParameters['id'] ?? '')) {
            final id? when id > 0 => PersonScreen(id: id),
            _ => const _BadLink(),
          },
    ),
    GoRoute(
      path: 'movie/:id',
      builder: (context, state) => switch (_key(state, 'movie')) {
        final key? => MovieScreen(id: key.tmdbId),
        null => const _BadLink(),
      },
    ),
    GoRoute(
      path: 'tv/:id',
      builder: (context, state) => switch (_key(state, 'tv')) {
        final key? => TvScreen(id: key.tmdbId, location: state.uri.path),
        null => const _BadLink(),
      },
      routes: [
        GoRoute(
          path: 's/:season',
          builder: (context, state) => switch (_key(state, 'tv')) {
            final key? => SeasonScreen(
              seasonKey: key,
              location: state.uri.path,
            ),
            null => const _BadLink(),
          },
          routes: [
            GoRoute(
              path: 'e/:episode',
              builder: (context, state) => switch (_key(state, 'tv')) {
                final key? => EpisodeScreen(episodeKey: key),
                null => const _BadLink(),
              },
            ),
          ],
        ),
      ],
    ),
  ];

  /// The key from the path parameters, via [WorkKey.tryParse] so the rules
  /// (no leading zeros, season ≥ 0, episode ≥ 1) are the same as everywhere.
  static WorkKey? _key(GoRouterState state, String type) {
    final p = state.pathParameters;
    final season = p['season'];
    final episode = p['episode'];
    return WorkKey.tryParse(
      [
        'tmdb:$type:${p['id']}',
        if (season != null) ':s$season',
        if (episode != null) ':e$episode',
      ].join(),
    );
  }
}

/// An address no key can be built from.
class _BadLink extends StatelessWidget {
  const _BadLink();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: const FailureView(error: SourceException(SourceFailure.notFound)),
  );
}
