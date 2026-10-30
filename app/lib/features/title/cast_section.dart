import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/sources/tmdb/tmdb_models.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/poster.dart';
import 'title_layout.dart';
import 'title_routes.dart';

/// A card's cast strip and its key crew; nothing when TMDB has neither.
List<Widget> castSection(BuildContext context, Credits credits) {
  if (credits.isEmpty) return const [];
  final l10n = AppLocalizations.of(context);
  return [
    if (credits.cast.isNotEmpty) ...[
      SectionTitle(l10n.castTitle),
      _CastStrip(cast: credits.cast),
    ],
    if (credits.crew.isNotEmpty) ...[
      const SizedBox(height: 16),
      for (final MapEntry(key: role, value: people)
          in credits.crewByRole.entries)
        _CrewLine(role: role, people: people),
    ],
  ];
}

/// Opens a person's page inside the tab the card belongs to.
void openPerson(BuildContext context, int personId) =>
    context.push('${TitleRoutes.branchOf(context)}/person/$personId');

class _CastStrip extends StatelessWidget {
  const _CastStrip({required this.cast});

  final List<CastMember> cast;

  /// The billing that matters; guest stars beyond it are on the person's
  /// page anyway.
  static const _shown = 20;
  static const _width = 84.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = cast.take(_shown).toList();
    final nameStyle = theme.textTheme.titleSmall?.copyWith(height: 1.2);
    final roleStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    double twoLineHeight(TextStyle? style) {
      final painter = TextPainter(
        text: TextSpan(text: 'M\nM', style: style),
        maxLines: 2,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: _width);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    return SizedBox(
      height:
          _width * 3 / 2 +
          6 +
          twoLineHeight(nameStyle) +
          twoLineHeight(roleStyle),
      // The strip runs to the screen edges, past the card's padding.
      child: OverflowBox(
        maxWidth: MediaQuery.sizeOf(context).width,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: shown.length,
          separatorBuilder: (_, _) => const SizedBox(width: 10),
          itemBuilder: (context, index) {
            final person = shown[index];
            return SizedBox(
              width: _width,
              child: InkWell(
                borderRadius: BorderRadius.circular(6),
                onTap: () => openPerson(context, person.personId),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Poster(
                      person.profilePath,
                      size: ImageSize.w185,
                      width: _width,
                      icon: Icons.person_outline,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      person.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: nameStyle,
                    ),
                    if (person.character case final role? when role.isNotEmpty)
                      Text(
                        role,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: roleStyle,
                      ),
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

/// "Directed by  Lana Wachowski, Lilly Wachowski" — every name opens its
/// person.
class _CrewLine extends StatelessWidget {
  const _CrewLine({required this.role, required this.people});

  final CrewRole role;
  final List<CrewMember> people;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                crewRoleLabel(l10n, role, people.length),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          Expanded(
            child: Wrap(
              children: [
                for (final person in people)
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () => openPerson(context, person.personId),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 6,
                      ),
                      child: Text(
                        person.name,
                        style: theme.textTheme.titleSmall,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String crewRoleLabel(AppLocalizations l10n, CrewRole role, int count) =>
    switch (role) {
      CrewRole.creator => l10n.crewCreator(count),
      CrewRole.director => l10n.crewDirector(count),
      CrewRole.writer => l10n.crewWriter,
      CrewRole.composer => l10n.crewComposer,
      CrewRole.cinematographer => l10n.crewCinematographer,
    };
