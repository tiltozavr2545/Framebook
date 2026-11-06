import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/library/favorite_people.dart';
import '../../data/library/insights.dart';
import '../../data/library/insights_provider.dart';
import '../../data/library/library.dart';
import '../../data/library/people_index.dart';
import '../../data/sources/providers.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/favorite_person_portrait.dart';
import '../person/person_screen.dart';

final popularPeopleProvider = FutureProvider.autoDispose<List<PersonSummary>>(
  (ref) => ref.watch(tmdbProvider).popularPeople(),
);

class PeopleShelves extends ConsumerWidget {
  const PeopleShelves({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favorites = ref.watch(favoritePeopleProvider).value ?? [];
    final titles = ref.watch(ratedTitlesProvider).value ?? [];
    final index = ref.watch(peopleIndexProvider);
    final insights =
        ref.watch(libraryInsightsProvider(null)).value ?? emptyLibraryInsights;
    final popular = ref.watch(popularPeopleProvider);
    PersonSummary person(PersonInsight p) => PersonSummary(
      id: p.person.id,
      name: p.person.name,
      profilePath: p.person.profilePath,
      knownFor: [l10n.statsRatingCount(p.profile.count)],
    );
    return ListView(
      padding: EdgeInsets.only(
        bottom: 24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        _PeopleShelf(
          title: l10n.peopleFavorites,
          people: [
            for (final p in favorites)
              PersonSummary(
                id: p.personId,
                name: p.name,
                profilePath: p.profilePath,
              ),
          ],
        ),
        if (favorites.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(l10n.peopleFavoritesEmpty),
          ),
        if (insights.people.isNotEmpty)
          _PeopleShelf(
            title: l10n.peopleFrequent,
            people: insights.people.take(20).map(person).toList(),
          ),
        for (final role in FilmographyRole.values)
          if (insights.people.where((p) => p.roles.containsKey(role)).toList()
              case final group when group.isNotEmpty)
            _PeopleShelf(
              title: filmographyLabel(l10n, role),
              people:
                  (group..sort(
                        (a, b) => b.roles[role]!.count.compareTo(
                          a.roles[role]!.count,
                        ),
                      ))
                      .take(20)
                      .map(
                        (p) => PersonSummary(
                          id: p.person.id,
                          name: p.person.name,
                          profilePath: p.person.profilePath,
                          knownFor: [
                            l10n.statsRatingCount(p.roles[role]!.count),
                          ],
                        ),
                      )
                      .toList(),
            ),
        if (titles.isNotEmpty) PeopleLoadStatus(index: index),
        if (popular.value case final people? when people.isNotEmpty)
          _PeopleShelf(title: l10n.peoplePopular, people: people)
        else if (popular.isLoading)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (popular.hasError)
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextButton.icon(
              onPressed: () => ref.invalidate(popularPeopleProvider),
              icon: const Icon(Icons.refresh),
              label: Text(l10n.retry),
            ),
          ),
      ],
    );
  }
}

class PeopleLoadStatus extends ConsumerWidget {
  const PeopleLoadStatus({super.key, required this.index});
  final PeopleIndexState index;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    if (index.total == 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.peopleLoadProgress(index.entries.length, index.total)),
          if (index.entries.length < index.total) ...[
            const SizedBox(height: 6),
            Text(
              l10n.peopleLoadHint,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (index.running)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: LinearProgressIndicator(),
              )
            else
              TextButton.icon(
                onPressed: () => ref.read(peopleIndexProvider.notifier).load(),
                icon: const Icon(Icons.refresh),
                label: Text(l10n.peopleLoadContinue),
              ),
          ],
        ],
      ),
    );
  }
}

class _PeopleShelf extends StatelessWidget {
  _PeopleShelf({required this.title, required this.people})
    : super(key: ValueKey(title));
  final String title;
  final List<PersonSummary> people;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
      ),
      if (people.isNotEmpty)
        SizedBox(
          height: _peopleShelfHeight(context),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: people.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final person = people[index];
              return SizedBox(
                key: ValueKey(person.id),
                width: 96,
                child: Column(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FavoritePersonPortrait(
                          person: person,
                          onTap: () => context.push(
                            '${Routes.search}/person/${person.id}',
                          ),
                        ),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => context.push(
                            '${Routes.search}/person/${person.id}',
                          ),
                          child: Text(
                            person.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        if (person.knownFor.isNotEmpty)
                          Text(
                            person.knownFor.first,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
    ],
  );
}

double _peopleShelfHeight(BuildContext context) {
  final theme = Theme.of(context);
  double textHeight(TextStyle? style, int lines) {
    final painter = TextPainter(
      text: TextSpan(text: List.filled(lines, 'Ag').join('\n'), style: style),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: 96);
    final height = painter.height;
    painter.dispose();
    return height;
  }

  return 144 +
      6 +
      textHeight(theme.textTheme.titleSmall, 2) +
      textHeight(theme.textTheme.labelSmall, 1);
}
