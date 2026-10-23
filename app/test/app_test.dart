import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/app.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/http.dart';
import 'package:framebook/data/key_validator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fake_http.dart';
import 'support/memory_key_storage.dart';

void main() {
  late MemoryKeyStorage storage;

  Future<void> pumpApp(
    WidgetTester tester, {
    ApiKeys keys = ApiKeys.empty,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final dio = createDio()
      ..httpClientAdapter = FakeHttpAdapter(
        (_) => (status: 200, body: fixture('tmdb/configuration.json')),
      );
    storage = MemoryKeyStorage();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          sharedPreferencesProvider.overrideWithValue(prefs),
          apiKeyStoreProvider.overrideWithValue(ApiKeyStore(storage)),
          initialApiKeysProvider.overrideWithValue(keys),
          keyValidatorProvider.overrideWithValue(KeyValidator(dio, db)),
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
    expect(
      find.text('Search for films and series will be here.'),
      findsOneWidget,
    );
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
}
