import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/foreground.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/response_cache.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/providers.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

import '../support/api_fixtures.dart';
import 'insights_test.dart' show rated;

class _Foreground extends Foreground {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

class _Api implements TmdbApi {
  final calls = <int>[];
  int active = 0, mostActive = 0;
  Completer<void>? barrier;
  bool offline = false;
  @override
  Future<List<PeopleCredit>> peopleCredits(WorkKey key, int expectedId) async {
    calls.add(expectedId);
    active++;
    if (active > mostActive) mostActive = active;
    try {
      await barrier?.future;
      if (offline) throw const SourceException(SourceFailure.offline);
      return [
        PeopleCredit(
          id: expectedId,
          name: 'Person $expectedId',
          role: FilmographyRole.acting,
        ),
      ];
    } finally {
      active--;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Api api;
  late MemoryResponseCache cache;
  late ProviderContainer container;
  Future<void> waitFor(bool Function() check) async {
    for (var i = 0; i < 1000; i++) {
      if (check()) return;
      await Future<void>.delayed(const Duration(milliseconds: 2));
    }
    fail('People pass did not finish');
  }

  void setup(List<RatedTitle> titles) {
    api = _Api();
    cache = MemoryResponseCache();
    container = ProviderContainer(
      overrides: [
        contentLanguageProvider.overrideWithValue('en-US'),
        foregroundProvider.overrideWith(_Foreground.new),
        tmdbProvider.overrideWithValue(api),
        responseCacheProvider.overrideWithValue(cache),
        ratedTitlesProvider.overrideWith((ref) => Stream.value(titles)),
      ],
    );
    addTearDown(container.dispose);
  }

  test(
    'backgrounding stops enrichment and resume recovers incomplete titles',
    () async {
      setup([for (var id = 1; id <= 20; id++) rated(id, 16)]);
      api.barrier = Completer<void>();
      container.listen(peopleIndexProvider, (_, _) {});
      await waitFor(() => api.calls.length == 4);
      final foreground =
          container.read(foregroundProvider.notifier) as _Foreground;
      foreground.set(false);
      api.barrier!.complete();
      await waitFor(() => !container.read(peopleIndexProvider).running);
      expect(api.calls, hasLength(4));
      expect(container.read(peopleIndexProvider).entries, isEmpty);
      foreground.set(true);
      await waitFor(
        () =>
            container.read(peopleIndexProvider).entries.length == 20 &&
            !container.read(peopleIndexProvider).running,
      );
      expect(api.calls.length, 24);
    },
  );

  test(
    'four parallel requests, bounded batches, cache-first resume without duplicate fetches',
    () async {
      setup([for (var id = 1; id <= 85; id++) rated(id, 16)]);
      api.barrier = Completer<void>();
      container.listen(peopleIndexProvider, (_, _) {});
      await waitFor(() => api.calls.length == 4);
      expect(api.mostActive, 4);
      api.barrier!.complete();
      await waitFor(() => !container.read(peopleIndexProvider).running);
      expect(api.calls.length, 80);
      expect(container.read(peopleIndexProvider).entries.length, 80);
      expect(container.read(peopleIndexProvider).total, 85);
      await container.read(peopleIndexProvider.notifier).load();
      expect(api.calls.length, 85);
      expect(container.read(peopleIndexProvider).entries.length, 85);
      final complete = container.read(peopleIndexProvider).entries;
      await container.read(peopleIndexProvider.notifier).load();
      expect(api.calls.length, 85);
      expect(
        identical(container.read(peopleIndexProvider).entries, complete),
        isTrue,
      );
    },
  );
  test(
    'offline uses valid disk entries and stops scheduling remaining requests',
    () async {
      final titles = [for (var id = 1; id <= 20; id++) rated(id, 16)];
      setup(titles);
      api.offline = true;
      cache.entries['people-index:v1:en-US:${peopleIdentity(titles.first)}'] =
          CachedResponse(
            jsonEncode([
              const PeopleCredit(
                id: 1,
                name: 'Cached',
                role: FilmographyRole.acting,
              ).toJson(),
            ]),
            0,
          );
      // A damaged cache must be retried through the API rather than counted.
      cache.entries['people-index:v1:en-US:${peopleIdentity(titles[1])}'] =
          const CachedResponse('broken', 0);
      container.listen(peopleIndexProvider, (_, _) {});
      await waitFor(
        () =>
            container.read(peopleIndexProvider).total == 20 &&
            !container.read(peopleIndexProvider).running,
      );
      expect(container.read(peopleIndexProvider).entries.length, 1);
      expect(api.calls.length, inInclusiveRange(1, 4));
      expect(api.calls, isNot(contains(1)));
      expect(container.read(peopleIndexProvider).failed, greaterThan(0));
    },
  );
  test(
    'disposal during requests never publishes into a disposed provider',
    () async {
      setup([rated(1, 16)]);
      api.barrier = Completer<void>();
      container.listen(peopleIndexProvider, (_, _) {});
      await waitFor(() => api.calls.isNotEmpty);
      container.dispose();
      api.barrier!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(cache.entries, isEmpty);
    },
  );
}
