import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/library/library.dart';
import '../../data/library/work_snapshot.dart';
import '../../data/ratings_service.dart';
import '../../data/source_failure.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/failure_view.dart';
import '../../shared/title_text.dart';
import 'my_rating.dart';
import 'ratings_panel.dart';
import 'title_layout.dart';

/// What a card shows when TMDB can't be reached and the HTTP cache has
/// nothing: the snapshot saved with your rating or watchlist entry — poster,
/// title, year, your score and note, the last known ratings. Without a
/// snapshot (a title you never rated or listed), the usual error.
class SavedCard extends ConsumerWidget {
  const SavedCard({
    super.key,
    required this.workKey,
    required this.error,
    required this.onRetry,
  });

  final WorkKey workKey;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedLineageProvider(workKey));
    return switch (saved) {
      AsyncData(value: final lineage?) => _Saved(
        lineage: lineage,
        error: error,
        onRetry: onRetry,
      ),
      AsyncData() ||
      AsyncError() => FailureView(error: error, onRetry: onRetry),
      _ => const Center(child: CircularProgressIndicator()),
    };
  }
}

class _Saved extends StatelessWidget {
  const _Saved({
    required this.lineage,
    required this.error,
    required this.onRetry,
  });

  /// Series first, the title last.
  final List<Work> lineage;
  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final work = lineage.last;
    final key = WorkKey.parse(work.workKey);
    final series = lineage.length > 1 ? lineage.first : null;
    final season = lineage.length > 2 ? lineage[1] : null;
    final lines = describeWork(l10n, work, series: series);
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        Row(
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                failureOf(error) == SourceFailure.offline
                    ? l10n.savedCardOffline
                    : l10n.savedCardFailed,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            TextButton(onPressed: onRetry, child: Text(l10n.retry)),
          ],
        ),
        const SizedBox(height: 12),
        TitleHeader(
          posterPath:
              work.posterPath ?? season?.posterPath ?? series?.posterPath,
          title: lines.title,
          coverKey: key,
          cachedCoverOnly: true,
          originalTitle: work.originalTitle,
          facts: [lines.subtitle],
        ),
        const SizedBox(height: 16),
        MyRatingSection(
          lineage: [for (final w in lineage) WorkSnapshot.fromWork(w)],
          // Rewriting a snapshot with itself would only bump its version.
          refreshSnapshots: false,
        ),
        const SizedBox(height: 16),
        RatingsPanel(
          target: RatingTarget(
            key: key,
            imdbId: key.kind == WorkKind.season ? null : work.imdbId,
            seriesImdbId: series?.imdbId,
          ),
        ),
      ],
    );
  }
}
