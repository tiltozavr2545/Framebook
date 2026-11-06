import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../sources/providers.dart';
import '../sources/tmdb/tmdb_models.dart';
import '../work_key.dart';

final trendingShelfProvider = FutureProvider.autoDispose<List<TitleSummary>>(
  (ref) => ref.watch(tmdbProvider).trending(),
);
final nowPlayingShelfProvider = FutureProvider.autoDispose<List<TitleSummary>>(
  (ref) => ref.watch(tmdbProvider).nowPlaying(),
);
final bestShelfProvider = FutureProvider.autoDispose<List<TitleSummary>>((
  ref,
) async {
  final tmdb = ref.watch(tmdbProvider);
  return interleaveTitles(
    await Future.wait([tmdb.best(WorkKind.movie), tmdb.best(WorkKind.tv)]),
  );
});

List<TitleSummary> interleaveTitles(List<List<TitleSummary>> lists) {
  final seen = <WorkKey>{};
  final out = <TitleSummary>[];
  final length = lists.fold(0, (n, l) => l.length > n ? l.length : n);
  for (var i = 0; i < length; i++) {
    for (final list in lists) {
      if (i < list.length && seen.add(list[i].key)) out.add(list[i]);
    }
  }
  return out;
}
