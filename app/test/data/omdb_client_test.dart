import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/omdb/omdb_client.dart';

import '../support/api_fixtures.dart';
import '../support/fake_http.dart';

void main() {
  late Dio dio;
  late FakeHttpAdapter http;
  late OmdbClient client;

  void serve(Reply? Function(RequestOptions) respond) {
    http = FakeHttpAdapter(respond);
    dio.httpClientAdapter = http;
  }

  setUp(() {
    dio = createDio();
    client = OmdbClient(dio, 'KEY');
    serve(apiFixtures);
  });

  Matcher failsWith(SourceFailure failure) => throwsA(
    isA<SourceException>().having((e) => e.failure, 'failure', failure),
  );

  test('a film: IMDb, Rotten Tomatoes, Metacritic from strings', () async {
    final found = (await client.byImdbId('tt0133093'))!;
    expect(found.imdb, 8.7);
    expect(found.imdbVotes, 2284373);
    expect(found.rottenTomatoes, 83);
    expect(found.metacritic, 73);
    expect(http.requests.single.uri.queryParameters, {
      'i': 'tt0133093',
      'apikey': 'KEY',
    });
  });

  test('a series has only IMDb', () async {
    final found = (await client.byImdbId('tt0944947'))!;
    expect(found.imdb, 9.2);
    expect(found.rottenTomatoes, isNull);
    expect(found.metacritic, isNull);
  });

  test('an episode by its own id and by series + numbers', () async {
    final byId = (await client.byImdbId('tt1829962'))!;
    final byNumbers = (await client.episode('tt0944947', 1, 3))!;
    expect(byId.imdb, 8.5);
    expect(byNumbers.imdb, 8.5);
    expect(byNumbers.imdbVotes, 41918);
    expect(
      http.requests.last.uri.queryParameters,
      {'i': 'tt0944947', 'Season': '1', 'Episode': '3'}..['apikey'] = 'KEY',
    );
  });

  test('a season is the average of rated episodes; N/A is skipped', () async {
    final average = (await client.seasonAverage('tt0944947', 1))!;
    // The fixture has 11 items: "episode 0" (the pilot) unrated, and 10
    // episodes.
    expect(average.episodes, 10);
    expect(average.average, closeTo(8.97, 1e-9));
  });

  test(
    '"Error getting data." and "Incorrect IMDb ID." are not found',
    () async {
      expect(await client.byImdbId('tt9999999'), isNull);
      serve((_) => ok('omdb/malformed_id.json'));
      expect(await client.byImdbId('tt9999999999'), isNull);
    },
  );

  test('"N/A" is no rating, not zero', () async {
    serve(
      (_) => (
        status: 200,
        body:
            '{"Response":"True","imdbRating":"N/A","imdbVotes":"N/A","Ratings":[]}',
      ),
    );
    final found = (await client.byImdbId('tt0000001'))!;
    expect(found.imdb, isNull);
    expect(found.imdbVotes, isNull);
  });

  test('a rejected key and a used-up limit', () async {
    serve((_) => (status: 401, body: fixture('omdb/invalid_key.json')));
    await expectLater(
      client.byImdbId('tt0133093'),
      failsWith(SourceFailure.unauthorized),
    );
    serve(
      (_) => (
        status: 401,
        body: '{"Response":"False","Error":"Request limit reached!"}',
      ),
    );
    await expectLater(
      client.byImdbId('tt0133093'),
      failsWith(SourceFailure.limitReached),
    );
  });

  test('an unknown error text is a failure, not "not found"', () async {
    serve(
      (_) => (status: 200, body: '{"Response":"False","Error":"Something."}'),
    );
    await expectLater(
      client.byImdbId('tt0133093'),
      failsWith(SourceFailure.failed),
    );
  });
}
