import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/failure_view.dart';
import '../../shared/poster.dart';
import 'cast_section.dart';
import 'title_providers.dart';

/// Reuses the card's cached provider; only visible rows build their portraits.
class CastScreen extends ConsumerWidget {
  const CastScreen({super.key, required this.workKey});
  final WorkKey workKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = workKey;
    final credits = switch (key.kind) {
      WorkKind.movie =>
        ref.watch(movieProvider(key.tmdbId)).whenData((v) => v.credits),
      WorkKind.tv =>
        ref.watch(tvProvider(key.tmdbId)).whenData((v) => v.credits),
      WorkKind.season =>
        ref.watch(seasonProvider(key)).whenData((v) => v.credits),
      WorkKind.episode => ref.watch(episodeCreditsProvider(key)),
    };
    void retry() {
      switch (key.kind) {
        case WorkKind.movie:
          ref.invalidate(movieProvider(key.tmdbId));
        case WorkKind.tv:
          ref.invalidate(tvProvider(key.tmdbId));
        case WorkKind.season:
          ref.invalidate(seasonProvider(key));
        case WorkKind.episode:
          ref.invalidate(episodeCreditsProvider(key));
      }
    }

    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context).castTitle)),
      body: credits.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => FailureView(error: error, onRetry: retry),
        data: (credits) => ListView.separated(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            24 + MediaQuery.paddingOf(context).bottom,
          ),
          itemCount: credits.cast.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final person = credits.cast[index];
            return InkWell(
              onTap: () => openPerson(context, person.personId),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    Poster(
                      person.profilePath,
                      size: ImageSize.w185,
                      width: 48,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(person.name, style: theme.textTheme.titleMedium),
                          if (person.character case final role?
                              when role.isNotEmpty)
                            Text(
                              role,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 20),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
