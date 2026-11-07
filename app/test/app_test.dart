import 'dart:async';
import 'dart:convert';

import 'package:framebook/features/title/cover_viewer.dart';
import 'package:framebook/features/title/title_layout.dart';
import 'package:framebook/features/title/ratings_panel.dart';
import 'package:framebook/data/update_checker.dart';
import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import 'package:framebook/data/library/favorite_people.dart';
import 'package:framebook/data/recommendations/providers.dart';
import 'package:framebook/data/recommendations/hidden.dart';
import 'package:framebook/data/recommendations/ranking.dart';
import 'package:framebook/app/ratings_preferences.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/response_cache.dart';
import 'package:framebook/data/sources/providers.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sync/google_account.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/person/person_screen.dart';
import 'package:framebook/features/search/search_controller.dart';
import 'package:framebook/features/search/search_mode_switcher.dart';
import 'package:framebook/features/search/search_history.dart';
import 'package:framebook/features/title/movie_screen.dart';
import 'package:framebook/features/title/score_reel.dart';
import 'package:framebook/shared/poster.dart';
import 'package:framebook/shared/favorite_person_portrait.dart';
import 'package:framebook/features/shell/navigation_motion.dart';
import 'package:framebook/features/title/cast_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/api_fixtures.dart';
import 'support/inline_view_computer.dart';
import 'package:framebook/data/view_computer.dart';
import 'support/fake_google.dart';
import 'support/fake_http.dart';
import 'support/memory_remote.dart';
import 'support/memory_key_storage.dart';

void main() {
  final allKeys = ApiKeys.empty
      .withKey(ApiSource.tmdb, const StoredKey('eyJ', verified: true))
      .withKey(ApiSource.poiskkino, const StoredKey('PK', verified: true))
      .withKey(ApiSource.omdb, const StoredKey('OM', verified: true));
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
          viewComputerProvider.overrideWithValue(const InlineViewComputer()),
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
          catalogJsonParserProvider.overrideWithValue(
            (body) async => tryJson(body),
          ),
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

  /// Fail quickly if an unfinished request leaves an endless spinner.
  Future<void> settle(WidgetTester tester) => tester.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );

  /// Every scenario: the tree is unmounted inside the test. When closing a
  /// `watch()` stream drift schedules a Timer, and the pending timers check
  /// runs before addTearDown — and since Discover watches your ratings,
  /// every screen past onboarding has such a stream.
  void cardTest(String description, Future<void> Function(WidgetTester) body) =>
      testWidgets(description, (tester) async {
        try {
          await body(tester);
        } finally {
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(milliseconds: 1));
        }
      });

  for (final keyboardOpen in [true, false]) {
    cardTest('search restores only an open keyboard on resume: $keyboardOpen', (
      tester,
    ) async {
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await pumpApp(tester, keys: allKeys);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      tester.view.viewInsets = FakeViewPadding(bottom: keyboardOpen ? 900 : 0);
      await tester.pump();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.view.viewInsets = FakeViewPadding.zero;
      tester.testTextInput.log.clear();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.hidden);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(
        tester.testTextInput.log.where(
          (call) => call.method == 'TextInput.show',
        ),
        keyboardOpen ? isNotEmpty : isEmpty,
      );
    });
  }

  cardTest('movie facts and related titles preserve navigation back to the film', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: allKeys,
      http: (request) {
        if (request.uri.path == '/3/collection/2344') {
          return (
            status: 200,
            body:
                '{"parts":[{"id":603,"title":"Current"},{"id":604,"title":"Related sequel","release_date":"2003-01-01"},{"id":604,"title":"Duplicate"}]}',
          );
        }
        if (request.uri.path.endsWith('/similar')) {
          return (
            status: 200,
            body:
                '{"results":[{"id":603,"title":"Current"},{"id":604,"title":"Similar sequel","release_date":"2003-01-01"}]}',
          );
        }
        if (request.uri.path == '/3/movie/604') {
          return (status: 200, body: '{"id":604,"title":"Sequel card"}');
        }
        return apiFixtures(request);
      },
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    );
    final router = container.read(routerProvider);
    router.go('/search/movie/603');
    await tester.pumpAndSettle();
    expect(find.textContaining('Mar 31, 1999'), findsOneWidget);
    expect(find.text('United States of America'), findsOneWidget);
    expect(find.textContaining(r'Budget: $63,000,000'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(TitleHeader),
        matching: find.textContaining(r'Budget: $63,000,000'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(TitleHeader),
        matching: find.text('1999 · 2 h 16 min'),
      ),
      findsNothing,
    );
    expect(
      find.textContaining(r'Worldwide box office: $463,517,383'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Related sequel'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Current'), findsNothing);
    expect(find.text('Duplicate'), findsNothing);
    await Scrollable.ensureVisible(
      tester.element(find.text('Related sequel')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Related sequel'));
    await tester.pumpAndSettle();
    expect(find.text('Sequel card'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<MovieScreen>(find.byType(MovieScreen)).id, 603);
    await tester.scrollUntilVisible(
      find.text('Similar sequel'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Similar sequel')),
      alignment: 0.5,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Similar sequel'));
    await tester.pumpAndSettle();
    expect(find.text('Sequel card'), findsOneWidget);
    router.pop();
    await tester.pumpAndSettle();
    expect(tester.widget<MovieScreen>(find.byType(MovieScreen)).id, 603);
    expect(tester.takeException(), isNull);
  });

  cardTest('recent titles appear in a dropdown and reopen their cards', (
    tester,
  ) async {
    await pumpApp(tester, keys: allKeys);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    );
    final history = container.read(searchHistoryProvider.notifier);
    await history.remember(
      const SearchHistoryEntry(
        key: WorkKey.movie(603),
        title: 'Recent Matrix',
        year: 1999,
      ),
    );
    await history.remember(
      const SearchHistoryEntry(
        key: WorkKey.tv(1399),
        title: 'Recent series',
        year: 2011,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Recent Matrix'), findsNothing);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(find.text('Recent Matrix'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from history').first);
    await tester.pumpAndSettle();
    expect(container.read(searchHistoryProvider).length, 1);
    await tester.tap(find.text('Recent Matrix'));
    await tester.pumpAndSettle();
    expect(find.byType(MovieScreen), findsOneWidget);
    expect(find.text('Recent Matrix'), findsNothing);
    container.read(routerProvider).go(Routes.search);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clear history'));
    await tester.pumpAndSettle();
    expect(container.read(searchHistoryProvider), isEmpty);
    expect(find.text('Recently opened'), findsNothing);
  });

  cardTest('without a TMDB key the app opens on onboarding', (tester) async {
    await pumpApp(tester);

    expect(find.text('Welcome to Framebook'), findsOneWidget);
    expect(
      find.text(
        'Register your TMDB account and API key on a computer, not a phone.',
      ),
      findsOneWidget,
    );
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

  cardTest(
    'search mode field matches search width and drags results with a shared query',
    (tester) async {
      await pumpApp(tester, keys: allKeys);
      final mode = find.byKey(const ValueKey('search-mode-slider'));
      final fieldBounds = tester.getRect(find.byType(TextField));
      final modeBounds = tester.getRect(mode);
      expect(modeBounds.left, fieldBounds.left);
      expect(modeBounds.width, fieldBounds.width);
      expect(modeBounds.height, closeTo(fieldBounds.height, 4));
      expect(modeBounds.top, greaterThan(fieldBounds.bottom));
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      await tester.enterText(find.byType(TextField), 'Matrix');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      final pages = tester.widget<SearchModePages>(
        find.byType(SearchModePages),
      );
      final gesture = await tester.startGesture(
        modeBounds.center - const Offset(80, 0),
      );
      await gesture.moveBy(const Offset(25, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(105, 0));
      await tester.pump();
      expect(pages.position.value, inExclusiveRange(0.5, 1));
      final page = find.descendant(
        of: find.byType(SearchModePages),
        matching: find.byType(FractionalTranslation),
      );
      expect(page, findsNWidgets(2));
      expect(
        tester.widget<FractionalTranslation>(page.first).translation.dx,
        lessThan(0),
      );
      await gesture.up();
      await settle(tester);
      expect(container.read(searchProvider).kind, SearchKind.people);
      expect(container.read(searchProvider).people, isNotEmpty);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        'Matrix',
      );
      await tester.tap(find.byKey(const ValueKey('search-mode-0')));
      await settle(tester);
      expect(container.read(searchProvider).kind, SearchKind.titles);
      expect(container.read(searchProvider).results, isNotEmpty);
      expect(container.read(searchProvider).query, 'Matrix');
      expect(pages.position.value, 0);
      container.read(searchProvider.notifier).selectKind(SearchKind.people);
      await settle(tester);
      expect(pages.position.value, 1);
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await settle(tester);
      expect(tester.takeException(), isNull);
    },
  );

  cardTest(
    'search modes retain shelf scroll position and dismiss title history',
    (tester) async {
      await pumpApp(tester, keys: allKeys);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      await container
          .read(searchHistoryProvider.notifier)
          .remember(
            const SearchHistoryEntry(
              key: WorkKey.movie(603),
              title: 'Saved history',
            ),
          );
      await tester.tap(find.byType(TextField));
      await settle(tester);
      expect(find.text('Recently opened'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('search-mode-1')));
      await settle(tester);
      expect(find.text('Recently opened'), findsNothing);
      expect(container.read(searchProvider).kind, SearchKind.people);
      expect(container.read(searchHistoryProvider), hasLength(1));
      await tester.tap(find.byKey(const ValueKey('search-mode-0')));
      await settle(tester);
      final scrollable = find
          .descendant(
            of: find.byType(SearchModePages),
            matching: find.byType(Scrollable),
          )
          .first;
      await tester.drag(scrollable, const Offset(0, -300));
      await settle(tester);
      final position = tester.state<ScrollableState>(scrollable).position;
      final offset = position.pixels;
      expect(offset, greaterThan(0));
      await tester.tap(find.byKey(const ValueKey('search-mode-1')));
      await settle(tester);
      await tester.tap(find.byKey(const ValueKey('search-mode-0')));
      await settle(tester);
      expect(position.pixels, offset);
      expect(find.text('Recently opened'), findsNothing);
    },
  );

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

  Finder inList(String text) =>
      find.descendant(of: find.byType(ListView), matching: find.text(text));

  cardTest('search finds The Matrix and its card shows every rating', (
    tester,
  ) async {
    await pumpApp(tester, keys: allKeys);

    await tester.enterText(find.byType(TextField), 'Матрица');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);

    final historyContainer = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    );
    expect(historyContainer.read(searchHistoryProvider), isEmpty);

    expect(inList('Матрица'), findsOneWidget);
    expect(inList('Film · 1999 · The Matrix'), findsOneWidget);
    expect(inList('Series · 2003 · Threat Matrix'), findsOneWidget);

    await tester.tap(inList('Матрица'));
    await settle(tester);

    expect(
      historyContainer.read(searchHistoryProvider).single.key,
      const WorkKey.movie(603),
    );
    expect(
      historyContainer.read(searchHistoryProvider).single.title,
      'Матрица',
    );

    expect(find.text('«Добро пожаловать в реальный мир»'), findsOneWidget);
    expect(find.text('Mar 31, 1999 · 2 h 16 min'), findsOneWidget);
    await tester.ensureVisible(find.byType(RatingsPanel));
    await tester.pumpAndSettle();
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

    await tester.ensureVisible(find.text('add a key').first);
    await settle(tester);
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

    expect(find.text('Apr 17, 2011–May 19, 2019 · ended'), findsOneWidget);
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
    await Scrollable.ensureVisible(
      tester.element(find.text('Сезон 1')),
      alignment: 0.5,
    );
    await settle(tester);
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

  cardTest('future films cannot be rated but can be watchlisted', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      http: (request) {
        if (request.uri.path == '/3/movie/603') {
          final json =
              jsonDecode(fixture('tmdb/movie_603_ru.json'))
                  as Map<String, dynamic>;
          json['release_date'] = '2999-01-01';
          return (status: 200, body: jsonEncode(json));
        }
        return apiFixtures(request);
      },
    );
    go(tester, '/search/movie/603');
    await settle(tester);
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('Rate'),
              matching: find.byWidgetPredicate(
                (widget) => widget is FilledButton,
              ),
            ),
          )
          .onPressed,
      isNull,
    );
    expect(find.text('Rating is available after release.'), findsOneWidget);
    await tester.tap(find.text('Want to watch'));
    await settle(tester);
    expect(find.text('On the watchlist'), findsOneWidget);
  });

  cardTest(
    'an existing rating on a future film can be deleted but not edited',
    (tester) async {
      await pumpApp(
        tester,
        keys: tmdbOnly,
        seed: (library) => library.rate(
          const [
            WorkSnapshot(
              key: WorkKey.movie(603),
              tmdbId: 603,
              title: 'Matrix',
              releaseDate: '2999-01-01',
            ),
          ],
          scoreHalf: 16,
          note: null,
        ),
        http: (request) {
          if (request.uri.path == '/3/movie/603') {
            final json =
                jsonDecode(fixture('tmdb/movie_603_ru.json'))
                    as Map<String, dynamic>;
            json['release_date'] = '2999-01-01';
            return (status: 200, body: jsonEncode(json));
          }
          return apiFixtures(request);
        },
      );
      go(tester, '/search/movie/603');
      await settle(tester);
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) => widget is IconButton && widget.tooltip == 'Change',
              ),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (widget) => widget is IconButton && widget.tooltip == 'Delete',
              ),
            )
            .onPressed,
        isNotNull,
      );
    },
  );

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

  cardTest('a movie cover opens full screen and the back button returns', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    go(tester, '/search/movie/603');
    await settle(tester);
    await tester.tap(
      find
          .descendant(
            of: find.byType(TitleHeader),
            matching: find.byType(InkWell),
          )
          .first,
    );
    await settle(tester);
    expect(find.byType(CoverViewer), findsOneWidget);
    await tester.pageBack();
    await settle(tester);
    expect(find.byType(CoverViewer), findsNothing);
    expect(find.byType(TitleHeader), findsOneWidget);
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

  cardTest('watchlisted seasons appear under their series and can be undone', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    go(tester, '/search/tv/1399/s/1');
    await settle(tester);
    await tester.tap(find.text('Want to watch'));
    await settle(tester);
    await tester.tap(tab('Watchlist'));
    await settle(tester);
    expect(inList('Игра Престолов'), findsOneWidget);
    expect(inList('Сезон 1'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove from the watchlist'));
    await settle(tester);
    expect(inList('Сезон 1'), findsNothing);
    await tester.tap(find.text('Undo'));
    await settle(tester);
    expect(inList('Сезон 1'), findsOneWidget);
    await tester.tap(inList('Сезон 1'));
    await settle(tester);
    expect(find.text('On the watchlist'), findsOneWidget);
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

  /// The Matrix, rated before the test starts.
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

  cardTest('canceling an editor preserves the score, note and version', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) async {
        await library.rate(
          const [
            WorkSnapshot(key: WorkKey.movie(603), tmdbId: 603, title: 'Matrix'),
          ],
          scoreHalf: 17,
          note: 'Original note',
        );
      },
    );
    go(tester, '/search/movie/603');
    await settle(tester);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    );
    final before = container
        .read(myRatingProvider(const WorkKey.movie(603)))
        .value;
    expect(before, isNotNull);
    await tester.tap(find.byTooltip('Change'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Unsaved note');
    await pickScore(tester, 3);
    container.read(routerProvider).pop();
    await settle(tester);
    final after = container
        .read(myRatingProvider(const WorkKey.movie(603)))
        .value;
    expect(after, before);
    expect(find.text('Original note'), findsOneWidget);
    expect(find.text('Unsaved note'), findsNothing);
  });

  cardTest('canceling deletion keeps the rating in the card and list', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) => matrixRated(library, 17),
    );
    go(tester, '/search/movie/603');
    await settle(tester);
    await tester.tap(find.byTooltip('Delete'));
    await settle(tester);
    await tester.tap(find.text('Cancel'));
    await settle(tester);
    expect(find.text('My rating'), findsOneWidget);
    await tester.tap(tab('Ratings'));
    await settle(tester);
    expect(inList('Матрица'), findsOneWidget);
    expect(inList('8.5'), findsOneWidget);
  });

  cardTest('rating a watchlisted film removes it and updates statistics', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    go(tester, '/search/movie/603');
    await settle(tester);
    await tester.tap(find.text('Want to watch'));
    await settle(tester);
    await tester.tap(find.text('Rate'));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Saved from the editor');
    await tester.tap(find.text('Save'));
    await settle(tester);
    expect(find.text('Saved from the editor'), findsOneWidget);
    await tester.tap(tab('Watchlist'));
    await settle(tester);
    expect(inList('Матрица'), findsNothing);
    await tester.tap(tab('Ratings'));
    await settle(tester);
    expect(inList('Матрица'), findsOneWidget);
    expect(inList('5'), findsOneWidget);
    await tester.tap(tab('Stats'));
    await settle(tester);
    expect(find.text('your score, the only one so far'), findsOneWidget);
    expect(find.text('5.0'), findsOneWidget);
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

  cardTest(
    'a watchlisted season follows a TMDB renumbering after confirmation',
    (tester) async {
      await pumpApp(
        tester,
        keys: tmdbOnly,
        seed: (library) => library.addToWatchlist([
          const WorkSnapshot(key: WorkKey.tv(1399), tmdbId: 1399, title: 'GoT'),
          const WorkSnapshot(
            key: WorkKey.season(1399, 2),
            tmdbId: 3624,
            title: 'Сезон 2',
          ),
        ]),
      );
      go(tester, '/search/tv/1399');
      await settle(tester);
      const question =
          'A season on your watchlist moved from Season 2 to Season 1. Move it?';
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
      await tester.tap(tab('Watchlist'));
      await settle(tester);
      expect(inList('Сезон 1'), findsOneWidget);
      expect(inList('Сезон 2'), findsNothing);
    },
  );

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
      of: find.byType(CustomScrollView),
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
    // The real isolate is outside fake widget-test time.
    for (
      var i = 0;
      i < 50 && find.text('Merge with Google Drive?').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Merge with Google Drive?'), findsOneWidget);
    expect(
      find.textContaining(
        'Ratings on this device: 1. In Google Drive: 1. After merging: 2.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Merge'));
    for (
      var i = 0;
      i < 50 && find.textContaining('Last synced').evaluate().isEmpty;
      i++
    ) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump(const Duration(milliseconds: 50));
    }
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

  cardTest('Discover: personalised rows use rated favourites', (tester) async {
    await pumpApp(tester, keys: tmdbOnly);
    // An empty library has the editorial shelves, without personal rows.
    expect(find.text('For you'), findsNothing);
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
    expect(find.text('For you'), findsOneWidget);
    final recommendations = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    ).read(recommendationFeedProvider).forYou;
    expect(recommendations, isNotEmpty);
    expect(
      recommendations.any((p) => p.reason == RecommendationReason.similar),
      isTrue,
    );
    expect(find.text(recommendations.first.title.title), findsWidgets);
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

  cardTest('filmography filters roles at large text scale', (tester) async {
    await pumpApp(tester, keys: tmdbOnly);
    ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
      listen: false,
    ).read(searchProvider.notifier).selectKind(SearchKind.people);
    go(tester, '/search/person/999');
    await settle(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.8;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await settle(tester);
    for (final category in [
      'Directing',
      'Production',
      'Writing',
      'Other work',
    ]) {
      final chip = find.widgetWithText(ChoiceChip, '$category · 1');
      await tester.ensureVisible(chip);
      await tester.tap(chip);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Test Film'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Test Film'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  cardTest('people search opens a profile and back keeps the search', (
    tester,
  ) async {
    await pumpApp(tester, keys: tmdbOnly);
    await tester.tap(find.text('People'));
    await tester.enterText(find.byType(TextField), 'Киану');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    await tester.tap(find.text('Киану Ривз'));
    await settle(tester);
    expect(find.byType(PersonScreen), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);
    expect(find.text('Киану Ривз'), findsOneWidget);
    expect(find.text('Киану'), findsOneWidget);
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

    await tester.scrollUntilVisible(
      find.text('Киану Ривз'),
      -150,
      scrollable: find.byType(Scrollable).first,
    );
    await Scrollable.ensureVisible(
      tester.element(find.text('Киану Ривз')),
      alignment: 0.5,
    );
    await settle(tester);
    await tester.tap(find.text('Киану Ривз'));
    await settle(tester);
    expect(find.text('Filmography'), findsOneWidget);
    expect(find.textContaining('Born'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('person-photo')));
    await settle(tester);
    expect(find.byType(CoverViewer), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await settle(tester);

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

  cardTest(
    'cast preview keeps 20 entries and full cast opens later actors and preserves back',
    (tester) async {
      await pumpApp(
        tester,
        keys: tmdbOnly,
        http: (request) {
          if (request.uri.path == '/3/movie/603') {
            final movie =
                jsonDecode(fixture('tmdb/movie_603_ru.json'))
                    as Map<String, dynamic>;
            movie['credits'] = {
              'cast': List.generate(
                26,
                (i) => {
                  'id': 6384 + i,
                  'name': 'Actor $i',
                  'character': 'Role $i',
                },
              ),
            };
            return (status: 200, body: jsonEncode(movie));
          }
          return apiFixtures(request);
        },
      );
      go(tester, '/search/movie/603');
      await settle(tester);
      final link = find.byKey(const ValueKey('full-cast-link'));
      await tester.scrollUntilVisible(
        link,
        250,
        scrollable: find.byType(Scrollable).first,
      );
      final strip = find
          .byWidgetPredicate(
            (w) => w is ListView && w.scrollDirection == Axis.horizontal,
          )
          .last;
      expect(
        tester.widget<ListView>(strip).childrenDelegate.estimatedChildCount,
        39,
      );
      await Scrollable.ensureVisible(tester.element(link), alignment: 0.5);
      await settle(tester);
      await tester.tap(link);
      await settle(tester);
      expect(find.byType(CastScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Actor 25'),
        350,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Role 25'), findsOneWidget);
      final castList = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      castList.position.jumpTo(castList.position.maxScrollExtent);
      await settle(tester);
      expect(
        tester.getRect(find.text('Role 25')).bottom,
        lessThan(tester.getRect(find.byType(NavigationBar)).top),
      );
      await tester.scrollUntilVisible(
        find.text('Actor 0'),
        -400,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Actor 0'));
      await settle(tester);
      expect(find.byType(PersonScreen), findsOneWidget);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      container.read(routerProvider).pop();
      await settle(tester);
      expect(find.byType(CastScreen), findsOneWidget);
      container.read(routerProvider).pop();
      await settle(tester);
      expect(find.byType(MovieScreen), findsOneWidget);
    },
  );

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
  cardTest(
    'history appears on empty Discover but stays hidden while searching',
    (tester) async {
      await pumpApp(tester, keys: tmdbOnly);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      await container
          .read(searchHistoryProvider.notifier)
          .remember(
            const SearchHistoryEntry(
              key: WorkKey.movie(603),
              title: 'History-only title',
            ),
          );
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Recently opened'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'Matrix');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await settle(tester);
      expect(find.text('Recently opened'), findsNothing);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('History-only title'), findsNothing);
      expect(find.text('Recently opened'), findsNothing);
      await tester.tap(find.byTooltip('Clear'));
      await tester.pumpAndSettle();
      expect(find.text('Recently opened'), findsNothing);
      expect(find.text('History-only title'), findsNothing);
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      expect(find.text('Recently opened'), findsOneWidget);
    },
  );

  cardTest('ratings show day sections only in date order', (tester) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      seed: (library) => matrixRated(library, 17),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Ratings'),
      ),
    );
    await settle(tester);
    expect(find.text('Today'), findsOneWidget);
    final container = ProviderScope.containerOf(
      tester.element(find.byType(FramebookApp)),
    );
    container.read(ratingsViewProvider.notifier).sortBy(RatingsSort.score);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsNothing);
    container.read(ratingsViewProvider.notifier).sortBy(RatingsSort.scoredAt);
    await tester.pumpAndSettle();
    expect(find.text('Today'), findsOneWidget);
  });

  cardTest(
    'people favourites populate Discover and all-role filmographies stay available',
    (tester) async {
      await pumpApp(tester, keys: tmdbOnly);
      go(tester, '/search/person/6384');
      await settle(tester);
      await tester.tap(find.byTooltip('Add to favourites'));
      await settle(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      expect(
        container.read(favoritePeopleProvider).value!.single.personId,
        6384,
      );
      go(tester, Routes.search);
      await tester.pumpAndSettle();
      tester.platformDispatcher.textScaleFactorTestValue = 1.8;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.tap(find.byKey(const ValueKey('search-mode-1')));
      await settle(tester);
      expect(find.text('Favourite people'), findsOneWidget);
      expect(find.text('Киану Ривз'), findsWidgets);
      expect(tester.takeException(), isNull);
      final portrait = find.byType(FavoritePersonPortrait).first;
      await tester.tap(portrait);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(portrait);
      await settle(tester);
      expect(container.read(favoritePeopleProvider).value, isEmpty);
      expect(
        find.text('Save people from their pages to find them here.'),
        findsOneWidget,
      );
    },
  );

  cardTest('expanded biographies survive scrolling through filmography', (
    tester,
  ) async {
    await pumpApp(
      tester,
      keys: tmdbOnly,
      http: (request) {
        if (request.uri.path == '/3/person/999') {
          return (
            status: 200,
            body: jsonEncode({
              'id': 999,
              'name': 'Test Person',
              'biography': List.filled(
                100,
                'Biography line with enough text to wrap.',
              ).join('\n'),
              'combined_credits': {
                'cast': [
                  for (var i = 1; i <= 60; i++)
                    {'id': i, 'media_type': 'movie', 'title': 'Film $i'},
                ],
              },
            }),
          );
        }
        return apiFixtures(request);
      },
    );
    go(tester, '/search/person/999');
    await settle(tester);
    await Scrollable.ensureVisible(tester.element(find.text('More')));
    await settle(tester);
    await tester.tap(find.text('More'));
    await settle(tester);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(scroll.position.maxScrollExtent);
    await settle(tester);
    scroll.position.jumpTo(0);
    await settle(tester);
    expect(find.text('More'), findsNothing);
    expect(find.textContaining('Biography line'), findsOneWidget);
  });

  cardTest(
    'page swipes change root tabs and leave shelf gestures and cards alone',
    (tester) async {
      await pumpApp(tester, keys: tmdbOnly);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      final router = container.read(routerProvider);
      String path() => router.routeInformationProvider.value.uri.path;
      go(tester, Routes.ratings);
      await settle(tester);
      final pages = find.byKey(const ValueKey('tab-page-swipe'));
      await tester.drag(pages, const Offset(-260, 0));
      await settle(tester);
      expect(path(), Routes.watchlist);
      await tester.drag(pages, const Offset(-260, 0));
      await settle(tester);
      expect(path(), Routes.stats);
      await tester.drag(pages, const Offset(-260, 0));
      await settle(tester);
      expect(path(), Routes.stats);
      await container.read(floatingNavigationProvider.notifier).set(false);
      await settle(tester);
      await tester.drag(pages, const Offset(260, 0));
      await settle(tester);
      expect(path(), Routes.watchlist);
      go(tester, Routes.search);
      await settle(tester);
      expect(path(), Routes.search);
      final shelf = find
          .byWidgetPredicate(
            (w) => w is ListView && w.scrollDirection == Axis.horizontal,
          )
          .first;
      await tester.drag(shelf, const Offset(-180, 0));
      await settle(tester);
      expect(path(), Routes.search);
      go(tester, '/search/person/6384');
      await settle(tester);
      await tester.drag(pages, const Offset(-260, 0));
      await settle(tester);
      expect(path(), '/search/person/6384');
    },
  );

  cardTest(
    'floating navigation follows a drag, preserves cards and supports classic mode',
    (tester) async {
      await pumpApp(tester, keys: tmdbOnly);
      go(tester, '/search/person/6384');
      await settle(tester);
      final bar = find.byKey(const ValueKey('glass-navigation'));
      final navRect = tester.getRect(find.byType(NavigationBar));
      expect(navRect.left, greaterThan(0));
      expect(navRect.right, lessThan(360));
      final scope = tester.widget<NavigationMotion>(
        find.byType(NavigationMotion),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(bar) - const Offset(115, 0),
      );
      await gesture.moveBy(const Offset(45, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
      expect(scope.position.value, greaterThan(0));
      expect(scope.position.value % 1, isNonZero);
      expect(find.byType(FractionalTranslation), findsWidgets);
      await gesture.up();
      await settle(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      expect(
        container.read(routerProvider).routeInformationProvider.value.uri.path,
        Routes.ratings,
      );
      expect(
        tester.getRect(find.byType(NavigationPages)).bottom,
        greaterThan(navRect.top),
      );
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Discover'),
        ),
      );
      await settle(tester);
      expect(find.byType(PersonScreen), findsOneWidget);
      unawaited(container.read(routerProvider).push<void>(Routes.settings));
      await settle(tester);
      await tester.tap(
        find.byWidgetPredicate((widget) => widget is DropdownButton<bool>),
      );
      await settle(tester);
      await tester.tap(find.text('Classic').last);
      await settle(tester);
      expect(container.read(floatingNavigationProvider), isFalse);
      container.read(routerProvider).pop();
      await settle(tester);
      expect(bar, findsNothing);
      expect(tester.getRect(find.byType(NavigationBar)).left, 0);
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text('Stats'),
        ),
      );
      await settle(tester);
      expect(
        find.text('Statistics will be here once you have ratings.'),
        findsOneWidget,
      );
      await container.read(floatingNavigationProvider.notifier).set(true);
      await settle(tester);
      expect(bar, findsOneWidget);
      expect(scope.position.value, 3);
    },
  );

  cardTest(
    'shelf portrait double tap toggles favourites and single tap opens profile',
    (tester) async {
      await pumpApp(tester, keys: tmdbOnly);
      await tester.tap(find.byKey(const ValueKey('search-mode-1')));
      await settle(tester);
      final portrait = find.byType(FavoritePersonPortrait).last;
      ScaffoldMessenger.of(tester.element(portrait)).clearSnackBars();
      await Scrollable.ensureVisible(tester.element(portrait), alignment: 0.5);
      await settle(tester);
      await tester.tap(portrait);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(portrait);
      await settle(tester);
      expect(find.byType(PersonScreen), findsNothing);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      expect(
        container.read(favoritePeopleProvider).value!.single.personId,
        6384,
      );
      expect(
        find.byKey(const ValueKey('favorite-portrait-badge')),
        findsWidgets,
      );
      expect(find.text('Киану Ривз added to favourites'), findsOneWidget);
      ScaffoldMessenger.of(tester.element(portrait)).clearSnackBars();
      await Scrollable.ensureVisible(tester.element(portrait), alignment: 0.5);
      await settle(tester);
      await tester.tap(portrait);
      await tester.pump(const Duration(milliseconds: 60));
      await tester.tap(portrait);
      await settle(tester);
      expect(container.read(favoritePeopleProvider).value, isEmpty);
      expect(
        find.byKey(const ValueKey('favorite-portrait-badge')),
        findsNothing,
      );
      await tester.tap(portrait);
      await tester.pump(const Duration(milliseconds: 350));
      await settle(tester);
      expect(find.byType(PersonScreen), findsOneWidget);
      expect(
        find.byKey(const ValueKey('favorite-portrait-badge')),
        findsNothing,
      );
      expect(
        find.ancestor(
          of: find.text('Add to favourites'),
          matching: find.byWidgetPredicate((widget) => widget is FilledButton),
        ),
        findsOneWidget,
      );
    },
  );

  cardTest(
    'statistics score groups open contributing works and cards in the Stats tab',
    (tester) async {
      await pumpApp(
        tester,
        keys: tmdbOnly,
        seed: (library) => matrixRated(library, 17),
      );
      await tester.tap(tab('Stats'));
      await settle(tester);
      await tester.tap(find.text('Scores 8–10 · 100%'));
      await tester.pumpAndSettle();
      expect(find.text('Scores 8–10 · 1'), findsOneWidget);
      await tester.tap(find.text('Матрица'));
      await settle(tester);
      expect(find.byType(MovieScreen), findsOneWidget);
      expect(
        GoRouterState.of(tester.element(find.byType(MovieScreen))).uri.path,
        '/stats/movie/603',
      );
      await tester.tap(find.byTooltip('Back'));
      await settle(tester);
      expect(find.text('All time · rated titles'), findsOneWidget);
    },
  );

  cardTest(
    'Not interested hides suggestions, supports Undo and restores without changing ratings',
    (tester) async {
      await pumpApp(
        tester,
        keys: tmdbOnly,
        seed: (library) => matrixRated(library, 18),
      );
      await settle(tester);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(FramebookApp)),
      );
      final pick = container.read(recommendationFeedProvider).forYou.first;
      final before = await tester.runAsync(
        () => SyncStore(container.read(databaseProvider)).read(),
      );
      await tester.tap(find.byTooltip('Recommendation actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not interested'));
      await settle(tester);
      expect(
        container.read(hiddenRecommendationsProvider),
        contains(pick.title.key),
      );
      expect(
        container
            .read(recommendationFeedProvider)
            .forYou
            .any((p) => p.title.key == pick.title.key),
        isFalse,
      );
      expect(
        find.text('“${pick.title.title}” hidden from recommendations'),
        findsOneWidget,
      );
      await tester.tap(find.text('Undo'));
      await settle(tester);
      expect(container.read(hiddenRecommendationsProvider), isEmpty);
      await tester.tap(find.byTooltip('Recommendation actions').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Not interested'));
      await settle(tester);
      await tester.tap(find.byTooltip('Hidden recommendations'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Show again'));
      await settle(tester);
      expect(container.read(hiddenRecommendationsProvider), isEmpty);
      final after = await tester.runAsync(
        () => SyncStore(container.read(databaseProvider)).read(),
      );
      expect(after!.ratings, before!.ratings);
      expect(after.watchlist, before.watchlist);
      expect(tester.takeException(), isNull);
    },
  );
}
