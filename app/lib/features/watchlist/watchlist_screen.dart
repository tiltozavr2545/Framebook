import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/library/library.dart';
import '../../data/library/work_snapshot.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/title_row.dart';
import '../../shared/title_text.dart';
import '../title/title_routes.dart';

/// Films and series to watch, most recently added first. Rating a title takes
/// it off the list by itself.
class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final titles = ref.watch(watchlistTitlesProvider).value;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabWatchlist),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: switch (titles) {
        null => const Center(child: CircularProgressIndicator()),
        [] => EmptyMessage(
          icon: Icons.bookmark_outline,
          text: l10n.watchlistEmpty,
        ),
        final titles => ListView.builder(
          itemCount: titles.length,
          itemBuilder: (context, index) => _WatchlistRow(title: titles[index]),
        ),
      },
    );
  }
}

class _WatchlistRow extends ConsumerWidget {
  const _WatchlistRow({required this.title});

  final WatchlistTitle title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return TitleRow(
      posterPath: title.work.posterPath,
      lines: describeWork(l10n, title.work),
      onTap: () =>
          context.go('${Routes.watchlist}/${TitleRoutes.path(title.key)}'),
      trailing: IconButton(
        icon: const Icon(Icons.bookmark_remove_outlined),
        tooltip: l10n.watchlistRemove,
        onPressed: () => _remove(context, ref),
      ),
    );
  }

  /// Removes at once and offers to undo — cheaper than a confirmation
  /// dialog for something this easy to put back.
  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final library = ref.read(libraryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final snapshot = WorkSnapshot.fromWork(title.work);
    await library.removeFromWatchlist(title.key);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.watchlistRemoved(title.work.title)),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => library.addToWatchlist([snapshot]),
          ),
        ),
      );
  }
}
