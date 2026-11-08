import 'dart:async';

import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
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

class _PendingCount extends QueryInterceptor {
  final release = Completer<void>();
  int calls = 0;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (statement.toLowerCase().contains('count(')) {
      calls++;
      await release.future;
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  testWidgets('repeated taps during a slow read open only one rating editor', (
    tester,
  ) async {
    final reads = _PendingCount();
    final db = AppDatabase(NativeDatabase.memory().interceptWith(reads));
    addTearDown(() async {
      if (!reads.release.isCompleted) reads.release.complete();
      await db.close();
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryProvider.overrideWithValue(Library(db, deviceId: 'local')),
          myRatingProvider.overrideWith((ref, key) => Stream.value(null)),
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
                WorkSnapshot(
                  key: WorkKey.movie(1),
                  tmdbId: 1,
                  title: 'Film',
                  releaseDate: '2000-01-01',
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rate'));
    await tester.tap(find.text('Rate'));
    await tester.pump();
    expect(reads.calls, 1);
    reads.release.complete();
    await tester.pumpAndSettle();
    expect(find.byType(RatingEditor, skipOffstage: false), findsOneWidget);
    tester.state<NavigatorState>(find.byType(Navigator).first).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Rate'));
    await tester.pumpAndSettle();
    expect(reads.calls, 2);
    expect(find.byType(RatingEditor, skipOffstage: false), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
