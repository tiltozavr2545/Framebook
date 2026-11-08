import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/library/insights.dart';
import '../../data/library/prepared_views.dart';
import '../../data/latest_worker.dart';
import '../../data/view_computer.dart';
import '../../data/library/library.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/poster.dart';
import '../title/title_routes.dart';
import 'stats_works.dart';

/// Only familiar roles and two plain ordering choices. Rows stay lazy even
/// after expanding a large library, and large preparations use the worker.
class StatsPeopleSection extends ConsumerStatefulWidget {
  const StatsPeopleSection({
    super.key,
    required this.titles,
    required this.insights,
  });
  final List<RatedTitle> titles;
  final LibraryInsights insights;
  @override
  ConsumerState<StatsPeopleSection> createState() => _StatsPeopleSectionState();
}

class _StatsPeopleSectionState extends ConsumerState<StatsPeopleSection> {
  FilmographyRole _role = FilmographyRole.acting;
  PeopleOrder _order = PeopleOrder.frequent;
  bool _showAll = false;
  InsightViewInput? _input;
  InsightView? _view;
  int _revision = 0;
  String? _error;
  late final _worker = LatestWorker<InsightViewInput, InsightView>(
    (input) => ref
        .read(viewComputerProvider)
        .run(prepareInsights, input, 'statistics people view'),
  );

  void _prepare() {
    final input = (widget.titles, widget.insights, _role, _order);
    if (_input == input) return;
    _input = input;
    _error = null;
    final revision = ++_revision;
    if (widget.titles.length <= 200 && widget.insights.people.length <= 200) {
      _view = prepareInsights(input);
      return;
    }
    unawaited(
      _worker
          .run(input)
          .then(
            (view) {
              if (mounted && revision == _revision && view != null) {
                setState(() => _view = view);
              }
            },
            onError: (Object error, StackTrace stack) {
              if (mounted && revision == _revision) {
                setState(
                  () =>
                      _error = AppLocalizations.of(context).localDataLoadFailed,
                );
              }
            },
          ),
    );
  }

  @override
  void dispose() {
    _worker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _prepare();
    final l10n = AppLocalizations.of(context);
    final view = _view;
    final pending = view == null || view.role != _role || view.order != _order;
    return SliverList.list(
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final (role, label) in [
              (FilmographyRole.acting, l10n.statsActors),
              (FilmographyRole.directing, l10n.statsDirectors),
            ])
              ChoiceChip(
                label: Text(label),
                selected: (view?.role ?? _role) == role,
                onSelected: (_) => setState(() {
                  _role = role;
                  _showAll = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final order in PeopleOrder.values)
              ChoiceChip(
                label: Text(
                  order == PeopleOrder.frequent
                      ? l10n.statsPeopleFrequent
                      : l10n.statsPeopleHighest,
                ),
                selected: (view?.order ?? _order) == order,
                onSelected: (_) => setState(() {
                  _order = order;
                  _showAll = false;
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_order == PeopleOrder.highest)
          Text(
            l10n.statsPeopleMinimum,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        if (_error != null) ...[
          Text(_error!),
          TextButton(
            onPressed: () => setState(() => _input = null),
            child: Text(l10n.retry),
          ),
        ] else if (pending)
          const LinearProgressIndicator(),
        if (view != null && view.ranked.isEmpty && !pending)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              widget.insights.covered == 0
                  ? l10n.peopleNoCredits
                  : l10n.statsNoQualifying,
            ),
          ),
        if (view != null) ...[
          for (final (person, profile)
              in _showAll ? view.ranked : view.ranked.take(8))
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Poster(
                person.person.profilePath,
                width: 40,
                size: ImageSize.w185,
                icon: Icons.person_outline,
              ),
              title: Text(person.person.name),
              subtitle: Text(
                l10n.statsPersonSummary(
                  profile.count,
                  formatScore(profile.average),
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.person_outline),
                tooltip: l10n.statsOpenPerson(person.person.name),
                onPressed: () => context.push(
                  '${TitleRoutes.branchOf(context)}/person/${person.person.id}',
                ),
              ),
              onTap: () => showRatedWorks(
                context,
                person.person.name,
                [...profile.titles]..sort(comparePersonalScores),
              ),
            ),
          if (!_showAll && view.ranked.length > 8)
            TextButton(
              onPressed: () => setState(() => _showAll = true),
              child: Text('${l10n.statsShowAll} · ${view.ranked.length}'),
            ),
        ],
      ],
    );
  }
}
