import 'package:flutter/material.dart';

import '../../shared/retained_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/poster.dart';
import 'my_rating.dart';
import 'title_layout.dart';
import 'title_providers.dart';
import 'title_routes.dart';

class RelatedTitles extends ConsumerWidget {
  const RelatedTitles({super.key, required this.current, this.collection});

  final WorkKey current;
  final MovieCollection? collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final collection = this.collection;
    return RetainedSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (collection != null)
            _Titles(
              label: collection.name ?? l10n.titleCollection,
              current: current,
              value: ref.watch(collectionTitlesProvider(collection.id)),
              retry: () =>
                  ref.invalidate(collectionTitlesProvider(collection.id)),
            ),
          _Titles(
            label: l10n.titleSimilar,
            current: current,
            value: ref.watch(similarTitlesProvider(current)),
            retry: () => ref.invalidate(similarTitlesProvider(current)),
          ),
        ],
      ),
    );
  }
}

class _Titles extends StatelessWidget {
  const _Titles({
    required this.label,
    required this.current,
    required this.value,
    required this.retry,
  });

  final String label;
  final WorkKey current;
  final AsyncValue<List<TitleSummary>> value;
  final VoidCallback retry;

  @override
  Widget build(BuildContext context) {
    final seen = <WorkKey>{current};
    final titles = [
      for (final title in value.value ?? <TitleSummary>[])
        if (seen.add(title.key)) title,
    ];
    if (!value.isLoading && !value.hasError && titles.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(label),
        if (titles.isEmpty)
          if (value.hasError)
            TextButton.icon(
              onPressed: retry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context).retry),
            )
          else
            const LinearProgressIndicator()
        else
          SizedBox(
            height: 168 + 76 * MediaQuery.textScalerOf(context).scale(1),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: titles.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final title = titles[index];
                return SizedBox(
                  width: 112,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(6),
                    onTap: () => context.push(
                      '${TitleRoutes.branchOf(context)}/${TitleRoutes.path(title.key)}',
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Stack(
                          children: [
                            Poster(
                              title.posterPath,
                              size: ImageSize.w185,
                              width: 112,
                            ),
                            Positioned(
                              left: 6,
                              bottom: 6,
                              child: MyScoreBadge(title.key, onPoster: true),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        if (title.year case final year?)
                          Text(
                            '$year',
                            style: Theme.of(context).textTheme.labelMedium,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
