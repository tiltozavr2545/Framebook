import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../data/source_failure.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/failure_view.dart';
import '../../shared/poster.dart';
import '../title/title_layout.dart';
import '../title/title_routes.dart';
import 'search_controller.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(
    text: ref.read(searchProvider).query,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final search = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          textInputAction: TextInputAction.search,
          decoration: InputDecoration(
            hintText: l10n.searchHint,
            border: InputBorder.none,
          ),
          onChanged: notifier.typed,
          onSubmitted: notifier.submit,
        ),
        actions: [
          ListenableBuilder(
            listenable: _controller,
            builder: (context, _) => _controller.text.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: l10n.searchClear,
                    onPressed: () {
                      _controller.clear();
                      notifier.typed('');
                    },
                  ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: l10n.settingsTitle,
            onPressed: () => context.push(Routes.settings),
          ),
        ],
      ),
      body: switch (search) {
        SearchState(query: '') => _Message(
          icon: Icons.search,
          text: l10n.searchEmpty,
        ),
        SearchState(results: [], loading: true) => const Center(
          child: CircularProgressIndicator(),
        ),
        SearchState(results: [], :final failure?) => FailureView(
          error: SourceException(failure),
          onRetry: notifier.retry,
        ),
        SearchState(results: [], hasMore: false) => _Message(
          icon: Icons.search_off,
          text: l10n.searchNothing(search.query),
        ),
        _ => _Results(search: search),
      },
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.search});

  final SearchState search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = search.results;
    final tail = search.hasMore || search.loading || search.failure != null;
    return ListView.builder(
      // Dragging the list hides the keyboard, which otherwise covers half of
      // the results.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length + (tail ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < results.length) return _ResultTile(results[index]);
        return _Tail(search: search);
      },
    );
  }
}

/// End of the list: loads the next page or offers a retry.
class _Tail extends ConsumerWidget {
  const _Tail({required this.search});

  final SearchState search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(searchProvider.notifier);
    final failure = search.failure;
    if (failure != null) {
      final l10n = AppLocalizations.of(context);
      return ListTile(
        title: Text(catalogFailureText(l10n, failure)),
        trailing: TextButton(
          onPressed: notifier.retry,
          child: Text(l10n.retry),
        ),
      );
    }
    // The end is reached, so load the next page — after the frame, since state
    // can't change during build.
    WidgetsBinding.instance.addPostFrameCallback((_) => notifier.loadMore());
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile(this.title);

  final TitleSummary title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final original = title.originalTitle;
    final kind = title.key.kind == WorkKind.movie
        ? l10n.kindMovie
        : l10n.kindTv;
    return InkWell(
      onTap: () =>
          context.go('${Routes.search}/${TitleRoutes.segment(title.key)}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Poster(
              title.posterPath,
              size: ImageSize.w185,
              width: 48,
              icon: title.key.kind == WorkKind.movie
                  ? Icons.movie_outlined
                  : Icons.live_tv_outlined,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.title, style: theme.textTheme.titleMedium),
                  Text(
                    joinFacts([
                      kind,
                      title.year?.toString(),
                      if (original != title.title) original,
                    ]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TmdbScore(title.vote),
          ],
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    ),
  );
}
