import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/library/library.dart';
import '../../data/library/work_snapshot.dart';
import '../../data/work_key.dart';
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
        final titles => _GroupedWatchlist(titles: titles),
      },
    );
  }
}

class _GroupedWatchlist extends StatelessWidget {
  const _GroupedWatchlist({required this.titles});
  final List<WatchlistTitle> titles;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final groups = <String, List<WatchlistTitle>>{};
    for (final title in titles) {
      final key = title.key.kind == WorkKind.season
          ? title.key.parent!
          : title.key;
      groups.putIfAbsent(key.toString(), () => []).add(title);
    }
    final items = <WidgetBuilder>[];
    for (final group in groups.values) {
      if (group.first.key.kind != WorkKind.season) {
        final title = group.first;
        items.add((_) => _WatchlistRow(title: title));
      } else {
        if (group.first.series case final series?) {
          items.add(
            (context) => TitleRow(
              posterPath: series.posterPath,
              lines: describeWork(l10n, series),
              onTap: () => context.go(
                '${Routes.watchlist}/${TitleRoutes.path(WorkKey.parse(series.workKey))}',
              ),
            ),
          );
        }
        for (final season in group) {
          items.add((_) => _WatchlistRow(title: season, nested: true));
        }
      }
    }
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) => items[index](context),
    );
  }
}

class _WatchlistRow extends ConsumerWidget {
  const _WatchlistRow({required this.title, this.nested = false});

  final WatchlistTitle title;
  final bool nested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final row = TitleRow(
      posterPath: title.work.posterPath ?? title.series?.posterPath,
      lines: nested
          ? (
              title: seasonName(l10n, title.key.season!, title.work.title),
              subtitle: title.work.year?.toString() ?? '',
            )
          : describeWork(l10n, title.work),
      onTap: () =>
          context.go('${Routes.watchlist}/${TitleRoutes.path(title.key)}'),
      trailing: IconButton(
        icon: const Icon(Icons.bookmark_remove_outlined),
        tooltip: l10n.watchlistRemove,
        onPressed: () => _remove(context, ref),
      ),
    );
    return nested
        ? Padding(padding: const EdgeInsets.only(left: 24), child: row)
        : row;
  }

  /// Removes at once and offers to undo — cheaper than a confirmation
  /// dialog for something this easy to put back.
  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    final library = ref.read(libraryProvider);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    final lineage = [
      if (title.series case final series?) WorkSnapshot.fromWork(series),
      WorkSnapshot.fromWork(title.work),
    ];
    await library.removeFromWatchlist(title.key);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(l10n.watchlistRemoved(title.work.title)),
          action: SnackBarAction(
            label: l10n.undo,
            onPressed: () => library.addToWatchlist(lineage),
          ),
        ),
      );
  }
}
