import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_source.dart';
import 'db/database.dart';
import 'db/database_provider.dart';
import 'http.dart';
import 'sources/tmdb/tmdb_client.dart';

/// The result of a trial request with a key.
enum KeyCheck {
  /// The service accepted the key.
  valid,

  /// The key works, but the daily limit is used up — it can be saved.
  limitReached,

  /// The service rejected the key — don't save it.
  invalid,

  /// The service wasn't reached — save it marked "not checked".
  offline,
}

/// Checks a key with one request (docs/external-sources.md, "Key checks"). The
/// responses the parsing relies on are in the fixtures under `test/fixtures/`.
final class KeyValidator {
  KeyValidator(this._dio, this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Dio _dio;
  final AppDatabase _db;
  final DateTime Function() _clock;

  /// The Matrix on Kinopoisk — a film that surely exists.
  static const _probeKpId = 301;

  /// The Matrix on IMDb.
  static const _probeImdbId = 'tt0133093';

  Future<KeyCheck> check(ApiSource source, String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return KeyCheck.invalid;
    try {
      return switch (source) {
        ApiSource.tmdb => await _checkTmdb(trimmed),
        ApiSource.poiskkino => await _checkPoiskkino(trimmed),
        ApiSource.omdb => await _checkOmdb(trimmed),
      };
    } on DioException catch (e) {
      if (isNetworkFailure(e)) return KeyCheck.offline;
      rethrow;
    }
  }

  Future<KeyCheck> _checkTmdb(String key) async {
    final auth = TmdbClient.auth(key);
    final response = await _dio.get<Object?>(
      'https://api.themoviedb.org/3/configuration',
      queryParameters: auth.query,
      options: Options(headers: auth.headers),
    );
    return switch (response.statusCode) {
      200 => KeyCheck.valid,
      401 => KeyCheck.invalid,
      // 429 and 5xx are answers, but they say nothing about the key.
      _ => KeyCheck.offline,
    };
  }

  Future<KeyCheck> _checkPoiskkino(String key) async {
    // The trial request spends 1 of the 200 daily ones, and is counted in the
    // budget.
    await _db.consumeBudget(
      ApiSource.poiskkino,
      AppDatabase.budgetDay(_clock()),
    );
    final response = await _dio.get<Object?>(
      'https://api.poiskkino.dev/v1.5/movie/$_probeKpId',
      options: Options(headers: {'X-API-KEY': key}),
    );
    return switch (response.statusCode) {
      200 => KeyCheck.valid,
      401 => KeyCheck.invalid,
      403 => KeyCheck.limitReached,
      _ => KeyCheck.offline,
    };
  }

  Future<KeyCheck> _checkOmdb(String key) async {
    await _db.consumeBudget(ApiSource.omdb, AppDatabase.budgetDay(_clock()));
    final response = await _dio.get<Object?>(
      'https://www.omdbapi.com/',
      queryParameters: {'i': _probeImdbId, 'apikey': key},
    );
    final body = response.data;
    final error = body is Map<String, Object?> ? body['Error'] : null;
    // OMDb errors differ only by their text (docs/external-sources.md).
    if (error == 'Invalid API key!') return KeyCheck.invalid;
    if (error == 'Request limit reached!') return KeyCheck.limitReached;
    if (response.statusCode == 200 &&
        body is Map<String, Object?> &&
        body['Response'] == 'True') {
      return KeyCheck.valid;
    }
    return KeyCheck.offline;
  }
}

final keyValidatorProvider = Provider<KeyValidator>(
  (ref) => KeyValidator(ref.watch(dioProvider), ref.watch(databaseProvider)),
);
