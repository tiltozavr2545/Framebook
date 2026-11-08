import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_source.dart';
import '../data/library/divergence.dart';
import '../data/library/library.dart';
import '../data/work_key.dart';
import 'preferences.dart';
import 'preference_writes.dart';

/// The chosen filter and order of "My ratings". Kept while the app is open;
/// the source to compare with is remembered across launches
/// (docs/data-model.md, "Outside the database").
typedef RatingsListView = ({
  WorkKind? kind,
  RatingsSort sort,
  RatingSource compareWith,
  DivergenceOrder order,
});

const _compareWithKey = 'divergence_source';

class RatingsListViewNotifier extends Notifier<RatingsListView> {
  late PreferenceWrites<RatingSource> _writes;
  @override
  RatingsListView build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_compareWithKey);
    final source = compareSources.firstWhere(
      (s) => s.name == stored,
      orElse: () => RatingSource.kp,
    );
    _writes = PreferenceWrites(source);
    return (
      kind: null,
      sort: RatingsSort.scoredAt,
      compareWith: source,
      order: DivergenceOrder.furthest,
    );
  }

  void filter(WorkKind? kind) => state = (
    kind: kind,
    sort: state.sort,
    compareWith: state.compareWith,
    order: state.order,
  );

  void sortBy(RatingsSort sort) => state = (
    kind: state.kind,
    sort: sort,
    compareWith: state.compareWith,
    order: state.order,
  );

  Future<void> compareWith(RatingSource source) {
    final prefs = ref.read(sharedPreferencesProvider);
    final writes = _writes;
    state = (
      kind: state.kind,
      sort: state.sort,
      compareWith: source,
      order: state.order,
    );
    return writes.save(
      source,
      () => prefs.setString(_compareWithKey, source.name),
      (saved) {
        if (ref.mounted && identical(writes, _writes)) {
          state = (
            kind: state.kind,
            sort: state.sort,
            compareWith: saved,
            order: state.order,
          );
        }
      },
    );
  }

  void orderBy(DivergenceOrder order) => state = (
    kind: state.kind,
    sort: state.sort,
    compareWith: state.compareWith,
    order: order,
  );
}

final ratingsViewProvider =
    NotifierProvider<RatingsListViewNotifier, RatingsListView>(
      RatingsListViewNotifier.new,
    );
