import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/db/database.dart';
import '../../data/library/library.dart';
import '../../data/library/work_snapshot.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../shared/poster.dart';
import '../../shared/title_text.dart';
import 'score_reel.dart';

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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
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

  /// Opens the editor and saves. Everything from ref is taken before the
  /// awaits: the card may be closed by then (AGENTS.md, pitfalls).
  Future<void> _edit(Rating? current) async {
    final library = ref.read(libraryProvider);
    final lineage = widget.lineage;
    final draft = await showModalBottomSheet<RatingDraft>(
      context: context,
      // Over the navigation bar: the reel needs the whole width and the
      // attention.
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RatingEditor(
        initialScoreHalf: current?.scoreHalf,
        initialNote: current?.note,
        compare: (half) => library.calibration(lineage.last.key, half),
      ),
    );
    if (draft == null) return;
    await library.rate(lineage, scoreHalf: draft.scoreHalf, note: draft.note);
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
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: onRate,
            icon: const Icon(Icons.edit_outlined),
            label: Text(l10n.ratingRate),
          ),
        ),
        if (watchlistable) ...[
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => onToggleWatchlist(listed),
              icon: Icon(
                listed ? Icons.bookmark_added : Icons.bookmark_outline,
              ),
              label: Text(
                listed ? l10n.watchlistListed : l10n.watchlistAdd,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
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
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The grease-pencil mark: your score is the loudest thing here.
            // It shrinks rather than overflows with a large system font.
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.bottomLeft,
                child: Text(
                  formatMyScore(rating.scoreHalf),
                  style: theme.textTheme.displayLarge?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.ratingMine, style: theme.textTheme.titleSmall),
                    Text(
                      context.formatTimestamp(rating.scoredAt),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Reel.of(context).edge,
                      ),
                    ),
                  ],
                ),
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
        // A note sits in the margin, marked with the same red.
        if (note != null)
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: theme.colorScheme.primary, width: 2),
              ),
            ),
            child: Text(note, style: theme.textTheme.bodyLarge),
          ),
      ],
    );
  }
}

/// Your score as a grease-pencil mark: next to a season or an episode in a
/// list, or on a poster ([onPoster]) on a lit tag. Nothing if it isn't rated.
class MyScoreBadge extends ConsumerWidget {
  const MyScoreBadge(this.workKey, {super.key, this.onPoster = false});

  final WorkKey workKey;
  final bool onPoster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rating = ref.watch(myRatingProvider(workKey)).value;
    if (rating == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final figure = Text(
      formatMyScore(rating.scoreHalf),
      style: theme.textTheme.headlineSmall?.copyWith(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w800,
        height: 1,
      ),
    );
    if (!onPoster) {
      return Padding(padding: const EdgeInsets.only(right: 8), child: figure);
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 3, 6, 2),
      decoration: BoxDecoration(
        color: Reel.of(context).gate,
        borderRadius: BorderRadius.circular(4),
      ),
      child: figure,
    );
  }
}

/// What the editor returns.
typedef RatingDraft = ({int scoreHalf, String? note});

/// Choosing a score on the [ScoreReel] and writing a note. The comparison
/// with your other ratings of this kind runs under the reel while it moves,
/// so it helps to choose rather than coming after the choice (Stage 6).
class RatingEditor extends StatefulWidget {
  const RatingEditor({
    super.key,
    this.initialScoreHalf,
    this.initialNote,
    required this.compare,
  });

  final int? initialScoreHalf;
  final String? initialNote;

  /// What else of this kind is rated at a score, and around it.
  final Future<Calibration> Function(int scoreHalf) compare;

  @override
  State<RatingEditor> createState() => _RatingEditorState();
}

class _RatingEditorState extends State<RatingEditor> {
  late int? _scoreHalf = widget.initialScoreHalf;
  late final _note = TextEditingController(text: widget.initialNote);

  /// The last comparison that arrived and the score it is for: kept on
  /// screen while the next one loads, so the panel doesn't blink.
  ({int scoreHalf, Calibration calibration})? _shown;

  static const _maxNote = 10000;

  @override
  void initState() {
    super.initState();
    if (_scoreHalf case final half?) _compare(half);
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _compare(int half) async {
    final calibration = await widget.compare(half);
    // Only the answer for the score still in the gate counts.
    if (!mounted || _scoreHalf != half) return;
    setState(() => _shown = (scoreHalf: half, calibration: calibration));
  }

  void _changed(int? half) {
    setState(() => _scoreHalf = half);
    if (half != null) _compare(half);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final score = _scoreHalf;
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                l10n.ratingEditorTitle,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            const SizedBox(height: 12),
            ScoreReel(
              initialScoreHalf: widget.initialScoreHalf,
              onChanged: _changed,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: score == null
                  ? Text(
                      l10n.reelHint,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  : _Comparison(shown: _shown),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: TextField(
                controller: _note,
                minLines: 2,
                maxLines: 6,
                maxLength: _maxNote,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.ratingNote),
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
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: FilledButton(
                onPressed: score == null
                    ? null
                    : () => Navigator.pop<RatingDraft>(context, (
                        scoreHalf: score,
                        note: _note.text,
                      )),
                child: Text(l10n.ratingSave),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Under the reel: what you rated the same, and the nearest scores below and
/// above, laid out the way the strip runs — lower on the left.
class _Comparison extends StatelessWidget {
  const _Comparison({required this.shown});

  final ({int scoreHalf, Calibration calibration})? shown;

  /// Tall enough for a label, a poster and a line of title, so the panel
  /// keeps its height while the reel moves.
  static const _rowHeight = 156.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final shown = this.shown;
    if (shown == null) return const SizedBox(height: _rowHeight * 2);
    final c = shown.calibration;
    if (c.isEmpty) {
      return Text(
        l10n.reelFirst,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }
    String scoreOf(List<RatedTitle> group) =>
        formatMyScore(group.first.rating.scoreHalf);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: _rowHeight,
          child: _Group(
            label: l10n.calibrationSame(formatMyScore(shown.scoreHalf)),
            titles: c.same,
            slots: Calibration.sameLimit,
          ),
        ),
        SizedBox(
          height: _rowHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _Group(
                  label: c.below.isEmpty
                      ? null
                      : l10n.calibrationBelow(scoreOf(c.below)),
                  titles: c.below,
                  slots: Calibration.neighbourLimit,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _Group(
                  label: c.above.isEmpty
                      ? null
                      : l10n.calibrationAbove(scoreOf(c.above)),
                  titles: c.above,
                  slots: Calibration.neighbourLimit,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.label,
    required this.titles,
    required this.slots,
  });

  final String? label;
  final List<RatedTitle> titles;

  /// How many posters the row has room for; they keep their size whether
  /// there is one title or four.
  final int slots;

  static const _poster = 64.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label ?? '',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 6),
        if (titles.isEmpty)
          Text(l10n.calibrationNothing, style: muted)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final title in titles.take(slots))
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SizedBox(
                    width: _poster,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Poster(
                          title.posterPath,
                          size: ImageSize.w185,
                          width: _poster,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          describeRated(l10n, title).title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: muted,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
