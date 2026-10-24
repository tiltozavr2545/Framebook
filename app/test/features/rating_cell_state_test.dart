import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/features/title/title_ratings.dart';

void main() {
  final now = DateTime.utc(2026, 10, 24).millisecondsSinceEpoch;
  const day = 24 * 60 * 60 * 1000;

  ExternalRating row(RatingStatus status, {int ageDays = 0}) => ExternalRating(
    workKey: 'tmdb:movie:603',
    source: RatingSource.kp,
    status: status,
    value: status == RatingStatus.ok ? 8.5 : null,
    scale: 10,
    via: ApiSource.poiskkino,
    fetchedAt: now - ageDays * day,
  );

  RatingCellState state({
    ExternalRating? cached,
    ApiSource? provider = ApiSource.poiskkino,
    bool loading = false,
    SourceFailure? failure,
  }) => ratingCellState(
    source: RatingSource.kp,
    view: RatingsView(
      rows: {if (cached != null) RatingSource.kp: cached},
      loading: {if (loading) ApiSource.poiskkino},
      failures: {if (failure != null) ApiSource.poiskkino: failure},
    ),
    provider: provider,
    nowMillis: now,
  );

  test('a value is shown — while refreshing, and even when stale', () {
    expect(
      state(cached: row(RatingStatus.ok)),
      isA<RatingShown>()
          .having((s) => s.stale, 'stale', isFalse)
          .having((s) => s.refreshing, 'refreshing', isFalse),
    );
    expect(
      state(cached: row(RatingStatus.ok, ageDays: 8), loading: true),
      isA<RatingShown>()
          .having((s) => s.stale, 'stale', isTrue)
          .having((s) => s.refreshing, 'refreshing', isTrue),
    );
  });

  test('a value outlives a failure and a removed key', () {
    expect(
      state(cached: row(RatingStatus.ok), failure: SourceFailure.offline),
      isA<RatingShown>(),
    );
    expect(
      state(cached: row(RatingStatus.ok), provider: null),
      isA<RatingShown>(),
    );
  });

  test('"not found" is no data', () {
    expect(state(cached: row(RatingStatus.notFound)), isA<RatingNoData>());
  });

  test('no key and nothing cached asks for the key of the right source', () {
    expect(
      state(provider: null),
      isA<RatingNeedsKey>().having(
        (s) => s.source,
        'source',
        ApiSource.poiskkino,
      ),
    );
  });

  test('loading, then the failure reason', () {
    expect(state(loading: true), isA<RatingLoading>());
    expect(
      state(failure: SourceFailure.limitReached),
      isA<RatingFailed>().having(
        (s) => s.failure,
        'failure',
        SourceFailure.limitReached,
      ),
    );
    expect(state(cached: row(RatingStatus.error)), isA<RatingFailed>());
  });

  test('the key to add: OMDb for IMDb and Rotten Tomatoes', () {
    expect(RatingsService.keyFor(RatingSource.imdb), ApiSource.omdb);
    expect(RatingsService.keyFor(RatingSource.rt), ApiSource.omdb);
  });
}
