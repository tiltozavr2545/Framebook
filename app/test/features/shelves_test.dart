import 'dart:async';
import 'package:framebook/features/search/shelves.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/data/sources/providers.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';

class Api implements TmdbApi {
  int requests = 0;
  final String label;
  Api(this.label);
  @override
  Future<SearchPage> search(String query, {int page = 1}) async => SearchPage(
    [
      TitleSummary(
        key: WorkKey.movie(page),
        title: label,
        originalTitle: null,
        releaseDate: null,
        posterPath: null,
        vote: TmdbVote(null, null),
        genreIds: [],
      ),
    ],
    page: page,
    pages: 2,
  );
  @override
  Future<List<TitleSummary>> recommendations(WorkKey key) async {
    requests++;
    return [
      TitleSummary(
        key: WorkKey.movie(2),
        title: 'recommended',
        originalTitle: null,
        releaseDate: null,
        posterPath: null,
        vote: TmdbVote(null, null),
        genreIds: [],
      ),
    ];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'rating and deleting a recommendation updates exclusions without requests',
    () async {
      final changes = StreamController<List<RatedTitle>>();
      addTearDown(changes.close);
      RatedTitle rated(int id, int half) => RatedTitle(
        rating: Rating(
          workKey: 'tmdb:movie:$id',
          scoreHalf: half,
          createdAt: 1,
          scoredAt: 1,
          updatedAt: 1,
          updatedBy: 'a',
        ),
        work: Work(
          workKey: 'tmdb:movie:$id',
          kind: WorkKind.movie,
          tmdbId: id,
          title: 'Film',
          genreIds: '[]',
          snapshotUpdatedAt: 1,
        ),
      );
      final api = Api('RU');
      final c = ProviderContainer(
        overrides: [
          tmdbProvider.overrideWithValue(api),
          ratedTitlesProvider.overrideWith((ref) => changes.stream),
        ],
      );
      addTearDown(c.dispose);
      c.listen(forYouShelfProvider, (_, __) {});
      changes.add([rated(1, 18)]);
      await pumpEventQueue();
      expect((await c.read(forYouShelfProvider.future)).map((x) => x.key), [
        WorkKey.movie(2),
      ]);
      changes.add([rated(1, 18), rated(2, 12)]);
      await pumpEventQueue();
      expect(await c.read(forYouShelfProvider.future), isEmpty);
      changes.add([rated(1, 18)]);
      await pumpEventQueue();
      expect((await c.read(forYouShelfProvider.future)).map((x) => x.key), [
        const WorkKey.movie(2),
      ]);
      expect(api.requests, 1);
    },
  );
}
