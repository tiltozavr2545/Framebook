import 'package:drift/native.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/background_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/features/stats/stats_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';

import '../data/insights_test.dart' show rated;

void main() {
  for (final locale in ['en', 'ru']) {
    for (final scale in [1.0, 1.3]) {
      testWidgets(
        'overview extent stays fixed while scrolling $locale $scale',
        (tester) async {
          tester.view.physicalSize = const Size(360, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final db = AppDatabase(NativeDatabase.memory());
          await tester.pumpWidget(
            ProviderScope(
              overrides: [
                ratingsServiceProvider.overrideWithValue(RatingsService(db)),
                backgroundRefreshEnabledProvider.overrideWithValue(false),
                ratedTitlesProvider.overrideWith(
                  (ref) => Stream.value([
                    for (var i = 1; i <= 7; i++)
                      rated(i, 18, genres: [18, 28, 35], year: 1999),
                  ]),
                ),
                genreNamesProvider.overrideWith(
                  (ref) async => {18: 'Drama', 28: 'Action', 35: 'Comedy'},
                ),
              ],
              child: MaterialApp(
                locale: Locale(locale),
                theme: FramebookTheme.dark,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
                home: const StatsScreen(),
              ),
            ),
          );
          await tester.pumpAndSettle();
          final scroll = tester.state<ScrollableState>(
            find
                .descendant(
                  of: find.byType(SingleChildScrollView),
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          final extent = scroll.position.maxScrollExtent;
          expect(extent, greaterThan(100));
          for (var offset = 100.0; offset < extent; offset += 100) {
            scroll.position.jumpTo(offset);
            await tester.pumpAndSettle();
            expect(
              scroll.position.maxScrollExtent,
              closeTo(extent, .01),
              reason: 'Scrolling must not revise the content height at $offset',
            );
            expect(scroll.position.pixels, closeTo(offset, .01));
          }
          scroll.position.jumpTo(extent);
          await tester.pumpAndSettle();
          expect(scroll.position.maxScrollExtent, closeTo(extent, .01));
          expect(scroll.position.pixels, closeTo(extent, .01));
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
          await db.close();
        },
      );
    }
  }
}
