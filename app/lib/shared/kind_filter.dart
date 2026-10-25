import 'package:flutter/material.dart';

import '../data/work_key.dart';
import '../l10n/app_localizations.dart';

/// Chips for "All / Films / Series / Seasons / Episodes", scrolling sideways
/// on a narrow screen.
class KindFilter extends StatelessWidget {
  const KindFilter({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  /// `null` — all kinds.
  final WorkKind? selected;
  final ValueChanged<WorkKind?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final options = <(WorkKind?, String)>[
      (null, l10n.kindAll),
      (WorkKind.movie, l10n.kindMovies),
      (WorkKind.tv, l10n.kindSeries),
      (WorkKind.season, l10n.kindSeasons),
      (WorkKind.episode, l10n.kindEpisodes),
    ];
    return ChipRow(
      children: [
        for (final (kind, label) in options)
          ChoiceChip(
            label: Text(label),
            selected: kind == selected,
            onSelected: (_) => onSelected(kind),
          ),
      ],
    );
  }
}

/// A row of chips that scrolls sideways.
class ChipRow extends StatelessWidget {
  const ChipRow({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
    child: Row(
      children: [
        for (final child in children)
          Padding(padding: const EdgeInsets.only(right: 8), child: child),
      ],
    ),
  );
}
