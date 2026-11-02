import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/rating_note.dart';
import 'package:framebook/features/title/my_rating.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:framebook/shared/note_length_formatter.dart';

void main() {
  test('note input uses code points and keeps compound characters intact', () {
    const formatter = NoteLengthFormatter();
    for (final cluster in ['e\u0301', '👨‍👩‍👧‍👦']) {
      final value = formatter.formatEditUpdate(
        TextEditingValue.empty,
        TextEditingValue(text: cluster * 10000),
      );
      expect(validRatingNote(value.text), isTrue);
      expect(value.text, cluster * (maxNoteCodePoints ~/ cluster.runes.length));
    }
  });

  testWidgets('a failed save keeps the rating editor and its draft', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: FramebookTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RatingEditor(
            showComparison: false,
            compare: (_) async =>
                const Calibration(same: [], above: [], below: []),
            onSave: (_) async {
              attempts++;
              throw StateError('disk unavailable');
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'Keep this draft');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(attempts, 1);
    expect(find.text('Keep this draft'), findsOneWidget);
    expect(find.textContaining('Could not save your rating'), findsOneWidget);
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(attempts, 2);
  });
}
