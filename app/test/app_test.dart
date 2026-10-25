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
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/response_cache.dart';
import 'package:framebook/data/work_key.dart';
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
    Future<void> Function(Library library)? seed,
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
    if (seed != null) {
      // Real async: these database writes shouldn't run under fake time.
      await tester.runAsync(() => seed(Library(db, deviceId: 'test')));
    }

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('test'),
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
    // The ratings sit below "My rating", past the first screen.
    await tester.scrollUntilVisible(find.text('Kinopoisk'), 200);
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

  // Stage 3: own ratings, the calibration sheet, the watchlist.

  final tmdbOnly = ApiKeys.empty.withKey(
    ApiSource.tmdb,
    const StoredKey('eyJ', verified: true),
  );

  void go(WidgetTester tester, String location) => ProviderScope.containerOf(
    tester.element(find.byType(FramebookApp)),
  ).read(routerProvider).go(location);

  Finder tab(String label) => find.descendant(
    of: find.byType(NavigationBar),
    matching: find.text(label),
  );

  /// Inception, rated before the test starts.
  Future<void> inceptionRated(Library library, int scoreHalf) => library.rate(
    [
      const WorkSnapshot(
        key: WorkKey.movie(27205),
        tmdbId: 27205,
        title: 'Начало',
        releaseDate: '2010-07-15',
      ),
    ],
    scoreHalf: scoreHalf,
    note: null,
  );

  cardTest('rating a film with a note; it appears in My ratings', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    go(tester, '/search/movie/603');
    await settle(tester);

    await tester.tap(find.text('Rate'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '8.5'));
    await tester.enterText(find.widgetWithText(TextField, 'Note'), 'Классика');
    await tester.tap(find.text('Save'));
    await settle(tester);

    // The first film rated: nothing to compare with, so no sheet.
    expect(find.text('How it compares'), findsNothing);
    expect(find.text('My rating'), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
    expect(find.text('Классика'), findsOneWidget);

    await tester.tap(tab('My ratings'));
    await settle(tester);
    expect(inList('Матрица'), findsOneWidget);
    expect(inList('Film · 1999'), findsOneWidget);
    expect(inList('8.5'), findsOneWidget);

    // A row opens the card inside this tab.
    await tester.tap(inList('Матрица'));
    await settle(tester);
    expect(find.text('Классика'), findsOneWidget);
  });

  cardTest('the calibration sheet shows what is rated the same, and nudges', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) => inceptionRated(library, 17),
    );
    go(tester, '/search/movie/603');
    await settle(tester);

    await tester.tap(find.text('Rate'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, '8.5'));
    // Save is enabled only after the chip's rebuild.
    await tester.pump();
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('How it compares'), findsOneWidget);
    expect(find.text('Also 8.5'), findsOneWidget);
    expect(find.text('Начало'), findsOneWidget);

    // Half a point higher: Inception becomes the neighbour below.
    await tester.tap(find.byTooltip('Half a point higher'));
    await settle(tester);
    expect(find.text('Also 9'), findsNothing);
    expect(find.text('A step below · 8.5'), findsOneWidget);
    expect(find.text('Начало'), findsOneWidget);

    await tester.tap(find.text('Done'));
    await settle(tester);
    // The card shows the nudged score.
    expect(find.text('9'), findsOneWidget);
  });

  cardTest('the watchlist: add from the card, remove and undo in the tab', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    go(tester, '/search/movie/603');
    await settle(tester);

    await tester.tap(find.text('Want to watch'));
    await settle(tester);
    expect(find.text('On the watchlist'), findsOneWidget);

    await tester.tap(tab('Watchlist'));
    await settle(tester);
    expect(inList('Матрица'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from the watchlist'));
    await settle(tester);
    expect(inList('Матрица'), findsNothing);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(inList('Матрица'), findsOneWidget);
  });

  cardTest('deleting a rating asks first', (tester) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) => library.rate(
        [
          const WorkSnapshot(
            key: WorkKey.movie(603),
            tmdbId: 603,
            title: 'Матрица',
          ),
        ],
        scoreHalf: 16,
        note: null,
      ),
    );
    go(tester, '/search/movie/603');
    await settle(tester);
    expect(find.text('My rating'), findsOneWidget);

    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    expect(find.text('Delete your rating?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(tester);

    expect(find.text('My rating'), findsNothing);
    expect(find.text('Rate'), findsOneWidget);
  });

  cardTest('My ratings filters by kind', (tester) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) => inceptionRated(library, 17),
    );
    await tester.tap(tab('My ratings'));
    await settle(tester);
    expect(inList('Начало'), findsOneWidget);

    // The chip row scrolls sideways on a phone.
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Episodes'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Episodes'));
    await settle(tester);
    expect(find.text('Nothing of this kind is rated yet.'), findsOneWidget);
  });
}
