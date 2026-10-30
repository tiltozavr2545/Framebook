import 'package:framebook/data/update_checker.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
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
import 'package:framebook/data/response_cache.dart';
import 'package:framebook/data/sync/google_account.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/person/person_screen.dart';
import 'package:framebook/features/title/movie_screen.dart';
import 'package:framebook/features/title/score_reel.dart';
import 'package:framebook/shared/poster.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/api_fixtures.dart';
import 'support/fake_google.dart';
import 'support/fake_http.dart';
import 'support/memory_remote.dart';
import 'support/memory_key_storage.dart';

void main() {
  late MemoryKeyStorage storage;
  late MemoryRemote drive;

  Future<void> pumpApp(
    WidgetTester tester, {
    ApiKeys keys = ApiKeys.empty,
    Future<void> Function(Library library)? seed,
    GoogleAccount? google,
    Reply? Function(RequestOptions request) http = apiFixtures,
  }) async {
    drive = MemoryRemote();
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
    final dio = createDio()..httpClientAdapter = FakeHttpAdapter(http);
    storage = MemoryKeyStorage();
    if (seed != null) {
      // Real async: these database writes shouldn't run under fake time.
      await tester.runAsync(() => seed(Library(db, deviceId: 'test')));
    }

    await tester.pumpWidget(
      ProviderScope(
        retry: (_, _) => null,
        overrides: [
          updateChecksEnabledProvider.overrideWithValue(false),
          databaseProvider.overrideWithValue(db),
          deviceIdProvider.overrideWithValue('test'),
          // Its passes run on timers; it has tests of its own.
          backgroundRefreshEnabledProvider.overrideWithValue(false),
          googleAccountProvider.overrideWithValue(
            google ?? FakeGoogleAccount(drive, configured: false),
          ),
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

  /// Every scenario: the tree is unmounted inside the test. When closing a
  /// `watch()` stream drift schedules a Timer, and the pending timers check
  /// runs before addTearDown — and since Discover watches your ratings,
  /// every screen past onboarding has such a stream.
  void cardTest(String description, Future<void> Function(WidgetTester) body) =>
      testWidgets(description, (tester) async {
        await body(tester);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
      });

  cardTest('without a TMDB key the app opens on onboarding', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome to Framebook'), findsOneWidget);
    expect(find.text('Add a working TMDB key to continue.'), findsOneWidget);
    expect(continueButton(tester).onPressed, isNull);
    expect(find.byType(NavigationBar), findsNothing);
  });

  cardTest('Drive restore is accessible without a TMDB key', (tester) async {
    await pumpApp(tester);
    await tester.tap(find.text('Restore from Google Drive'));
    await tester.pumpAndSettle();
    expect(find.text('Sync and backup'), findsOneWidget);
    expect(find.text('Welcome to Framebook'), findsNothing);
  });

  cardTest('a checked TMDB key unlocks the app', (tester) async {
    await pumpApp(tester);

    await tester.enterText(find.byType(TextField).first, 'eyJtoken');
    final check = find.widgetWithText(FilledButton, 'Check and save').first;
    await tester.ensureVisible(check);
    await tester.pumpAndSettle();
    await tester.tap(check);
    await tester.pumpAndSettle();

    expect(find.text('Key works'), findsOneWidget);
    expect(storage.values['api_key.tmdb'], 'eyJtoken');
    expect(storage.values['api_key.tmdb.verified'], 'true');

    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Trending this week'), findsOneWidget);
  });

  cardTest('with a TMDB key the app opens on the tabs', (tester) async {
    await pumpApp(
      tester,
      keys: ApiKeys.empty.withKey(
        ApiSource.tmdb,
        const StoredKey('eyJ', verified: true),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    for (final label in ['Discover', 'Ratings', 'Watchlist', 'Stats']) {
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

  cardTest('removing the TMDB key in settings returns to onboarding', (
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
    await tester.scrollUntilVisible(
      find.text('Kinopoisk'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('9.0'), findsOneWidget); // Kinopoisk 9.009
    expect(find.text('9.2'), findsOneWidget); // IMDb

    await tester.scrollUntilVisible(
      find.text('Сезон 1'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Сезон 1'));
    await settle(tester);

    expect(find.text('episode average'), findsOneWidget);
    expect(find.text('9.0'), findsOneWidget); // IMDb episode average 8.97
    expect(find.text('Kinopoisk'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Лорд Сноу'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
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

  /// Pulls the score reel until [score] stands in the gate: a slow drag
  /// with a pause before letting go, so there is no fling to overshoot.
  Future<void> pickScore(WidgetTester tester, double score) async {
    final reel = find.byType(ScoreReel);
    final position = tester
        .state<ScrollableState>(
          find.descendant(of: reel, matching: find.byType(Scrollable)),
        )
        .position;
    // Frame 0 is score 1; score s is frame 2s − 2.
    final target = (score * 2 - 2) * ScoreReel.extent;
    final gesture = await tester.startGesture(tester.getCenter(reel));
    final distance = position.pixels - target;
    final steps = (distance.abs() / 20).ceil() + 1;
    // The first move only takes up the touch slop.
    await gesture.moveBy(Offset(distance.sign * 20, 0));
    for (var i = 0; i < steps; i++) {
      await gesture.moveBy(Offset(distance / steps, 0));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await settle(tester);
  }

  cardTest('new ratings save 5 and existing ratings reopen at their score', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    go(tester, '/search/movie/603');
    await settle(tester);
    await tester.tap(find.text('Rate'));
    await settle(tester);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('5'), findsWidgets);
    await tester.tap(find.byTooltip('Change'));
    await settle(tester);
    expect(
      tester.widget<ScoreReel>(find.byType(ScoreReel)).initialScoreHalf,
      10,
    );
    await pickScore(tester, 8.5);
    await tester.tap(find.text('Save'));
    await settle(tester);
    await tester.tap(find.byTooltip('Change'));
    await settle(tester);
    expect(
      tester.widget<ScoreReel>(find.byType(ScoreReel)).initialScoreHalf,
      17,
    );
  });

  cardTest('rating a film with a note; it appears in My ratings', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    go(tester, '/search/movie/603');
    await settle(tester);

    await tester.tap(find.text('Rate'));
    await settle(tester);
    // The default score is ready to save without moving the reel.
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNotNull,
    );
    await pickScore(tester, 8.5);
    // The comparison panel stays hidden until there are enough ratings.
    expect(
      find.text(
        'Your first rating of this kind — nothing to compare with yet.',
      ),
      findsNothing,
    );
    await tester.enterText(find.widgetWithText(TextField, 'Note'), 'Классика');
    await tester.tap(find.text('Save'));
    await settle(tester);

    expect(find.text('My rating'), findsOneWidget);
    expect(find.text('8.5'), findsOneWidget);
    expect(find.text('Классика'), findsOneWidget);

    await tester.tap(tab('Ratings'));
    await settle(tester);
    expect(inList('Матрица'), findsOneWidget);
    expect(inList('Film · 1999'), findsOneWidget);
    expect(inList('8.5'), findsOneWidget);

    // A row opens the card inside this tab.
    await tester.tap(inList('Матрица'));
    await settle(tester);
    expect(find.text('Классика'), findsOneWidget);
  });

  cardTest('the reel compares while it moves, before saving', (tester) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) async {
        await inceptionRated(library, 17);
        for (var id = 1; id <= 20; id++) {
          await library.rate(
            [
              WorkSnapshot(
                key: WorkKey.movie(id),
                tmdbId: id,
                title: 'Film $id',
              ),
            ],
            scoreHalf: 2,
            note: null,
          );
        }
      },
    );
    go(tester, '/search/movie/603');
    await settle(tester);

    await tester.tap(find.text('Rate'));
    await settle(tester);
    await pickScore(tester, 8.5);
    expect(find.text('Also 8.5'), findsOneWidget);
    expect(find.text('Начало'), findsOneWidget);

    // Half a point higher: Inception becomes the neighbour below.
    await pickScore(tester, 9);
    expect(find.text('Also 9'), findsOneWidget);
    expect(find.text('A step below · 8.5'), findsOneWidget);
    expect(find.text('Начало'), findsOneWidget);

    await tester.tap(find.text('Save'));
    await settle(tester);
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
    await tester.tap(tab('Ratings'));
    await settle(tester);
    expect(inList('Начало'), findsOneWidget);

    // The chip row scrolls sideways on a phone.
    await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'Episodes'));
    await settle(tester);
    await tester.tap(find.widgetWithText(ChoiceChip, 'Episodes'));
    await settle(tester);
    expect(find.text('Nothing of this kind is rated yet.'), findsOneWidget);
  });

  /// The Matrix, rated before the test starts.
  // Stage 6.5: TMDB renumbering. The fixtures are as TMDB answers now; a
  // rating "from before" is seeded with another title's id under its number.

  cardTest('a rating TMDB renumbered is moved to its episode on asking', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      // S1 · E5 was rated when it was the episode TMDB now numbers E3.
      seed: (library) => library.rate(
        [
          const WorkSnapshot(key: WorkKey.tv(1399), tmdbId: 1399, title: 'GoT'),
          const WorkSnapshot(
            key: WorkKey.season(1399, 1),
            tmdbId: 3624,
            title: 'Сезон 1',
          ),
          const WorkSnapshot(
            key: WorkKey.episode(1399, 1, 5),
            tmdbId: 63058,
            title: 'Лорд Сноу',
          ),
        ],
        scoreHalf: 3,
        note: null,
      ),
    );
    go(tester, '/search/tv/1399/s/1');
    await settle(tester);

    const question =
        'Your rating of S1 · E5 was for an episode that is now S1 · E3. '
        'Move it?';
    await tester.scrollUntilVisible(
      find.text(question),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Move'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Move'));
    await settle(tester);

    expect(find.text(question), findsNothing);
    final row = find.ancestor(
      of: find.text('Лорд Сноу'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: row, matching: find.text('1.5')),
      findsOneWidget,
    );
  });

  cardTest('keeping a renumbered season\'s rating asks no more', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      // Rated as season 2 when it was the season TMDB now numbers 1.
      seed: (library) => library.rate(
        [
          const WorkSnapshot(key: WorkKey.tv(1399), tmdbId: 1399, title: 'GoT'),
          const WorkSnapshot(
            key: WorkKey.season(1399, 2),
            tmdbId: 3624,
            title: 'Сезон 2',
          ),
        ],
        scoreHalf: 3,
        note: null,
      ),
    );
    go(tester, '/search/tv/1399');
    await settle(tester);

    const question =
        'Your rating of Season 2 was for a season that is now Season 1. '
        'Move it?';
    await tester.scrollUntilVisible(
      find.text(question),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.widgetWithText(TextButton, 'Keep'));
    await settle(tester);
    await tester.tap(find.widgetWithText(TextButton, 'Keep'));
    await settle(tester);

    expect(find.text(question), findsNothing);
    final row = find.ancestor(
      of: find.text('Сезон 2'),
      matching: find.byType(ListTile),
    );
    expect(
      find.descendant(of: row, matching: find.text('1.5')),
      findsOneWidget,
    );
  });

  Future<void> matrixRated(Library library, int scoreHalf) => library.rate(
    [
      const WorkSnapshot(
        key: WorkKey.movie(603),
        tmdbId: 603,
        title: 'Матрица',
        releaseDate: '1999-03-31',
        imdbId: 'tt0133093',
      ),
    ],
    scoreHalf: scoreHalf,
    note: null,
  );

  cardTest('the card shows mine minus theirs on the 1–10 ratings', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: allKeys,
      seed: (library) => matrixRated(library, 18),
    );
    go(tester, '/search/movie/603');
    await settle(tester);

    expect(find.text('+0.5'), findsOneWidget); // 9 − Kinopoisk 8.501
    expect(find.text('+0.3'), findsOneWidget); // 9 − IMDb 8.7
    expect(find.text('+0.7'), findsOneWidget); // 9 − TMDB 8.261
    // Rotten Tomatoes and Metacritic are other scales: no difference.
    expect(find.textContaining('+'), findsNWidgets(3));
  });

  cardTest('My ratings sorts by divergence from Kinopoisk', (tester) async {
    await pumpApp(
      tester,
      keys: allKeys,
      seed: (library) async {
        await matrixRated(library, 18);
        await inceptionRated(library, 17);
      },
    );
    // Opening the card fetches the Matrix's ratings; Inception's stay
    // unknown (background refresh is off in tests).
    go(tester, '/search/movie/603');
    await settle(tester);
    await tester.tap(tab('Ratings'));
    await settle(tester);

    await tester.tap(find.byTooltip('Sort'));
    await settle(tester);
    await tester.tap(find.text('By divergence'));
    await settle(tester);

    expect(find.text('Kinopoisk ratings loaded for 1 of 2'), findsOneWidget);
    expect(inList('8.5 · +0.5'), findsOneWidget);
    expect(inList('no data'), findsOneWidget);
    // Rows without data go last.
    expect(
      tester.getTopLeft(inList('Матрица')).dy,
      lessThan(tester.getTopLeft(inList('Начало')).dy),
    );

    await tester.tap(find.widgetWithText(ChoiceChip, 'IMDb'));
    await settle(tester);
    expect(find.text('IMDb ratings loaded for 1 of 2'), findsOneWidget);
    expect(inList('8.7 · +0.3'), findsOneWidget);
  });

  cardTest('Stats: distribution, comparison, genres and decades', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) async {
        await matrixRated(library, 15);
        await library.rate(
          [
            const WorkSnapshot(
              key: WorkKey.movie(27205),
              tmdbId: 27205,
              title: 'Начало',
              releaseDate: '2010-07-15',
              genreIds: [28, 878],
            ),
          ],
          scoreHalf: 17,
          note: null,
        );
      },
    );
    await tester.tap(tab('Stats'));
    await settle(tester);
    // The list, not the chip row that also scrolls.
    final statsList = find.descendant(
      of: find.byType(ListView),
      matching: find.byType(Scrollable),
    );

    expect(find.text('8.0'), findsOneWidget);
    expect(find.text('your average over 2 ratings'), findsOneWidget);
    expect(find.text('Your scores'), findsOneWidget);
    // Without a PoiskKino key there is nothing to compare with.
    await tester.scrollUntilVisible(
      find.text('Nothing to compare with yet: no Kinopoisk ratings.'),
      200,
      scrollable: statsList,
    );
    expect(
      find.text('Add a key in Sources to compare with Kinopoisk'),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      find.text('By genre'),
      200,
      scrollable: statsList,
    );
    await settle(tester);
    await tester.scrollUntilVisible(
      find.text('1990s · 1 rating'),
      200,
      scrollable: statsList,
    );
    expect(find.text('Боевик · 1 rating'), findsOneWidget);
    expect(find.text('2010s · 1 rating'), findsOneWidget);
  });

  cardTest('signing in merges with Google Drive after a dialog', (
    tester,
  ) async {
    // Another device already put the Matrix in Drive.
    final other = MemoryRemote();
    await tester.runAsync(() async {
      final db = AppDatabase(NativeDatabase.memory());
      await matrixRated(Library(db, deviceId: 'other'), 18);
      other.put(
        SyncFile.name,
        SyncFile.encode(
          await SyncStore(db).read(),
          writtenAt: 1,
          writtenBy: 'other',
          appVersion: 'test',
        ),
      );
      await db.close();
    });
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) => inceptionRated(library, 17),
      google: FakeGoogleAccount(other),
    );

    go(tester, Routes.sync);
    await settle(tester);
    await tester.tap(find.text('Sign in with Google'));
    await settle(tester);

    expect(find.text('Merge with Google Drive?'), findsOneWidget);
    expect(
      find.textContaining(
        'Ratings on this device: 1. In Google Drive: 1. After merging: 2.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Merge'));
    await settle(tester);
    expect(find.text('Signed in as me@example.com'), findsOneWidget);
    expect(find.textContaining('Last synced'), findsOneWidget);

    // Both films are here now, and Drive has both too.
    go(tester, Routes.ratings);
    await settle(tester);
    expect(inList('Матрица'), findsOneWidget);
    expect(inList('Начало'), findsOneWidget);
    final file = SyncFile.decode(
      other.files.values.firstWhere((f) => f.name == SyncFile.name).bytes,
    );
    expect(file.liveRatings, 2);
  });

  cardTest('without a Google setup the screen says so', (tester) async {
    await pumpApp(tester, keys: tmdbOnly);
    await tester.tap(find.byTooltip('Settings'));
    await settle(tester);
    await tester.tap(find.text('Sync and backup'));
    await settle(tester);
    expect(
      find.text("Google sign-in isn't set up in this build of the app."),
      findsOneWidget,
    );
    expect(find.text('Export to a file'), findsOneWidget);
  });

  cardTest('Discover: the shelves, with one like your favourites', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    // Nothing rated 8+ yet: no "like your favourites".
    expect(find.text('Like your favourites'), findsNothing);
    expect(find.text('Trending this week'), findsOneWidget);
    expect(find.text('In cinemas now'), findsOneWidget);
    // Start over with a film rated 9.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));

    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) => matrixRated(library, 18),
    );
    expect(find.text('Like your favourites'), findsOneWidget);
    expect(find.text('Матрица: Революция'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Best of all time'),
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Best of all time'), findsOneWidget);
  });

  cardTest('the cast opens a person, their filmography opens a card', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    go(tester, '/search/movie/603');
    await settle(tester);
    expect(find.text('Cast'), findsNothing); // below the fold
    await tester.scrollUntilVisible(
      find.text('Киану Ривз'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Neo'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Don Davis'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Directors'), findsOneWidget);

    await tester.tap(find.text('Киану Ривз'));
    await settle(tester);
    expect(find.text('Filmography'), findsOneWidget);
    expect(find.textContaining('Born'), findsOneWidget);

    // Back in 1999, the film this started from.
    await tester.scrollUntilVisible(
      find.text('Матрица').hitTestable(),
      600,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Матрица'));
    await settle(tester);
    expect(find.text('The Matrix'), findsOneWidget);

    // Back walks the pushes: the person, then the first card.
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(PersonScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.byType(PersonScreen), findsNothing);
    expect(find.byType(MovieScreen), findsOneWidget);
  });

  cardTest('offline, a rated title opens from its saved snapshot', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) => matrixRated(library, 18),
      // TMDB's film cards are out of reach.
      http: (request) => request.uri.path.startsWith('/3/movie/')
          ? null
          : apiFixtures(request),
    );
    go(tester, '/search/movie/603');
    await settle(tester);
    expect(
      find.textContaining('No connection: this is the saved card'),
      findsOneWidget,
    );
    expect(find.text('Матрица'), findsOneWidget);
    expect(find.text('Film · 1999'), findsOneWidget);
    expect(find.text('9'), findsOneWidget);

    // A title you never rated has nothing saved: the usual error.
    go(tester, '/search/movie/604');
    await settle(tester);
    expect(find.textContaining('saved card'), findsNothing);
    expect(find.text('Try again'), findsOneWidget);
  });
}
