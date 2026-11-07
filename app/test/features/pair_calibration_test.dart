import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/foreground.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/db/database_provider.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/library/pair_calibration_store.dart';
import 'package:framebook/data/view_computer.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/stats/pair_calibration_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';

import '../support/inline_view_computer.dart';

class _Foreground extends Foreground {
  @override
  bool build() => true;
  void set(bool value) => state = value;
}

void main() {
  late AppDatabase db;
  late Library library;
  var now = DateTime(2026, 11, 7, 12);
  setUp(() async {
    now = DateTime(2026, 11, 7, 12);
    db = AppDatabase(NativeDatabase.memory());
    library = Library(db, deviceId: 'test', clock: () => now);
    for (var id = 1; id <= 12; id++) {
      await library.rate(
        [
          WorkSnapshot(
            key: WorkKey.movie(id),
            tmdbId: id,
            title: 'Film $id',
            genreIds: [18],
          ),
        ],
        scoreHalf: id == 1 ? 18 : 16,
        note: 'Note $id',
      );
    }
  });
  tearDown(() => db.close());

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    String locale = 'en',
    double scale = 1,
  }) async {
    tester.view.physicalSize = const Size(320, 780);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(db),
          libraryProvider.overrideWithValue(library),
          viewComputerProvider.overrideWithValue(const InlineViewComputer()),
          pairCalibrationClockProvider.overrideWithValue(() => now),
          foregroundProvider.overrideWith(_Foreground.new),
        ],
        child: MaterialApp(
          theme: FramebookTheme.light,
          locale: Locale(locale),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(scale)),
            child: child!,
          ),
          home: const PairCalibrationScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(PairCalibrationScreen)),
    );
  }

  Future<void> tap(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.scrollUntilVisible(finder, 200);
    await tester.pumpAndSettle();
    await Scrollable.ensureVisible(tester.element(finder), alignment: .5);
    await tester.pumpAndSettle();
    expect(finder.hitTestable(), findsOneWidget);
    await tester.tap(finder.hitTestable());
    await tester.pumpAndSettle();
  }

  Future<void> unmount(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
  }

  for (final locale in ['en', 'ru']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('hidden scores, equality and skip fit $locale at $scale', (
        tester,
      ) async {
        await pump(tester, locale: locale, scale: scale);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(PairCalibrationScreen)),
        );
        expect(
          find.byKey(const ValueKey('pair-score-tmdb:movie:10')),
          findsNothing,
        );
        await tap(tester, l10n.pairSkip);
        expect(await db.select(db.pairComparisons).get(), isEmpty);
        await tap(tester, l10n.pairEqual);
        expect(find.text('8'), findsNWidgets(2));
        expect(
          await db.select(db.pairComparisons).get(),
          isEmpty,
          reason: 'Revealing scores must not save an answer or change a score',
        );
        await tap(tester, l10n.pairNext);
        expect(await db.select(db.pairComparisons).get(), hasLength(1));
        expect(
          (await db.select(db.ratings).get()).every(
            (r) => r.scoreHalf == (r.workKey == 'tmdb:movie:1' ? 18 : 16),
          ),
          isTrue,
        );
        expect(tester.takeException(), isNull);
        await unmount(tester);
      });
    }
  }

  testWidgets(
    'five answers stop the session and resume tomorrow restores access',
    (tester) async {
      final container = await pump(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PairCalibrationScreen)),
      );
      for (var answer = 0; answer < 5; answer++) {
        await tap(tester, l10n.pairEqual);
        // Equal-score pairs precede the sole higher-scored film.
        await tap(tester, l10n.pairNext);
      }
      expect(await db.select(db.pairComparisons).get(), hasLength(5));
      expect(find.text(l10n.pairLimit), findsOneWidget);
      expect(find.text(l10n.pairPreferFirst), findsNothing);
      now = now.add(const Duration(days: 1));
      final foreground =
          container.read(foregroundProvider.notifier) as _Foreground;
      foreground.set(false);
      await tester.pump();
      foreground.set(true);
      await tester.pumpAndSettle();
      expect(find.text(l10n.pairLimit), findsNothing);
      await tester.scrollUntilVisible(find.text(l10n.pairEqual), 200);
      await tester.pumpAndSettle();
      expect(find.text(l10n.pairEqual), findsOneWidget);
      await unmount(tester);
    },
  );

  testWidgets(
    'equality with different scores waits for a correction confirmation',
    (tester) async {
      // Reduce the library so the only available comparison has unequal scores.
      for (var id = 3; id <= 12; id++) {
        await library.deleteRating(WorkKey.movie(id));
      }
      await pump(tester);
      final l10n = AppLocalizations.of(
        tester.element(find.byType(PairCalibrationScreen)),
      );
      await tap(tester, l10n.pairEqual);
      final before = await library.watchRatings().first;
      expect(before.map((r) => r.rating.scoreHalf).toSet(), {16, 18});
      await tap(tester, l10n.pairCorrection('Film 1', '9', '8'));
      final after = await library.watchRatings().first;
      expect(after.map((r) => r.rating.scoreHalf).toSet(), {16});
      expect(
        (await db.select(db.pairComparisons).getSingle()).preference.name,
        'equal',
      );
      expect(
        find.text(l10n.pairFinished),
        findsOneWidget,
        reason: 'The adjusted pair must not immediately reappear',
      );
      await unmount(tester);
    },
  );
}
