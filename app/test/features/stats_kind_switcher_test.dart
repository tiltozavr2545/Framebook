import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/stats/stats_kind_switcher.dart';
import 'package:framebook/l10n/app_localizations.dart';

void main() {
  for (final rtl in [false, true]) {
    for (final reducedMotion in [false, true]) {
      testWidgets(
        'kind switcher taps, drags and cancels rtl=$rtl reduced=$reducedMotion',
        (tester) async {
          tester.view.physicalSize = const Size(320, 780);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          var selected = WorkKind.movie;
          await tester.pumpWidget(
            MaterialApp(
              theme: FramebookTheme.dark,
              locale: const Locale('ru'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) => Directionality(
                textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(2),
                    disableAnimations: reducedMotion,
                  ),
                  child: child!,
                ),
              ),
              home: Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: StatefulBuilder(
                    builder: (context, setState) => StatsKindSwitcher(
                      selected: selected,
                      onSelected: (kind) => setState(() => selected = kind),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('stats-kind-3')));
          await tester.pumpAndSettle();
          expect(selected, WorkKind.episode);
          final stationary = await tester.startGesture(
            tester.getCenter(find.byKey(const ValueKey('stats-kind-3'))),
          );
          await stationary.cancel();
          await tester.pumpAndSettle();
          expect(selected, WorkKind.episode);
          await tester.tap(find.byKey(const ValueKey('stats-kind-0')));
          await tester.pumpAndSettle();

          Future<TestGesture> drag() async {
            final rect = tester.getRect(
              find.byKey(const ValueKey('stats-kind-slider')),
            );
            final slot = rect.width / 4;
            final direction = rtl ? -1.0 : 1.0;
            final start = Offset(
              rtl ? rect.right - slot / 2 : rect.left + slot / 2,
              rect.center.dy,
            );
            final gesture = await tester.startGesture(start);
            await gesture.moveBy(Offset(direction * 25, 0));
            await tester.pump();
            await gesture.moveBy(Offset(direction * slot * 1.6, 0));
            await tester.pump();
            expect(selected, WorkKind.season);
            return gesture;
          }

          final cancelled = await drag();
          await cancelled.cancel();
          await tester.pumpAndSettle();
          // Flutter finishes an accepted drag on pointer cancellation; its
          // already-selected kind stays active, as in Discover's switcher.
          expect(selected, WorkKind.season);
          await tester.tap(find.byKey(const ValueKey('stats-kind-0')));
          await tester.pumpAndSettle();
          final completed = await drag();
          await completed.up();
          await tester.pumpAndSettle();
          expect(selected, WorkKind.season);
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox());
          await tester.pump(const Duration(milliseconds: 1));
        },
      );
    }
  }
}
