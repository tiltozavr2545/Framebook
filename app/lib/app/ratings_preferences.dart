import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/api_source.dart';
import '../data/library/divergence.dart';
import '../data/library/library.dart';
import '../data/work_key.dart';
import 'preferences.dart';

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
  @override
  RatingsListView build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_compareWithKey);
    return (
      kind: null,
      sort: RatingsSort.scoredAt,
      compareWith: compareSources.firstWhere(
        (s) => s.name == stored,
        orElse: () => RatingSource.kp,
      ),
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

  Future<void> compareWith(RatingSource source) async {
    state = (
      kind: state.kind,
      sort: state.sort,
      compareWith: source,
      order: state.order,
    );
    await ref
        .read(sharedPreferencesProvider)
        .setString(_compareWithKey, source.name);
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
