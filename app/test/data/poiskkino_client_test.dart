import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/poiskkino/poiskkino_client.dart';

import '../support/api_fixtures.dart';
import '../support/fake_http.dart';

void main() {
  late Dio dio;
  late FakeHttpAdapter http;
  late PoiskKinoClient client;

  void serve(Reply? Function(RequestOptions) respond) {
    http = FakeHttpAdapter(respond);
    dio.httpClientAdapter = http;
  }

  setUp(() {
    dio = createDio();
    client = PoiskKinoClient(dio, 'KEY');
    serve(apiFixtures);
  });

  Matcher failsWith(SourceFailure failure) => throwsA(
    isA<SourceException>().having((e) => e.failure, 'failure', failure),
  );

  test('by imdb id: kp id, Kinopoisk and IMDb ratings in one go', () async {
    final found = (await client.byImdbId('tt0133093', isSeries: false))!;
    expect(found.kpId, 301);
    expect(found.kp, 8.501);
    expect(found.kpVotes, 816869);
    expect(found.imdb, 8.7);
    expect(found.imdbVotes, 2200000);
    final request = http.requests.single;
    expect(request.headers['X-API-KEY'], 'KEY');
    expect(request.uri.queryParameters, {'externalId.imdb': 'tt0133093'});
  });

  test('by tmdb id the type decides: 603 is The Matrix, not a 1997 series '
      '(the series comes first in the response)', () async {
    final movie = await client.byTmdbId(603, isSeries: false);
    expect(movie!.kpId, 301);
    final series = await client.byTmdbId(603, isSeries: true);
    expect(series!.kpId, 277631);
  });

  test('a series by tmdb id', () async {
    final found = await client.byTmdbId(1399, isSeries: true);
    expect(found!.kpId, 464963);
    expect(found.kp, 9.009);
  });

  test('two candidates of the same type is not a match', () async {
    serve(
      (_) => (
        status: 200,
        body: '{"docs":[{"id":1,"isSeries":false},{"id":2,"isSeries":false}]}',
      ),
    );
    expect(await client.byTmdbId(5, isSeries: false), isNull);
  });

  test('nothing found is null, not an error', () async {
    expect(await client.byImdbId('tt9999999', isSeries: false), isNull);
  });

  test('a tmdb id PoiskKino would reject is not sent at all', () async {
    expect(await client.byTmdbId(2000001, isSeries: false), isNull);
    expect(http.requests, isEmpty);
  });

  test('by kp id', () async {
    final found = await client.byKpId(301);
    expect(found!.kp, 8.501);
    expect(http.requests.single.uri.path, '/v1.5/movie/301');
  });

  test('a zero Kinopoisk rating means no rating yet', () async {
    serve(
      (_) => (
        status: 200,
        body: '{"id":7,"rating":{"kp":0,"imdb":0},"votes":{"kp":0}}',
      ),
    );
    final found = await client.byKpId(7);
    expect(found!.kp, isNull);
    expect(found.imdb, isNull);
  });

  test('401 is a rejected key, 403 the daily limit', () async {
    serve((_) => (status: 401, body: '{}'));
    await expectLater(
      client.byKpId(301),
      failsWith(SourceFailure.unauthorized),
    );
    serve((_) => (status: 403, body: '{}'));
    await expectLater(
      client.byKpId(301),
      failsWith(SourceFailure.limitReached),
    );
  });

  test('no network is offline', () async {
    serve((_) => null);
    await expectLater(client.byKpId(301), failsWith(SourceFailure.offline));
  });
}
