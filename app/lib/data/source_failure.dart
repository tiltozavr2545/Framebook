import 'dart:convert';

import 'package:dio/dio.dart';

import 'http.dart';

/// Why an external source gave no data. No answer and a refusal are told
/// apart: offline is shown differently from "key rejected".
enum SourceFailure {
  /// The service was not reached: no network, timeout, DNS.
  offline,

  /// The service rejected the key (or there is none).
  unauthorized,

  /// The daily limit is used up, by the service's answer or our own counter.
  limitReached,

  /// The source has no such title.
  notFound,

  /// The service answered, but wrongly: 5xx, 429, a body we can't read.
  failed,
}

final class SourceException implements Exception {
  const SourceException(this.failure, [this.detail]);

  /// A dio network failure is [SourceFailure.offline], anything else `failed`.
  factory SourceException.fromDio(DioException error) => SourceException(
    isNetworkFailure(error) ? SourceFailure.offline : SourceFailure.failed,
    error.type.name,
  );

  final SourceFailure failure;

  /// For debugging. Must never contain an API key.
  final String? detail;

  @override
  String toString() =>
      'SourceException(${failure.name}${detail == null ? '' : ': $detail'})';
}

/// Reading external API JSON under `strict-casts`. Everything is optional: a
/// field of the wrong type reads as missing instead of failing the whole
/// card.
extension type const Json(Map<String, Object?> raw) {
  /// An empty string means "no value": TMDB sends `release_date: ""` for
  /// titles not yet released.
  String? string(String key) {
    final value = raw[key];
    return value is String && value.isNotEmpty ? value : null;
  }

  int? integer(String key) {
    final value = raw[key];
    return value is num ? value.toInt() : null;
  }

  double? number(String key) {
    final value = raw[key];
    return value is num ? value.toDouble() : null;
  }

  bool? boolean(String key) {
    final value = raw[key];
    return value is bool ? value : null;
  }

  Json? object(String key) {
    final value = raw[key];
    return value is Map<String, Object?> ? Json(value) : null;
  }

  List<Json> objects(String key) {
    final value = raw[key];
    if (value is! List<Object?>) return const [];
    return [
      for (final item in value)
        if (item is Map<String, Object?>) Json(item),
    ];
  }

  List<int> integers(String key) {
    final value = raw[key];
    if (value is! List<Object?>) return const [];
    return [
      for (final item in value)
        if (item is int) item,
    ];
  }
}

/// Parses a body received as a string. `null` if it is not a JSON object (a
/// proxy's HTML page on a 502 and the like). Clients ask dio for a string,
/// not JSON: in dio an unparsable body is `DioExceptionType.unknown`, which
/// reads as "no network", while it is an answer from the service, just a bad
/// one.
Json? tryJson(String? body) {
  if (body == null || body.isEmpty) return null;
  try {
    final decoded = jsonDecode(body);
    return decoded is Map<String, Object?> ? Json(decoded) : null;
  } on FormatException {
    return null;
  }
}

/// `YYYY` from `YYYY-MM-DD`. A date without a time is never turned into a
/// `DateTime` (AGENTS.md, pitfalls).
int? yearOf(String? date) =>
    date == null || date.length < 4 ? null : int.tryParse(date.substring(0, 4));
