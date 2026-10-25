import 'dart:async';

import 'package:drift/drift.dart';
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
/// One pass goes through a queue — titles with no rating at all first, then
/// the oldest — one title at a time, with a pause after every one that cost
/// a request. Spending is held to the background ceilings by the service.
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
  Future<List<RatingTarget>> queue() async {
    final rated =
        await (_db.select(_db.works).join([
              innerJoin(
                _db.ratings,
                _db.ratings.workKey.equalsExp(_db.works.workKey),
              ),
            ])..where(_db.ratings.deletedAt.isNull()))
            .map((row) => row.readTable(_db.works))
            .get();
    if (rated.isEmpty) return const [];

    // A season or an episode is looked up by its series' imdb id.
    final series = {
      for (final work in await (_db.select(
        _db.works,
      )..where((w) => w.kind.equalsValue(WorkKind.tv))).get())
        work.workKey: work,
    };
    final rows = <String, List<ExternalRating>>{};
    for (final row
        in await (_db.select(_db.externalRatings).join([
              innerJoin(
                _db.ratings,
                _db.ratings.workKey.equalsExp(_db.externalRatings.workKey),
              ),
            ])..where(_db.ratings.deletedAt.isNull()))
            .map((row) => row.readTable(_db.externalRatings))
            .get()) {
      rows.putIfAbsent(row.workKey, () => []).add(row);
    }

    final due = <(int, String, RatingTarget)>[];
    for (final work in rated) {
      final key = WorkKey.parse(work.workKey);
      final since = _service.backgroundDue(key, rows[work.workKey] ?? const []);
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
    for (final target in await queue()) {
      if (cancelled()) return;
      var requested = false;
      final outcomes = await _service.refresh(
        target,
        background: true,
        onDone: (api, failure) {
          if (failure != SourceFailure.limitReached) requested = true;
        },
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

/// Turned off in widget tests: a pass runs on timers.
final backgroundRefreshEnabledProvider = Provider<bool>((ref) => true);

/// Runs [BackgroundRefresh] passes while the app is in the foreground: a
/// first one shortly after start, then every half hour (a new day brings a
/// new budget; a new key restarts it at once). The state is whether a pass
/// is going on now — for the "loaded for N of M" indicator.
class BackgroundRefreshNotifier extends Notifier<bool> {
  static const startDelay = Duration(seconds: 10);
  static const interval = Duration(minutes: 30);

  @override
  bool build() {
    if (!ref.watch(backgroundRefreshEnabledProvider)) return false;
    final refresh = BackgroundRefresh(
      ref.watch(databaseProvider),
      ref.watch(ratingsServiceProvider),
    );
    final sleeper = _Sleeper();
    var foreground = _isForeground(WidgetsBinding.instance.lifecycleState);
    final lifecycle = AppLifecycleListener(
      onStateChange: (state) {
        foreground = _isForeground(state);
        if (foreground) sleeper.wake();
      },
    );
    var cancelled = false;
    ref.onDispose(() {
      cancelled = true;
      lifecycle.dispose();
      sleeper.wake();
    });
    unawaited(_loop(refresh, sleeper, () => cancelled, () => foreground));
    return false;
  }

  Future<void> _loop(
    BackgroundRefresh refresh,
    _Sleeper sleeper,
    bool Function() cancelled,
    bool Function() foreground,
  ) async {
    await sleeper.sleep(startDelay);
    while (!cancelled()) {
      if (!foreground()) {
        // Woken by the app coming back.
        await sleeper.sleep(interval);
        continue;
      }
      state = true;
      try {
        await refresh.run(
          cancelled: () => cancelled() || !foreground(),
          wait: sleeper.sleep,
        );
      } finally {
        if (!cancelled()) state = false;
      }
      await sleeper.sleep(interval);
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

  Future<void> sleep(Duration duration) {
    wake();
    final waiting = _waiting = Completer<void>();
    _timer = Timer(duration, wake);
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
