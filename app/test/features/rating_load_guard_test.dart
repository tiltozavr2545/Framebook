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
import 'package:framebook/shared/local_data_failure.dart';

void main() {
  for (final scenario in ['pending', 'failure', 'stale library']) {
    final failure = scenario == 'failure';
    testWidgets(
      'an unknown saved rating cannot open a blank draft: $scenario',
      (tester) async {
        final db = AppDatabase(NativeDatabase.memory());
        final library = Library(db, deviceId: 'test');
        const lineage = [
          WorkSnapshot(
            key: WorkKey.movie(1),
            tmdbId: 1,
            title: 'Film',
            releaseDate: '2000-01-01',
          ),
        ];
        await tester.runAsync(
          () => library.rate(
            lineage,
            scoreHalf: 16,
            note: 'Existing private note',
          ),
        );
        final saved = await tester.runAsync(
          () => db.select(db.ratings).getSingle(),
        );
        final own = Completer<Rating?>();
        final all = Completer<List<RatedTitle>>();
        if (scenario == 'stale library') all.complete([]);
        var failRead = failure;
        await tester.pumpWidget(
          ProviderScope(
            retry: (_, _) => null,
            overrides: [
              libraryProvider.overrideWithValue(library),
              myRatingProvider.overrideWith(
                (ref, key) => failRead
                    ? Stream.error(StateError('Read unavailable'))
                    : Stream.fromFuture(own.future),
              ),
              ratedTitlesProvider.overrideWith(
                (ref) => failRead
                    ? Stream.error(StateError('Read unavailable'))
                    : Stream.fromFuture(all.future),
              ),
              inWatchlistProvider.overrideWith(
                (ref, key) => Stream.value(false),
              ),
            ],
            child: MaterialApp(
              theme: FramebookTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(
                body: MyRatingSection(
                  lineage: lineage,
                  refreshSnapshots: false,
                ),
              ),
            ),
          ),
        );
        try {
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 1));
          expect(find.byType(RatingEditor), findsNothing);
          if (scenario == 'stale library') {
            await tester.tap(find.text('Rate'));
          } else {
            expect(find.text('Rate'), findsNothing);
            if (failure) {
              expect(find.byType(LocalDataFailure), findsOneWidget);
              failRead = false;
              await tester.tap(find.text('Try again'));
              await tester.pump();
            } else {
              expect(find.byType(CircularProgressIndicator), findsOneWidget);
            }
            own.complete(saved);
            all.complete([]);
            await tester.pumpAndSettle();
            expect(find.text('Existing private note'), findsOneWidget);
            await tester.tap(find.byIcon(Icons.edit_outlined));
          }
          for (
            var i = 0;
            i < 20 && find.byType(RatingEditor).evaluate().isEmpty;
            i++
          ) {
            await tester.runAsync(
              () => Future<void>.delayed(const Duration(milliseconds: 10)),
            );
            await tester.pump(const Duration(milliseconds: 50));
          }
          await tester.pumpAndSettle();
          expect(find.byType(RatingEditor), findsOneWidget);
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            'Existing private note',
          );
          expect(
            (await tester.runAsync(
              () => db.select(db.ratings).getSingle(),
            ))!.note,
            'Existing private note',
          );
        } finally {
          if (!own.isCompleted) own.complete(saved);
          if (!all.isCompleted) all.complete([]);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(milliseconds: 1));
          await tester.runAsync(db.close);
        }
      },
    );
  }
}
