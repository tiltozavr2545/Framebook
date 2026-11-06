import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/rating_note.dart';
import 'package:framebook/features/title/my_rating.dart';
import 'package:framebook/features/title/score_reel.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:framebook/shared/note_length_formatter.dart';

import '../data/insights_test.dart' show rated;

void main() {
  testWidgets(
    'an older comparison cannot replace a newer request for the same score',
    (tester) async {
      final requests = <Completer<Calibration>>[];
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RatingEditor(
                compare: (_) {
                  final request = Completer<Calibration>();
                  requests.add(request);
                  return request.future;
                },
              ),
            ),
          ),
        ),
      );
      tester.widget<ScoreReel>(find.byType(ScoreReel)).onChanged(12);
      tester.widget<ScoreReel>(find.byType(ScoreReel)).onChanged(10);
      requests.last.complete(
        Calibration(same: [rated(2, 10)], above: [], below: []),
      );
      await tester.pumpAndSettle();
      expect(find.text('Title 2'), findsOneWidget);
      requests.first.complete(
        Calibration(same: [rated(1, 10)], above: [], below: []),
      );
      requests[1].complete(const Calibration(same: [], above: [], below: []));
      await tester.pumpAndSettle();
      expect(find.text('Title 2'), findsOneWidget);
      expect(find.text('Title 1'), findsNothing);
    },
  );
  testWidgets('a failed calibration lookup leaves the editor usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: FramebookTheme.light,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: RatingEditor(
            compare: (_) async => throw StateError('database unavailable'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Draft survives');
    expect(find.text('Draft survives'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
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

  for (final moving in [false, true]) {
    testWidgets(
      'a pending save keeps the reel and retry draft at the saved score: moving=$moving',
      (tester) async {
        final release = Completer<void>();
        final drafts = <RatingDraft>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: FramebookTheme.light,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: RatingEditor(
                initialScoreHalf: 10,
                showComparison: false,
                compare: (_) async =>
                    const Calibration(same: [], above: [], below: []),
                onSave: (draft) async {
                  drafts.add(draft);
                  if (drafts.length == 1) await release.future;
                  throw StateError('disk unavailable');
                },
              ),
            ),
          ),
        );
        await tester.enterText(
          find.byType(TextField),
          'Keep this score and note',
        );
        if (moving) {
          await tester.fling(
            find.byType(ScoreReel),
            const Offset(-128, 0),
            1200,
          );
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.tap(find.text('Save'));
        await tester.pump();
        await tester.drag(find.byType(ScoreReel), const Offset(-128, 0));
        await tester.pumpAndSettle();
        release.complete();
        await tester.pumpAndSettle();
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();
        expect(drafts, hasLength(2));
        expect(drafts.last, drafts.first);
        if (!moving) {
          expect(drafts.first, (
            scoreHalf: 10,
            note: 'Keep this score and note',
          ));
        }
      },
    );
  }
}
