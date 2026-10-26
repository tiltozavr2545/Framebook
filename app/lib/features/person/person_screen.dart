import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/sources/providers.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/poster.dart';
import '../title/my_rating.dart';
import '../title/title_layout.dart';
import '../title/title_routes.dart';

final personProvider = FutureProvider.autoDispose.family<Person, int>(
  (ref, id) => ref.watch(tmdbProvider).person(id),
);

/// A person: who they are and what they made. A title opens its card in the
/// same tab, and back returns here.
class PersonScreen extends ConsumerStatefulWidget {
  const PersonScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends ConsumerState<PersonScreen> {
  /// Acting or behind the camera; `null` until chosen — acting first, unless
  /// the person only worked behind the camera.
  bool? _acting;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TitlePage(
      value: ref.watch(personProvider(widget.id)),
      onRetry: () => ref.invalidate(personProvider(widget.id)),
      builder: (context, person) {
        final acting = _acting ?? person.acting.isNotEmpty;
        final credits = acting ? person.acting : person.crew;
        return [
          _Header(person: person),
          if (person.biography case final bio? when bio.trim().isNotEmpty)
            _Biography(text: bio.trim()),
          SectionTitle(l10n.personFilmography),
          if (person.acting.isNotEmpty && person.crew.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: Text(l10n.personActing(person.acting.length)),
                    selected: acting,
                    onSelected: (_) => setState(() => _acting = true),
                  ),
                  ChoiceChip(
                    label: Text(l10n.personCrew(person.crew.length)),
                    selected: !acting,
                    onSelected: (_) => setState(() => _acting = false),
                  ),
                ],
              ),
            ),
          // One list item per title: a filmography runs to hundreds, and
          // the list builds only what is on screen.
          for (final credit in credits) _CreditRow(credit: credit),
        ];
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.person});

  final Person person;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final born = context.formatDate(person.birthday);
    final died = context.formatDate(person.deathday);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Poster(
          person.profilePath,
          size: ImageSize.w342,
          width: 120,
          icon: Icons.person_outline,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(person.name, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              if (born != null)
                Text(
                  person.placeOfBirth == null
                      ? l10n.personBorn(born)
                      : l10n.personBornIn(born, person.placeOfBirth!),
                  style: muted,
                ),
              if (died != null) Text(l10n.personDied(died), style: muted),
            ],
          ),
        ),
      ],
    );
  }
}

/// The biography, folded to a few lines: TMDB's can run to pages.
class _Biography extends StatefulWidget {
  const _Biography({required this.text});

  final String text;

  @override
  State<_Biography> createState() => _BiographyState();
}

class _BiographyState extends State<_Biography> {
  var _open = false;

  static const _folded = 6;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final painter = TextPainter(
            text: TextSpan(text: widget.text, style: style),
            maxLines: _folded,
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
          )..layout(maxWidth: constraints.maxWidth);
          final long = painter.didExceedMaxLines;
          painter.dispose();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.text,
                style: style,
                maxLines: _open ? null : _folded,
                overflow: _open ? null : TextOverflow.fade,
              ),
              if (long && !_open)
                InkWell(
                  onTap: () => setState(() => _open = true),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.personMore,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _CreditRow extends StatelessWidget {
  const _CreditRow({required this.credit});

  final PersonCredit credit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = credit.title;
    return InkWell(
      onTap: () => context.push(
        '${TitleRoutes.branchOf(context)}/${TitleRoutes.path(title.key)}',
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Poster(
              title.posterPath,
              size: ImageSize.w185,
              width: 44,
              icon: title.key.kind == WorkKind.movie
                  ? Icons.movie_outlined
                  : Icons.live_tv_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  Text.rich(
                    TextSpan(
                      children: [
                        if (title.year case final year?)
                          TextSpan(
                            text: '$year  ',
                            style: TextStyle(color: Reel.of(context).edge),
                          ),
                        TextSpan(text: credit.roles.join(', ')),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            MyScoreBadge(title.key),
          ],
        ),
      ),
    );
  }
}
