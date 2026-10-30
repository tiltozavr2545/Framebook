import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/data/sync/sync_controller.dart';
import 'package:framebook/data/update_checker.dart';
import 'package:framebook/features/settings/about_screen.dart';
import 'package:framebook/features/shell/shell_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeUpdateSource implements UpdateSource {
  @override
  Future<UpdateRelease?> latest() async => UpdateRelease(
    'v0.8.0',
    Uri.parse('https://github.com/tiltozavr2545/Framebook/releases/tag/v0.8.0'),
  );
}

void main() {
  testWidgets('manual check offers the release page even when dismissed', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'update_dismissed': 'v0.8.0'});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          appVersionProvider.overrideWithValue('0.7.0+9'),
          updateChecksEnabledProvider.overrideWithValue(false),
          updateSourceProvider.overrideWithValue(FakeUpdateSource()),
        ],
        child: MaterialApp(
          theme: FramebookTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const AboutScreen(),
        ),
      ),
    );
    await tester.tap(find.text('Check for updates'));
    await tester.pumpAndSettle();
    expect(find.text('An update is available'), findsOneWidget);
    expect(find.text('Open release'), findsOneWidget);
  });
  testWidgets('banner opens a release and dismisses the current version', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appVersionProvider.overrideWithValue('0.7.0+9'),
        updateChecksEnabledProvider.overrideWithValue(false),
        updateSourceProvider.overrideWithValue(FakeUpdateSource()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: FramebookTheme.light,
          locale: const Locale('en'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const Scaffold(body: UpdateBanner()),
        ),
      ),
    );
    await container.read(updateControllerProvider.notifier).check(manual: true);
    await tester.pumpAndSettle();
    expect(find.text('Update v0.8.0 is available'), findsOneWidget);
    expect(find.text('Open release'), findsOneWidget);
    await tester.tap(find.text('Dismiss'));
    await tester.pumpAndSettle();
    expect(find.text('Update v0.8.0 is available'), findsNothing);
    expect(prefs.getString('update_dismissed'), 'v0.8.0');
  });
}
