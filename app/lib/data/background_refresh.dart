import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_source.dart';
import 'db/database.dart';
import 'db/database_provider.dart';
import 'ratings_service.dart';
import 'source_failure.dart';
import 'work_key.dart';

/// Refreshes the external ratings of rated titles while the app is open, so
/// "My ratings" and the statistics have something to compare with without
/// opening every card (docs/external-sources.md, "Request budget").
///
/// Each pass fills gaps for every source before refreshing stale known
/// answers, one title at a time, with a pause after actual requests. Spending
/// is held to the background ceilings by the service.
final class BackgroundRefresh {
  BackgroundRefresh(
    this._db,
    this._service, {
    this.pause = const Duration(seconds: 3),
  });

  final AppDatabase _db;
  final RatingsService _service;

  /// Between titles that made a request.
  final Duration pause;

  /// The rated titles that need asking, most overdue first.
  Future<List<RatingTarget>> queue({bool missingOnly = false}) async {
    final rated =
        await (_db.select(_db.works).join([
              innerJoin(
                _db.ratings,
                _db.ratings.workKey.equalsExp(_db.works.workKey),
                useColumns: false,
              ),
            ])..where(_db.ratings.deletedAt.isNull()))
            .map((row) => row.readTable(_db.works))
            .get();
    if (rated.isEmpty) return const [];

    // A season or an episode is looked up by its series' imdb id.
    final seriesKeys = {
      for (final work in rated)
        if (work.kind == WorkKind.season || work.kind == WorkKind.episode)
          WorkKey.tv(WorkKey.parse(work.workKey).tmdbId).toString(),
    }.toList();
    final series = <String, Work>{};
    for (var offset = 0; offset < seriesKeys.length; offset += 400) {
      for (final work
          in await (_db.select(_db.works)..where(
                (w) => w.workKey.isIn(seriesKeys.skip(offset).take(400)),
              ))
              .get()) {
        series[work.workKey] = work;
      }
    }
    final rows = <String, List<ExternalRating>>{};
    for (final row
        in await (_db.select(_db.externalRatings).join([
              innerJoin(
                _db.ratings,
                _db.ratings.workKey.equalsExp(_db.externalRatings.workKey),
                useColumns: false,
              ),
            ])..where(_db.ratings.deletedAt.isNull()))
            .map((row) => row.readTable(_db.externalRatings))
            .get()) {
      rows.putIfAbsent(row.workKey, () => []).add(row);
    }

    final due = <(int, String, RatingTarget)>[];
    for (final work in rated) {
      final key = WorkKey.parse(work.workKey);
      final since = _service.backgroundDue(
        key,
        rows[work.workKey] ?? const [],
        missingOnly: missingOnly,
      );
      if (since == null) continue;
      final whole = key.kind == WorkKind.movie || key.kind == WorkKind.tv;
      due.add((
        since,
        work.workKey,
        RatingTarget(
          key: key,
          imdbId: key.kind == WorkKind.season ? null : work.imdbId,
          seriesImdbId: whole
              ? null
              : series[WorkKey.tv(key.tmdbId).toString()]?.imdbId,
        ),
      ));
    }
    due.sort(
      (a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2),
    );
    return [for (final (_, _, target) in due) target];
  }

  /// One pass over [queue]. Ends early without a network (the next pass will
  /// retry), once every source's background budget is spent, or when
  /// [cancelled]. [wait] is the pause; tests pass their own.
  Future<void> run({
    required bool Function() cancelled,
    required Future<void> Function(Duration) wait,
  }) async {
    final budgeted = _service.budgetedSources;
    if (budgeted.isEmpty) return;
    final spent = <ApiSource>{};
    // Fill every source's gaps before refreshing known values. A missing
    // IMDb row must not let a stale Kinopoisk value jump ahead of KP gaps.
    for (final missingOnly in [true, false]) {
      if (cancelled()) return;
      for (final target in await queue(missingOnly: missingOnly)) {
        if (cancelled()) return;
        var requested = false;
        final outcomes = await _service.refresh(
          target,
          background: true,
          missingOnly: missingOnly,
          cancelled: cancelled,
          onRequest: (_) => requested = true,
        );
        if (outcomes.values.contains(SourceFailure.offline)) return;
        for (final MapEntry(key: api, value: failure) in outcomes.entries) {
          if (failure == SourceFailure.limitReached) spent.add(api);
        }
        if (spent.containsAll(budgeted)) return;
        if (requested && !cancelled()) await wait(pause);
      }
    }
  }
}

/// Turned off in widget tests: a pass runs on timers.
final backgroundRefreshEnabledProvider = Provider<bool>((ref) => true);

/// Runs [BackgroundRefresh] passes while the app is in the foreground: a
/// first one shortly after start, then every half hour (a new day brings a
/// new budget; new rated titles wake it without waiting for the interval).
/// A new key rebuilds the loop. State reports whether a pass is active,
/// for the "loaded for N of M" indicator.
class BackgroundRefreshNotifier extends Notifier<bool> {
  static const startDelay = Duration(seconds: 10);
  static const interval = Duration(minutes: 30);

  @override
  bool build() {
    if (!ref.watch(backgroundRefreshEnabledProvider)) return false;
    final service = ref.watch(ratingsServiceProvider);
    if (service.budgetedSources.isEmpty) return false;
    final db = ref.watch(databaseProvider);
    final refresh = BackgroundRefresh(db, service);
    final sleeper = _Sleeper();
    var foreground = _isForeground(WidgetsBinding.instance.lifecycleState);
    final lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        foreground = _isForeground(state);
        sleeper.wake();
      },
    );
    var cancelled = false;
    var changed = false;
    List<String>? previousKeys;
    final libraryChanges =
        (db.selectOnly(db.ratings)
              ..addColumns([db.ratings.workKey])
              ..where(db.ratings.deletedAt.isNull())
              ..orderBy([OrderingTerm.asc(db.ratings.workKey)]))
            .map((row) => row.read(db.ratings.workKey)!)
            .watch()
            .listen(
              (keys) {
                if (cancelled) return;
                if (previousKeys != null && !listEquals(previousKeys, keys)) {
                  changed = true;
                  sleeper.wake();
                }
                previousKeys = keys;
              },
              // This optional listener must not terminate normal scheduled
              // retries after a local storage failure.
              onError: (Object _) {},
            );
    ref.onDispose(() {
      cancelled = true;
      unawaited(libraryChanges.cancel());
      lifecycle.dispose();
      sleeper.wake();
    });
    bool takeChanges() {
      final pending = changed;
      changed = false;
      return pending;
    }

    unawaited(
      _loop(refresh, sleeper, () => cancelled, () => foreground, takeChanges),
    );
    return false;
  }

  Future<void> _loop(
    BackgroundRefresh refresh,
    _Sleeper sleeper,
    bool Function() cancelled,
    bool Function() foreground,
    bool Function() takeChanges,
  ) async {
    await sleeper.sleep(foreground() ? startDelay : null);
    while (!cancelled()) {
      if (!foreground()) {
        // Woken by the app coming back.
        await sleeper.sleep();
        continue;
      }
      state = true;
      takeChanges();
      try {
        await refresh.run(
          cancelled: () => cancelled() || !foreground(),
          wait: sleeper.sleep,
        );
      } on Exception {
        // Optional refresh must survive a transient local read/write failure.
        // Retry on the normal schedule rather than ending the unawaited loop.
      } finally {
        if (!cancelled()) state = false;
      }
      if (cancelled()) return;
      if (foreground() && !takeChanges()) await sleeper.sleep(interval);
    }
  }

  static bool _isForeground(AppLifecycleState? state) =>
      state == null || state == AppLifecycleState.resumed;
}

final backgroundRefreshProvider =
    NotifierProvider<BackgroundRefreshNotifier, bool>(
      BackgroundRefreshNotifier.new,
    );

/// A pause that can be cut short: by the app returning to the foreground, or
/// by the loop being cancelled.
final class _Sleeper {
  Completer<void>? _waiting;
  Timer? _timer;

  Future<void> sleep([Duration? duration]) {
    wake();
    final waiting = _waiting = Completer<void>();
    if (duration != null) _timer = Timer(duration, wake);
    return waiting.future;
  }

  void wake() {
    _timer?.cancel();
    _timer = null;
    final waiting = _waiting;
    _waiting = null;
    if (waiting != null && !waiting.isCompleted) waiting.complete();
  }
}
