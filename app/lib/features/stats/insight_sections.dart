import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/api_source.dart';
import '../../data/library/insights.dart';
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

class InsightSections extends StatefulWidget {
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
  State<InsightSections> createState() => _InsightSectionsState();
}

enum _Order { frequent, highest, reliable, polarizing }

class _InsightSectionsState extends State<InsightSections> {
  FilmographyRole? _role;
  _Order _order = _Order.frequent;
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final insights = widget.insights;
    final titles = [...widget.titles]
      ..sort((a, b) {
        final score = b.rating.scoreHalf.compareTo(a.rating.scoreHalf);
        return score != 0
            ? score
            : b.rating.scoredAt.compareTo(a.rating.scoredAt);
      });
    final genres =
        insights.genres.entries.where((e) => e.value.eligible).toList()
          ..sort((a, b) {
            final share = b.value.highShare.compareTo(a.value.highShare);
            return share != 0
                ? share
                : b.value.average.compareTo(a.value.average);
          });
    final ranked = <(PersonInsight, ScoreProfile)>[];
    for (final person in insights.people) {
      final profile = _role == null ? person.profile : person.roles[_role];
      if (profile == null ||
          _order != _Order.frequent && !profile.eligible ||
          _order == _Order.polarizing && !profile.polarizing) {
        continue;
      }
      ranked.add((person, profile));
    }
    ranked.sort((a, b) {
      final cmp = switch (_order) {
        _Order.frequent => b.$2.count.compareTo(a.$2.count),
        _Order.highest => b.$2.average.compareTo(a.$2.average),
        _Order.reliable => b.$2.highShare.compareTo(a.$2.highShare),
        _Order.polarizing => b.$2.spread.compareTo(a.$2.spread),
      };
      if (cmp != 0) return cmp;
      final count = b.$2.count.compareTo(a.$2.count);
      return count != 0 ? count : a.$1.person.id.compareTo(b.$1.person.id);
    });
    String orderLabel(_Order order) => switch (order) {
      _Order.frequent => l10n.statsPeopleFrequent,
      _Order.highest => l10n.statsPeopleHighest,
      _Order.reliable => l10n.statsPeopleReliable,
      _Order.polarizing => l10n.statsPeoplePolarizing,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            for (final order in _Order.values)
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
            categoryBreadth(insights.genres.values).toStringAsFixed(1),
            categoryBreadth(insights.decades.values).toStringAsFixed(1),
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
  const SourceInsights({super.key, required this.source, required this.titles});
  final RatingSource source;
  final List<RatedTitle> titles;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shared = titles
        .where((t) => t.divergenceFrom(source) != null)
        .toList();
    final finds = shared.where((t) => t.divergenceFrom(source)! >= 1).toList()
      ..sort(
        (a, b) =>
            b.divergenceFrom(source)!.compareTo(a.divergenceFrom(source)!),
      );
    final disappointments =
        shared.where((t) => t.divergenceFrom(source)! <= -1).toList()..sort(
          (a, b) =>
              a.divergenceFrom(source)!.compareTo(b.divergenceFrom(source)!),
        );
    final agreement = rankAgreement(titles, source);
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
                  shared.length,
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
