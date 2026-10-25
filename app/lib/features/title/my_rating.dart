import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/database.dart';
import '../../data/library/library.dart';
import '../../data/library/work_snapshot.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import 'calibration_sheet.dart';

/// "My rating" on a card of any kind: the score and note, or a button to
/// rate; the watchlist toggle for films and series; for a series or a
/// season, the average of its rated parts as a hint.
///
/// [lineage] is the title's snapshot with all its ancestors, series first —
/// a rating is saved together with them (docs/data-model.md).
class MyRatingSection extends ConsumerStatefulWidget {
  const MyRatingSection({super.key, required this.lineage});

  final List<WorkSnapshot> lineage;

  @override
  ConsumerState<MyRatingSection> createState() => _MyRatingSectionState();
}

class _MyRatingSectionState extends ConsumerState<MyRatingSection> {
  WorkKey get _key => widget.lineage.last.key;

  @override
  void initState() {
    super.initState();
    // The card was just opened: refresh the snapshots that already exist
    // (title in the current language, poster), never creating new ones.
    unawaited(ref.read(libraryProvider).refreshSnapshots(widget.lineage));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final rating = ref.watch(myRatingProvider(_key)).value;
    final kind = _key.kind;
    final watchlistable = kind == WorkKind.movie || kind == WorkKind.tv;
    final listed =
        watchlistable && (ref.watch(inWatchlistProvider(_key)).value ?? false);
    final parts = kind == WorkKind.tv || kind == WorkKind.season
        ? ref.watch(partsAverageProvider(_key)).value
        : null;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rating == null)
            _Unrated(
              listed: listed,
              watchlistable: watchlistable,
              onRate: () => _edit(null),
              onToggleWatchlist: _toggleWatchlist,
            )
          else
            _Rated(
              rating: rating,
              onEdit: () => _edit(rating),
              onDelete: () => _delete(),
            ),
          if (parts != null) ...[
            const SizedBox(height: 8),
            Text(
              parts.parts == WorkKind.season
                  ? l10n.partsAverageSeasons(
                      parts.count,
                      formatScore(parts.average),
                    )
                  : l10n.partsAverageEpisodes(
                      parts.count,
                      formatScore(parts.average),
                    ),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Opens the editor, saves, and — if the score itself changed — shows the
  /// calibration sheet. Everything from ref is taken before the awaits: the
  /// card may be closed by then (AGENTS.md, pitfalls).
  Future<void> _edit(Rating? current) async {
    final library = ref.read(libraryProvider);
    final lineage = widget.lineage;
    final draft = await showModalBottomSheet<RatingDraft>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RatingEditor(
        initialScoreHalf: current?.scoreHalf,
        initialNote: current?.note,
      ),
    );
    if (draft == null) return;
    await library.rate(lineage, scoreHalf: draft.scoreHalf, note: draft.note);
    if (current?.scoreHalf == draft.scoreHalf || !mounted) return;
    await showCalibrationSheet(
      context,
      library: library,
      key: lineage.last.key,
      scoreHalf: draft.scoreHalf,
    );
  }

  Future<void> _delete() async {
    final library = ref.read(libraryProvider);
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.ratingDeleteTitle),
        content: Text(l10n.ratingDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.ratingDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await library.deleteRating(_key);
  }

  Future<void> _toggleWatchlist(bool listed) {
    final library = ref.read(libraryProvider);
    return listed
        ? library.removeFromWatchlist(_key)
        : library.addToWatchlist(widget.lineage);
  }
}

class _Unrated extends StatelessWidget {
  const _Unrated({
    required this.listed,
    required this.watchlistable,
    required this.onRate,
    required this.onToggleWatchlist,
  });

  final bool listed;
  final bool watchlistable;
  final VoidCallback onRate;
  final Future<void> Function(bool listed) onToggleWatchlist;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: onRate,
          icon: const Icon(Icons.star_outline),
          label: Text(l10n.ratingRate),
        ),
        if (watchlistable)
          OutlinedButton.icon(
            onPressed: () => onToggleWatchlist(listed),
            icon: Icon(listed ? Icons.bookmark_added : Icons.bookmark_outline),
            label: Text(listed ? l10n.watchlistListed : l10n.watchlistAdd),
          ),
      ],
    );
  }
}

class _Rated extends StatelessWidget {
  const _Rated({
    required this.rating,
    required this.onEdit,
    required this.onDelete,
  });

  final Rating rating;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final note = rating.note;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              formatMyScore(rating.scoreHalf),
              style: theme.textTheme.displaySmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.ratingMine, style: theme.textTheme.titleSmall),
                  Text(
                    context.formatTimestamp(rating.scoredAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: l10n.ratingEdit,
              onPressed: onEdit,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: l10n.ratingDelete,
              onPressed: onDelete,
            ),
          ],
        ),
        if (note != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 8),
            child: Text(note, style: theme.textTheme.bodyMedium),
          ),
      ],
    );
  }
}

/// The user's score next to a season or an episode in a list; nothing if it
/// isn't rated.
class MyScoreBadge extends ConsumerWidget {
  const MyScoreBadge(this.workKey, {super.key});

  final WorkKey workKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(myRatingProvider(workKey)).value;
    if (rating == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        formatMyScore(rating.scoreHalf),
        style: Theme.of(
          context,
        ).textTheme.labelLarge?.copyWith(color: scheme.onPrimaryContainer),
      ),
    );
  }
}

/// What the editor returns.
typedef RatingDraft = ({int scoreHalf, String? note});

/// Choosing a score (1–10 in steps of 0.5) and writing a note. No default
/// score: a pre-selected 7 would nudge the choice. Tapping the selected
/// score keeps it — deleting is a separate action.
class RatingEditor extends StatefulWidget {
  const RatingEditor({super.key, this.initialScoreHalf, this.initialNote});

  final int? initialScoreHalf;
  final String? initialNote;

  @override
  State<RatingEditor> createState() => _RatingEditorState();
}

class _RatingEditorState extends State<RatingEditor> {
  late int? _scoreHalf = widget.initialScoreHalf;
  late final _note = TextEditingController(text: widget.initialNote);

  static const _maxNote = 10000;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final score = _scoreHalf;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        0,
        16,
        16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.ratingEditorTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (var half = 2; half <= 20; half++)
                  ChoiceChip(
                    label: Text(formatMyScore(half)),
                    selected: half == score,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _scoreHalf = half),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _note,
              minLines: 2,
              maxLines: 6,
              maxLength: _maxNote,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                labelText: l10n.ratingNote,
                border: const OutlineInputBorder(),
              ),
              // The counter only matters near the limit.
              buildCounter:
                  (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) => currentLength > _maxNote - 500
                  ? Text('$currentLength / $maxLength')
                  : null,
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: score == null
                  ? null
                  : () => Navigator.pop<RatingDraft>(context, (
                      scoreHalf: score,
                      note: _note.text,
                    )),
              child: Text(l10n.ratingSave),
            ),
          ],
        ),
      ),
    );
  }
}
