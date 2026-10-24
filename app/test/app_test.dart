import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/app.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/router.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/response_cache.dart';
import 'package:framebook/shared/poster.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/api_fixtures.dart';
import 'support/fake_http.dart';
import 'support/memory_key_storage.dart';

void main() {
  late MemoryKeyStorage storage;

  Future<void> pumpApp(
    WidgetTester tester, {
    ApiKeys keys = ApiKeys.empty,
  }) async {
    // A phone-sized screen (360×780 dp) instead of the default 800×600: the
    // layouts are made for a phone, and a narrow screen catches overflows.
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    // Every API answers with recorded responses; the TMDB key check is
    // /configuration, which the fixtures have.
    final dio = createDio()..httpClientAdapter = FakeHttpAdapter(apiFixtures);
    storage = MemoryKeyStorage();

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiKeyStoreProvider.overrideWithValue(ApiKeyStore(storage)),
          initialApiKeysProvider.overrideWithValue(keys),
          dioProvider.overrideWithValue(dio),
          responseCacheProvider.overrideWithValue(MemoryResponseCache()),
          posterImageProvider.overrideWithValue(
            (_, _) => MemoryImage(transparentPng),
          ),
        ],
        child: const FramebookApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  FilledButton continueButton(WidgetTester tester) => tester
      .widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));

  testWidgets('without a TMDB key the app opens on onboarding', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome to Framebook'), findsOneWidget);
    expect(find.text('Add a working TMDB key to continue.'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('a checked TMDB key unlocks the app', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField).first, 'eyJtoken');
    await tester.tap(find.widgetWithText(FilledButton, 'Check and save').first);
    await tester.pumpAndSettle();

    expect(find.text('Key works'), findsOneWidget);
    expect(storage.values['api_key.tmdb'], 'eyJtoken');
    expect(storage.values['api_key.tmdb.verified'], 'true');

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Find a film or series by title.'), findsOneWidget);
  });

  testWidgets('with a TMDB key the app opens on the tabs', (tester) async {
    await pumpApp(
      tester,
      keys: ApiKeys.empty.withKey(
        ApiSource.tmdb,
        const StoredKey('eyJ', verified: true),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Search', 'My ratings', 'Watchlist', 'Stats']) {
      expect(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
        findsOneWidget,
      );
    }

    await tester.tap(find.text('Stats'));
    await tester.pumpAndSettle();
    expect(
      find.text('Statistics will be here once you have ratings.'),
      findsOneWidget,
    );
  });

  testWidgets('removing the TMDB key in settings returns to onboarding', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: ApiKeys.empty.withKey(
        ApiSource.tmdb,
        const StoredKey('eyJ', verified: true),
      ),
    );

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sources and API keys'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Remove').first);
    await tester.pumpAndSettle();

    expect(find.text('Welcome to Framebook'), findsOneWidget);
  });

  /// pumpAndSettle with a short limit: an endless animation (a spinner that
  /// never got its answer) fails with a clear reason instead of hanging for
  /// ten minutes.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );

  /// A scenario with a card open. The tree is unmounted inside the test: when
  /// closing a `watch()` stream drift schedules a Timer, and the pending
  /// timers check runs before addTearDown.
  void cardTest(String description, Future<void> Function(WidgetTester) body) =>
      testWidgets(description, (tester) async {
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
      });

  final allKeys = ApiKeys.empty
      .withKey(ApiSource.tmdb, const StoredKey('eyJ', verified: true))
      .withKey(ApiSource.poiskkino, const StoredKey('PK', verified: true))
      .withKey(ApiSource.omdb, const StoredKey('OM', verified: true));

  Finder inList(String text) =>
      find.descendant(of: find.byType(ListView), matching: find.text(text));

  cardTest('search finds The Matrix and its card shows every rating', (
    tester,
  ) async {
    await pumpApp(tester, keys: allKeys);

    await tester.enterText(find.byType(TextField), 'Матрица');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);

    expect(inList('Матрица'), findsOneWidget);
    expect(inList('Film · 1999 · The Matrix'), findsOneWidget);
    expect(inList('Series · 2003 · Threat Matrix'), findsOneWidget);

    await tester.tap(inList('Матрица'));
    await settle(tester);

    expect(find.text('«Добро пожаловать в реальный мир»'), findsOneWidget);
    expect(find.text('1999 · 2 h 16 min'), findsOneWidget);
    for (final label in [
      'Kinopoisk',
      'IMDb',
      'TMDB',
      'Rotten Tomatoes',
      'Metacritic',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(find.text('8.5'), findsOneWidget); // Kinopoisk 8.501
    expect(find.text('817K votes'), findsOneWidget);
    expect(find.text('8.7'), findsOneWidget); // IMDb from OMDb
    expect(find.text('8.3'), findsWidgets); // TMDB 8.261
    expect(find.text('83%'), findsOneWidget);
    expect(find.text('73'), findsOneWidget);

    // Back returns to the search results, not to an empty field.
    await tester.pageBack();
    await settle(tester);
    expect(inList('Film · 1999 · The Matrix'), findsOneWidget);
  });

  cardTest('without optional keys the card asks for them', (tester) async {
    await pumpApp(
      tester,
      keys: ApiKeys.empty.withKey(
        ApiSource.tmdb,
        const StoredKey('eyJ', verified: true),
      ),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    );
    container.read(routerProvider).go('/search/movie/603');
    await settle(tester);

    expect(find.text('add a key'), findsNWidgets(4)); // Kinopoisk, IMDb, RT, MC
    expect(find.text('8.3'), findsOneWidget); // TMDB is always there

    await tester.tap(find.text('add a key').first);
    await settle(tester);
    expect(find.text('Sources and API keys'), findsOneWidget);
  });

  cardTest('series → season → episode', (tester) async {
    await pumpApp(tester, keys: allKeys);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    );
    container.read(routerProvider).go('/search/tv/1399');
    await settle(tester);

    expect(find.text('2011–2019 · ended'), findsOneWidget);
    expect(find.text('8 seasons · 73 episodes'), findsOneWidget);
    expect(find.text('9.0'), findsOneWidget); // Kinopoisk 9.009
    expect(find.text('9.2'), findsOneWidget); // IMDb

    await tester.scrollUntilVisible(find.text('Сезон 1'), 200);
    await tester.tap(find.text('Сезон 1'));
    await settle(tester);

    expect(find.text('episode average'), findsOneWidget);
    expect(find.text('9.0'), findsOneWidget); // IMDb episode average 8.97
    expect(find.text('Kinopoisk'), findsNothing);

    await tester.scrollUntilVisible(find.text('Лорд Сноу'), 200);
    await tester.tap(find.text('Лорд Сноу'));
    await settle(tester);

    expect(find.text('S1 · E3 · May 1, 2011 · 58 min'), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget); // the episode's IMDb
    expect(find.text('41.9K votes'), findsOneWidget);
  });

  cardTest('a title TMDB does not have says so', (tester) async {
    await pumpApp(tester, keys: allKeys);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    );
    container.read(routerProvider).go('/search/movie/42');
    await settle(tester);
    expect(find.text('TMDB has no such title.'), findsOneWidget);
  });
}
