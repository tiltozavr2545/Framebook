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

void main() {
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
