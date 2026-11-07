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

import '../data/insights_test.dart' show rated;

void main() {
  testWidgets(
    'an opening card uses the live library until its rating query answers',
    (tester) async {
      final pending = StreamController<Rating?>();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(() async {
        await pending.close();
        await db.close();
      });
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            libraryProvider.overrideWithValue(Library(db, deviceId: 'test')),
            ratedTitlesProvider.overrideWith(
              (ref) => Stream.value([rated(1, 16)]),
            ),
            myRatingProvider.overrideWith((ref, key) => pending.stream),
            inWatchlistProvider.overrideWith((ref, key) => Stream.value(false)),
          ],
          child: MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: MyRatingSection(
                refreshSnapshots: false,
                lineage: [
                  WorkSnapshot(key: WorkKey.movie(1), tmdbId: 1, title: 'Film'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('8'), findsOneWidget);
      expect(find.text('Rate'), findsNothing);
      pending.add(null);
      await tester.pumpAndSettle();
      expect(find.text('Rate'), findsOneWidget);
      expect(find.text('8'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    },
  );
}
