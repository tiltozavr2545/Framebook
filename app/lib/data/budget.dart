import 'api_source.dart';

/// A source's daily limit and how it is split (docs/external-sources.md,
/// "Request budget").
///
/// `api_budget` keeps one counter per source, so the split is done with
/// ceilings on that shared counter: background refresh runs only while less
/// than [background] is spent, requests from an open card while less than
/// `daily - reserve`. Background never eats more than its share, and the card
/// keeps at least `daily - reserve - background`.
final class ApiQuota {
  const ApiQuota({
    required this.daily,
    required this.reserve,
    required this.background,
  });

  /// The service's free daily limit.
  final int daily;

  /// Never spent: the service's day and our UTC day may not line up.
  final int reserve;

  /// Ceiling for background refresh (Stage 4).
  final int background;

  int get interactiveCeiling => daily - reserve;

  /// `null` for a source without a daily limit (TMDB).
  static ApiQuota? of(ApiSource source) => switch (source) {
    ApiSource.tmdb => null,
    ApiSource.poiskkino => const ApiQuota(
      daily: 200,
      reserve: 20,
      background: 60,
    ),
    ApiSource.omdb => const ApiQuota(
      daily: 1000,
      reserve: 100,
      background: 300,
    ),
  };
}
