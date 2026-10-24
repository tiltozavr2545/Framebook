import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/api_source.dart';
import '../../data/db/database.dart';
import '../../data/db/database_provider.dart';
import '../../data/ratings_service.dart';
import '../../data/source_failure.dart';

/// Ratings of an open card: cached rows and what is going on with each
/// source.
final class RatingsView {
  const RatingsView({
    this.rows = const {},
    this.loading = const {},
    this.failures = const {},
  });

  final Map<RatingSource, ExternalRating> rows;
  final Set<ApiSource> loading;

  /// How the last attempt ended during this visit to the card.
  final Map<ApiSource, SourceFailure> failures;

  RatingsView copyWith({
    Map<RatingSource, ExternalRating>? rows,
    Set<ApiSource>? loading,
    Map<ApiSource, SourceFailure>? failures,
  }) => RatingsView(
    rows: rows ?? this.rows,
    loading: loading ?? this.loading,
    failures: failures ?? this.failures,
  );
}

/// Shows the cache right away and refreshes what is stale in the background
/// (docs/client-architecture.md, "Title card").
class TitleRatings extends Notifier<RatingsView> {
  TitleRatings(this.target);

  final RatingTarget target;

  @override
  RatingsView build() {
    final service = ref.watch(ratingsServiceProvider);
    final rows = ref
        .watch(databaseProvider)
        .watchExternalRatings(target.key.toString())
        .listen(
          (rows) => state = state.copyWith(
            rows: {for (final row in rows) row.source: row},
          ),
        );
    ref.onDispose(rows.cancel);
    unawaited(_refresh(service));
    return const RatingsView();
  }

  Future<void> _refresh(RatingsService service) async {
    // After a rebuild (a key changed) the old run may still be answering;
    // ref.mounted cuts off its callbacks.
    final outcomes = await service.refresh(
      target,
      onStart: (api) {
        if (!ref.mounted) return;
        state = state.copyWith(loading: {...state.loading, api});
      },
      onDone: (api, _) {
        if (!ref.mounted) return;
        state = state.copyWith(loading: {...state.loading}..remove(api));
      },
    );
    if (!ref.mounted) return;
    // The outcomes also include sources the service skipped without a request
    // (a recent failure, no budget left): they need a reason too, not an
    // endless spinner.
    final failures = {...state.failures};
    for (final MapEntry(key: api, value: failure) in outcomes.entries) {
      if (failure == null) {
        failures.remove(api);
      } else {
        failures[api] = failure;
      }
    }
    state = state.copyWith(failures: failures);
  }
}

final titleRatingsProvider = NotifierProvider.autoDispose
    .family<TitleRatings, RatingsView, RatingTarget>(TitleRatings.new);

/// What one rating cell shows.
sealed class RatingCellState {
  const RatingCellState();
}

final class RatingShown extends RatingCellState {
  const RatingShown(this.row, {required this.stale, required this.refreshing});

  final ExternalRating row;

  /// Older than the freshness limit: shown with its date.
  final bool stale;
  final bool refreshing;
}

final class RatingNoData extends RatingCellState {
  const RatingNoData();
}

final class RatingNeedsKey extends RatingCellState {
  const RatingNeedsKey(this.source);

  final ApiSource source;
}

final class RatingLoading extends RatingCellState {
  const RatingLoading();
}

final class RatingFailed extends RatingCellState {
  const RatingFailed(this.failure);

  final SourceFailure failure;
}

/// A pure function so that every combination is checked by a test, not by
/// eye. [provider] is the API answering for the rating now (`null` without a
/// key).
RatingCellState ratingCellState({
  required RatingSource source,
  required RatingsView view,
  required ApiSource? provider,
  required int nowMillis,
}) {
  final row = view.rows[source];
  final refreshing = provider != null && view.loading.contains(provider);
  if (row != null && row.status == RatingStatus.ok) {
    final age = nowMillis - row.fetchedAt;
    return RatingShown(
      row,
      stale: age >= RatingTtl.interactive.inMilliseconds,
      refreshing: refreshing,
    );
  }
  if (row != null && row.status == RatingStatus.notFound) {
    return const RatingNoData();
  }
  if (provider == null) return RatingNeedsKey(RatingsService.keyFor(source));
  if (refreshing) return const RatingLoading();
  final failure = view.failures[provider];
  if (failure != null) return RatingFailed(failure);
  if (row != null && row.status == RatingStatus.error) {
    return const RatingFailed(SourceFailure.failed);
  }
  return const RatingLoading();
}
