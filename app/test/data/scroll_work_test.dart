import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/library/insights_provider.dart';
import 'package:framebook/data/recommendations/providers.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';

import 'insights_test.dart' show rated;
import 'recommendation_performance_test.dart' show waitFor;
import 'recommendations_test.dart' show watch;

class _Index extends PeopleIndex {
  @override
  PeopleIndexState build() => const PeopleIndexState();

  void publish(PeopleIndexState next) => state = next;
}

void main() {
  test(
    'watchlist rereads and snapshot timestamps do not invalidate ranking input',
    () async {
      final changes = StreamController<List<WatchlistTitle>>();
      final c = ProviderContainer(
        overrides: [
          watchlistTitlesProvider.overrideWith((ref) => changes.stream),
        ],
      );
      var events = 0;
      final sub = c.listen(recommendationWatchlistProvider, (_, _) => events++);
      changes.add([]);
      await pumpEventQueue();
      expect(events, 0);
      final item = watch(1);
      changes.add([item]);
      await pumpEventQueue();
      expect(events, 1);
      changes.add([
        WatchlistTitle(
          entry: item.entry,
          work: item.work.copyWith(snapshotUpdatedAt: 999),
        ),
      ]);
      await pumpEventQueue();
      expect(events, 1);
      changes.add([
        WatchlistTitle(
          entry: item.entry,
          work: item.work.copyWith(title: 'Changed title'),
        ),
      ]);
      await pumpEventQueue();
      expect(events, 2);
      sub.close();
      c.dispose();
      await changes.close();
    },
  );

  test(
    'large casts and pair products use workers even for one rated series',
    () {
      final titles = [rated(1, 18)];
      final cast = [
        for (var i = 0; i < 300; i++)
          PeopleCredit(id: i + 1, name: 'Actor', role: FilmographyRole.acting),
        for (var i = 0; i < 30; i++)
          PeopleCredit(
            id: i + 1000,
            name: 'Director',
            role: FilmographyRole.directing,
          ),
      ];
      expect(insightsNeedWorker(titles, {'tmdb:movie:1@1': cast}), isTrue);
      expect(
        insightsNeedWorker(titles, {'tmdb:movie:1@1': cast.take(10).toList()}),
        isFalse,
      );
      expect(
        insightsNeedWorker(List.generate(81, (i) => rated(i, 18)), {}),
        isTrue,
      );
    },
  );

  test(
    'a large taste replacement retains the previous profile until ready',
    () async {
      final updates = StreamController<List<RatedTitle>>(sync: true);
      final c = ProviderContainer(
        overrides: [
          ratedTitlesProvider.overrideWith((ref) => updates.stream),
          peopleIndexProvider.overrideWith(_Index.new),
        ],
      );
      final sub = c.listen(tasteProfileProvider, (_, _) {});
      try {
        updates.add([rated(1, 16)]);
        await pumpEventQueue();
        final first = c.read(tasteProfileProvider);
        updates.add(List.generate(81, (i) => rated(i + 1, 18)));
        expect(c.read(tasteProfileProvider), same(first));
        await waitFor(() => c.read(tasteProfileProvider).signals.length == 81);
        expect(c.read(tasteProfileProvider).signals.first.score, 9);
      } finally {
        sub.close();
        c.dispose();
        await updates.close();
      }
    },
  );

  test('partial credit batches do not repeatedly rerank tastes', () async {
    final c = ProviderContainer(
      overrides: [
        ratedTitlesProvider.overrideWith((ref) => Stream.value([rated(1, 18)])),
        peopleIndexProvider.overrideWith(_Index.new),
      ],
    );
    final sub = c.listen(tasteProfileProvider, (_, _) {});
    await pumpEventQueue();
    final index = c.read(peopleIndexProvider.notifier) as _Index;
    Map<String, List<PeopleCredit>> credits(int id) => {
      'tmdb:movie:1@1': [
        PeopleCredit(id: id, name: 'Person $id', role: FilmographyRole.acting),
      ],
    };
    index.publish(PeopleIndexState(entries: credits(1), running: true));
    final first = c.read(tasteProfileProvider);
    expect(first.signals.single.people.single.id, 1);
    index.publish(PeopleIndexState(entries: credits(2), running: true));
    expect(c.read(tasteProfileProvider), same(first));
    index.publish(PeopleIndexState(entries: credits(2)));
    expect(c.read(tasteProfileProvider).signals.single.people.single.id, 2);
    sub.close();
    c.dispose();
  });

  test(
    'external rating and note changes do not rebuild the taste profile',
    () async {
      final updates = StreamController<List<RatedTitle>>();
      final c = ProviderContainer(
        overrides: [
          ratedTitlesProvider.overrideWith((ref) => updates.stream),
          peopleIndexProvider.overrideWith(_Index.new),
        ],
      );
      final subscription = c.listen(tasteProfileProvider, (_, _) {});
      try {
        updates.add([rated(1, 16, imdb: 6)]);
        await pumpEventQueue();
        final first = c.read(tasteProfileProvider);
        updates.add([rated(1, 16, imdb: 9)]);
        await pumpEventQueue();
        expect(c.read(tasteProfileProvider), same(first));
        final item = rated(1, 16, imdb: 9);
        updates.add([
          RatedTitle(
            work: item.work,
            rating: item.rating.copyWith(note: const Value('changed')),
          ),
        ]);
        await pumpEventQueue();
        expect(c.read(tasteProfileProvider), same(first));
        updates.add([
          RatedTitle(
            work: item.work.copyWith(
              snapshotUpdatedAt: 999,
              posterPath: const Value('/new.jpg'),
            ),
            rating: item.rating,
          ),
        ]);
        await pumpEventQueue();
        expect(c.read(tasteProfileProvider), same(first));
        updates.add([rated(1, 18)]);
        await pumpEventQueue();
        expect(c.read(tasteProfileProvider), isNot(same(first)));
        expect(c.read(tasteProfileProvider).signals.single.score, 9);
      } finally {
        subscription.close();
        c.dispose();
        await updates.close();
      }
    },
  );

  test(
    'large catalog JSON preserves valid and malformed response behavior',
    () async {
      final padding = 'x' * (80 * 1024);
      final json = await tryJsonAsync('{"padding":"$padding","id":42}');
      expect(json?.integer('id'), 42);
      expect(json?.string('padding'), padding);
      expect(await tryJsonAsync('{"padding":"$padding"'), isNull);
      expect(await tryJsonAsync('["$padding"]'), isNull);
    },
  );
}
