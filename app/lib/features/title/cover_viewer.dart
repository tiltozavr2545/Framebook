import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../../data/sources/providers.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../shared/poster.dart';

/// Current cover first, then UI-language, original-language and textless
/// images, retaining TMDB's order within each group.
List<String> orderedCovers(
  String current,
  List<TmdbImage> images, {
  required String uiLanguage,
  String? originalLanguage,
}) {
  final seen = <String>{current};
  final result = <String>[current];
  for (final language in {
    uiLanguage,
    if (originalLanguage != null) originalLanguage,
    null,
  }) {
    for (final image in images) {
      if (image.language == language && seen.add(image.path)) {
        result.add(image.path);
      }
    }
  }
  return result;
}

final coverVariantsProvider = FutureProvider.autoDispose
    .family<List<TmdbImage>, WorkKey>(
      (ref, key) => ref.watch(tmdbProvider).images(key),
    );

final personImagesProvider = FutureProvider.autoDispose
    .family<List<TmdbImage>, int>(
      (ref, id) => ref.watch(tmdbProvider).personImages(id),
    );

/// Opens immediately with the current cover, including while variants load.
class CoverViewer extends ConsumerStatefulWidget {
  const CoverViewer({
    super.key,
    required this.currentPath,
    this.keyForImages,
    this.personId,
    required this.previewSize,
    this.originalLanguage,
    this.cachedOnly = false,
  }) : assert((keyForImages == null) != (personId == null));
  final String currentPath;
  final WorkKey? keyForImages;
  final int? personId;
  final ImageSize previewSize;
  final String? originalLanguage;
  final bool cachedOnly;

  @override
  ConsumerState<CoverViewer> createState() => _CoverViewerState();
}

class _CoverViewerState extends ConsumerState<CoverViewer> {
  bool _zoomed = false;

  @override
  Widget build(BuildContext context) {
    final images = widget.cachedOnly
        ? const <TmdbImage>[]
        : (widget.personId != null
                  ? ref.watch(personImagesProvider(widget.personId!)).value
                  : ref
                        .watch(coverVariantsProvider(widget.keyForImages!))
                        .value) ??
              const <TmdbImage>[];
    final paths = widget.personId != null
        ? {widget.currentPath, for (final image in images) image.path}.toList()
        : orderedCovers(
            widget.currentPath,
            images,
            uiLanguage: ref.watch(contentLanguageProvider).split('-').first,
            originalLanguage: widget.originalLanguage,
          );
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: PageView.builder(
        physics: _zoomed ? const NeverScrollableScrollPhysics() : null,
        itemCount: paths.length,
        onPageChanged: (_) => setState(() => _zoomed = false),
        itemBuilder: (context, index) => _CoverPage(
          key: ValueKey(paths[index]),
          path: paths[index],
          previewSize: widget.previewSize,
          cachedOnly: widget.cachedOnly,
          still:
              widget.personId != null ||
              widget.keyForImages?.kind == WorkKind.episode,
          onZoom: (zoomed) {
            if (_zoomed != zoomed) setState(() => _zoomed = zoomed);
          },
        ),
      ),
    );
  }
}

class _CoverPage extends ConsumerStatefulWidget {
  const _CoverPage({
    super.key,
    required this.path,
    required this.previewSize,
    required this.cachedOnly,
    required this.still,
    required this.onZoom,
  });
  final String path;
  final ImageSize previewSize;
  final bool cachedOnly;
  final bool still;
  final ValueChanged<bool> onZoom;
  @override
  ConsumerState<_CoverPage> createState() => _CoverPageState();
}

class _CoverPageState extends ConsumerState<_CoverPage> {
  final _transform = TransformationController();
  @override
  void dispose() {
    _transform.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final path = widget.path;
    Widget preview;
    if (widget.cachedOnly) {
      final file = ref
          .watch(cachedPosterProvider((path: path, size: widget.previewSize)))
          .value;
      preview = file == null
          ? const SizedBox.shrink()
          : Image.file(file, fit: BoxFit.contain);
    } else {
      final config =
          ref.watch(imageConfigProvider).value ?? ImageConfig.fallback;
      final provider = ref.watch(posterImageProvider);
      final large = widget.still ? config.stillLarge : config.posterLarge;
      preview = Stack(
        alignment: Alignment.center,
        children: [
          Image(
            image: provider(
              config.url(path, widget.previewSize),
              '${widget.previewSize.name}$path',
            ),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
          ),
          Image(
            image: provider(config.url(path, large), '${large.name}$path'),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => const SizedBox.shrink(),
            frameBuilder: (_, child, frame, synchronous) =>
                frame == null && !synchronous ? const SizedBox.shrink() : child,
          ),
        ],
      );
    }
    return InteractiveViewer(
      transformationController: _transform,
      minScale: 1,
      maxScale: 4,
      panEnabled: _transform.value.getMaxScaleOnAxis() > 1.001,
      onInteractionUpdate: (_) =>
          widget.onZoom(_transform.value.getMaxScaleOnAxis() > 1.001),
      child: SizedBox.expand(child: Center(child: preview)),
    );
  }
}
