import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/preferences.dart';
import 'navigation_motion.dart';
import '../../data/background_refresh.dart';
import '../../data/library/localized_titles.dart';
import '../../data/recommendations/providers.dart';
import '../../data/update_checker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/sync/sync_controller.dart';
import '../../l10n/app_localizations.dart';

/// Bottom navigation tabs, in display order.
enum AppTab {
  search(Routes.search, Icons.explore_outlined),
  ratings(Routes.ratings, Icons.star_outline),
  watchlist(Routes.watchlist, Icons.bookmark_outline),
  stats(Routes.stats, Icons.insights_outlined);

  const AppTab(this.path, this.icon);

  final String path;
  final IconData icon;

  /// The short name under the icon; screens carry the full one.
  String label(AppLocalizations l10n) => switch (this) {
    AppTab.search => l10n.navDiscover,
    AppTab.ratings => l10n.navRatings,
    AppTab.watchlist => l10n.navWatchlist,
    AppTab.stats => l10n.navStats,
  };
}

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen>
    with SingleTickerProviderStateMixin {
  late final _position = AnimationController.unbounded(
    vsync: this,
    value: widget.shell.currentIndex.toDouble(),
  );
  bool _dragging = false;
  late int _routeIndex = widget.shell.currentIndex;
  int _dragOrigin = 0;

  @override
  void dispose() {
    _position.dispose();
    super.dispose();
  }

  void _settle(int index) {
    _dragging = false;
    _routeIndex = index;
    if (MediaQuery.disableAnimationsOf(context) ||
        !ref.read(floatingNavigationProvider)) {
      _position.value = index.toDouble();
    } else {
      _position.animateTo(
        index.toDouble(),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
    widget.shell.goBranch(index);
  }

  void _select(int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    final reset = index == widget.shell.currentIndex;
    _settle(index);
    if (reset) widget.shell.goBranch(index, initialLocation: true);
  }

  @override
  Widget build(BuildContext context) {
    // Background refresh and sync live as long as the tabs do: not on onboarding,
    // where there are no keys to refresh with. Listened to, not watched, so
    // its passes don't rebuild the shell.
    ref.listen(backgroundRefreshProvider, (_, _) {});
    ref.watch(localizedTitlesProvider);
    // Sync too: on launch, on returning to the app, after changes.
    ref.listen(syncControllerProvider, (_, _) {});
    // Keep streamed recommendation dependencies current while a nested card
    // pauses Discover's widget subscriptions, so back can resume them safely.
    ref.listen(recommendationFeedProvider, (_, _) {});
    final l10n = AppLocalizations.of(context);
    final shell = widget.shell;
    final floating = ref.watch(floatingNavigationProvider);
    if (!_dragging && _routeIndex != shell.currentIndex) {
      _routeIndex = shell.currentIndex;
      _position.value = _routeIndex.toDouble();
    }
    final destinations = [
      for (final tab in AppTab.values)
        NavigationDestination(icon: Icon(tab.icon), label: tab.label(l10n)),
    ];
    return Scaffold(
      extendBody: floating,
      body: Column(
        children: [
          const UpdateBanner(),
          Expanded(
            child: NavigationMotion(
              position: _position,
              enabled: floating,
              child: shell,
            ),
          ),
        ],
      ),
      bottomNavigationBar: floating
          ? GlassNavigationBar(
              position: _position,
              selectedIndex: shell.currentIndex,
              destinations: destinations,
              onSelected: _select,
              onDragStart: () {
                FocusManager.instance.primaryFocus?.unfocus();
                _position.stop();
                _dragOrigin = shell.currentIndex;
                _dragging = true;
              },
              onDragUpdate: (delta) {
                _position.value = (_position.value + delta).clamp(
                  0.0,
                  AppTab.values.length - 1.0,
                );
                final index = _position.value.round();
                if (index != widget.shell.currentIndex) {
                  _routeIndex = index;
                  widget.shell.goBranch(index);
                }
              },
              onDragEnd: (velocity) => _settle(
                (_position.value +
                        (velocity.abs() > 2 ? velocity.sign * 0.35 : 0))
                    .round()
                    .clamp(0, AppTab.values.length - 1),
              ),
              onDragCancel: () => _settle(_dragOrigin),
            )
          : NavigationBar(
              selectedIndex: shell.currentIndex,
              // Tapping the active tab again takes it back to its start.
              onDestinationSelected: _select,
              destinations: destinations,
            ),
    );
  }
}

/// Shows the latest release until this version is dismissed.
class UpdateBanner extends ConsumerWidget {
  const UpdateBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final release = ref.watch(updateControllerProvider);
    if (release == null) return const SizedBox.shrink();
    final l10n = AppLocalizations.of(context);
    return MaterialBanner(
      content: Text(l10n.updateAvailable(release.version)),
      actions: [
        TextButton(
          onPressed: () =>
              launchUrl(release.url, mode: LaunchMode.externalApplication),
          child: Text(l10n.updateOpen),
        ),
        TextButton(
          onPressed: () =>
              ref.read(updateControllerProvider.notifier).dismiss(),
          child: Text(l10n.updateDismiss),
        ),
      ],
    );
  }
}
