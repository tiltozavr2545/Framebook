import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../work_key.dart';
import '../latest_worker.dart';
import '../sources/tmdb/tmdb_models.dart';
import 'insights.dart';
import 'library.dart';
import 'people_index.dart';

final emptyLibraryInsights = LibraryInsights(
  genres: const {},
  decades: const {},
  people: const [],
  duos: const [],
  covered: 0,
);

typedef _Input = (List<RatedTitle>, Map<String, List<PeopleCredit>>);
LibraryInsights _analyze(_Input input) => analyzeLibrary(input.$1, input.$2);

final _workerProvider = Provider.autoDispose
    .family<LatestWorker<_Input, LibraryInsights>, WorkKind?>((ref, kind) {
      final worker = LatestWorker<_Input, LibraryInsights>(
        (input) => compute(_analyze, input, debugLabel: 'library insights'),
      );
      ref.onDispose(worker.dispose);
      return worker;
    });

/// Title count alone does not bound TV aggregate casts or actor/director pairs.
bool insightsNeedWorker(
  List<RatedTitle> titles,
  Map<String, List<PeopleCredit>> entries,
) {
  if (titles.length > 80) return true;
  var credits = 0;
  var pairs = 0;
  for (final title in titles) {
    final people = entries[peopleIdentity(title)] ?? const <PeopleCredit>[];
    credits += people.length;
    if (credits > 1000) return true;
    var actors = 0;
    var directors = 0;
    for (final person in people) {
      if (person.role == FilmographyRole.acting) actors++;
      if (person.role == FilmographyRole.directing) directors++;
    }
    pairs += actors * directors;
    if (pairs > 4000) return true;
  }
  return false;
}

/// Shared by people browsing and statistics. Favourite changes and index
/// progress alone must not recompute every person's roles and director pairs.
final libraryInsightsProvider = FutureProvider.autoDispose
    .family<LibraryInsights, WorkKind?>((ref, kind) {
      final all = ref.watch(ratedTitlesProvider).value ?? const <RatedTitle>[];
      final entries = ref.watch(peopleIndexProvider.select((s) => s.entries));
      final titles = kind == null
          ? all
          : all.where((t) => t.key.kind == kind).toList();
      final input = (titles, entries);
      if (!insightsNeedWorker(titles, entries)) return _analyze(input);
      return ref
          .watch(_workerProvider(kind))
          .run(input)
          .then((value) => value ?? emptyLibraryInsights);
    });
