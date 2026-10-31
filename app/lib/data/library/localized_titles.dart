import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../background_refresh.dart';
import '../db/database_provider.dart';
import '../source_failure.dart';
import '../sources/providers.dart';
import '../sync/sync_controller.dart';
import '../sync/sync_store.dart';
import '../work_key.dart';
import 'library.dart';

/// Refresh saved titles in the selected language, using the normal TMDB cache.
final localizedTitlesProvider = Provider<void>((ref) {
  if (!ref.watch(backgroundRefreshEnabledProvider)) return;
  final tmdb = ref.watch(tmdbProvider);
  final library = ref.watch(libraryProvider);
  final store = SyncStore(ref.watch(databaseProvider));
  var active = true;
  var running = false;
  var again = false;

  Future<void> refresh() async {
    if (running) {
      again = true;
      return;
    }
    running = true;
    try {
      do {
        again = false;
        final state = await store.read();
        final live = <String>{
          for (final row in state.ratings)
            if (row.deletedAt == null) row.workKey,
          for (final row in state.watchlist)
            if (row.deletedAt == null) row.workKey,
        };
        final wanted = <String>{
          for (final key in live)
            for (final part in WorkKey.parse(key).lineage) part.toString(),
        };
        final works = {
          for (final work in state.works)
            if (wanted.contains(work.workKey)) work.workKey: work,
        };
        Future<void> save(WorkKey key, String? title, int? currentId) async {
          final old = works[key.toString()];
          if (!active ||
              old == null ||
              title == null ||
              (old.tmdbId != key.tmdbId && old.tmdbId != currentId)) {
            return;
          }
          await library.refreshLocalizedTitle(
            key,
            title,
            old.tmdbId,
            () => active,
          );
        }

        for (final work in works.values.where(
          (w) => w.kind == WorkKind.movie || w.kind == WorkKind.tv,
        )) {
          if (!active) return;
          final key = WorkKey.parse(work.workKey);
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
              final seasons = works.values
                  .where(
                    (w) =>
                        w.kind == WorkKind.episode &&
                        WorkKey.parse(w.workKey).tmdbId == key.tmdbId,
                  )
                  .map((w) => WorkKey.parse(w.workKey).season!)
                  .toSet();
              for (final number in seasons) {
                if (!active) return;
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
      } while (active && again);
    } finally {
      running = false;
    }
  }

  ref.listen(syncControllerProvider.select((s) => s.lastSyncAt), (old, next) {
    if (next != null && next != old) unawaited(refresh());
  });
  final lifecycle = AppLifecycleListener(onResume: () => unawaited(refresh()));
  ref.onDispose(() {
    active = false;
    lifecycle.dispose();
  });
  scheduleMicrotask(() {
    if (active) unawaited(refresh());
  });
});
