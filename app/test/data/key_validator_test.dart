import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/key_validator.dart';

import '../support/fake_http.dart';

void main() {
  late AppDatabase db;
  late Dio dio;
  late FakeHttpAdapter http;
  late KeyValidator validator;
  final now = DateTime.utc(2026, 10, 23, 12);

  void serve(({int status, String body})? Function(RequestOptions) respond) {
    http = FakeHttpAdapter(respond);
    dio.httpClientAdapter = http;
  }

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    dio = createDio();
    validator = KeyValidator(dio, db, clock: () => now);
  });

  tearDown(() => db.close());

  group('TMDB', () {
    test('a read access token goes in the Authorization header', () async {
      serve((_) => (status: 200, body: fixture('tmdb/configuration.json')));
      expect(
        await validator.check(ApiSource.tmdb, ' eyJtoken '),
        KeyCheck.valid,
      );
      final request = http.requests.single;
      expect(request.headers['Authorization'], 'Bearer eyJtoken');
      expect(request.uri.queryParameters, isNot(contains('api_key')));
    });

    test('a short v3 key goes in the api_key query parameter', () async {
      serve((_) => (status: 200, body: fixture('tmdb/configuration.json')));
      expect(await validator.check(ApiSource.tmdb, 'abc123'), KeyCheck.valid);
      final request = http.requests.single;
      expect(request.uri.queryParameters['api_key'], 'abc123');
      expect(request.headers, isNot(contains('Authorization')));
    });

    test('401 means the key is rejected', () async {
      serve(
        (_) => (
          status: 401,
          body:
              '{"status_code":7,"status_message":"Invalid API key","success":false}',
        ),
      );
      expect(await validator.check(ApiSource.tmdb, 'eyJbad'), KeyCheck.invalid);
    });

    test('does not spend any budget', () async {
      serve((_) => (status: 200, body: fixture('tmdb/configuration.json')));
      await validator.check(ApiSource.tmdb, 'eyJtoken');
      expect(await db.budgetUsed(ApiSource.tmdb, '2026-10-23'), 0);
    });
  });

  group('PoiskKino', () {
    test('valid key, sent as X-API-KEY, and the probe is counted', () async {
      serve((_) => (status: 200, body: fixture('poiskkino/movie_301.json')));
      expect(await validator.check(ApiSource.poiskkino, 'KEY'), KeyCheck.valid);
      expect(http.requests.single.headers['X-API-KEY'], 'KEY');
      expect(await db.budgetUsed(ApiSource.poiskkino, '2026-10-23'), 1);
    });

    test('401 rejects, 403 is a used-up limit', () async {
      serve((_) => (status: 401, body: '{"statusCode":401}'));
      expect(
        await validator.check(ApiSource.poiskkino, 'KEY'),
        KeyCheck.invalid,
      );
      serve((_) => (status: 403, body: '{"statusCode":403}'));
      expect(
        await validator.check(ApiSource.poiskkino, 'KEY'),
        KeyCheck.limitReached,
      );
    });
  });

  group('OMDb', () {
    test('valid key', () async {
      serve((_) => (status: 200, body: fixture('omdb/tt0133093.json')));
      expect(await validator.check(ApiSource.omdb, '1a2b3c4'), KeyCheck.valid);
      expect(http.requests.single.uri.queryParameters['apikey'], '1a2b3c4');
      expect(await db.budgetUsed(ApiSource.omdb, '2026-10-23'), 1);
    });

    test('"Invalid API key!" rejects (recorded response)', () async {
      serve((_) => (status: 401, body: fixture('omdb/invalid_key.json')));
      expect(await validator.check(ApiSource.omdb, 'bad'), KeyCheck.invalid);
    });

    test('"Request limit reached!" keeps the key', () async {
      serve(
        (_) => (
          status: 401,
          body: '{"Response":"False","Error":"Request limit reached!"}',
        ),
      );
      expect(
        await validator.check(ApiSource.omdb, 'key'),
        KeyCheck.limitReached,
      );
    });
  });

  test('no network is reported as offline, not as a bad key', () async {
    serve((_) => null);
    for (final source in ApiSource.values) {
      expect(await validator.check(source, 'eyJkey'), KeyCheck.offline);
    }
  });

  test('an empty key is invalid without any request', () async {
    serve((_) => throw StateError('must not be called'));
    expect(await validator.check(ApiSource.tmdb, '   '), KeyCheck.invalid);
    expect(http.requests, isEmpty);
  });
}
