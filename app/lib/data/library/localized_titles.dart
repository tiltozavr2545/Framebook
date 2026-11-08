import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api_keys.dart';
import '../api_source.dart';
import '../background_refresh.dart';
import '../db/database.dart';
import '../db/database_provider.dart';
import '../source_failure.dart';
import '../sources/providers.dart';
import '../sync/sync_controller.dart';
import '../work_key.dart';
import 'library.dart';

final localizedTitlesClockProvider = Provider<DateTime Function()>(
  (ref) => DateTime.now,
);

/// Refresh saved titles in the selected language, using the normal TMDB cache.
final localizedTitlesProvider = Provider<void>((ref) {
  if (!ref.watch(backgroundRefreshEnabledProvider)) return;
  final key = ref.watch(apiKeysProvider.select((keys) => keys[ApiSource.tmdb]));
  if (key == null || key.value.trim().isEmpty) return;
  final tmdb = ref.watch(tmdbProvider);
  final library = ref.watch(libraryProvider);
  final db = ref.watch(databaseProvider);
  final clock = ref.watch(localizedTitlesClockProvider);
  var active = true;
  var running = false;
  var again = false;
  var foreground =
      WidgetsBinding.instance.lifecycleState == null ||
      WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
  final completed = <String, (Work, DateTime)>{};
  bool valid() => active && foreground;

  Future<Map<String, Work>> savedWorks() => db.transaction(() async {
    final keys = await db
        .customSelect(
          'SELECT work_key FROM ratings WHERE deleted_at IS NULL '
          'UNION SELECT work_key FROM watchlist WHERE deleted_at IS NULL',
          readsFrom: {db.ratings, db.watchlist},
        )
        .get();
    final wanted = {
      for (final row in keys)
        for (final part in WorkKey.parse(row.read<String>('work_key')).lineage)
          part.toString(),
    }.toList();
    final works = <String, Work>{};
    for (var offset = 0; offset < wanted.length; offset += 400) {
      for (final work in await (db.select(
        db.works,
      )..where((w) => w.workKey.isIn(wanted.skip(offset).take(400)))).get()) {
        works[work.workKey] = work;
      }
    }
    return works;
  });

  Future<void> refresh() async {
    if (!valid()) return;
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      do {
        again = false;
        final works = await savedWorks();
        completed.removeWhere((key, _) => !works.containsKey(key));
        final groups = <WorkKey, List<Work>>{};
        for (final work in works.values) {
          groups
              .putIfAbsent(WorkKey.parse(work.workKey).lineage.first, () => [])
              .add(work);
        }
        Future<void> save(WorkKey key, String? title, int? currentId) async {
          final old = works[key.toString()];
          if (!valid() ||
              old == null ||
              title == null ||
              title.isEmpty ||
              (old.tmdbId != key.tmdbId && old.tmdbId != currentId)) {
            return;
          }
          if (old.title != title) {
            await library.refreshLocalizedTitle(key, title, old.tmdbId, valid);
          }
          if (valid()) {
            completed[key.toString()] = (old.copyWith(title: title), clock());
          }
        }

        for (final MapEntry(key: key, value: group) in groups.entries) {
          if (!valid()) return;
          if (group.every((candidate) {
            final cached = completed[candidate.workKey];
            return cached != null &&
                cached.$1 == candidate &&
                !clock().isBefore(cached.$2) &&
                clock().difference(cached.$2) < const Duration(days: 1);
          })) {
            continue;
          }
          try {
            if (key.kind == WorkKind.movie) {
              final movie = await tmdb.movie(key.tmdbId);
              await save(key, movie.title, movie.key.tmdbId);
            } else {
              final tv = await tmdb.tv(key.tmdbId);
              await save(key, tv.title, tv.key.tmdbId);
              for (final summary in tv.seasons) {
                await save(summary.key, summary.name, summary.tmdbId);
              }
              final seasons = group
                  .where(
                    (w) =>
                        w.kind == WorkKind.episode &&
                        WorkKey.parse(w.workKey).tmdbId == key.tmdbId,
                  )
                  .map((w) => WorkKey.parse(w.workKey).season!)
                  .toSet();
              for (final number in seasons) {
                if (!valid()) return;
                try {
                  final season = await tmdb.season(key.tmdbId, number);
                  await save(season.key, season.name, season.tmdbId);
                  for (final episode in season.episodes) {
                    await save(episode.key, episode.name, episode.tmdbId);
                  }
                } on SourceException {
                  /* Keep the offline snapshot. */
                }
              }
            }
          } on SourceException {
            /* Keep the offline snapshot. */
          }
        }
      } while (valid() && again);
    } on Exception {
      // Optional title enrichment can retry on the next sync or resume.
      // Local storage failures must not escape an unawaited foreground task.
    } finally {
      running = false;
    }
  }

  ref.listen(syncControllerProvider.select((s) => s.lastSyncAt), (old, next) {
    if (next != null && next != old) unawaited(refresh());
  });
  final lifecycle = AppLifecycleListener(
    onStateChange: (state) {
      foreground = state == AppLifecycleState.resumed;
      if (foreground) unawaited(refresh());
    },
  );
  ref.onDispose(() {
    active = false;
    lifecycle.dispose();
  });
  scheduleMicrotask(() {
    if (active) unawaited(refresh());
  });
});
