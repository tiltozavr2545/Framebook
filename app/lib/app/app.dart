import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../data/sync/secrets_controller.dart';
import '../data/update_checker.dart';
import 'preferences.dart';
import 'router.dart';
import 'theme.dart';

class FramebookApp extends ConsumerWidget {
  const FramebookApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(secretsControllerProvider);
    ref.watch(updateControllerProvider);
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      theme: FramebookTheme.light,
      darkTheme: FramebookTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      // As in Amicus: the system font scale is honoured, but capped — otherwise
      // a large font stretches lines beyond what the layout is made for.
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: 1.0,
        maxScaleFactor: 1.3,
        child: child!,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
