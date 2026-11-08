import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/insights_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';

import 'insights_test.dart' show rated;

class _Index extends PeopleIndex {
  @override
  PeopleIndexState build() => const PeopleIndexState(
    entries: {
      'tmdb:movie:1@1': [
        PeopleCredit(id: 1, name: 'Person', role: FilmographyRole.acting),
      ],
      'tmdb:tv:2@2': [
        PeopleCredit(id: 1, name: 'Person', role: FilmographyRole.acting),
      ],
    },
  );
}

void main() {
  test(
    'people insights ignore source refreshes and changes outside their kind',
    () async {
      final updates = StreamController<List<RatedTitle>>();
      final container = ProviderContainer(
        overrides: [
          ratedTitlesProvider.overrideWith((ref) => updates.stream),
          peopleIndexProvider.overrideWith(_Index.new),
        ],
      );
      addTearDown(() async {
        container.dispose();
        await updates.close();
      });
      final provider = libraryInsightsProvider(WorkKind.movie);
      container.listen(provider, (_, _) {});
      updates.add([rated(1, 16, imdb: 6), rated(2, 10, kind: WorkKind.tv)]);
      await pumpEventQueue();
      final first = await container.read(provider.future);
      updates.add([rated(1, 16, imdb: 9), rated(2, 10, kind: WorkKind.tv)]);
      await pumpEventQueue();
      expect(await container.read(provider.future), same(first));
      updates.add([rated(1, 16, imdb: 9), rated(2, 18, kind: WorkKind.tv)]);
      await pumpEventQueue();
      expect(await container.read(provider.future), same(first));
      final refreshed = rated(1, 16, imdb: 9);
      updates.add([
        RatedTitle(
          work: refreshed.work.copyWith(snapshotUpdatedAt: 999),
          rating: refreshed.rating,
          external: refreshed.external,
        ),
        rated(2, 18, kind: WorkKind.tv),
      ]);
      await pumpEventQueue();
      expect(await container.read(provider.future), same(first));
      final movie = rated(1, 16, imdb: 9);
      final changed = RatedTitle(
        work: movie.work.copyWith(
          title: 'Translated',
          posterPath: const Value('/new.jpg'),
        ),
        rating: movie.rating.copyWith(note: const Value('Retained note')),
        external: movie.external,
      );
      updates.add([changed]);
      await pumpEventQueue();
      final latest = await container.read(provider.future);
      expect(latest, isNot(same(first)));
      expect(
        latest.people.single.profile.titles.single.rating.note,
        'Retained note',
      );
      expect(
        latest.people.single.profile.titles.single.work.title,
        'Translated',
      );
      expect(latest.people.single.profile.titles.single.posterPath, '/new.jpg');
      updates.add([
        RatedTitle(
          work: changed.work,
          rating: changed.rating.copyWith(scoreHalf: 14),
        ),
      ]);
      await pumpEventQueue();
      expect(
        (await container.read(provider.future)).people.single.profile.average,
        7,
      );
    },
  );
}
