import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/background_refresh.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/insights.dart';
import 'package:framebook/data/library/insights_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/features/stats/stats_detail_screen.dart';
import 'package:framebook/features/stats/stats_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';

import '../data/insights_test.dart' show rated;

class _Index extends PeopleIndex {
  @override
  PeopleIndexState build() => const PeopleIndexState();
}

void main() {
  for (final locale in ['en', 'ru']) {
    for (final dark in [false, true]) {
      for (final scale in [1.0, 1.3, 2.0]) {
        testWidgets('statistics routes fit $locale dark=$dark scale=$scale', (
          tester,
        ) async {
          tester.view.physicalSize = const Size(320, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final db = AppDatabase(NativeDatabase.memory());
          final titles = [
            rated(1, 18, imdb: 7, genres: [18], year: 1999),
            rated(2, 16, imdb: 9, genres: [18], year: 1999),
            rated(3, 14, imdb: 8, genres: [18], year: 2010),
          ];
          final insights = LibraryInsights(
            genres: {},
            decades: {},
            duos: [],
            covered: 3,
            people: [
              PersonInsight(
                const PeopleCredit(
                  id: 1,
                  name: 'Shared actor',
                  role: FilmographyRole.acting,
                ),
                titles,
                {FilmographyRole.acting: titles},
              ),
              PersonInsight(
                const PeopleCredit(
                  id: 2,
                  name: 'Shared director',
                  role: FilmographyRole.directing,
                ),
                titles,
                {FilmographyRole.directing: titles},
              ),
            ],
          );
          var insightReads = 0;
          final router = GoRouter(
            initialLocation: '/stats',
            routes: [
              GoRoute(
                path: '/stats',
                builder: (_, _) => const StatsScreen(),
                routes: [
                  for (final section in StatsSection.values)
                    GoRoute(
                      path: section.name,
                      builder: (_, _) => StatsDetailScreen(section: section),
                    ),
                  GoRoute(
                    path: 'movie/:id',
                    builder: (_, state) => Scaffold(
                      body: Text('Opened title ${state.pathParameters['id']}'),
                    ),
                  ),
                  GoRoute(
                    path: 'person/:id',
                    builder: (_, state) => Scaffold(
                      body: Text('Opened person ${state.pathParameters['id']}'),
                    ),
                  ),
                ],
              ),
            ],
          );
          Future<void> tap(String text) async {
            final finder = find.text(text);
            await tester.scrollUntilVisible(
              finder,
              180,
              scrollable: find
                  .byWidgetPredicate(
                    (w) =>
                        w is Scrollable &&
                        w.axisDirection == AxisDirection.down,
                  )
                  .first,
            );
            await Scrollable.ensureVisible(
              tester.element(finder),
              alignment: .5,
            );
            await tester.pumpAndSettle();
            await tester.tap(finder);
            await tester.pumpAndSettle();
          }

          try {
            await tester.pumpWidget(
              ProviderScope(
                retry: (_, _) => null,
                overrides: [
                  ratedTitlesProvider.overrideWith(
                    (ref) => Stream.value(titles),
                  ),
                  ratingsServiceProvider.overrideWithValue(RatingsService(db)),
                  backgroundRefreshEnabledProvider.overrideWithValue(false),
                  peopleIndexProvider.overrideWith(_Index.new),
                  libraryInsightsProvider.overrideWith((ref, kind) async {
                    insightReads++;
                    return insights;
                  }),
                  genreNamesProvider.overrideWith(
                    (ref) async => {18: locale == 'ru' ? 'драма' : 'drama'},
                  ),
                ],
                child: MaterialApp.router(
                  theme: dark ? FramebookTheme.dark : FramebookTheme.light,
                  locale: Locale(locale),
                  routerConfig: router,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  builder: (context, child) => MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(scale)),
                    child: child!,
                  ),
                ),
              ),
            );
            await tester.pumpAndSettle();
            final l10n = AppLocalizations.of(
              tester.element(find.byType(StatsScreen)),
            );
            expect(find.text(l10n.statsRated), findsOneWidget);
            expect(find.text(l10n.statsAverage), findsOneWidget);
            expect(
              insightReads,
              0,
              reason: 'The overview must not wait for people enrichment',
            );
            expect(tester.takeException(), isNull);

            await tap(l10n.statsDistribution);
            expect(
              tester
                  .widget<StatsDetailScreen>(find.byType(StatsDetailScreen))
                  .section,
              StatsSection.scores,
            );
            final nine = find.widgetWithText(ListTile, '9');
            await tester.ensureVisible(nine);
            await tester.tap(nine);
            await tester.pumpAndSettle();
            expect(find.text('Title 1'), findsOneWidget);
            router.pop();
            await tester.pumpAndSettle();
            router.pop();
            await tester.pumpAndSettle();

            await tap(l10n.statsGenresAndDecades);
            expect(
              tester
                  .widget<StatsDetailScreen>(find.byType(StatsDetailScreen))
                  .section,
              StatsSection.genres,
            );
            await tap(
              '${l10n.statsDecade('1990')} · ${l10n.statsRatingCount(2)}',
            );
            expect(find.text('Title 1'), findsOneWidget);
            expect(find.text('Title 2'), findsOneWidget);
            router.pop();
            await tester.pumpAndSettle();
            router.pop();
            await tester.pumpAndSettle();

            await tap(l10n.statsCompared);
            expect(
              tester
                  .widget<StatsDetailScreen>(find.byType(StatsDetailScreen))
                  .section,
              StatsSection.comparison,
            );
            final titleRect = tester.getRect(
              find.descendant(
                of: find.byType(AppBar),
                matching: find.text(l10n.statsCompared),
              ),
            );
            final barRect = tester.getRect(find.byType(AppBar));
            expect(titleRect.top, greaterThanOrEqualTo(barRect.top));
            expect(titleRect.bottom, lessThanOrEqualTo(barRect.bottom));
            await tester.ensureVisible(find.widgetWithText(ChoiceChip, 'IMDb'));
            await tester.pumpAndSettle();
            await tester.tap(find.widgetWithText(ChoiceChip, 'IMDb'));
            await tester.pumpAndSettle();
            expect(find.text(l10n.statsRatesSame), findsOneWidget);
            await tap(l10n.statsFinds);
            expect(find.textContaining('IMDb 7.0'), findsOneWidget);
            await tester.tap(find.text('Title 1'));
            await tester.pumpAndSettle();
            expect(find.text('Opened title 1'), findsOneWidget);
            router.pop();
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.widgetWithText(ChoiceChip, 'IMDb'),
              -200,
              scrollable: find
                  .byWidgetPredicate(
                    (w) =>
                        w is Scrollable &&
                        w.axisDirection == AxisDirection.down,
                  )
                  .first,
            );
            expect(
              tester
                  .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'IMDb'))
                  .selected,
              isTrue,
            );
            router.pop();
            await tester.pumpAndSettle();

            await tap(l10n.statsActorsDirectors);
            expect(find.text('Shared actor'), findsOneWidget);
            expect(find.text('Shared director'), findsNothing);
            await tester.tap(
              find.widgetWithText(ChoiceChip, l10n.statsDirectors),
            );
            await tester.pumpAndSettle();
            expect(find.text('Shared director'), findsOneWidget);
            expect(find.text('Shared actor'), findsNothing);
            await tester.ensureVisible(
              find.byTooltip(l10n.statsOpenPerson('Shared director')),
            );
            await tester.tap(
              find.byTooltip(l10n.statsOpenPerson('Shared director')),
            );
            await tester.pumpAndSettle();
            expect(find.text('Opened person 2'), findsOneWidget);
            router.pop();
            await tester.pumpAndSettle();
            router.pop();
            await tester.pumpAndSettle();

            await tester.ensureVisible(
              find.byKey(const ValueKey('stats-kind-1')),
            );
            await tester.tap(find.byKey(const ValueKey('stats-kind-1')));
            await tester.pumpAndSettle();
            expect(find.text(l10n.ratingsEmptyKind), findsOneWidget);
            expect(tester.takeException(), isNull);
          } finally {
            await tester.pumpWidget(const SizedBox());
            await tester.pump(const Duration(milliseconds: 1));
            router.dispose();
            await db.close();
          }
        });
      }
    }
  }
}
