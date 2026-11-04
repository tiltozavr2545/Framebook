import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/features/title/my_rating.dart';
import 'package:framebook/l10n/app_localizations.dart';

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets(
      'all three calibration groups scroll independently at scale $scale',
      (tester) async {
        tester.view.physicalSize = const Size(360, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        RatedTitle title(String group, int index, int half) => RatedTitle(
          rating: Rating(
            workKey: 'tmdb:movie:$index',
            scoreHalf: half,
            createdAt: 1,
            scoredAt: 1,
            updatedAt: 1,
            updatedBy: 'test',
          ),
          work: Work(
            workKey: 'tmdb:movie:$index',
            kind: WorkKind.movie,
            tmdbId: index,
            title: '$group $index',
            genreIds: '[]',
            snapshotUpdatedAt: 1,
          ),
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: FramebookTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: TextScaler.linear(scale)),
                child: child!,
              ),
              home: Scaffold(
                body: RatingEditor(
                  compare: (_) async => Calibration(
                    same: [for (var i = 1; i <= 12; i++) title('Same', i, 10)],
                    below: [for (var i = 1; i <= 12; i++) title('Below', i, 9)],
                    above: [
                      for (var i = 1; i <= 12; i++) title('Above', i, 11),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final labels = ['Also 5', 'A step below · 4.5', 'A step above · 5.5'];
        for (var i = 0; i < labels.length; i++) {
          final list = find.byKey(ValueKey(labels[i]));
          expect(find.text(labels[i]), findsOneWidget);
          final scrollable = find.descendant(
            of: list,
            matching: find.byType(Scrollable),
          );
          expect(tester.state<ScrollableState>(scrollable).position.pixels, 0);
          await tester.fling(list, const Offset(-1600, 0), 2000);
          await tester.pumpAndSettle();
          expect(
            tester.state<ScrollableState>(scrollable).position.pixels,
            greaterThan(0),
          );
          expect(
            find.text('${['Same', 'Below', 'Above'][i]} 12'),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }

  for (final visible in [false, true]) {
    testWidgets('comparison panel visibility: $visible', (tester) async {
      var comparisons = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: FramebookTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: RatingEditor(
              initialScoreHalf: 10,
              showComparison: visible,
              compare: (_) async {
                comparisons++;
                return const Calibration(same: [], above: [], below: []);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text(
          'Your first rating of this kind — nothing to compare with yet.',
        ),
        visible ? findsOneWidget : findsNothing,
      );
      expect(comparisons, visible ? 1 : 0);
    });
  }
}
