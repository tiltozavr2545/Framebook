import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/app/theme.dart';
import 'package:framebook/features/settings/settings_screen.dart';
import 'package:framebook/l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final locale in ['en', 'ru']) {
    for (final scale in [1.0, 2.0]) {
      testWidgets('settings fit a narrow phone: $locale scale=$scale', (
        tester,
      ) async {
        tester.view.physicalSize = const Size(320, 780);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
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
              home: const SettingsScreen(),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final l10n = AppLocalizations.of(
          tester.element(find.byType(SettingsScreen)),
        );
        final label = tester.getRect(find.text(l10n.settingsNavigationStyle));
        expect(
          label.left,
          tester.getRect(find.text(l10n.settingsSources)).left,
        );
        final choice = tester.getRect(find.byType(DropdownButton<bool>));
        if (scale == 1) {
          expect(choice.left, greaterThan(label.right));
          expect(choice.center.dy, closeTo(label.center.dy, 1));
        } else {
          expect(choice.top, greaterThanOrEqualTo(label.bottom));
        }
        await tester.tap(find.byType(DropdownButton<bool>));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.tap(find.text(l10n.navigationClassic).last);
        await tester.pumpAndSettle();
        expect(prefs.getBool('floating_navigation'), isFalse);
        await tester.ensureVisible(find.byType(DropdownButton<String>));
        await tester.tap(find.byType(DropdownButton<String>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.languageEnglish).last);
        await tester.pumpAndSettle();
        expect(prefs.getString('locale'), 'en');
        await tester.ensureVisible(find.byType(DropdownButton<ThemeMode>));
        await tester.tap(find.byType(DropdownButton<ThemeMode>));
        await tester.pumpAndSettle();
        await tester.tap(find.text(l10n.themeDark).last);
        await tester.pumpAndSettle();
        expect(prefs.getString('theme_mode'), 'dark');
        await tester.drag(find.byType(ListView), const Offset(0, -600));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }
}
