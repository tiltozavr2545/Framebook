import 'package:drift/drift.dart'
    show ApplyInterceptor, BatchedStatements, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/api_source.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/ratings_service.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/title/ratings_panel.dart';
import 'package:framebook/l10n/app_localizations.dart';

class _FailCache extends QueryInterceptor {
  bool failReads = false;
  bool failWrites = false;

  @override
  Future<List<Map<String, Object?>>> runSelect(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (failReads && statement.contains('external_ratings')) {
      throw StateError('Cache read unavailable');
    }
    return super.runSelect(executor, statement, args);
  }

  @override
  Future<void> runBatched(
    QueryExecutor executor,
    BatchedStatements statements,
  ) {
    if (failWrites) throw StateError('Cache write unavailable');
    return super.runBatched(executor, statements);
  }
}

void main() {
  for (final failure in ['read', 'write']) {
    testWidgets('external-rating cache $failure failure offers retry', (
      tester,
    ) async {
      final storage = _FailCache();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(storage));
      addTearDown(db.close);
      if (failure == 'write') {
        await db.putExternalRatings([
          const ExternalRating(
            workKey: 'tmdb:movie:1',
            source: RatingSource.tmdb,
            status: RatingStatus.ok,
            value: 7,
            scale: 10,
            via: ApiSource.tmdb,
            fetchedAt: 1,
          ),
        ]);
      }
      storage.failReads = failure == 'read';
      storage.failWrites = failure == 'write';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(db),
            ratingsServiceProvider.overrideWithValue(RatingsService(db)),
            myRatingProvider.overrideWith((ref, key) => Stream.value(null)),
          ],
          child: MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const Scaffold(
              body: RatingsPanel(
                target: RatingTarget(
                  key: WorkKey.movie(1),
                  tmdbVote: TmdbVote(9, 100),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      if (failure == 'write') expect(find.text('7.0'), findsOneWidget);
      storage.failReads = false;
      storage.failWrites = false;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.text('Try again'), findsNothing);
      expect(find.text('9.0'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 1));
    });
  }
}
