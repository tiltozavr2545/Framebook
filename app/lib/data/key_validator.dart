import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_source.dart';
import 'db/database.dart';
import 'db/database_provider.dart';
import 'http.dart';

/// Результат пробного запроса с ключом.
enum KeyCheck {
  /// Сервис принял ключ.
  valid,

  /// Ключ рабочий, но суточный лимит исчерпан — сохранять можно.
  limitReached,

  /// Сервис отверг ключ — не сохранять.
  invalid,

  /// До сервиса не достучались — сохранить с пометкой «не проверен».
  offline,
}

/// Проверка ключа одним запросом (docs/external-sources.md, «Проверка
/// ключей»). Ответы, на которые опирается разбор, лежат в фикстурах
/// `test/fixtures/`.
final class KeyValidator {
  KeyValidator(this._dio, this._db, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final Dio _dio;
  final AppDatabase _db;
  final DateTime Function() _clock;

  /// «Матрица» на Кинопоиске — заведомо существующий фильм.
  static const _probeKpId = 301;

  /// «Матрица» на IMDb.
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

  /// Принимает и API Read Access Token (`eyJ…`, заголовок), и короткий API
  /// key v3 (параметр запроса) — docs/api-keys.md.
  static ({Map<String, String> headers, Map<String, String> query}) tmdbAuth(
    String key,
  ) => key.startsWith('eyJ')
      ? (headers: {'Authorization': 'Bearer $key'}, query: const {})
      : (headers: const {}, query: {'api_key': key});

  Future<KeyCheck> _checkTmdb(String key) async {
    final auth = tmdbAuth(key);
    final response = await _dio.get<Object?>(
      'https://api.themoviedb.org/3/configuration',
      queryParameters: auth.query,
      options: Options(headers: auth.headers),
    );
    return switch (response.statusCode) {
      200 => KeyCheck.valid,
      401 => KeyCheck.invalid,
      // 429 и 5xx — ответ есть, но про ключ он ничего не говорит.
      _ => KeyCheck.offline,
    };
  }

  Future<KeyCheck> _checkPoiskkino(String key) async {
    // Пробный запрос тратит 1 из 200 суточных — и учитывается в бюджете.
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
    // Ошибки OMDb различаются только текстом (docs/external-sources.md).
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
