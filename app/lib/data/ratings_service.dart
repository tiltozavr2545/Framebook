import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_source.dart';
import 'budget.dart';
import 'db/database.dart';
import 'db/database_provider.dart';
import 'source_failure.dart';
import 'sources/omdb/omdb_client.dart';
import 'sources/poiskkino/poiskkino_client.dart';
import 'sources/providers.dart';
import 'sources/tmdb/tmdb_models.dart';
import 'work_key.dart';

/// What a card knows about a title that its ratings need.
final class RatingTarget {
  const RatingTarget({
    required this.key,
    required this.tmdbVote,
    this.imdbId,
    this.seriesImdbId,
  });

  final WorkKey key;

  /// The TMDB rating comes with the card; there is no separate request.
  final TmdbVote tmdbVote;

  /// The title's own imdb id: a film's, series' or episode's. Seasons have
  /// none.
  final String? imdbId;

  /// The series' imdb id: for a season, and for an episode whose own imdb id
  /// TMDB doesn't know.
  final String? seriesImdbId;

  @override
  bool operator ==(Object other) =>
      other is RatingTarget &&
      other.key == key &&
      other.tmdbVote == tmdbVote &&
      other.imdbId == imdbId &&
      other.seriesImdbId == seriesImdbId;

  @override
  int get hashCode => Object.hash(key, tmdbVote, imdbId, seriesImdbId);
}

/// Lifetimes of `external_ratings` rows (docs/external-sources.md, "Cache and
/// lifetimes").
abstract final class RatingTtl {
  /// An open card asks again when a row is older than this.
  static const interactive = Duration(days: 7);

  /// Background refresh (Stage 4).
  static const background = Duration(days: 14);
  static const notFound = Duration(days: 30);

  /// After a source failure, retry no more often than this.
  static const failure = Duration(hours: 1);
}

/// Gathers external ratings: cache → budget → request
/// (docs/client-architecture.md, "Layers"). Decides where each rating comes
/// from — screens don't know.
final class RatingsService {
  RatingsService(
    this._db, {
    PoiskKinoApi? poiskkino,
    OmdbApi? omdb,
    DateTime Function()? clock,
  }) : _poiskkino = poiskkino,
       _omdb = omdb,
       _clock = clock ?? DateTime.now;

  final AppDatabase _db;

  /// `null` when there is no key.
  final PoiskKinoApi? _poiskkino;
  final OmdbApi? _omdb;
  final DateTime Function() _clock;

  /// Last failure per (work_key, source), UTC ms. Kept in memory, not in the
  /// table: a key change recreates the service, and the retry is needed right
  /// away, not in an hour.
  final _failures = <(String, ApiSource), (SourceFailure, int)>{};
  final _inFlight = <(String, ApiSource), Future<SourceFailure?>>{};

  /// Which ratings a card of this kind shows, in order. OMDb has RT and
  /// Metacritic for films only; Kinopoisk doesn't rate seasons or episodes
  /// (docs/external-sources.md).
  static List<RatingSource> shownFor(WorkKind kind) => switch (kind) {
    WorkKind.movie => const [
      RatingSource.kp,
      RatingSource.imdb,
      RatingSource.tmdb,
      RatingSource.rt,
      RatingSource.metacritic,
    ],
    WorkKind.tv => const [
      RatingSource.kp,
      RatingSource.imdb,
      RatingSource.tmdb,
    ],
    WorkKind.season ||
    WorkKind.episode => const [RatingSource.imdb, RatingSource.tmdb],
  };

  /// Which API answers for a rating with the current keys; `null` means a
  /// key is needed. IMDb comes from OMDb, or, without its key, from PoiskKino
  /// for films and series.
  ApiSource? providerOf(RatingSource source, WorkKind kind) {
    final whole = kind == WorkKind.movie || kind == WorkKind.tv;
    return switch (source) {
      RatingSource.tmdb => ApiSource.tmdb,
      RatingSource.kp =>
        whole && _poiskkino != null ? ApiSource.poiskkino : null,
      RatingSource.imdb when _omdb != null => ApiSource.omdb,
      RatingSource.imdb =>
        whole && _poiskkino != null ? ApiSource.poiskkino : null,
      RatingSource.rt ||
      RatingSource.metacritic => _omdb != null ? ApiSource.omdb : null,
    };
  }

  /// Which key to add for the rating to appear.
  static ApiSource keyFor(RatingSource source) => switch (source) {
    RatingSource.tmdb => ApiSource.tmdb,
    RatingSource.kp => ApiSource.poiskkino,
    RatingSource.imdb ||
    RatingSource.rt ||
    RatingSource.metacritic => ApiSource.omdb,
  };

  /// Refreshes what is stale, within the budget. Results go to
  /// `external_ratings`, and the screen sees them through `watch()`. Returns
  /// the outcome for every source considered: `null` means success.
  Future<Map<ApiSource, SourceFailure?>> refresh(
    RatingTarget target, {
    bool background = false,
    void Function(ApiSource api)? onStart,
    void Function(ApiSource api, SourceFailure? failure)? onDone,
  }) async {
    final key = target.key.toString();
    final now = _clock().toUtc().millisecondsSinceEpoch;
    final existing = {
      for (final row in await _db.externalRatingsFor(key)) row.source: row,
    };

    // TMDB comes from the card that has just loaded, so it is always fresh.
    await _db.putExternalRatings([_tmdbRow(key, target.tmdbVote, now)]);

    final outcomes = <ApiSource, SourceFailure?>{};
    for (final api in const [ApiSource.poiskkino, ApiSource.omdb]) {
      final sources = shownFor(
        target.key.kind,
      ).where((s) => providerOf(s, target.key.kind) == api).toList();
      if (sources.isEmpty) continue;
      // A recent failure goes first: an `error` row in the table doesn't
      // remember it.
      final recent = _failures[(key, api)];
      if (recent != null &&
          now - recent.$2 < RatingTtl.failure.inMilliseconds) {
        outcomes[api] = recent.$1;
        continue;
      }
      if (!sources.any((s) => _stale(existing[s], api, now, background))) {
        continue;
      }

      onStart?.call(api);
      final failure = await (_inFlight[(key, api)] ??=
          _fetch(
            api,
            target,
            sources,
            existing,
            background: background,
          ).whenComplete(() {
            // Not `=>`: remove would return this very Future, and whenComplete
            // would wait for itself.
            _inFlight.remove((key, api));
          }));
      outcomes[api] = failure;
      onDone?.call(api, failure);
    }
    return outcomes;
  }

  bool _stale(ExternalRating? row, ApiSource api, int now, bool background) {
    // A row from another API (IMDb from PoiskKino, and now there is an OMDb
    // key) is as good as no row.
    if (row == null || row.via != api) return true;
    final age = now - row.fetchedAt;
    final ttl = switch (row.status) {
      RatingStatus.ok =>
        background ? RatingTtl.background : RatingTtl.interactive,
      RatingStatus.notFound => RatingTtl.notFound,
      // Failures are retried by the service's memory (`_failures`), not by
      // the table: right after a key change, otherwise in an hour.
      RatingStatus.error => Duration.zero,
    };
    return age >= ttl.inMilliseconds;
  }

  Future<SourceFailure?> _fetch(
    ApiSource api,
    RatingTarget target,
    List<RatingSource> sources,
    Map<RatingSource, ExternalRating> existing, {
    required bool background,
  }) async {
    final key = target.key.toString();
    final nowTime = _clock().toUtc();
    final now = nowTime.millisecondsSinceEpoch;
    final day = AppDatabase.budgetDay(nowTime);
    final quota = ApiQuota.of(api)!;
    final ceiling = background ? quota.background : quota.interactiveCeiling;

    // Nothing to look up by: "no data" without a request or any budget.
    final request = switch (api) {
      ApiSource.poiskkino => _kpRequest(target),
      ApiSource.omdb => _omdbRequest(target),
      ApiSource.tmdb => throw ArgumentError.value(api),
    };
    if (request == null) {
      await _db.putExternalRatings([
        for (final s in sources) _row(key, s, api, now, RatingStatus.notFound),
      ]);
      return null;
    }

    if (!await _db.tryConsumeBudget(api, day, ceiling)) {
      return SourceFailure.limitReached;
    }
    try {
      await _db.putExternalRatings(await request(sources, now));
      _failures.remove((key, api));
      return null;
    } on SourceException catch (e) {
      if (e.failure == SourceFailure.limitReached) {
        await _db.exhaustBudget(api, day, quota.daily);
      }
      // Offline is not the source's answer: retry as soon as there is a
      // network.
      if (e.failure != SourceFailure.offline) {
        _failures[(key, api)] = (e.failure, now);
        // A failure never overwrites an earlier value: a stale rating beats
        // an empty cell. It is written only where there was nothing.
        await _db.putExternalRatings([
          for (final s in sources)
            if (existing[s] == null) _row(key, s, api, now, RatingStatus.error),
        ]);
      }
      return e.failure;
    }
  }

  /// The matching chain (docs/external-sources.md, "Matching ids"): a known
  /// kp id → imdb id → tmdb id with its type. Never by title.
  _Request? _kpRequest(RatingTarget target) {
    final client = _poiskkino;
    final kind = target.key.kind;
    if (client == null || (kind != WorkKind.movie && kind != WorkKind.tv)) {
      return null;
    }
    final isSeries = kind == WorkKind.tv;
    return (sources, now) async {
      final key = target.key.toString();
      final known = await _db.kpIdFor(key);
      final found = known != null
          ? await client.byKpId(known)
          : target.imdbId != null
          ? await client.byImdbId(target.imdbId!, isSeries: isSeries)
          : await client.byTmdbId(target.key.tmdbId, isSeries: isSeries);
      if (found != null && found.kpId != known) {
        await _db.rememberKpId(key, found.kpId);
      }
      return [
        for (final s in sources)
          switch (s) {
            RatingSource.kp => _value(key, s, ApiSource.poiskkino, now, (
              found?.kp,
              found?.kpVotes,
            )),
            _ => _value(key, s, ApiSource.poiskkino, now, (
              found?.imdb,
              found?.imdbVotes,
            )),
          },
      ];
    };
  }

  _Request? _omdbRequest(RatingTarget target) {
    final client = _omdb;
    if (client == null) return null;
    final key = target.key;
    final series = target.seriesImdbId;
    final Future<OmdbRatings?> Function()? single = switch (key.kind) {
      WorkKind.movie || WorkKind.tv when target.imdbId != null =>
        () => client.byImdbId(target.imdbId!),
      WorkKind.episode when target.imdbId != null => () => client.byImdbId(
        target.imdbId!,
      ),
      WorkKind.episode when series != null => () => client.episode(
        series,
        key.season!,
        key.episode!,
      ),
      _ => null,
    };
    if (single != null) {
      return (sources, now) async {
        final found = await single();
        return [
          for (final s in sources)
            _value(key.toString(), s, ApiSource.omdb, now, switch (s) {
              RatingSource.imdb => (found?.imdb, found?.imdbVotes),
              RatingSource.rt => (found?.rottenTomatoes?.toDouble(), null),
              RatingSource.metacritic => (found?.metacritic?.toDouble(), null),
              _ => (null, null),
            }),
        ];
      };
    }
    if (key.kind == WorkKind.season && series != null) {
      return (sources, now) async {
        final average = await client.seasonAverage(series, key.season!);
        return [
          for (final s in sources)
            _value(key.toString(), s, ApiSource.omdb, now, (
              average?.average,
              null,
            )),
        ];
      };
    }
    return null;
  }

  static ExternalRating _tmdbRow(String key, TmdbVote vote, int now) => _value(
    key,
    RatingSource.tmdb,
    ApiSource.tmdb,
    now,
    (vote.average, vote.count),
  );

  static ExternalRating _value(
    String key,
    RatingSource source,
    ApiSource via,
    int now,
    (double?, int?) found,
  ) {
    final (value, votes) = found;
    if (value == null) {
      return _row(key, source, via, now, RatingStatus.notFound);
    }
    return ExternalRating(
      workKey: key,
      source: source,
      status: RatingStatus.ok,
      value: value,
      scale: scaleOf(source),
      votes: votes,
      via: via,
      fetchedAt: now,
    );
  }

  static ExternalRating _row(
    String key,
    RatingSource source,
    ApiSource via,
    int now,
    RatingStatus status,
  ) => ExternalRating(
    workKey: key,
    source: source,
    status: status,
    scale: scaleOf(source),
    via: via,
    fetchedAt: now,
  );

  /// RT is a percentage, Metacritic 0…100, the rest 1…10.
  static int scaleOf(RatingSource source) => switch (source) {
    RatingSource.rt || RatingSource.metacritic => 100,
    RatingSource.kp || RatingSource.imdb || RatingSource.tmdb => 10,
  };
}

/// One request to a source and the rows it produces.
typedef _Request =
    Future<List<ExternalRating>> Function(List<RatingSource> sources, int now);

final ratingsServiceProvider = Provider<RatingsService>(
  (ref) => RatingsService(
    ref.watch(databaseProvider),
    poiskkino: ref.watch(poiskkinoProvider),
    omdb: ref.watch(omdbProvider),
  ),
);
