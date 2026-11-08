import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/library/library.dart';
import '../../data/library/prepared_views.dart';
import '../../data/latest_worker.dart';
import '../../data/view_computer.dart';
import '../../data/source_failure.dart';
import '../../data/sources/providers.dart';
import '../../data/work_key.dart';

/// The kind the statistics are filtered by; `null` — all. Kept while the app
/// is open.
class StatsKindNotifier extends Notifier<WorkKind?> {
  @override
  WorkKind? build() => WorkKind.movie;

  void select(WorkKind? kind) => state = kind;
}

final statsKindProvider = NotifierProvider<StatsKindNotifier, WorkKind?>(
  StatsKindNotifier.new,
);

final _statsWorkerProvider = Provider.autoDispose((ref) {
  final computer = ref.watch(viewComputerProvider);
  final worker = LatestWorker<StatsInput, StatsView>(
    (input) => computer.run(prepareStatsKind, input, 'statistics summary'),
  );
  ref.onDispose(worker.dispose);
  return worker;
});

class _StatsData extends AsyncNotifier<StatsView?> {
  @override
  FutureOr<StatsView?> build() {
    final all = ref.watch(ratedTitlesProvider).value;
    final kind = ref.watch(statsKindProvider);
    if (all == null) return null;
    final input = (all, kind);
    if (all.length <= 200) return prepareStatsKind(input);
    return ref.watch(_statsWorkerProvider).run(input);
  }
}

final statsViewProvider =
    AsyncNotifierProvider.autoDispose<_StatsData, StatsView?>(_StatsData.new);

/// Genre names in the content language, from TMDB through the HTTP cache.
/// Empty when TMDB can't be reached and nothing is cached: the rest of the
/// statistics doesn't need a network.
final genreNamesProvider = FutureProvider.autoDispose<Map<int, String>>((
  ref,
) async {
  final tmdb = ref.watch(tmdbProvider);
  try {
    final lists = await Future.wait([
      tmdb.genres(WorkKind.tv),
      tmdb.genres(WorkKind.movie),
    ]);
    // Film names win where the lists share an id: they are the same genre.
    return {
      for (final list in lists)
        for (final genre in list) genre.id: genre.name,
    };
  } on SourceException {
    return const {};
  }
});
