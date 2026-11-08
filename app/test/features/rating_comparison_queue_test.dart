import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/features/title/my_rating.dart';
import 'package:framebook/features/title/score_reel.dart';
import 'package:framebook/l10n/app_localizations.dart';

import '../data/insights_test.dart' show rated;

Widget _editor(
  Future<Calibration> Function(int) compare, {
  Future<void> Function(RatingDraft)? onSave,
}) => MaterialApp(
  theme: FramebookTheme.light,
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: RatingEditor(compare: compare, onSave: onSave),
  ),
);

void _select(WidgetTester tester, int half) =>
    tester.widget<ScoreReel>(find.byType(ScoreReel)).onChanged(half);

void main() {
  testWidgets('a failed save resumes comparison for the selected score', (
    tester,
  ) async {
    final calls = <int>[];
    await tester.pumpWidget(
      _editor((half) async {
        calls.add(half);
        return Calibration(same: [rated(half, half)], above: [], below: []);
      }, onSave: (_) async => throw StateError('Write unavailable')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save'));
    _select(tester, 16);
    await tester.pump();
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(calls, [10, 16]);
    expect(find.text('Title 16'), findsOneWidget);
    expect(find.textContaining('Could not save your rating'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('rapid score changes coalesce before querying comparisons', (
    tester,
  ) async {
    final calls = <int>[];
    await tester.pumpWidget(
      _editor((half) async {
        calls.add(half);
        return const Calibration(same: [], above: [], below: []);
      }),
    );
    await tester.pump();
    for (final half in [12, 14, 16]) {
      _select(tester, half);
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(calls, [10]);
    await tester.pump(const Duration(milliseconds: 120));
    expect(calls, [10, 16]);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'a slow lookup runs alone and obsolete queued scores are skipped',
    (tester) async {
      final calls = <int>[];
      final requests = <Completer<Calibration>>[];
      await tester.pumpWidget(
        _editor((half) {
          calls.add(half);
          final request = Completer<Calibration>();
          requests.add(request);
          return request.future;
        }),
      );
      await tester.pump();
      for (final half in [12, 14, 16]) {
        _select(tester, half);
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(calls, [10]);
      requests.first.complete(
        Calibration(same: [rated(1, 10)], above: [], below: []),
      );
      await tester.pump();
      expect(calls, [10, 16]);
      expect(find.text('Title 1'), findsNothing);
      requests.last.complete(
        Calibration(same: [rated(2, 16)], above: [], below: []),
      );
      await tester.pumpAndSettle();
      expect(find.text('Title 2'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('closing the editor cancels a scheduled comparison', (
    tester,
  ) async {
    final calls = <int>[];
    await tester.pumpWidget(
      _editor((half) async {
        calls.add(half);
        return const Calibration(same: [], above: [], below: []);
      }),
    );
    await tester.pump();
    _select(tester, 16);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(calls, [10]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'a failed active comparison does not block the latest queued score',
    (tester) async {
      final blocked = Completer<Calibration>();
      final calls = <int>[];
      await tester.pumpWidget(
        _editor((half) {
          calls.add(half);
          return half == 10
              ? blocked.future
              : Future.value(
                  Calibration(same: [rated(2, half)], above: [], below: []),
                );
        }),
      );
      await tester.pump();
      _select(tester, 16);
      await tester.pump(const Duration(milliseconds: 120));
      blocked.completeError(StateError('Local read unavailable'));
      await tester.pumpAndSettle();
      expect(calls, [10, 16]);
      expect(find.text('Title 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'disposal skips queued comparisons after an active read completes',
    (tester) async {
      final blocked = Completer<Calibration>();
      final calls = <int>[];
      await tester.pumpWidget(
        _editor((half) {
          calls.add(half);
          return blocked.future;
        }),
      );
      await tester.pump();
      _select(tester, 16);
      await tester.pump(const Duration(milliseconds: 120));
      await tester.pumpWidget(const SizedBox());
      blocked.complete(const Calibration(same: [], above: [], below: []));
      await tester.pump();
      expect(calls, [10]);
      expect(tester.takeException(), isNull);
    },
  );
}
