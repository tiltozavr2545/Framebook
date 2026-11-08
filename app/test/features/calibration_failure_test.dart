import 'package:drift/drift.dart'
    show QueryExecutor, QueryInterceptor, ApplyInterceptor;
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

class _FailCount extends QueryInterceptor {
  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) async {
    if (statement.toLowerCase().contains('count(')) {
      throw StateError('count unavailable');
    }
    return super.runSelect(executor, statement, args);
  }
}

void main() {
  testWidgets('a failed calibration threshold query does not prevent rating', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final db = AppDatabase(NativeDatabase.memory().interceptWith(_FailCount()));
    addTearDown(db.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          libraryProvider.overrideWithValue(Library(db, deviceId: 'test')),
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
    await tester.pumpAndSettle();
    expect(find.byType(RatingEditor), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'Saved despite missing comparison',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    final saved = await db.select(db.ratings).getSingle();
    expect(saved.scoreHalf, 10);
    expect(saved.note, 'Saved despite missing comparison');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 1));
  });
}
