import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/ratings_preferences.dart';
import '../../data/latest_worker.dart';
import '../../data/view_computer.dart';
import '../../data/library/library.dart';
import '../../data/library/rating_days.dart';

typedef RatingsInput = (List<RatedTitle>, RatingsListView);

class RatingsPageData {
  RatingsPageData(RatingsInput input) : all = input.$1, view = input.$2 {
    shown = arrangeRatings(
      all,
      kind: view.kind,
      sort: view.sort,
      compareWith: view.compareWith,
      order: view.order,
    );
    items = view.sort == RatingsSort.scoredAt
        ? ratingDayItems(shown)
        : [for (final title in shown) RatingItem(title)];
  }
  final List<RatedTitle> all;
  final RatingsListView view;
  late final List<RatedTitle> shown;
  late final List<RatingListItem> items;
}

RatingsPageData prepareRatings(RatingsInput input) => RatingsPageData(input);
final _workerProvider = Provider.autoDispose((ref) {
  final computer = ref.watch(viewComputerProvider);
  final worker = LatestWorker<RatingsInput, RatingsPageData>(
    (input) => computer.run(prepareRatings, input, 'ratings view'),
  );
  ref.onDispose(worker.dispose);
  return worker;
});

class _RatingsData extends AsyncNotifier<RatingsPageData?> {
  @override
  FutureOr<RatingsPageData?> build() {
    final all = ref.watch(ratedTitlesProvider).value;
    final view = ref.watch(ratingsViewProvider);
    if (all == null) return null;
    final input = (all, view);
    if (all.length <= 200) return prepareRatings(input);
    return ref.watch(_workerProvider).run(input);
  }
}

final ratingsPageDataProvider =
    AsyncNotifierProvider.autoDispose<_RatingsData, RatingsPageData?>(
      _RatingsData.new,
    );
