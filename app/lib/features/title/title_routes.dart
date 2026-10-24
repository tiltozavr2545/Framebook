import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/source_failure.dart';
import '../../data/work_key.dart';
import '../../shared/failure_view.dart';
import 'episode_screen.dart';
import 'movie_screen.dart';
import 'season_screen.dart';
import 'tv_screen.dart';

/// Cards nest inside the branch of the tab they were opened from:
/// `…/movie/603`, `…/tv/1399`, `…/tv/1399/s/1`, `…/tv/1399/s/1/e/3`. The bottom
/// navigation stays in place, and back leads to the season, the series, the
/// search, in that order. Stage 3 hangs the same routes under "My ratings".
abstract final class TitleRoutes {
  /// Path to a film or series relative to the branch.
  static String segment(WorkKey key) => switch (key.kind) {
    WorkKind.movie => 'movie/${key.tmdbId}',
    WorkKind.tv => 'tv/${key.tmdbId}',
    WorkKind.season || WorkKind.episode => throw ArgumentError.value(
      key,
      'key',
      'seasons and episodes open from their series',
    ),
  };

  static String seasonSegment(int season) => 's/$season';
  static String episodeSegment(int episode) => 'e/$episode';

  static List<RouteBase> routes() => [
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
