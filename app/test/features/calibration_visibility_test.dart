import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/features/title/my_rating.dart';
import 'package:framebook/l10n/app_localizations.dart';

void main() {
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
