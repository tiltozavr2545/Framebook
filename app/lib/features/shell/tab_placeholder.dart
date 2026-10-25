import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../l10n/app_localizations.dart';
import 'shell_screen.dart';

/// Placeholder for a tab until its stage (docs/implementation-plan.md):
/// statistics come in Stage 4.
class TabPlaceholder extends StatelessWidget {
  const TabPlaceholder({super.key, required this.tab});

  final AppTab tab;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = switch (tab) {
      AppTab.stats => l10n.tabStatsPlaceholder,
      AppTab.search ||
      AppTab.ratings ||
      AppTab.watchlist => throw StateError('$tab has its own screen'),
    };
    return Scaffold(
      appBar: AppBar(
        title: Text(tab.label(l10n)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                tab.icon,
                size: 48,
                color: Theme.of(context).colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                text,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
