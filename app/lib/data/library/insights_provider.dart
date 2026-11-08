import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../work_key.dart';
import '../db/database.dart';
import '../latest_worker.dart';
import '../sources/tmdb/tmdb_models.dart';
import 'insights.dart';
import 'library.dart';
import 'people_index.dart';
import 'people_credit_payload.dart';

final emptyLibraryInsights = LibraryInsights(
  genres: const {},
  decades: const {},
  people: const [],
  duos: const [],
  covered: 0,
);

typedef _Input = (List<RatedTitle>, Map<String, List<PeopleCredit>>);
LibraryInsights _analyze(_Input input) => analyzeLibrary(input.$1, input.$2);

bool _sameSnapshot(Work? a, Work? b) =>
    a == b ||
    a != null &&
        b != null &&
        a.copyWith(snapshotUpdatedAt: b.snapshotUpdatedAt) == b;

/// Source scores do not affect people aggregates. Keep complete local rows so
/// drill-down titles, posters and notes still follow library edits.
class _InsightTitles extends Notifier<List<RatedTitle>> {
  _InsightTitles(this.kind);

  final WorkKind? kind;

  @override
  List<RatedTitle> build() {
    final all = ref.watch(ratedTitlesProvider).value ?? const <RatedTitle>[];
    return kind == null
        ? all
        : all.where((title) => title.work.kind == kind).toList();
  }

  @override
  bool updateShouldNotify(List<RatedTitle> previous, List<RatedTitle> next) {
    if (previous.length != next.length) return true;
    for (var i = 0; i < next.length; i++) {
      final a = previous[i];
      final b = next[i];
      if (a.rating != b.rating ||
          !_sameSnapshot(a.work, b.work) ||
          !_sameSnapshot(a.series, b.series) ||
          !_sameSnapshot(a.season, b.season)) {
        return true;
      }
    }
    return false;
  }
}

final _insightTitlesProvider = NotifierProvider.autoDispose
    .family<_InsightTitles, List<RatedTitle>, WorkKind?>(_InsightTitles.new);

final _creditPayloadProvider = FutureProvider.autoDispose((ref) {
  final entries = ref.watch(peopleIndexProvider.select((s) => s.entries));
  return sharedPeopleCreditPayload(entries, active: () => ref.mounted);
});

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
      final titles = ref.watch(_insightTitlesProvider(kind));
      final entries = ref.watch(peopleIndexProvider.select((s) => s.entries));
      final input = (titles, entries);
      if (!insightsNeedWorker(titles, entries)) return _analyze(input);
      final worker = ref.watch(_workerProvider(kind));
      final payload = ref.watch(_creditPayloadProvider.future);
      return payload.then((entries) async {
        if (!ref.mounted || entries == null) return emptyLibraryInsights;
        return await worker.run((titles, entries)) ?? emptyLibraryInsights;
      });
    });
