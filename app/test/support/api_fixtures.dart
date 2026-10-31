import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:framebook/data/response_cache.dart';

import 'fake_http.dart';

typedef Reply = ({int status, String body});

Reply ok(String path) => (status: 200, body: fixture(path));

/// Answers with recorded responses the way the live APIs answered the same
/// requests (`scripts/capture-fixtures.sh`). Anything the fixtures lack is
/// "not found" in each API's own manner.
Reply? apiFixtures(RequestOptions request) {
  final uri = request.uri;
  final q = uri.queryParameters;
  switch (uri.host) {
    case 'api.themoviedb.org':
      return switch (uri.path) {
        '/3/configuration' => ok('tmdb/configuration.json'),
        '/3/genre/movie/list' => ok('tmdb/genre_movie_ru.json'),
        '/3/tv/1399/season/1/episode/3/credits' => ok(
          'tmdb/tv_1399_s1e3_credits_ru.json',
        ),
        '/3/person/6384' => ok('tmdb/person_6384_ru.json'),
        '/3/person/6384/images' => (
          status: 200,
          body:
              '{"profiles":[{"file_path":"/one.jpg"},{"file_path":"/two.jpg"}]}',
        ),
        '/3/trending/all/week' => ok('tmdb/trending_all_week_ru.json'),
        '/3/movie/now_playing' => ok('tmdb/movie_now_playing_ru.json'),
        '/3/discover/movie' => ok('tmdb/discover_movie_best_ru.json'),
        '/3/discover/tv' => ok('tmdb/discover_tv_best_ru.json'),
        '/3/movie/603/recommendations' => ok(
          'tmdb/movie_603_recommendations_ru.json',
        ),
        '/3/tv/1399/recommendations' => ok(
          'tmdb/tv_1399_recommendations_ru.json',
        ),
        '/3/genre/tv/list' => ok('tmdb/genre_tv_ru.json'),
        '/3/search/multi' => ok('tmdb/search_multi_matrix_ru.json'),
        '/3/movie/603' => ok('tmdb/movie_603_ru.json'),
        '/3/tv/1399' => ok('tmdb/tv_1399_ru.json'),
        '/3/tv/1399/season/1' => ok('tmdb/tv_1399_season_1_ru.json'),
        '/3/tv/1399/season/1/episode/3/external_ids' => ok(
          'tmdb/tv_1399_s1e3_external_ids.json',
        ),
        _ => (status: 404, body: fixture('tmdb/movie_not_found.json')),
      };
    case 'api.poiskkino.dev':
      if (uri.path == '/v1.5/movie/301') return ok('poiskkino/movie_301.json');
      if (uri.path != '/v1.5/movie') return (status: 404, body: '{}');
      return switch ((q['externalId.imdb'], q['externalId.tmdb'])) {
        ('tt0133093', _) => ok('poiskkino/movie_by_imdb_tt0133093.json'),
        (_, '603') => ok('poiskkino/movie_by_tmdb_603.json'),
        // Captured by tmdb id with a type filter, but it holds Game of Thrones
        // alone, so it also serves as the answer by its imdb id (there is no
        // such fixture).
        (_, '1399') || ('tt0944947', _) => ok('poiskkino/tv_by_tmdb_1399.json'),
        _ => ok('poiskkino/movie_by_imdb_not_found.json'),
      };
    case 'www.omdbapi.com':
      return switch ((q['i'], q['Season'], q['Episode'])) {
        ('tt0133093', null, null) => ok('omdb/tt0133093.json'),
        ('tt0944947', null, null) => ok('omdb/tt0944947_series.json'),
        ('tt0944947', '1', null) => ok('omdb/tt0944947_season_1.json'),
        ('tt0944947', '1', '3') ||
        ('tt1829962', null, null) => ok('omdb/tt0944947_s1e3.json'),
        _ => ok('omdb/not_found.json'),
      };
  }
  return null;
}

final class MemoryResponseCache implements ResponseCache {
  final Map<String, CachedResponse> entries = {};

  @override
  Future<CachedResponse?> read(String key) async => entries[key];

  @override
  Future<void> write(String key, CachedResponse response) async =>
      entries[key] = response;
}

/// A transparent 1×1 PNG: the poster in widget tests instead of the network.
final transparentPng = Uint8List.fromList(
  base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
  ),
);
