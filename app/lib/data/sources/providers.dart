import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../api_keys.dart';
import '../api_source.dart';
import '../http.dart';
import '../response_cache.dart';
import 'omdb/omdb_client.dart';
import 'poiskkino/poiskkino_client.dart';
import 'tmdb/tmdb_client.dart';

// Clients are rebuilt when a key or the language changes, and everything
// that depends on them (cards, ratings) is fetched again by itself.

final tmdbProvider = Provider<TmdbApi>((ref) {
  // Without a TMDB key the router keeps the user on onboarding, so cards are
  // never reached.
  final key = ref.watch(apiKeysProvider.select((k) => k[ApiSource.tmdb]));
  return TmdbClient(
    ref.watch(dioProvider),
    ref.watch(responseCacheProvider),
    key: key?.value ?? '',
    language: ref.watch(contentLanguageProvider),
  );
});

/// `null` without a key: there is no Kinopoisk rating then.
final poiskkinoProvider = Provider<PoiskKinoApi?>((ref) {
  final key = ref.watch(apiKeysProvider.select((k) => k[ApiSource.poiskkino]));
  return key == null
      ? null
      : PoiskKinoClient(ref.watch(dioProvider), key.value);
});

/// `null` without a key: IMDb comes from PoiskKino, no RT or Metacritic.
final omdbProvider = Provider<OmdbApi?>((ref) {
  final key = ref.watch(apiKeysProvider.select((k) => k[ApiSource.omdb]));
  return key == null ? null : OmdbClient(ref.watch(dioProvider), key.value);
});
