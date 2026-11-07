import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_source.dart';
import '../../data/library/insights.dart';
import '../../data/library/prepared_views.dart';
import '../../data/latest_worker.dart';
import '../../data/view_computer.dart';
import '../../data/library/library.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/poster.dart';
import '../person/person_screen.dart';
import '../title/title_routes.dart';
import 'stats_works.dart';

String profileLabel(AppLocalizations l10n, ScoreProfile profile) =>
    l10n.statsProfile(
      profile.count,
      formatScore(profile.average),
      (profile.highShare * 100).round(),
      formatScore(profile.spread),
    );

class InsightHeading extends StatelessWidget {
  const InsightHeading(this.title, {super.key});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 8),
    child: Text(title, style: Theme.of(context).textTheme.headlineSmall),
  );
}

class InsightSections extends ConsumerStatefulWidget {
  const InsightSections({
    super.key,
    required this.titles,
    required this.insights,
    required this.genreNames,
  });
  final List<RatedTitle> titles;
  final LibraryInsights insights;
  final Map<int, String> genreNames;
  @override
  ConsumerState<InsightSections> createState() => _InsightSectionsState();
}

class _InsightSectionsState extends ConsumerState<InsightSections> {
  FilmographyRole? _role;
  PeopleOrder _order = PeopleOrder.frequent;
  bool _showAll = false;

  InsightViewInput? _input;
  InsightView? _view;
  int _revision = 0;
  late final _worker = LatestWorker<InsightViewInput, InsightView>(
    (input) => ref
        .read(viewComputerProvider)
        .run(prepareInsights, input, 'statistics people view'),
  );

  void _prepare() {
    final input = (widget.titles, widget.insights, _role, _order);
    if (_input == input) return;
    _input = input;
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
                FlutterError.reportError(
                  FlutterErrorDetails(exception: error, stack: stack),
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
    final l10n = AppLocalizations.of(context);
    final insights = widget.insights;
    _prepare();
    final view = _view;
    if (view == null) {
      return const SliverToBoxAdapter(child: SizedBox(height: 32));
    }
    final titles = view.titles;
    final genres = view.genres;
    final ranked = view.ranked;
    String orderLabel(PeopleOrder order) => switch (order) {
      PeopleOrder.frequent => l10n.statsPeopleFrequent,
      PeopleOrder.highest => l10n.statsPeopleHighest,
      PeopleOrder.reliable => l10n.statsPeopleReliable,
      PeopleOrder.polarizing => l10n.statsPeoplePolarizing,
    };
    return SliverList.list(
      children: [
        const SizedBox(height: 12),
        _WorksTile(title: l10n.statsBest, titles: titles),
        _WorksTile(title: l10n.statsWorst, titles: titles.reversed.toList()),
        InsightHeading(l10n.statsReliableGenres),
        if (genres.isEmpty) Text(l10n.statsNoQualifying),
        for (final genre in genres)
          _ProfileTile(
            label: widget.genreNames[genre.key] ?? '#${genre.key}',
            profile: genre.value,
          ),
        InsightHeading(l10n.statsPeople),
        Text(l10n.peopleLoadProgress(insights.covered, widget.titles.length)),
        Text(
          l10n.statsMinimumWorks,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            ChoiceChip(
              label: Text(l10n.filmographyAll),
              selected: _role == null,
              onSelected: (_) => setState(() {
                _role = null;
                _showAll = false;
              }),
            ),
            for (final role in FilmographyRole.values)
              ChoiceChip(
                label: Text(filmographyLabel(l10n, role)),
                selected: _role == role,
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
                label: Text(orderLabel(order)),
                selected: _order == order,
                onSelected: (_) => setState(() {
                  _order = order;
                  _showAll = false;
                }),
              ),
          ],
        ),
        if (ranked.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              insights.covered == 0
                  ? l10n.peopleNoCredits
                  : l10n.statsNoQualifying,
            ),
          ),
        for (final (person, profile) in _showAll ? ranked : ranked.take(8))
          _ProfileTile(
            label: person.person.name,
            profile: profile,
            person: person.person,
          ),
        if (!_showAll && ranked.length > 8)
          TextButton(
            onPressed: () => setState(() => _showAll = true),
            child: Text('${l10n.statsShowAll} · ${ranked.length}'),
          ),
        InsightHeading(l10n.statsDuos),
        if (insights.duos.isEmpty) Text(l10n.statsNoQualifying),
        for (final duo in insights.duos.take(10))
          _ProfileTile(
            label: '${duo.director.name} × ${duo.actor.name}',
            profile: duo.profile,
          ),
        InsightHeading(l10n.statsBreadth),
        Text(
          l10n.statsBreadthSummary(
            insights.genres.length,
            insights.decades.length,
            insights.people.length,
          ),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(
          l10n.statsEffectiveDiversity(
            view.genreBreadth.toStringAsFixed(1),
            view.decadeBreadth.toStringAsFixed(1),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.statsBreadthHint,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.label, required this.profile, this.person});
  final String label;
  final ScoreProfile profile;
  final PeopleCredit? person;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: person == null
        ? null
        : SizedBox(
            width: 40,
            child: Poster(
              person!.profilePath,
              width: 40,
              size: ImageSize.w185,
              icon: Icons.person_outline,
            ),
          ),
    title: Text(label),
    subtitle: Text(profileLabel(AppLocalizations.of(context), profile)),
    trailing: person == null
        ? const Icon(Icons.chevron_right)
        : IconButton(
            tooltip: label,
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(
              '${TitleRoutes.branchOf(context)}/person/${person!.id}',
            ),
          ),
    onTap: () => showRatedWorks(
      context,
      label,
      [...profile.titles]
        ..sort((a, b) => b.rating.scoreHalf.compareTo(a.rating.scoreHalf)),
    ),
  );
}

class _WorksTile extends StatelessWidget {
  const _WorksTile({required this.title, required this.titles});
  final String title;
  final List<RatedTitle> titles;
  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title),
    subtitle: titles.isEmpty
        ? null
        : Text(
            titles
                .take(3)
                .map(
                  (t) =>
                      '${t.work.title} · ${formatMyScore(t.rating.scoreHalf)}',
                )
                .join('\n'),
          ),
    trailing: const Icon(Icons.chevron_right),
    onTap: () => showRatedWorks(context, title, titles),
  );
}

class SourceInsights extends StatelessWidget {
  const SourceInsights({
    super.key,
    required this.source,
    required this.titles,
    this.prepared,
  });
  final RatingSource source;
  final List<RatedTitle> titles;
  final SourceBreakdown? prepared;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = prepared ?? SourceBreakdown(titles, source);
    final finds = data.finds;
    final disappointments = data.disappointments;
    final agreement = data.agreement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.statsTasteAgreement,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        Text(
          agreement == null
              ? l10n.statsAgreementMissing
              : l10n.statsAgreementValue(
                  agreement.toStringAsFixed(2),
                  data.count,
                ),
        ),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: Text('${l10n.statsFinds} · ${finds.length}'),
              onPressed: finds.isEmpty
                  ? null
                  : () => showRatedWorks(
                      context,
                      '${l10n.statsFinds} · ${ratingSourceLabel(l10n, source)}',
                      finds,
                    ),
            ),
            ActionChip(
              label: Text(
                '${l10n.statsDisappointments} · ${disappointments.length}',
              ),
              onPressed: disappointments.isEmpty
                  ? null
                  : () => showRatedWorks(
                      context,
                      '${l10n.statsDisappointments} · ${ratingSourceLabel(l10n, source)}',
                      disappointments,
                    ),
            ),
          ],
        ),
      ],
    );
  }
}
