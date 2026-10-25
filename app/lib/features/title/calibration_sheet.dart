import 'package:flutter/material.dart';

import '../../data/library/library.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/poster.dart';
import '../../shared/title_text.dart';

/// Shows the calibration sheet after [key] was scored [scoreHalf] — unless
/// there is nothing to compare with yet (the first rating of this kind).
Future<void> showCalibrationSheet(
  BuildContext context, {
  required Library library,
  required WorkKey key,
  required int scoreHalf,
}) async {
  final calibration = await library.calibration(key, scoreHalf);
  if (calibration.isEmpty || !context.mounted) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => CalibrationSheet(
      library: library,
      workKey: key,
      scoreHalf: scoreHalf,
      calibration: calibration,
    ),
  );
}

/// "What else you rated the same": the same score, and the nearest scores
/// above and below, always within the same kind (docs/project-brief.md,
/// "How the product works"). The score in the header can be nudged by half a
/// point; that changes the rating just given, and the sheet rebuilds.
class CalibrationSheet extends StatefulWidget {
  const CalibrationSheet({
    super.key,
    required this.library,
    required this.workKey,
    required this.scoreHalf,
    required this.calibration,
  });

  final Library library;
  final WorkKey workKey;
  final int scoreHalf;
  final Calibration calibration;

  @override
  State<CalibrationSheet> createState() => _CalibrationSheetState();
}

class _CalibrationSheetState extends State<CalibrationSheet> {
  late int _scoreHalf = widget.scoreHalf;
  late Calibration _calibration = widget.calibration;
  bool _busy = false;

  Future<void> _rescore(int scoreHalf) async {
    setState(() {
      _busy = true;
      _scoreHalf = scoreHalf;
    });
    await widget.library.rescore(widget.workKey, scoreHalf);
    final calibration = await widget.library.calibration(
      widget.workKey,
      scoreHalf,
    );
    if (!mounted) return;
    setState(() {
      _calibration = calibration;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final aboveScore = _calibration.above.firstOrNull?.rating.scoreHalf;
    final belowScore = _calibration.below.firstOrNull?.rating.scoreHalf;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        children: [
          Text(l10n.calibrationTitle, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(l10n.ratingMine, style: theme.textTheme.titleSmall),
              const Spacer(),
              IconButton.filledTonal(
                icon: const Icon(Icons.remove),
                tooltip: l10n.calibrationLower,
                onPressed: _busy || _scoreHalf <= 2
                    ? null
                    : () => _rescore(_scoreHalf - 1),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  formatMyScore(_scoreHalf),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton.filledTonal(
                icon: const Icon(Icons.add),
                tooltip: l10n.calibrationHigher,
                onPressed: _busy || _scoreHalf >= 20
                    ? null
                    : () => _rescore(_scoreHalf + 1),
              ),
            ],
          ),
          if (_calibration.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(l10n.calibrationNothing),
            ),
          if (aboveScore != null)
            _Group(
              title: l10n.calibrationAbove(formatMyScore(aboveScore)),
              titles: _calibration.above,
            ),
          if (_calibration.same.isNotEmpty)
            _Group(
              title: l10n.calibrationSame(formatMyScore(_scoreHalf)),
              titles: _calibration.same,
            ),
          if (belowScore != null)
            _Group(
              title: l10n.calibrationBelow(formatMyScore(belowScore)),
              titles: _calibration.below,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({required this.title, required this.titles});

  final String title;
  final List<RatedTitle> titles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(title, style: theme.textTheme.titleMedium),
        ),
        for (final rated in titles)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Poster(rated.posterPath, size: ImageSize.w92, width: 32),
                const SizedBox(width: 12),
                Expanded(
                  child: Builder(
                    builder: (context) {
                      final lines = describeRated(l10n, rated);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lines.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            lines.subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
