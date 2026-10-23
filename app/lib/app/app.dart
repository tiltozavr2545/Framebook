import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import 'preferences.dart';
import 'router.dart';

// Строятся один раз: ColorScheme.fromSeed считает тональную палитру, а
// приложение перестраивается на каждую смену темы и маршрута.
final _lightTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
);
final _darkTheme = ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.deepOrange,
    brightness: Brightness.dark,
  ),
);

class FramebookApp extends ConsumerWidget {
  const FramebookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: _lightTheme,
      darkTheme: _darkTheme,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // Как в Amicus: системный масштаб шрифта пропускается, но с потолком —
      // иначе крупный шрифт растягивает строки сверх того, на что рассчитана
      // вёрстка.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: child!,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
