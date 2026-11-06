import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library/work_snapshot.dart';
import '../../data/ratings_service.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import 'cast_section.dart';
import 'my_rating.dart';
import 'ratings_panel.dart';
import 'related_titles.dart';
import 'title_layout.dart';
import 'title_providers.dart';

class MovieScreen extends ConsumerWidget {
  const MovieScreen({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return TitlePage(
      value: ref.watch(movieProvider(id)),
      onRetry: () => ref.invalidate(movieProvider(id)),
      savedKey: WorkKey.movie(id),
      builder: (context, movie) => [
        TitleHeader(
          posterPath: movie.posterPath,
          coverKey: movie.key,
          originalLanguage: movie.originalLanguage,
          title: movie.title,
          originalTitle: movie.originalTitle,
          facts: [
            joinFacts([
              context.formatDate(movie.premiereDate ?? movie.releaseDate),
              if (movie.runtime case final runtime?)
                context.formatRuntime(runtime),
            ]),
            movie.genres.map((g) => g.name).join(', '),
            if (movie.countries.isNotEmpty) movie.countries.join(', '),
            if (movie.budget case final budget?)
              '${l10n.titleBudget}: ${context.formatUsd(budget)}',
            if (movie.revenue case final revenue?)
              '${l10n.titleRevenue}: ${context.formatUsd(revenue)}',
          ],
          tagline: movie.tagline,
        ),
        const SizedBox(height: 16),
        MyRatingSection(lineage: [WorkSnapshot.movie(movie)]),
        const SizedBox(height: 16),
        RatingsPanel(
          target: RatingTarget(
            key: movie.key,
            tmdbVote: movie.vote,
            imdbId: movie.imdbId,
          ),
        ),
        ...overviewSection(context, movie.overview),
        ...castSection(context, movie.credits, workKey: movie.key),
        RelatedTitles(current: movie.key, collection: movie.collection),
      ],
    );
  }
}
