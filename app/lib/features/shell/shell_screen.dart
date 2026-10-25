import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/background_refresh.dart';
import '../../data/sync/sync_controller.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation tabs, in display order.
enum AppTab {
  search(Routes.search, Icons.search),
  ratings(Routes.ratings, Icons.star_outline),
  watchlist(Routes.watchlist, Icons.bookmark_outline),
  stats(Routes.stats, Icons.insights_outlined);

  const AppTab(this.path, this.icon);

  final String path;
  final IconData icon;

  String label(AppLocalizations l10n) => switch (this) {
    AppTab.search => l10n.tabSearch,
    AppTab.ratings => l10n.tabRatings,
    AppTab.watchlist => l10n.tabWatchlist,
    AppTab.stats => l10n.tabStats,
  };
}

class ShellScreen extends ConsumerWidget {
  const ShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Background refresh and sync live as long as the tabs do: not on onboarding,
    // where there are no keys to refresh with. Listened to, not watched, so
    // its passes don't rebuild the shell.
    ref.listen(backgroundRefreshProvider, (_, _) {});
    // Sync too: on launch, on returning to the app, after changes.
    ref.listen(syncControllerProvider, (_, _) {});
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        // Tapping the active tab again takes it back to its start.
        onDestinationSelected: (index) =>
            shell.goBranch(index, initialLocation: index == shell.currentIndex),
        destinations: [
          for (final tab in AppTab.values)
            NavigationDestination(icon: Icon(tab.icon), label: tab.label(l10n)),
        ],
      ),
    );
  }
}
