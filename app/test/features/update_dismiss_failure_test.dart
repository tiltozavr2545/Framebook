import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/update_checker.dart';
import 'package:framebook/features/shell/shell_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Preferences implements SharedPreferences {
  final values = <String, Object>{};
  final dismissals = <Completer<bool>>[];
  @override
  String? getString(String key) => values[key] as String?;
  @override
  int? getInt(String key) => values[key] as int?;
  @override
  Future<bool> setString(String key, String value) async {
    if (key == 'update_dismissed') {
      final result = Completer<bool>();
      dismissals.add(result);
      if (!await result.future) return false;
    }
    values[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    values[key] = value;
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Source implements UpdateSource {
  String version = 'v1.0.0';
  @override
  Future<UpdateRelease?> latest() async => UpdateRelease(
    version,
    Uri.parse(
      'https://github.com/tiltozavr2545/Framebook/releases/tag/$version',
    ),
  );
}

void main() {
  for (final throwing in [false, true]) {
    testWidgets(
      'banner dismissal retains retry after storage failure: $throwing',
      (tester) async {
        final prefs = _Preferences();
        final source = _Source();
        final container = ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            appVersionProvider.overrideWithValue('0.9.5+25'),
            updateChecksEnabledProvider.overrideWithValue(false),
            updateSourceProvider.overrideWithValue(source),
          ],
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: FramebookTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: const Scaffold(body: UpdateBanner()),
            ),
          ),
        );
        final controller = container.read(updateControllerProvider.notifier);
        await controller.check(manual: true);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        expect(find.text('Update v1.0.0 is available'), findsOneWidget);
        final pending = controller.dismiss();
        expect(controller.dismiss(), same(pending));
        expect(prefs.dismissals, hasLength(1));
        if (throwing) {
          prefs.dismissals.single.completeError(
            StateError('Storage unavailable'),
          );
        } else {
          prefs.dismissals.single.complete(false);
        }
        await tester.pumpAndSettle();
        final l10n = AppLocalizations.of(
          tester.element(find.byType(UpdateBanner)),
        );
        expect(find.text(l10n.recommendationsSaveFailed), findsOneWidget);
        expect(find.text('Update v1.0.0 is available'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        source.version = 'v1.1.0';
        await controller.check(manual: true);
        prefs.dismissals.last.complete(true);
        await tester.pumpAndSettle();
        expect(prefs.values['update_dismissed'], 'v1.0.0');
        expect(find.text('Update v1.1.0 is available'), findsOneWidget);
        await tester.tap(find.text('Dismiss'));
        await tester.pumpAndSettle();
        prefs.dismissals.last.complete(true);
        await tester.pumpAndSettle();
        expect(prefs.values['update_dismissed'], 'v1.1.0');
        expect(find.byType(MaterialBanner), findsNothing);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
