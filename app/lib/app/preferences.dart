import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/app_localizations.dart';
import 'preference_writes.dart';

/// Read during startup before the main application is built, so its first
/// frame uses the saved theme and language.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

const _themeModeKey = 'theme_mode';
const _localeKey = 'locale';

/// Device-local presentation preference, excluded from account synchronization.
class FloatingNavigationNotifier extends Notifier<bool> {
  late PreferenceWrites<bool> _writes;
  @override
  bool build() {
    final initial =
        ref.watch(sharedPreferencesProvider).getBool('floating_navigation') ??
        true;
    _writes = PreferenceWrites(initial);
    return initial;
  }

  Future<void> set(bool enabled) {
    final prefs = ref.read(sharedPreferencesProvider);
    final writes = _writes;
    state = enabled;
    return writes.save(
      enabled,
      () => prefs.setBool('floating_navigation', enabled),
      (saved) {
        if (ref.mounted && identical(writes, _writes)) state = saved;
      },
    );
  }
}

final floatingNavigationProvider =
    NotifierProvider<FloatingNavigationNotifier, bool>(
      FloatingNavigationNotifier.new,
    );

class ThemeModeNotifier extends Notifier<ThemeMode> {
  late PreferenceWrites<ThemeMode> _writes;
  @override
  ThemeMode build() {
    final stored = ref
        .watch(sharedPreferencesProvider)
        .getString(_themeModeKey);
    final initial = ThemeMode.values.firstWhere(
      (m) => m.name == stored,
      orElse: () => ThemeMode.system,
    );
    _writes = PreferenceWrites(initial);
    return initial;
  }

  Future<void> set(ThemeMode mode) {
    final prefs = ref.read(sharedPreferencesProvider);
    final writes = _writes;
    state = mode;
    return writes.save(mode, () => prefs.setString(_themeModeKey, mode.name), (
      saved,
    ) {
      if (ref.mounted && identical(writes, _writes)) state = saved;
    });
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

/// `null` means system: Flutter picks the first supported locale from the
/// device's list, or en.
class LocaleNotifier extends Notifier<Locale?> {
  late PreferenceWrites<Locale?> _writes;
  @override
  Locale? build() {
    final stored = ref.watch(sharedPreferencesProvider).getString(_localeKey);
    Locale? initial;
    for (final locale in AppLocalizations.supportedLocales) {
      if (locale.languageCode == stored) initial = locale;
    }
    _writes = PreferenceWrites(initial);
    return initial;
  }

  Future<void> set(Locale? locale) {
    final prefs = ref.read(sharedPreferencesProvider);
    final writes = _writes;
    state = locale;
    return writes.save(
      locale,
      () => locale == null
          ? prefs.remove(_localeKey)
          : prefs.setString(_localeKey, locale.languageCode),
      (saved) {
        if (ref.mounted && identical(writes, _writes)) state = saved;
      },
    );
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
