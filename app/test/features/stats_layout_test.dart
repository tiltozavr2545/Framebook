import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/insights.dart';
import 'package:framebook/data/library/insights_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/features/stats/insight_sections.dart';
import 'package:framebook/features/stats/stats_screen.dart';
import 'package:framebook/features/stats/stats_detail_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';

import '../data/insights_test.dart' show rated;
import '../support/inline_view_computer.dart';
import 'package:framebook/data/view_computer.dart';

class _Index extends PeopleIndex {
  @override
  PeopleIndexState build() => const PeopleIndexState();
}

Widget app(Widget child) => ProviderScope(
  overrides: [
    viewComputerProvider.overrideWithValue(const InlineViewComputer()),
  ],
  child: MaterialApp(
    theme: FramebookTheme.light,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  ),
);

void main() {
  testWidgets(
    'showing all people builds visible rows and keeps the last person reachable',
    (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final row = rated(1, 16);
      final insights = LibraryInsights(
        genres: {},
        decades: {},
        duos: [],
        covered: 1,
        people: [
          for (var i = 0; i < 1000; i++)
            PersonInsight(
              PeopleCredit(
                id: i + 1,
                name: 'Person $i',
                role: FilmographyRole.acting,
              ),
              [row],
              {
                FilmographyRole.acting: [row],
              },
            ),
        ],
      );
      final scroll = ScrollController();
      addTearDown(scroll.dispose);
      await tester.pumpWidget(
        app(
          Scaffold(
            body: CustomScrollView(
              controller: scroll,
              slivers: [
                StatsPeopleSection(titles: [row], insights: insights),
              ],
            ),
          ),
        ),
      );
      await tester.scrollUntilVisible(find.text('Show all · 1000'), 300);
      await Scrollable.ensureVisible(
        tester.element(find.text('Show all · 1000')),
        alignment: .5,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Show all · 1000'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile).evaluate().length, lessThan(40));
      expect(find.text('Person 999'), findsNothing);
      // Scroll extent is estimated while the lazy list learns row heights.
      for (var i = 0; i < 8; i++) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
        await tester.pumpAndSettle();
      }
      expect(find.text('Person 999'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );

  testWidgets('decade drill-down works before background insights finish', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final router = GoRouter(
      initialLocation: '/stats',
      routes: [
        GoRoute(
          path: '/stats',
          builder: (_, _) => const StatsScreen(),
          routes: [
            GoRoute(
              path: 'genres',
              builder: (_, _) =>
                  const StatsDetailScreen(section: StatsSection.genres),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);
    final pending = Completer<LibraryInsights>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ratingsServiceProvider.overrideWithValue(RatingsService(db)),
          ratedTitlesProvider.overrideWith(
            (ref) => Stream.value([rated(1, 16, year: 1999)]),
          ),
          peopleIndexProvider.overrideWith(_Index.new),
          libraryInsightsProvider.overrideWith((ref, kind) => pending.future),
          genreNamesProvider.overrideWith((ref) async => {}),
        ],
        child: MaterialApp.router(
          theme: FramebookTheme.light,
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Genres and decades'),
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.text('Genres and decades'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('1990s · 1 rating'),
      300,
      scrollable: find.descendant(
        of: find.byType(CustomScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    await tester.tap(find.text('1990s · 1 rating'));
    await tester.pumpAndSettle();
    expect(find.text('1990s · 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    pending.complete(emptyLibraryInsights);
  });
}
