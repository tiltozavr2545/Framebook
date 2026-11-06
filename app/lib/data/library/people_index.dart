import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../../app/foreground.dart';
import '../response_cache.dart';
import '../source_failure.dart';
import '../sources/providers.dart';
import '../sources/tmdb/tmdb_models.dart';
import 'library.dart';

String peopleIdentity(RatedTitle title) =>
    '${title.work.workKey}@${title.work.tmdbId}';

final class PeopleIndexState {
  const PeopleIndexState({
    this.entries = const {},
    this.running = false,
    this.total = 0,
    this.failed = 0,
  });
  final Map<String, List<PeopleCredit>> entries;
  final bool running;
  final int total;
  final int failed;
}

final peopleIndexProvider =
    NotifierProvider.autoDispose<PeopleIndex, PeopleIndexState>(
      PeopleIndex.new,
    );

/// A bounded pass loads disk entries first, then at most four catalog requests
/// at once. Only compact derived credits live in the evictable cache, never
/// in the database or sync. A large library can continue on the next pass.
class PeopleIndex extends Notifier<PeopleIndexState> {
  int _generation = 0;
  bool _pending = false;
  String _inputIdentity = '';

  String _identities(List<RatedTitle> titles) =>
      (titles.map(peopleIdentity).toList()..sort()).join(',');

  @override
  PeopleIndexState build() {
    final generation = ++_generation;
    _pending = false;
    _inputIdentity = '';
    ref.watch(tmdbProvider);
    ref.watch(contentLanguageProvider);
    ref.onDispose(() => _generation++);
    ref.listen(foregroundProvider, (previous, next) {
      if (next && previous == false) {
        scheduleMicrotask(() {
          if (generation != _generation) return;
          if (state.running) {
            _pending = true;
          } else {
            unawaited(load());
          }
        });
      }
    });
    ref.listen(ratedTitlesProvider, (previous, next) {
      if (next.value != null &&
          _identities(previous?.value ?? []) != _identities(next.value!)) {
        scheduleMicrotask(() {
          if (generation != _generation) return;
          final latest = ref.read(ratedTitlesProvider).value;
          if (latest == null || _identities(latest) == _inputIdentity) return;
          if (state.running) {
            _pending = true;
          } else {
            unawaited(load());
          }
        });
      }
    });
    scheduleMicrotask(() {
      if (generation == _generation) unawaited(load());
    });
    return const PeopleIndexState();
  }

  Future<void> load() async {
    if (state.running || !ref.read(foregroundProvider)) return;
    final generation = _generation;
    final tmdb = ref.read(tmdbProvider);
    final cache = ref.read(responseCacheProvider);
    final language = ref.read(contentLanguageProvider);
    final titlesFuture = ref.read(ratedTitlesProvider.future);
    var entries = {...state.entries};
    state = PeopleIndexState(
      entries: state.entries,
      running: true,
      total: state.total,
    );
    bool current() => generation == _generation;
    try {
      final titles = await titlesFuture;
      if (!current()) return;
      _inputIdentity = _identities(titles);
      _pending = false;
      final identities = titles.map(peopleIdentity).toSet();
      var dirty = entries.keys.any((key) => !identities.contains(key));
      entries.removeWhere((key, _) => !identities.contains(key));
      var failures = 0;
      final publishClock = Stopwatch()..start();
      var lastPublished = const Duration(milliseconds: -100);
      Map<String, List<PeopleCredit>> snapshot = state.entries;
      void publish({bool running = true}) {
        if (current()) {
          if (running &&
              publishClock.elapsed - lastPublished <
                  const Duration(milliseconds: 100)) {
            return;
          }
          lastPublished = publishClock.elapsed;
          if (dirty) {
            snapshot = Map.unmodifiable(entries);
            dirty = false;
          }
          state = PeopleIndexState(
            entries: snapshot,
            running: running,
            total: titles.length,
            failed: failures,
          );
        }
      }

      String cacheKey(RatedTitle t) =>
          'people-index:v2:$language:${peopleIdentity(t)}';
      var cursor = 0;
      Future<void> diskWorker() async {
        while (current() && cursor < titles.length) {
          final title = titles[cursor++];
          final identity = peopleIdentity(title);
          if (entries.containsKey(identity)) continue;
          final cached = await cache.read(cacheKey(title));
          if (cached == null) continue;
          try {
            final raw = jsonDecode(cached.body) as List<Object?>;
            entries[identity] = [
              for (final item in raw)
                PeopleCredit.fromCache(item as Map<String, Object?>),
            ];
            dirty = true;
          } on Object {
            // A damaged cache is a miss, not a failed statistics screen.
          }
        }
      }

      await Future.wait(List.generate(4, (_) => diskWorker()));
      if (!current()) return;
      publish();
      final missing = titles
          .where((t) => !entries.containsKey(peopleIdentity(t)))
          .toList();
      cursor = 0;
      var stopNetwork = false;
      final elapsed = Stopwatch()..start();
      Future<void> networkWorker() async {
        while (current() &&
            ref.read(foregroundProvider) &&
            !stopNetwork &&
            cursor < missing.length &&
            cursor < 80 &&
            elapsed.elapsed < const Duration(seconds: 45)) {
          final title = missing[cursor++];
          try {
            final people = await tmdb
                .peopleCredits(title.key, title.work.tmdbId)
                .timeout(const Duration(seconds: 10));
            if (!current() || !ref.read(foregroundProvider)) return;
            entries[peopleIdentity(title)] = people;
            dirty = true;
            await cache.write(
              cacheKey(title),
              CachedResponse(
                jsonEncode([for (final p in people) p.toJson()]),
                DateTime.now().toUtc().millisecondsSinceEpoch,
              ),
            );
          } on Object catch (error) {
            failures++;
            if (error is TimeoutException ||
                error is SourceException &&
                    (error.failure == SourceFailure.offline ||
                        error.failure == SourceFailure.unauthorized ||
                        error.failure == SourceFailure.limitReached)) {
              stopNetwork = true;
            }
          }
          publish();
        }
      }

      await Future.wait(List.generate(4, (_) => networkWorker()));
      publish(running: false);
    } on Object {
      if (current()) {
        state = PeopleIndexState(
          entries: Map.unmodifiable(entries),
          total: state.total,
          failed: 1,
        );
      }
    } finally {
      if (current() && _pending) {
        _pending = false;
        unawaited(load());
      }
    }
  }
}
