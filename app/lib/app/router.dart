import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/api_keys.dart';
import '../data/api_source.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/ratings/ratings_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/about_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/sources_screen.dart';
import '../features/shell/shell_screen.dart';
import '../features/shell/tab_placeholder.dart';
import '../features/title/title_routes.dart';
import '../features/watchlist/watchlist_screen.dart';

abstract final class Routes {
  static const onboarding = '/onboarding';
  static const search = '/search';
  static const ratings = '/ratings';
  static const watchlist = '/watchlist';
  static const stats = '/stats';
  static const settings = '/settings';
  static const sources = '/settings/sources';
  static const about = '/settings/about';
}

final routerProvider = Provider<GoRouter>((ref) {
  // Without a TMDB key the app is useless: no search, no cards. The router
  // keeps the user on onboarding while there is no key, and sends them back
  // there if the key is removed in settings. The user leaves onboarding
  // themselves, with a button: after the TMDB key they may want to add the
  // optional ones too.
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
                  builder: (context, state) => switch (tab) {
                    AppTab.search => const SearchScreen(),
                    AppTab.ratings => const RatingsScreen(),
                    AppTab.watchlist => const WatchlistScreen(),
                    AppTab.stats => TabPlaceholder(tab: tab),
                  },
                  // Cards open inside the tab they were opened from.
                  routes: tab == AppTab.stats ? const [] : TitleRoutes.routes(),
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
          GoRoute(
            path: 'about',
            builder: (context, state) => const AboutScreen(),
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
