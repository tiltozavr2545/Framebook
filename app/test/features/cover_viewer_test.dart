import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/title/cover_viewer.dart';
import 'package:framebook/shared/poster.dart';

import '../support/api_fixtures.dart';

class _PendingImage extends ImageProvider<_PendingImage> {
  final frame = Completer<ImageInfo>();

  @override
  Future<_PendingImage> obtainKey(ImageConfiguration configuration) =>
      SynchronousFuture(this);

  @override
  ImageStreamCompleter loadImage(
    _PendingImage key,
    ImageDecoderCallback decode,
  ) => OneFrameImageStreamCompleter(frame.future);
}

Future<ui.Image> _raster(int width, int height) async {
  final recorder = ui.PictureRecorder();
  Canvas(recorder).drawColor(Colors.blue, BlendMode.src);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}

void main() {
  testWidgets(
    'large covers decode within zoom and memory bounds without stretching',
    (tester) async {
      final resized =
          boundedCoverImage(
                MemoryImage(transparentPng),
                const Size(1440, 3200),
                3,
              )
              as ResizeImage;
      expect(resized.width, 4096);
      expect(resized.height, 4096);
      expect(resized.allowUpscaling, isFalse);
      final image = (await tester.runAsync(() => _raster(1000, 2000)))!;
      final bytes = (await tester.runAsync(
        () => image.toByteData(format: ui.ImageByteFormat.png),
      ))!;
      image.dispose();
      final provider = boundedCoverImage(
        MemoryImage(bytes.buffer.asUint8List()),
        const Size(100, 100),
        1,
      );
      final completer = Completer<ImageInfo>();
      final stream = provider.resolve(ImageConfiguration.empty);
      final listener = ImageStreamListener(
        (info, _) => completer.complete(info),
        onError: completer.completeError,
      );
      stream.addListener(listener);
      for (var i = 0; i < 100 && !completer.isCompleted; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 10)),
        );
      }
      expect(completer.isCompleted, isTrue);
      final info = await completer.future;
      expect(info.image.width, 200);
      expect(info.image.height, 400);
      info.dispose();
      stream.removeListener(listener);
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    },
  );

  testWidgets('full-screen route fades without scaling the image', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => Navigator.of(context).push(
              coverViewerRoute(
                (_) => const ColoredBox(
                  key: ValueKey('viewer-page'),
                  color: Colors.black,
                ),
              ),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));
    expect(find.byKey(const ValueKey('viewer-page')), findsOneWidget);
    expect(find.byType(FadeTransition), findsWidgets);
    expect(find.byType(ScaleTransition), findsNothing);
  });

  test(
    'current cover then UI, original and textless images, with no duplicates',
    () {
      expect(
        orderedCovers(
          '/current',
          [
            const TmdbImage('/en', 'en'),
            const TmdbImage('/none', null),
            const TmdbImage('/ru', 'ru'),
            const TmdbImage('/other', 'fr'),
            const TmdbImage('/current', 'ru'),
            const TmdbImage('/en', 'en'),
          ],
          uiLanguage: 'ru',
          originalLanguage: 'en',
        ),
        ['/current', '/ru', '/en', '/none'],
      );
    },
  );

  for (final kind in ['poster', 'person', 'still']) {
    testWidgets(
      '$kind preview fills the final image area before the large image loads',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final preview = _PendingImage();
        final large = _PendingImage();
        final width = kind == 'still' ? 160 : 64;
        final height = kind == 'still' ? 90 : 96;
        final smallRaster = (await tester.runAsync(
          () => _raster(width, height),
        ))!;
        final largeRaster = (await tester.runAsync(
          () => _raster(width * 5, height * 5),
        ))!;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              contentLanguageProvider.overrideWithValue('en-US'),
              imageConfigProvider.overrideWith(
                (ref) async => ImageConfig.fallback,
              ),
              coverVariantsProvider.overrideWith((ref, key) async => []),
              personImagesProvider.overrideWith((ref, key) async => []),
              posterImageProvider.overrideWithValue(
                (url, key) => key.startsWith('w185') ? preview : large,
              ),
            ],
            child: MaterialApp(
              home: CoverViewer(
                currentPath: '/delayed-$kind',
                personId: kind == 'person' ? 1 : null,
                keyForImages: kind == 'person'
                    ? null
                    : kind == 'still'
                    ? const WorkKey.episode(1, 1, 1)
                    : const WorkKey.movie(1),
                previewSize: ImageSize.w185,
              ),
            ),
          ),
        );
        await tester.pump();
        preview.frame.complete(ImageInfo(image: smallRaster));
        await tester.pumpAndSettle();
        final viewport = tester.getSize(find.byType(InteractiveViewer));
        final smallImage = find.byWidgetPredicate(
          (widget) => widget is Image && identical(widget.image, preview),
        );
        expect(tester.getSize(smallImage), viewport);
        final previewPaintSize = applyBoxFit(
          BoxFit.contain,
          Size(width.toDouble(), height.toDouble()),
          viewport,
        ).destination;
        large.frame.complete(ImageInfo(image: largeRaster));
        await tester.pumpAndSettle();
        final bigImage = find.byWidgetPredicate(
          (widget) =>
              widget is Image &&
              widget.image is ResizeImage &&
              identical((widget.image as ResizeImage).imageProvider, large),
        );
        expect(tester.getSize(bigImage), viewport);
        expect(
          applyBoxFit(
            BoxFit.contain,
            Size(width * 5.0, height * 5.0),
            tester.getSize(bigImage),
          ).destination,
          previewPaintSize,
        );
        await tester.pumpWidget(const SizedBox());
        PaintingBinding.instance.imageCache.clear();
        PaintingBinding.instance.imageCache.clearLiveImages();
      },
    );
  }

  testWidgets('online cover shows variants and allows paging and zoom', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentLanguageProvider.overrideWithValue('ru-RU'),
          imageConfigProvider.overrideWith((ref) async => ImageConfig.fallback),
          posterImageProvider.overrideWithValue(
            (_, __) => MemoryImage(transparentPng),
          ),
          coverVariantsProvider.overrideWith(
            (ref, key) async => [const TmdbImage('/other', 'ru')],
          ),
        ],
        child: const MaterialApp(
          home: CoverViewer(
            currentPath: '/first',
            keyForImages: WorkKey.movie(1),
            previewSize: ImageSize.w342,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    final center = tester.getCenter(find.byType(InteractiveViewer));
    final first = await tester.startGesture(
      center + const Offset(-40, 0),
      pointer: 1,
    );
    final second = await tester.startGesture(
      center + const Offset(40, 0),
      pointer: 2,
    );
    await first.moveBy(const Offset(-60, 0));
    await second.moveBy(const Offset(60, 0));
    await tester.pump();
    final viewer = tester.widget<InteractiveViewer>(
      find.byType(InteractiveViewer),
    );
    expect(
      viewer.transformationController!.value.getMaxScaleOnAxis(),
      greaterThan(1),
    );
    await first.moveBy(const Offset(60, 0));
    await second.moveBy(const Offset(-60, 0));
    await tester.pump();
    await first.up();
    await second.up();
    await tester.pumpAndSettle();
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/other')), findsOneWidget);
  });

  testWidgets('person photos open with all available profiles', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          contentLanguageProvider.overrideWithValue('en-US'),
          imageConfigProvider.overrideWith((ref) async => ImageConfig.fallback),
          posterImageProvider.overrideWithValue(
            (_, __) => MemoryImage(transparentPng),
          ),
          personImagesProvider.overrideWith(
            (ref, id) async => [const TmdbImage('/second', null)],
          ),
        ],
        child: const MaterialApp(
          home: CoverViewer(
            currentPath: '/first',
            personId: 1,
            previewSize: ImageSize.w185,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(InteractiveViewer), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('/second')), findsOneWidget);
  });

  testWidgets(
    'saved offline cover never fetches image variants or network images',
    (tester) async {
      var variantRequests = 0;
      var networkImages = 0;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentLanguageProvider.overrideWithValue('en-US'),
            coverVariantsProvider.overrideWith((ref, key) async {
              variantRequests++;
              return [];
            }),
            posterImageProvider.overrideWithValue((_, __) {
              networkImages++;
              return MemoryImage(transparentPng);
            }),
            cachedPosterProvider.overrideWith(
              (ref, key) async => File('assets/tmdb_logo.png'),
            ),
          ],
          child: const MaterialApp(
            home: CoverViewer(
              currentPath: '/first',
              keyForImages: WorkKey.movie(1),
              previewSize: ImageSize.w342,
              cachedOnly: true,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(variantRequests, 0);
      expect(networkImages, 0);
      expect(find.byType(Image), findsOneWidget);
      expect(
        tester.getSize(find.byType(Image)),
        tester.getSize(find.byType(InteractiveViewer)),
      );
    },
  );
}
