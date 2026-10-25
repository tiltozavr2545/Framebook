import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../app/router.dart';
import '../data/api_source.dart';
import '../data/background_refresh.dart';
import '../data/library/library.dart';
import '../data/library/stats.dart';
import '../data/ratings_service.dart';
import '../data/work_key.dart';
import '../l10n/app_localizations.dart';
import 'format.dart';

/// "Kinopoisk ratings loaded for N of M", with a spinner while background
/// refresh is at work; without a key for [source], a link to Sources.
class CoverageLine extends ConsumerWidget {
  const CoverageLine({super.key, required this.source, required this.titles});

  final RatingSource source;
  final List<RatedTitle> titles;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final service = ref.watch(ratingsServiceProvider);
    final running = ref.watch(backgroundRefreshProvider);
    final name = ratingSourceLabel(l10n, source);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final (:loaded, :total) = coverage(
      titles,
      source,
      (kind) => service.providerOf(source, kind) != null,
    );

    if (total == 0) {
      // Nothing it could cover: either there is no key (a film is covered by
      // any key that gives this source), or nothing of a kind it rates.
      final keyless = service.providerOf(source, WorkKind.movie) == null;
      if (!keyless || titles.isEmpty) return const SizedBox.shrink();
      return InkWell(
        onTap: () => context.push(Routes.sources),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            l10n.coverageNeedsKey(name),
            style: style?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Flexible(
            child: Text(l10n.coverageLoaded(name, loaded, total), style: style),
          ),
          if (running && loaded < total) ...[
            const SizedBox(width: 8),
            const SizedBox.square(
              dimension: 12,
              child: CircularProgressIndicator(strokeWidth: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
