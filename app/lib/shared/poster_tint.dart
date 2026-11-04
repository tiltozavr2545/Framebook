import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/sources/tmdb/tmdb_models.dart';
import 'poster.dart';

/// Samples a bounded number of pixels into a small colour histogram.
/// Transparent pixels are excluded; a missing image leaves the normal theme.
Color? dominantPosterColor(Uint8List rgba) {
  final bins = <int, (int, int, int, int)>{};
  final stride = ((rgba.length ~/ 4) ~/ 4096 + 1) * 4;
  for (var i = 0; i + 3 < rgba.length; i += stride) {
    if (rgba[i + 3] < 128) continue;
    final r = rgba[i];
    final g = rgba[i + 1];
    final b = rgba[i + 2];
    final key = (r >> 5) << 6 | (g >> 5) << 3 | (b >> 5);
    final old = bins[key] ?? (0, 0, 0, 0);
    bins[key] = (old.$1 + 1, old.$2 + r, old.$3 + g, old.$4 + b);
  }
  if (bins.isEmpty) return null;
  // Dark borders and white lettering often outnumber the artwork's colour.
  // Prefer chromatic midtones when present, then fall back to the whole image.
  final chromatic = bins.values.where((bin) {
    final hsl = HSLColor.fromColor(
      Color.fromARGB(255, bin.$2 ~/ bin.$1, bin.$3 ~/ bin.$1, bin.$4 ~/ bin.$1),
    );
    return hsl.saturation >= 0.18 &&
        hsl.lightness >= 0.12 &&
        hsl.lightness <= 0.88;
  }).toList();
  final candidates = chromatic.isEmpty ? bins.values : chromatic;
  final best = candidates.reduce((a, b) => a.$1 >= b.$1 ? a : b);
  return Color.fromARGB(
    255,
    best.$2 ~/ best.$1,
    best.$3 ~/ best.$1,
    best.$4 ~/ best.$1,
  );
}

final posterTintProvider = FutureProvider.autoDispose.family<Color?, String>((
  ref,
  path,
) async {
  final config = ref.watch(imageConfigProvider).value ?? ImageConfig.fallback;
  // The header already loads this size through the same image provider.
  final source = ref.watch(posterImageProvider)(
    config.url(path, ImageSize.w342),
    '${ImageSize.w342.name}$path',
  );
  final stream = source.resolve(ImageConfiguration.empty);
  final result = Completer<Color?>();
  var disposed = false;
  late final ImageStreamListener listener;
  listener = ImageStreamListener(
    (info, _) async {
      stream.removeListener(listener);
      try {
        if (disposed) return;
        final bytes = await info.image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        );
        if (!result.isCompleted) {
          result.complete(
            bytes == null
                ? null
                : dominantPosterColor(
                    bytes.buffer.asUint8List(
                      bytes.offsetInBytes,
                      bytes.lengthInBytes,
                    ),
                  ),
          );
        }
      } catch (_) {
        if (!result.isCompleted) result.complete(null);
      } finally {
        info.dispose();
      }
    },
    onError: (Object error, StackTrace? stack) {
      stream.removeListener(listener);
      if (!result.isCompleted) result.complete(null);
    },
  );
  ref.onDispose(() {
    disposed = true;
    stream.removeListener(listener);
    if (!result.isCompleted) result.complete(null);
  });
  stream.addListener(listener);
  return result.future;
});

class PosterTint extends ConsumerWidget {
  const PosterTint({super.key, required this.path, required this.child});

  final String? path;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = this.path;
    final color = path == null
        ? null
        : ref.watch(posterTintProvider(path)).value;
    final surface = Theme.of(context).colorScheme.surface;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final accent = color == null
        ? surface
        : HSLColor.fromColor(color).withLightness(dark ? 0.55 : 0.45).toColor();
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: color == null
            ? null
            : Border.all(color: accent.withValues(alpha: 0.65)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              accent.withValues(alpha: dark ? 0.38 : 0.24),
              surface,
            ),
            surface,
          ],
        ),
      ),
      child: child,
    );
  }
}
