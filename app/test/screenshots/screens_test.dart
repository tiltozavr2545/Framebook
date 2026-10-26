// Renders the main screens to PNG files with the real fonts, to look at the
// design without a device: `SCREENSHOTS=/tmp/fb-shots flutter test
// test/screenshots`. Skipped in normal runs — it checks nothing, and font
// rendering differs between machines.

import 'dart:io';
import 'dart:convert' show JsonCodec;
import 'dart:ui' as ui;

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/app.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/router.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/background_refresh.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/response_cache.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/sync/google_account.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/shared/poster.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/api_fixtures.dart';
import '../support/fake_google.dart';
import '../support/fake_http.dart';
import '../support/memory_key_storage.dart';
import '../support/memory_remote.dart';

final _out = Platform.environment['SCREENSHOTS'];

Future<void> _loadFonts() async {
  Future<void> family(String name, List<String> files) async {
    final loader = FontLoader(name);
    for (final file in files) {
      final bytes = File(file).readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }

  await family('Sofia Sans', [
    for (final w in [400, 500, 600, 700]) 'assets/fonts/SofiaSans-$w.ttf',
  ]);
  await family('Sofia Sans Extra Condensed', [
    for (final w in [500, 700, 800])
      'assets/fonts/SofiaSansExtraCondensed-$w.ttf',
  ]);
  final flutterRoot = Platform.environment['FLUTTER_ROOT']!;
  await family('MaterialIcons', [
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

final _posters = [
  for (final name in ['a', 'b', 'c', 'd'])
    File('test/screenshots/poster_$name.png').readAsBytesSync(),
];

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final skip = _out == null ? 'set SCREENSHOTS=<dir> to render' : null;

  final keys = ApiKeys.empty
      .withKey(ApiSource.tmdb, const StoredKey('eyJ', verified: true))
      .withKey(ApiSource.poiskkino, const StoredKey('PK', verified: true))
      .withKey(ApiSource.omdb, const StoredKey('OM', verified: true));

  final boundary = GlobalKey();

  Future<AppDatabase> pump(
    WidgetTester tester, {
    required Brightness brightness,
    Future<void> Function(Library library, AppDatabase db)? seed,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    tester.platformDispatcher.platformBrightnessTestValue = brightness;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.runAsync(_loadFonts);
    SharedPreferences.setMockInitialValues({'locale': 'ru'});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final dio = createDio()..httpClientAdapter = FakeHttpAdapter(apiFixtures);
    if (seed != null) {
      await tester.runAsync(() => seed(Library(db, deviceId: 'shots'), db));
    }
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: ProviderScope(
          retry: (_, _) => null,
          overrides: [
            databaseProvider.overrideWithValue(db),
            deviceIdProvider.overrideWithValue('shots'),
            backgroundRefreshEnabledProvider.overrideWithValue(false),
            googleAccountProvider.overrideWithValue(
              FakeGoogleAccount(MemoryRemote(), configured: false),
            ),
            sharedPreferencesProvider.overrideWithValue(prefs),
            apiKeyStoreProvider.overrideWithValue(
              ApiKeyStore(MemoryKeyStorage()),
            ),
            initialApiKeysProvider.overrideWithValue(keys),
            dioProvider.overrideWithValue(dio),
            responseCacheProvider.overrideWithValue(MemoryResponseCache()),
            posterImageProvider.overrideWithValue(
              (url, _) =>
                  MemoryImage(_posters[url.path.hashCode % _posters.length]),
            ),
          ],
          child: const FramebookApp(),
        ),
      ),
    );
    await settle(tester);
    return db;
  }

  void go(WidgetTester tester, String location) => ProviderScope.containerOf(
    tester.element(find.byType(FramebookApp)),
  ).read(routerProvider).go(location);

  Future<void> shoot(WidgetTester tester, String name) async {
    await settle(tester);
    final render =
        boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await render.toImage(pixelRatio: 2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      return data!.buffer.asUint8List();
    });
    Directory(_out!).createSync(recursive: true);
    File('$_out/$name.png').writeAsBytesSync(bytes!);
  }

  Future<void> library(Library library, AppDatabase db) async {
    final matrix = MovieDetails.fromJson(
      Json(_fixtureJson('tmdb/movie_603_ru.json')),
    );
    await library.rate(
      [WorkSnapshot.movie(matrix)],
      scoreHalf: 18,
      note: 'Пересматривал — всё ещё лучший боевик про выбор.',
    );
    final films = <(int, String, String, int)>[
      (27205, 'Начало', '2010-07-15', 17),
      (157336, 'Интерстеллар', '2014-11-05', 18),
      (680, 'Криминальное чтиво', '1994-09-10', 16),
      (550, 'Бойцовский клуб', '1999-10-15', 15),
      (13, 'Форрест Гамп', '1994-06-23', 17),
      (238, 'Крёстный отец', '1972-03-14', 19),
    ];
    for (final (id, title, date, score) in films) {
      await library.rate(
        [
          WorkSnapshot(
            key: WorkKey.movie(id),
            tmdbId: id,
            title: title,
            releaseDate: date,
            posterPath: '/p$id.jpg',
            genreIds: const [18, 28],
          ),
        ],
        scoreHalf: score,
        note: null,
      );
    }
    await RatingsService(db).refresh(
      RatingTarget(
        key: matrix.key,
        tmdbVote: matrix.vote,
        imdbId: matrix.imdbId,
      ),
    );
  }

  for (final brightness in Brightness.values) {
    final theme = brightness.name;

    testWidgets('card $theme', skip: skip != null, (tester) async {
      await pump(tester, brightness: brightness, seed: library);
      go(tester, '/search/movie/603');
      await shoot(tester, 'card-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('editor $theme', skip: skip != null, (tester) async {
      await pump(tester, brightness: brightness, seed: library);
      go(tester, '/search/movie/603');
      await settle(tester);
      await tester.tap(find.byIcon(Icons.edit_outlined));
      await shoot(tester, 'editor-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('cast $theme', skip: skip != null, (tester) async {
      await pump(tester, brightness: brightness, seed: library);
      go(tester, '/search/movie/603');
      await settle(tester);
      await tester.scrollUntilVisible(
        find.text('Композитор'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await shoot(tester, 'cast-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('person $theme', skip: skip != null, (tester) async {
      await pump(tester, brightness: brightness, seed: library);
      go(tester, '/search/person/6384');
      await shoot(tester, 'person-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('ratings $theme', skip: skip != null, (tester) async {
      await pump(tester, brightness: brightness, seed: library);
      go(tester, Routes.ratings);
      await shoot(tester, 'ratings-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('stats $theme', skip: skip != null, (tester) async {
      await pump(tester, brightness: brightness, seed: library);
      go(tester, Routes.stats);
      await shoot(tester, 'stats-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('watchlist $theme', skip: skip != null, (tester) async {
      await pump(
        tester,
        brightness: brightness,
        seed: (library, db) async {
          for (final (id, title, date) in [
            (603, 'Матрица', '1999-03-31'),
            (157336, 'Интерстеллар', '2014-11-05'),
            (1399, 'Игра престолов', '2011-04-17'),
          ]) {
            await library.addToWatchlist([
              WorkSnapshot(
                key: id == 1399 ? const WorkKey.tv(1399) : WorkKey.movie(id),
                tmdbId: id,
                title: title,
                releaseDate: date,
                posterPath: '/w$id.jpg',
              ),
            ]);
          }
        },
      );
      go(tester, Routes.watchlist);
      await shoot(tester, 'watchlist-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('settings $theme', skip: skip != null, (tester) async {
      await pump(tester, brightness: brightness);
      go(tester, Routes.settings);
      await shoot(tester, 'settings-$theme');
      go(tester, Routes.sync);
      await shoot(tester, 'sync-$theme');
      go(tester, Routes.about);
      await shoot(tester, 'about-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });

    testWidgets('search $theme', skip: skip != null, (tester) async {
      await pump(tester, brightness: brightness);
      await shoot(tester, 'search-$theme');
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });
  }
}

/// Lets images decode (that needs real async) and animations finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pumpAndSettle(
      const Duration(milliseconds: 100),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 10),
    );
  }
}

Map<String, Object?> _fixtureJson(String path) =>
    (const JsonCodec().decode(fixture(path)) as Map).cast<String, Object?>();
