import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/title/cover_viewer.dart';
import 'package:framebook/shared/poster.dart';

import '../support/api_fixtures.dart';

void main() {
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
    },
  );
}
