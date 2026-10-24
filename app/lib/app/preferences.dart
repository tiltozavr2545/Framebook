import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Read in `main()` before `runApp`, so theme and language are right from the
/// first frame instead of switching after loading.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

const _themeModeKey = 'theme_mode';
const _localeKey = 'locale';

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_themeModeKey);
    return ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_themeModeKey, mode.name);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// `null` means system: Flutter picks the first supported locale from the
/// device's list, or en.
class LocaleNotifier extends Notifier<Locale?> {
  @override
  Locale? build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_localeKey);
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == stored) return locale;
    }
    return null;
  }

  Future<void> set(Locale? locale) async {
    state = locale;
    final prefs = ref.read(sharedPreferencesProvider);
    if (locale == null) {
      await prefs.remove(_localeKey);
    } else {
      await prefs.setString(_localeKey, locale.languageCode);
    }
  }
}

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

/// Language of TMDB titles and overviews: `ru-RU` or `en-US`, same as the UI.
/// "System" is the first supported language in the device's list, the same
/// way Flutter itself picks it.
final contentLanguageProvider = Provider<String>((ref) {
  final chosen = ref.watch(localeProvider);
  final code =
      chosen?.languageCode ??
      PlatformDispatcher.instance.locales
          .map((l) => l.languageCode)
          .firstWhere(
            (code) => AppLocalizations.supportedLocales.any(
              (l) => l.languageCode == code,
            ),
            orElse: () => 'en',
          );
  return code == 'ru' ? 'ru-RU' : 'en-US';
});
