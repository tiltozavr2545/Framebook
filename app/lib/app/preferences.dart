import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';

/// Read during startup before the main application is built, so its first
/// frame uses the saved theme and language.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

const _themeModeKey = 'theme_mode';
const _localeKey = 'locale';

/// Device-local presentation preference, excluded from account synchronization.
class FloatingNavigationNotifier extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool('floating_navigation') ??
      true;

  Future<void> set(bool enabled) async {
    state = enabled;
    await ref
        .read(sharedPreferencesProvider)
        .setBool('floating_navigation', enabled);
  }
}

final floatingNavigationProvider =
    NotifierProvider<FloatingNavigationNotifier, bool>(
      FloatingNavigationNotifier.new,
    );

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
  if (chosen == null) {
    final observer = _SystemLocaleObserver(ref.invalidateSelf);
    WidgetsBinding.instance.addObserver(observer);
    ref.onDispose(() => WidgetsBinding.instance.removeObserver(observer));
  }
  final code =
      chosen?.languageCode ??
      WidgetsBinding.instance.platformDispatcher.locales
          .map((l) => l.languageCode)
          .firstWhere(
            (code) => AppLocalizations.supportedLocales.any(
              (l) => l.languageCode == code,
            ),
            orElse: () => 'en',
          );
  return code == 'ru' ? 'ru-RU' : 'en-US';
});

class _SystemLocaleObserver with WidgetsBindingObserver {
  _SystemLocaleObserver(this.changed);
  final VoidCallback changed;

  @override
  void didChangeLocales(List<Locale>? locales) => changed();
}
