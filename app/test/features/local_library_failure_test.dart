import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/features/ratings/ratings_screen.dart';
import 'package:framebook/features/stats/stats_screen.dart';
import 'package:framebook/features/watchlist/watchlist_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:framebook/shared/local_data_failure.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final tab in ['ratings', 'watchlist', 'stats']) {
    testWidgets('$tab retries a failed local-library read', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      var failing = true;
      var reads = 0;
      await tester.pumpWidget(
        ProviderScope(
          retry: (_, _) => null,
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            ratedTitlesProvider.overrideWith((ref) {
              reads++;
              return failing
                  ? Stream.error(StateError('Local library unavailable'))
                  : Stream.value([]);
            }),
            watchlistTitlesProvider.overrideWith((ref) {
              reads++;
              return failing
                  ? Stream.error(StateError('Local library unavailable'))
                  : Stream.value([]);
            }),
          ],
          child: MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: switch (tab) {
              'ratings' => const RatingsScreen(),
              'watchlist' => const WatchlistScreen(),
              _ => const StatsScreen(),
            },
          ),
        ),
      );
      try {
        await tester.pumpAndSettle();
        expect(find.byType(LocalDataFailure), findsOneWidget);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        final previousReads = reads;
        failing = false;
        await tester.tap(find.text('Try again'));
        await tester.pumpAndSettle();
        expect(reads, greaterThan(previousReads));
        expect(find.byType(LocalDataFailure), findsNothing);
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(tester.takeException(), isNull);
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
      }
    });
  }
}
