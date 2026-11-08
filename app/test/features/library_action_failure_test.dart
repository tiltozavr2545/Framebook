import 'package:drift/drift.dart'
    show ApplyInterceptor, QueryExecutor, QueryInterceptor;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/source_failure.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/title/my_rating.dart';
import 'package:framebook/features/title/renumber_notice.dart';
import 'package:framebook/features/watchlist/watchlist_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';

class _FailWrites extends QueryInterceptor {
  bool failing = false;

  @override
  Future<int> runInsert(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (failing) return Future.error(StateError('Storage unavailable'));
    return super.runInsert(executor, statement, args);
  }

  @override
  Future<int> runUpdate(
    QueryExecutor executor,
    String statement,
    List<Object?> args,
  ) {
    if (failing) return Future.error(StateError('Storage unavailable'));
    return super.runUpdate(executor, statement, args);
  }
}

void main() {
  for (final releaseDate in ['2099-02-30', '2099-13-01', '2099-01-01']) {
    testWidgets('rating eligibility validates calendar date $releaseDate', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            myRatingProvider.overrideWith((ref, key) => Stream.value(null)),
            inWatchlistProvider.overrideWith((ref, key) => Stream.value(false)),
            ratedTitlesProvider.overrideWith((ref) => Stream.value([])),
          ],
          child: MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: MyRatingSection(
                refreshSnapshots: false,
                lineage: [
                  WorkSnapshot(
                    key: const WorkKey.movie(1),
                    tmdbId: 1,
                    title: 'Film',
                    releaseDate: releaseDate,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final button = tester.widget<FilledButton>(
        find.byWidgetPredicate((widget) => widget is FilledButton),
      );
      expect(button.onPressed == null, releaseDate == '2099-01-01');
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 1));
    });
  }

  const lineage = [
    WorkSnapshot(key: WorkKey.movie(1), tmdbId: 1, title: 'Film'),
  ];

  Future<void> flush(WidgetTester tester) async {
    for (var i = 0; i < 15; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  for (final watchlist in [false, true]) {
    for (final move in [false, true]) {
      testWidgets(
        'renumber choice retries after storage failure: watchlist $watchlist, move $move',
        (tester) async {
          final writes = _FailWrites();
          final db = AppDatabase(NativeDatabase.memory().interceptWith(writes));
          final library = Library(db, deviceId: 'test');
          const saved = [
            WorkSnapshot(key: WorkKey.tv(1), tmdbId: 1, title: 'Show'),
            WorkSnapshot(
              key: WorkKey.season(1, 1),
              tmdbId: 11,
              title: 'Season',
            ),
          ];
          await tester.runAsync(
            () => watchlist
                ? library.addToWatchlist(saved)
                : library.rate(saved, scoreHalf: 16, note: 'Preserve'),
          );
          final tv = TvDetails.fromJson(
            const Json({
              'id': 1,
              'name': 'Show',
              'seasons': [
                {'id': 12, 'season_number': 1},
                {'id': 11, 'season_number': 2},
              ],
            }),
          );
          writes.failing = true;
          try {
            await tester.pumpWidget(
              ProviderScope(
                overrides: [
                  databaseProvider.overrideWithValue(db),
                  libraryProvider.overrideWithValue(library),
                ],
                child: MaterialApp(
                  theme: FramebookTheme.light,
                  localizationsDelegates:
                      AppLocalizations.localizationsDelegates,
                  supportedLocales: AppLocalizations.supportedLocales,
                  home: Scaffold(
                    body: watchlist
                        ? WatchlistRenumberNotice(tv: tv)
                        : RenumberNotice.seasons(tv),
                  ),
                ),
              ),
            );
            await flush(tester);
            final label = move ? 'Move' : 'Keep';
            await tester.tap(find.widgetWithText(TextButton, label));
            await flush(tester);
            expect(tester.takeException(), isNull);
            expect(
              find.text('Could not save changes. Try again.'),
              findsOneWidget,
            );
            expect(find.widgetWithText(TextButton, label), findsOneWidget);
            final unchanged = await tester.runAsync(
              () => (db.select(
                db.works,
              )..where((w) => w.workKey.equals('tmdb:tv:1:s1'))).getSingle(),
            );
            expect(unchanged!.tmdbId, 11);
            writes.failing = false;
            await tester.tap(find.widgetWithText(TextButton, label));
            await flush(tester);
            expect(find.widgetWithText(TextButton, label), findsNothing);
            if (watchlist) {
              final rows = await tester.runAsync(
                () => db.select(db.watchlist).get(),
              );
              expect(
                rows!.where((r) => r.deletedAt == null).map((r) => r.workKey),
                [move ? 'tmdb:tv:1:s2' : 'tmdb:tv:1:s1'],
              );
            } else {
              final rows = await tester.runAsync(
                () => db.select(db.ratings).get(),
              );
              final live = rows!.where((r) => r.deletedAt == null).toList();
              expect(live, hasLength(1));
              expect(
                live.single.workKey,
                move ? 'tmdb:tv:1:s2' : 'tmdb:tv:1:s1',
              );
              expect(live.single.note, 'Preserve');
              expect(live.single.scoreHalf, 16);
            }
          } finally {
            await tester.pumpWidget(const SizedBox.shrink());
            await tester.pump(const Duration(milliseconds: 1));
            await tester.runAsync(db.close);
          }
        },
      );
    }
  }

  for (final action in [
    'add',
    'remove',
    'delete',
    'snapshot',
    'row-remove',
    'undo',
  ]) {
    testWidgets('card $action recovers from a failed local write', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final writes = _FailWrites();
      final db = AppDatabase(NativeDatabase.memory().interceptWith(writes));
      final library = Library(db, deviceId: 'test');
      await tester.runAsync(() async {
        if (['remove', 'row-remove', 'undo'].contains(action)) {
          await library.addToWatchlist(lineage);
        }
        if (action == 'delete' || action == 'snapshot') {
          await library.rate(lineage, scoreHalf: 16, note: 'Keep this note');
        }
        await db.select(db.works).get();
      });
      writes.failing = action != 'undo';
      try {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              databaseProvider.overrideWithValue(db),
              libraryProvider.overrideWithValue(library),
            ],
            child: MaterialApp(
              theme: FramebookTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: action == 'row-remove' || action == 'undo'
                  ? const WatchlistScreen()
                  : Scaffold(
                      body: MyRatingSection(
                        lineage: lineage,
                        refreshSnapshots: action == 'snapshot',
                      ),
                    ),
            ),
          ),
        );
        await flush(tester);
        Future<void> act() async {
          if (action == 'undo') {
            await tester.tap(find.text('Undo'));
          } else if (action == 'row-remove') {
            await tester.tap(find.byIcon(Icons.bookmark_remove_outlined));
          } else if (action == 'delete') {
            await tester.tap(find.byIcon(Icons.delete_outline));
            await tester.pumpAndSettle();
            await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
          } else {
            await tester.tap(
              find.byIcon(
                action == 'remove'
                    ? Icons.bookmark_added
                    : Icons.bookmark_outline,
              ),
            );
          }
          await flush(tester);
        }

        if (action == 'undo') {
          await tester.tap(find.byIcon(Icons.bookmark_remove_outlined));
          await flush(tester);
          writes.failing = true;
        }
        if (action != 'snapshot') await act();
        expect(tester.takeException(), isNull);
        if (action == 'snapshot') {
          expect(find.text('Keep this note'), findsOneWidget);
        } else {
          expect(
            find.text('Could not save changes. Try again.'),
            findsOneWidget,
          );
        }
        if (action == 'delete' || action == 'snapshot') {
          final rating = await tester.runAsync(
            () => db.select(db.ratings).getSingle(),
          );
          expect(rating!.deletedAt, isNull);
          expect(rating.note, 'Keep this note');
        } else {
          final entries = await tester.runAsync(
            () => db.select(db.watchlist).get(),
          );
          expect(
            entries!.where((entry) => entry.deletedAt == null),
            hasLength(action == 'remove' || action == 'row-remove' ? 1 : 0),
          );
        }
        writes.failing = false;
        if (action != 'snapshot') {
          await act();
          if (action == 'delete') {
            final rating = await tester.runAsync(
              () => db.select(db.ratings).getSingle(),
            );
            expect(rating!.deletedAt, isNotNull);
          } else {
            final entries = await tester.runAsync(
              () => db.select(db.watchlist).get(),
            );
            expect(
              entries!.where((entry) => entry.deletedAt == null),
              hasLength(action == 'add' || action == 'undo' ? 1 : 0),
            );
          }
        }
      } finally {
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(milliseconds: 1));
        await tester.runAsync(db.close);
      }
    });
  }
}
