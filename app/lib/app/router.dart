import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_keys.dart';
import '../data/api_source.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/sources_screen.dart';
import '../features/shell/shell_screen.dart';
import '../features/shell/tab_placeholder.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const search = '/search';
  static const ratings = '/ratings';
  static const watchlist = '/watchlist';
  static const stats = '/stats';
  static const settings = '/settings';
  static const sources = '/settings/sources';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Без ключа TMDB приложение бесполезно: нет ни поиска, ни карточек. Роутер
  // держит человека на онбординге, пока ключа нет, — и возвращает туда, если
  // ключ удалили в настройках. Уходит с онбординга человек сам, кнопкой:
  // после ключа TMDB он может захотеть добавить и необязательные.
  final hasTmdb = ValueNotifier(ref.read(apiKeysProvider).has(ApiSource.tmdb));
  ref.listen(
    apiKeysProvider,
    (_, keys) => hasTmdb.value = keys.has(ApiSource.tmdb),
  );
  ref.onDispose(hasTmdb.dispose);

  final router = GoRouter(
    initialLocation: Routes.search,
    refreshListenable: hasTmdb,
    redirect: (context, state) {
      final onOnboarding = state.matchedLocation == Routes.onboarding;
      if (!hasTmdb.value && !onOnboarding) return Routes.onboarding;
      return null;
    },
    routes: [
      GoRoute(
        path: Routes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ShellScreen(shell: shell),
        branches: [
          for (final tab in AppTab.values)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: tab.path,
                  builder: (context, state) => TabPlaceholder(tab: tab),
                ),
              ],
            ),
        ],
      ),
      GoRoute(
        path: Routes.settings,
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'sources',
            builder: (context, state) => const SourcesScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
