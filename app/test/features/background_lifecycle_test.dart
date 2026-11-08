import 'dart:async';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/background_refresh.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/sources/omdb/omdb_client.dart';
import 'package:framebook/data/work_key.dart';

import '../support/api_fixtures.dart';
import '../support/fake_http.dart';

class _PendingOmdb implements OmdbApi {
  final requested = Completer<void>();
  final result = Completer<OmdbRatings?>();

  @override
  Future<OmdbRatings?> byImdbId(String id) {
    requested.complete();
    return result.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FailingRead extends QueryInterceptor {
  bool failNext = false;
  int failures = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (failNext) {
      failNext = false;
      failures++;
      return Future.error(
        const FormatException('Transient local read failure'),
      );
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  testWidgets('a failed local read does not terminate background refresh', (
    tester,
  ) async {
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    final reads = _FailingRead();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(reads));
    final adapter = FakeHttpAdapter(apiFixtures);
    final dio = createDio()..httpClientAdapter = adapter;
    await tester.runAsync(
      () => Library(db, deviceId: 'test').rate(
        const [
          WorkSnapshot(
            key: WorkKey.movie(603),
            tmdbId: 603,
            title: 'Matrix',
            imdbId: 'tt0133093',
          ),
        ],
        scoreHalf: 16,
        note: null,
      ),
    );
    final container = ProviderContainer(
      overrides: [
        databaseProvider.overrideWithValue(db),
        ratingsServiceProvider.overrideWithValue(
          RatingsService(db, omdb: OmdbClient(dio, 'test-key')),
        ),
      ],
    );
    try {
      reads.failNext = true;
      container.listen(backgroundRefreshProvider, (_, _) {});
      await tester.pump(BackgroundRefreshNotifier.startDelay);
      for (var i = 0; i < 50 && reads.failures == 0; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      await tester.pump();
      expect(reads.failures, 1);
      expect(container.read(backgroundRefreshProvider), isFalse);
      expect(adapter.requests, isEmpty);
      expect(tester.takeException(), isNull);
      await tester.pump(BackgroundRefreshNotifier.interval);
      for (var i = 0; i < 100 && adapter.requests.isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
        await tester.pump();
      }
      expect(adapter.requests, hasLength(1));
    } finally {
      container.dispose();
      await tester.pump(const Duration(hours: 1));
      await tester.runAsync(db.close);
      dio.close(force: true);
    }
    expect(tester.takeException(), isNull);
  });

  for (final rebuild in [false, true]) {
    testWidgets(
      rebuild
          ? 'a replaced service leaves no timer after its active pass completes'
          : 'disposal during an active pass leaves no timer',
      (tester) async {
        tester.binding.handleAppLifecycleStateChanged(
          AppLifecycleState.resumed,
        );
        final db = AppDatabase(NativeDatabase.memory());
        final api = _PendingOmdb();
        await tester.runAsync(
          () => Library(db, deviceId: 'test').rate(
            [
              const WorkSnapshot(
                key: WorkKey.movie(1),
                tmdbId: 1,
                title: 'Film',
                imdbId: 'tt1',
              ),
            ],
            scoreHalf: 16,
            note: null,
          ),
        );
        final service = RatingsService(db, omdb: api);
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            ratingsServiceProvider.overrideWithValue(service),
          ],
        );
        container.listen(backgroundRefreshProvider, (_, _) {});
        await tester.pump(BackgroundRefreshNotifier.startDelay);
        for (var i = 0; i < 100 && !api.requested.isCompleted; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
          await tester.pump();
        }
        expect(api.requested.isCompleted, isTrue);
        if (rebuild) {
          container.updateOverrides([
            databaseProvider.overrideWithValue(db),
            ratingsServiceProvider.overrideWithValue(RatingsService(db)),
          ]);
          await tester.pump();
        } else {
          container.dispose();
        }
        api.result.complete(null);
        // Let fake-zone continuations and real SQLite IO both finish.
        for (var i = 0; i < 20; i++) {
          await tester.pump();
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 10)),
          );
        }
        await tester.pump();
        if (rebuild) container.dispose();
        await tester.pump();
        // Do not advance half an hour: the test must detect a retained timer.
        expect(tester.binding.transientCallbackCount, 0);
        await tester.runAsync(db.close);
      },
    );
  }

  for (final resume in [true, false]) {
    testWidgets(
      resume
          ? 'background refresh waits while paused and starts on resume'
          : 'disposing background refresh cancels its startup timer',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final adapter = FakeHttpAdapter(apiFixtures);
        final dio = createDio()..httpClientAdapter = adapter;
        await tester.runAsync(
          () => Library(db, deviceId: 'test').rate(
            const [
              WorkSnapshot(
                key: WorkKey.movie(603),
                tmdbId: 603,
                title: 'Matrix',
                imdbId: 'tt0133093',
              ),
            ],
            scoreHalf: 16,
            note: null,
          ),
        );
        final container = ProviderContainer(
          overrides: [
            databaseProvider.overrideWithValue(db),
            ratingsServiceProvider.overrideWithValue(
              RatingsService(db, omdb: OmdbClient(dio, 'test-key')),
            ),
          ],
        );
        try {
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.paused,
          );
          final states = <bool>[];
          container.listen(
            backgroundRefreshProvider,
            (_, next) => states.add(next),
            fireImmediately: true,
          );
          if (resume) {
            await tester.pump(BackgroundRefreshNotifier.startDelay);
            expect(adapter.requests, isEmpty);
            expect(states, [false]);
            for (final state in [
              AppLifecycleState.hidden,
              AppLifecycleState.inactive,
              AppLifecycleState.resumed,
            ]) {
              tester.binding.handleAppLifecycleStateChanged(state);
            }
            await tester.pump(const Duration(milliseconds: 10));
            for (var i = 0; i < 50 && adapter.requests.isEmpty; i++) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(milliseconds: 10)),
              );
              await tester.pump(const Duration(milliseconds: 10));
            }
            expect(
              adapter.requests,
              hasLength(1),
              reason:
                  'states: $states; lifecycle: ${tester.binding.lifecycleState}',
            );
            expect(adapter.requests.single.uri.host, 'www.omdbapi.com');
            expect(states, contains(true));
          }
        } finally {
          container.dispose();
          await tester.pump(const Duration(hours: 1));
          tester.binding.handleAppLifecycleStateChanged(
            AppLifecycleState.resumed,
          );
          await tester.runAsync(db.close);
          dio.close(force: true);
        }
        if (!resume) expect(adapter.requests, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
