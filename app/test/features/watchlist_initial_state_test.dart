import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/title/my_rating.dart';
import 'package:framebook/l10n/app_localizations.dart';

void main() {
  for (final key in [
    const WorkKey.movie(1),
    const WorkKey.tv(1),
    const WorkKey.season(1, 1),
  ]) {
    for (final failed in [false, true]) {
      testWidgets('watchlist state for $key waits and retries: $failed', (
        tester,
      ) async {
        final pending = StreamController<bool>();
        final db = AppDatabase(NativeDatabase.memory());
        final library = Library(db, deviceId: 'test');
        final lineage = [
          for (final part in key.lineage)
            WorkSnapshot(
              key: part,
              tmdbId: 1,
              title: 'Title',
              releaseDate: '2000-01-01',
            ),
        ];
        addTearDown(() async {
          await pending.close();
          await db.close();
        });
        await tester.runAsync(() => library.addToWatchlist(lineage));
        var attempts = 0;
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              libraryProvider.overrideWithValue(library),
              myRatingProvider.overrideWith((ref, key) => Stream.value(null)),
              inWatchlistProvider.overrideWith((ref, key) {
                attempts++;
                return attempts == 1 ? pending.stream : Stream.value(true);
              }),
              partsAverageProvider.overrideWith(
                (ref, key) => Stream.value(null),
              ),
              ratedTitlesProvider.overrideWith((ref) => Stream.value([])),
            ],
            child: MaterialApp(
              theme: FramebookTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: MyRatingSection(
                  refreshSnapshots: false,
                  lineage: lineage,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(MyRatingSection)),
        );
        final toggle = find.byWidgetPredicate(
          (widget) => widget is OutlinedButton,
        );
        OutlinedButton button() => tester.widget(toggle);
        expect(button().onPressed, isNull);
        expect(
          tester
              .widget<FilledButton>(
                find.byWidgetPredicate((widget) => widget is FilledButton),
              )
              .onPressed,
          isNotNull,
        );
        if (failed) {
          pending.addError(StateError('Storage unavailable'));
          await tester.pumpAndSettle();
          expect(button().onPressed, isNull);
          expect(find.text(l10n.localDataLoadFailed), findsOneWidget);
          await tester.tap(find.text(l10n.retry));
          await tester.pumpAndSettle();
          expect(attempts, 2);
          expect(find.text(l10n.localDataLoadFailed), findsNothing);
        } else {
          pending.add(true);
          await tester.pumpAndSettle();
        }
        expect(button().onPressed, isNotNull);
        expect(find.text(l10n.watchlistListed), findsOneWidget);
        await tester.tap(toggle);
        await tester.runAsync(
          () => library
              .watchInWatchlist(key)
              .firstWhere((listed) => !listed)
              .timeout(const Duration(seconds: 5)),
        );
        await tester.pumpAndSettle();
        expect(
          (await db.select(db.watchlist).getSingle()).deletedAt,
          isNotNull,
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await tester.pump(const Duration(milliseconds: 1));
      });
    }
  }
}
