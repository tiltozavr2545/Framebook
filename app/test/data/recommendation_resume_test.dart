import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/foreground.dart';
import 'package:framebook/data/recommendations/candidates.dart';
import 'package:framebook/data/recommendations/profile.dart';
import 'package:framebook/data/recommendations/providers.dart';
import 'package:framebook/data/sources/providers.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

import 'insights_test.dart' show rated;
import 'recommendations_test.dart' show title;

class _Foreground extends Foreground {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

class _Api implements TmdbApi {
  int calls = 0;
  Completer<void>? barrier;
  @override
  Future<List<TitleSummary>> recommendations(WorkKey key) async {
    calls++;
    return [title(2)];
  }

  @override
  Future<List<TitleSummary>> discoverRecommendations(
    WorkKind kind, {
    int? genre,
  }) async {
    await barrier?.future;
    return [];
  }

  @override
  Future<List<TitleSummary>> trending() async => [];
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final interrupted in [false, true]) {
    test(
      'recommendations survive resume without empty batches or refetch: interrupted=$interrupted',
      () async {
        final api = _Api();
        var now = DateTime(2026, 11, 6);
        if (interrupted) api.barrier = Completer<void>();
        final container = ProviderContainer(
          overrides: [
            foregroundProvider.overrideWith(_Foreground.new),
            tmdbProvider.overrideWithValue(api),
            recommendationClockProvider.overrideWithValue(() => now),
            recommendationPlanProvider.overrideWith(
              (ref) => RecommendationPlan(
                profile: TasteProfile(tasteSignals([rated(1, 18)], {})),
                favorites: {},
                watchlist: {},
                now: ref.watch(recommendationClockProvider)(),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        final values = <RecommendationPool>[];
        container.listen(recommendationPoolProvider, (_, next) {
          if (next.value case final value?) values.add(value);
        });
        await pumpEventQueue();
        expect(values.last.candidates.map((c) => c.title.key), [
          const WorkKey.movie(2),
        ]);
        expect(values.last.running, interrupted);
        values.clear();
        final foreground =
            container.read(foregroundProvider.notifier) as _Foreground;
        foreground.set(false);
        api.barrier?.complete();
        await pumpEventQueue();
        foreground.set(true);
        await pumpEventQueue();
        expect(values.any((pool) => pool.candidates.isEmpty), isFalse);
        expect(
          container.read(recommendationPoolProvider).value!.candidates,
          hasLength(1),
        );
        expect(api.calls, 1);
        now = now.add(const Duration(days: 1));
        foreground.set(false);
        await pumpEventQueue();
        foreground.set(true);
        await pumpEventQueue();
        expect(api.calls, 2, reason: 'A new day must refresh the daily plan');
      },
    );
  }
}
