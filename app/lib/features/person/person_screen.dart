import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/library/prepared_views.dart';
import '../../data/latest_worker.dart';
import '../../data/view_computer.dart';
import '../../data/sources/providers.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/accent_panel.dart';
import '../../shared/format.dart';
import '../../shared/poster.dart';
import '../../shared/favorite_person_button.dart';
import '../title/my_rating.dart';
import '../title/cover_viewer.dart';
import '../title/title_layout.dart';
import '../title/title_routes.dart';

final personProvider = FutureProvider.autoDispose.family<Person, int>(
  (ref, id) => ref.watch(tmdbProvider).person(id),
);

final _personWorker = Provider.autoDispose
    .family<LatestWorker<Person, PersonView>, int>((ref, id) {
      final computer = ref.watch(viewComputerProvider);
      final worker = LatestWorker<Person, PersonView>(
        (person) => computer.run(preparePerson, person, 'filmography'),
      );
      ref.onDispose(worker.dispose);
      return worker;
    });
final preparedPersonProvider = FutureProvider.autoDispose
    .family<PersonView, int>((ref, id) async {
      final worker = ref.watch(_personWorker(id));
      final person = await ref.watch(personProvider(id).future);
      if (person.acting.length + person.crew.length <= 200) {
        return preparePerson(person);
      }
      final result = await worker.run(person);
      if (result == null) {
        throw StateError('Superseded filmography preparation');
      }
      return result;
    });

/// A person: who they are and what they made. A title opens its card in the
/// same tab, and back returns here.
class PersonScreen extends ConsumerStatefulWidget {
  const PersonScreen({super.key, required this.id});

  final int id;

  @override
  ConsumerState<PersonScreen> createState() => _PersonScreenState();
}

class _PersonScreenState extends ConsumerState<PersonScreen> {
  FilmographyRole? _role;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return TitlePage(
      value: ref.watch(preparedPersonProvider(widget.id)),
      onRetry: () => ref.invalidate(personProvider(widget.id)),
      builder: (context, prepared) {
        final person = prepared.person;
        final groups = prepared.groups;
        final allCredits = prepared.all;
        final role = groups.containsKey(_role)
            ? _role
            : groups.keys.firstOrNull;
        final credits = _role == null
            ? allCredits
            : groups[role] ?? const <PersonCredit>[];
        return [
          _Header(person: person),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: FavoritePersonButton(
                prominent: true,
                person: PersonSummary(
                  id: person.id,
                  name: person.name,
                  profilePath: person.profilePath,
                ),
              ),
            ),
          ),
          if (person.biography case final bio? when bio.trim().isNotEmpty)
            _Biography(text: bio.trim()),
          SectionTitle(l10n.personFilmography),
          if (groups.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: Text(
                      '${l10n.filmographyAll} · ${allCredits.length}',
                    ),
                    selected: _role == null,
                    onSelected: (_) => setState(() => _role = null),
                  ),
                  for (final entry in groups.entries)
                    ChoiceChip(
                      label: Text(
                        '${filmographyLabel(l10n, entry.key)} · ${entry.value.length}',
                      ),
                      selected: _role == entry.key,
                      onSelected: (_) => setState(() => _role = entry.key),
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
    return DecoratedBox(
      decoration: accentPanelDecoration(context),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              button: person.profilePath != null,
              label: person.profilePath != null ? l10n.photoOpen : null,
              child: InkWell(
                key: const ValueKey('person-photo'),
                onTap: person.profilePath == null
                    ? null
                    : () => Navigator.of(context, rootNavigator: true).push(
                        coverViewerRoute(
                          (_) => CoverViewer(
                            currentPath: person.profilePath!,
                            personId: person.id,
                            previewSize: ImageSize.w185,
                          ),
                        ),
                      ),
                child: Poster(
                  person.profilePath,
                  size: ImageSize.w185,
                  width: 120,
                  icon: Icons.person_outline,
                ),
              ),
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
        ),
      ),
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

class _BiographyState extends State<_Biography>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  var _open = false;

  static const _folded = 6;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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

String filmographyLabel(AppLocalizations l10n, FilmographyRole role) =>
    switch (role) {
      FilmographyRole.acting => l10n.filmographyActing,
      FilmographyRole.directing => l10n.filmographyDirecting,
      FilmographyRole.production => l10n.filmographyProduction,
      FilmographyRole.writing => l10n.filmographyWriting,
      FilmographyRole.music => l10n.filmographyMusic,
      FilmographyRole.camera => l10n.filmographyCamera,
      FilmographyRole.other => l10n.filmographyOther,
    };
