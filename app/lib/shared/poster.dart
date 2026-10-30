import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/providers.dart';
import '../data/sources/tmdb/tmdb_models.dart';

/// Where TMDB images live. Until it loads (or if it never does) —
/// [ImageConfig.fallback].
final imageConfigProvider = FutureProvider<ImageConfig>(
  (ref) => ref.watch(tmdbProvider).imageConfig(),
);

/// Image cache, evicted by file count. A list poster is ~10 KB, a card poster
/// ~60 KB, so 1,500 files is tens of megabytes.
final _posterCache = CacheManager(
  Config(
    'posters',
    stalePeriod: const Duration(days: 90),
    maxNrOfCacheObjects: 1500,
  ),
);

/// A cached image without a network request, used by saved offline cards.
final cachedPosterProvider = FutureProvider.autoDispose
    .family<File?, ({String path, ImageSize size})>(
      (ref, key) async => (await _posterCache.getFileFromCache(
        '${key.size.name}${key.path}',
      ))?.file,
    );

/// Where an image comes from, by URL and cache key. Tests replace it with an
/// in-memory image.
final posterImageProvider =
    Provider<ImageProvider Function(Uri url, String cacheKey)>(
      (ref) =>
          (url, cacheKey) => CachedNetworkImageProvider(
            url.toString(),
            cacheKey: cacheKey,
            cacheManager: _posterCache,
          ),
    );

/// A TMDB poster or still. The cache key is size and path, not the full URL:
/// the CDN base address may change, the image doesn't
/// (docs/client-architecture.md).
class Poster extends ConsumerWidget {
  const Poster(
    this.path, {
    super.key,
    required this.size,
    required this.width,
    this.aspectRatio = 2 / 3,
    this.icon = Icons.movie_outlined,
  });

  final String? path;
  final ImageSize size;
  final double width;

  /// Width to height: a poster is 2:3, an episode still 16:9.
  final double aspectRatio;
  final IconData icon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(icon, color: scheme.outline, size: width / 3),
      ),
    );
    final path = this.path;
    Widget child = placeholder;
    if (path != null) {
      final config =
          ref.watch(imageConfigProvider).value ?? ImageConfig.fallback;
      child = Image(
        image: ref.watch(posterImageProvider)(
          config.url(path, size),
          '${size.name}$path',
        ),
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => placeholder,
        frameBuilder: (_, image, frame, synchronous) =>
            frame == null && !synchronous ? placeholder : image,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: SizedBox(width: width, height: width / aspectRatio, child: child),
    );
  }
}
