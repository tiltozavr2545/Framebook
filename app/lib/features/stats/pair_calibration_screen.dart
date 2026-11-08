import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/foreground.dart';
import '../../data/db/database.dart';
import '../../data/latest_worker.dart';
import '../../data/library/library.dart';
import '../../data/library/pair_calibration.dart';
import '../../data/library/pair_calibration_store.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/view_computer.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/format.dart';
import '../../shared/poster.dart';
import '../../shared/score_color.dart';
import '../../shared/accent_panel.dart';

class PairCalibrationEntry extends StatelessWidget {
  const PairCalibrationEntry({super.key, required this.filmCount});
  final int filmCount;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: accentPanelDecoration(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.pairEntryTitle,
                  style: theme.textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                filmCount < 2 ? l10n.pairNeedFilms : l10n.pairEntryHint,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.compare_arrows),
                  label: Text(l10n.pairStart, textAlign: TextAlign.center),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, 52),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    textStyle: theme.textTheme.titleMedium,
                  ),
                  onPressed: filmCount < 2
                      ? null
                      : () => context.push(Routes.statsCalibration),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PairCalibrationScreen extends ConsumerStatefulWidget {
  const PairCalibrationScreen({super.key});
  @override
  ConsumerState<PairCalibrationScreen> createState() =>
      _PairCalibrationScreenState();
}

class _PairCalibrationScreenState extends ConsumerState<PairCalibrationScreen> {
  late final _clock = ref.read(pairCalibrationClockProvider);
  late final _computer = ref.read(viewComputerProvider);
  late final _worker = LatestWorker<PairSelectionInput, CalibrationPair?>(
    (input) =>
        _computer.run(selectCalibrationPair, input, 'pairwise calibration'),
  );
  final _skipped = <String>{};
  final _local = <String, PairComparison>{};
  CalibrationPair? _pair;
  PairPreference? _preference;
  bool _selecting = true, _saving = false, _scheduled = false;
  String? _error;
  int _generation = 0;
  Timer? _midnight;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _armDayTimer();
    _schedule();
  }

  void _armDayTimer() {
    _midnight?.cancel();
    final now = _clock();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    _midnight = Timer(
      tomorrow.difference(now) + const Duration(milliseconds: 100),
      () {
        if (!mounted) return;
        _armDayTimer();
        _schedule();
      },
    );
  }

  List<PairComparison> _history() => {
    ..._local,
    for (final p
        in ref.read(pairComparisonsProvider).value ?? <PairComparison>[])
      p.comparisonKey: p,
  }.values.toList();

  int _used(List<PairComparison> history) =>
      history.where((p) => p.day == calibrationDay(_clock())).length;

  void _schedule() {
    if (_scheduled || !mounted) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted && !_saving) unawaited(_refresh());
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _refresh() async {
    final rows = ref.read(ratedTitlesProvider).value;
    final saved = ref.read(pairComparisonsProvider);
    if (rows == null || !saved.hasValue) return;
    final history = _history();
    final reviewed = {
      for (final p in history) ...[p.comparisonKey, comparisonResultVersion(p)],
    };
    final available = _used(history) < dailyPairLimit;
    final current = _pair;
    bool matches(RatedTitle expected) => rows.any(
      (r) =>
          r.work.workKey == expected.work.workKey &&
          r.rating.deletedAt == null &&
          r.rating.scoreHalf == expected.rating.scoreHalf &&
          r.rating.scoredAt == expected.rating.scoredAt,
    );
    if (available &&
        current != null &&
        !reviewed.contains(current.version) &&
        !_skipped.contains(current.version) &&
        matches(current.left) &&
        matches(current.right)) {
      setState(() {});
      return;
    }
    final generation = ++_generation;
    final appearances = <String, int>{};
    for (final p in history) {
      for (final key in [p.leftKey, p.rightKey]) {
        appearances.update(key, (n) => n + 1, ifAbsent: () => 1);
      }
    }
    setState(() {
      _pair = null;
      _preference = null;
      _selecting = available;
    });
    if (!available) return;
    final input = (
      titles: rows,
      reviewed: reviewed,
      skipped: {..._skipped},
      appearances: appearances,
      comparisons: history,
    );
    try {
      final next = rows.length <= 200
          ? selectCalibrationPair(input)
          : await _worker.run(input);
      if (!mounted || generation != _generation) return;
      setState(() {
        _pair = next;
        _selecting = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
      });
    } on Object {
      if (mounted && generation == _generation) {
        setState(() {
          _selecting = false;
          _error = AppLocalizations.of(context).pairLoadFailed;
        });
      }
    }
  }

  Future<void> _save(Map<String, int> changes) async {
    final pair = _pair, preference = _preference;
    if (_saving || pair == null || preference == null) return;
    final store = ref.read(pairCalibrationStoreProvider);
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final event = await store.answer(pair, preference, changes: changes);
      if (!mounted) return;
      setState(() {
        _local[event.comparisonKey] = event;
        _saving = false;
        _pair = null;
        _preference = null;
      });
      _schedule();
    } on CalibrationStale {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _pair = null;
        _preference = null;
        _error = l10n.pairChanged;
      });
      _schedule();
    } on CalibrationLimitReached {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _pair = null;
        _preference = null;
      });
      _schedule();
    } on Object {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = l10n.pairSaveFailed;
        });
      }
    }
  }

  @override
  void dispose() {
    _midnight?.cancel();
    _worker.dispose();
    _scroll.dispose();
    _generation++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ref.listen(ratedTitlesProvider, (_, _) => _schedule());
    ref.listen(pairComparisonsProvider, (_, _) => _schedule());
    ref.listen(foregroundProvider, (_, active) {
      if (active) {
        _armDayTimer();
        _schedule();
      } else {
        _midnight?.cancel();
      }
    });
    final ratings = ref.watch(ratedTitlesProvider),
        saved = ref.watch(pairComparisonsProvider);
    final history = _history(), pair = _pair, preference = _preference;
    final used = _used(history);
    final loaded = ratings.hasValue && saved.hasValue;
    final failed = ratings.hasError || saved.hasError;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: MediaQuery.textScalerOf(
          context,
        ).scale(kToolbarHeight).clamp(kToolbarHeight, 112),
        title: Text(
          l10n.pairTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        controller: _scroll,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l10n.pairHow),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(l10n.pairIntro),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            l10n.pairProgress(used),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (_error != null) ...[const SizedBox(height: 12), Text(_error!)],
          if (failed) ...[
            Text(l10n.pairLoadFailed),
            TextButton(
              onPressed: () {
                ref.invalidate(ratedTitlesProvider);
                ref.invalidate(pairComparisonsProvider);
                _schedule();
              },
              child: Text(l10n.retry),
            ),
          ] else if (!loaded || _selecting)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            ),
          if (loaded && used >= dailyPairLimit)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.pairLimit),
            ),
          if (loaded &&
              !_selecting &&
              used < dailyPairLimit &&
              pair == null &&
              !failed)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.pairFinished),
            ),
          if (loaded && pair != null && used < dailyPairLimit) ...[
            const SizedBox(height: 16),
            Text(
              pair.reason == PairReason.comparisonChain
                  ? l10n.pairReasonChain
                  : l10n.pairReasonBoundary,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.pairQuestion,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final stacked = MediaQuery.textScalerOf(context).scale(16) > 24;
                final cards = [
                  _Film(
                    title: pair.left,
                    label: l10n.pairFirst,
                    showScore: preference != null,
                    compact: stacked,
                  ),
                  _Film(
                    title: pair.right,
                    label: l10n.pairSecond,
                    showScore: preference != null,
                    compact: stacked,
                  ),
                ];
                return stacked
                    ? Column(
                        children: [
                          cards[0],
                          const SizedBox(height: 16),
                          cards[1],
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: cards[0]),
                          const SizedBox(width: 16),
                          Expanded(child: cards[1]),
                        ],
                      );
              },
            ),
            const SizedBox(height: 16),
            if (preference == null) ...[
              FilledButton.tonal(
                onPressed: () =>
                    setState(() => _preference = PairPreference.left),
                child: Text(l10n.pairPreferFirst),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    setState(() => _preference = PairPreference.equal),
                child: Text(l10n.pairEqual),
              ),
              FilledButton.tonal(
                onPressed: () =>
                    setState(() => _preference = PairPreference.right),
                child: Text(l10n.pairPreferSecond),
              ),
              TextButton(
                onPressed: () {
                  _skipped.add(pair.version);
                  _schedule();
                },
                child: Text(l10n.pairSkip),
              ),
            ] else ...[
              Text(
                preference == PairPreference.equal
                    ? l10n.pairEqual
                    : preference == PairPreference.left
                    ? l10n.pairPreferFirst
                    : l10n.pairPreferSecond,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                pair.agrees(preference) ? l10n.pairAgrees : l10n.pairDisagrees,
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _preference = null),
                child: Text(l10n.pairChangeAnswer),
              ),
              for (final correction in calibrationCorrections(pair, preference))
                OutlinedButton(
                  onPressed: _saving ? null : () => _save(correction),
                  child: Text(
                    [
                      for (final title in [pair.left, pair.right])
                        if (correction[title.work.workKey] case final half?)
                          l10n.pairCorrection(
                            title.work.title,
                            formatMyScore(title.rating.scoreHalf),
                            formatMyScore(half),
                          ),
                    ].join('\n'),
                  ),
                ),
              FilledButton(
                onPressed: _saving ? null : () => _save(const {}),
                child: Text(
                  pair.agrees(preference) ? l10n.pairNext : l10n.pairKeep,
                ),
              ),
              if (_saving) const Center(child: CircularProgressIndicator()),
            ],
          ],
        ],
      ),
    );
  }
}

class _Film extends StatelessWidget {
  const _Film({
    required this.title,
    required this.label,
    required this.showScore,
    required this.compact,
  });
  final RatedTitle title;
  final String label;
  final bool showScore, compact;
  @override
  Widget build(BuildContext context) {
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        Text(title.work.title, style: Theme.of(context).textTheme.titleMedium),
        if (title.work.year != null) Text('${title.work.year}'),
        if (showScore)
          Text(
            formatMyScore(title.rating.scoreHalf),
            key: ValueKey('pair-score-${title.work.workKey}'),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: scoreColor(context, title.rating.scoreHalf / 2),
            ),
          ),
      ],
    );
    return compact
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Poster(title.posterPath, size: ImageSize.w185, width: 64),
              const SizedBox(width: 12),
              Expanded(child: details),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Poster(
                  title.posterPath,
                  size: ImageSize.w185,
                  width: 104,
                ),
              ),
              const SizedBox(height: 8),
              details,
            ],
          );
  }
}
