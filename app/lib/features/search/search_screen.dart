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
import 'search_history.dart';
import 'shelves.dart';

/// The Discover tab (Stage 6): a search field on top and, while it is empty,
/// shelves to browse; typing turns the shelves into search results.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late final _controller = TextEditingController(
    text: ref.read(searchProvider).query,
  );

  final _focus = FocusNode();
  final _historyOverlay = OverlayPortalController();
  final _fieldLink = LayerLink();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (_focus.hasFocus) {
        _historyOverlay.show();
      } else {
        _historyOverlay.hide();
      }
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final search = ref.watch(searchProvider);
    final notifier = ref.read(searchProvider.notifier);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 8, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      l10n.tabSearch,
                      style: theme.textTheme.headlineLarge,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings_outlined),
                    tooltip: l10n.settingsTitle,
                    onPressed: () => context.push(Routes.settings),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: CompositedTransformTarget(
                link: _fieldLink,
                child: OverlayPortal(
                  controller: _historyOverlay,
                  overlayChildBuilder: (context) => Positioned(
                    left: 0,
                    top: 0,
                    child: CompositedTransformFollower(
                      link: _fieldLink,
                      showWhenUnlinked: false,
                      targetAnchor: Alignment.bottomLeft,
                      offset: const Offset(0, 4),
                      child: TextFieldTapRegion(
                        child: SizedBox(
                          width: MediaQuery.sizeOf(context).width - 32,
                          child: _SearchHistory(
                            onSelected: (entry) {
                              _focus.unfocus();
                              _historyOverlay.hide();
                              ref
                                  .read(searchHistoryProvider.notifier)
                                  .remember(entry);
                              context.go(
                                '${Routes.search}/${TitleRoutes.path(entry.key)}',
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: TextField(
                    focusNode: _focus,
                    onTap: () => _historyOverlay.show(),
                    onTapOutside: (_) {
                      _focus.unfocus();
                      _historyOverlay.hide();
                    },
                    controller: _controller,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: search.kind == SearchKind.people
                          ? l10n.searchPeopleHint
                          : l10n.searchHint,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: ListenableBuilder(
                        listenable: _controller,
                        builder: (context, _) => _controller.text.isEmpty
                            ? const SizedBox.shrink()
                            : IconButton(
                                icon: const Icon(Icons.close),
                                tooltip: l10n.searchClear,
                                onPressed: () {
                                  _controller.clear();
                                  notifier.typed('');
                                  _historyOverlay.show();
                                },
                              ),
                      ),
                    ),
                    onChanged: (text) {
                      _historyOverlay.hide();
                      notifier.typed(text);
                    },
                    onSubmitted: (query) {
                      _historyOverlay.hide();
                      notifier.submit(query);
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final kind in SearchKind.values)
                    ChoiceChip(
                      label: Text(
                        kind == SearchKind.titles
                            ? l10n.searchTitles
                            : l10n.searchPeople,
                      ),
                      selected: search.kind == kind,
                      onSelected: (_) {
                        _focus.unfocus();
                        _historyOverlay.hide();
                        notifier.selectKind(kind);
                      },
                    ),
                ],
              ),
            ),
            Expanded(
              child: switch (search) {
                SearchState(query: '', kind: SearchKind.people) => _Message(
                  icon: Icons.people_outline,
                  text: l10n.searchPeopleHint,
                ),
                SearchState(query: '') => const Shelves(),
                SearchState(isEmpty: true, loading: true) => const Center(
                  child: CircularProgressIndicator(),
                ),
                SearchState(isEmpty: true, :final failure?) => FailureView(
                  error: SourceException(failure),
                  onRetry: notifier.retry,
                ),
                SearchState(isEmpty: true, hasMore: false) => _Message(
                  icon: Icons.search_off,
                  text: l10n.searchNothing(search.query),
                ),
                _ => _Results(search: search),
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Results extends ConsumerWidget {
  const _Results({required this.search});

  final SearchState search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final results = search.kind == SearchKind.people
        ? search.people
        : search.results;
    final tail = search.hasMore || search.loading || search.failure != null;
    return ListView.builder(
      // Dragging the list hides the keyboard, which otherwise covers half of
      // the results.
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length + (tail ? 1 : 0),
      itemBuilder: (context, index) {
        if (index < results.length) {
          if (search.kind == SearchKind.people) {
            return _PersonTile(search.people[index]);
          }
          return _ResultTile(
            search.results[index],
            onOpen: () {
              FocusScope.of(context).unfocus();
              ref
                  .read(searchHistoryProvider.notifier)
                  .remember(
                    SearchHistoryEntry.fromTitle(search.results[index]),
                  );
            },
          );
        }
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
  const _ResultTile(this.title, {required this.onOpen});

  final VoidCallback onOpen;

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
      onTap: () {
        onOpen();
        context.go('${Routes.search}/${TitleRoutes.path(title.key)}');
      },
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

class _PersonTile extends StatelessWidget {
  const _PersonTile(this.person);
  final PersonSummary person;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () {
      context.push('${Routes.search}/person/${person.id}');
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Poster(
            person.profilePath,
            size: ImageSize.w185,
            width: 48,
            icon: Icons.person_outline,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  person.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (person.knownFor.isNotEmpty)
                  Text(
                    person.knownFor.join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _SearchHistory extends ConsumerWidget {
  const _SearchHistory({required this.onSelected});
  final ValueChanged<SearchHistoryEntry> onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kind = ref.watch(searchProvider.select((s) => s.kind));
    final entries = ref.watch(searchHistoryProvider);
    if (entries.isEmpty || kind != SearchKind.titles) {
      return const SizedBox.shrink();
    }
    final notifier = ref.read(searchHistoryProvider.notifier);
    final l10n = AppLocalizations.of(context);
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.searchHistory,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  onPressed: notifier.clear,
                  child: Text(l10n.searchHistoryClear),
                ),
              ],
            ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  (MediaQuery.sizeOf(context).height -
                          MediaQuery.viewInsetsOf(context).bottom -
                          260)
                      .clamp(80.0, 220.0),
            ),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: entries.length,
              itemBuilder: (context, index) => ListTile(
                leading: Poster(
                  entries[index].posterPath,
                  size: ImageSize.w185,
                  width: 32,
                  icon: entries[index].key.kind == WorkKind.movie
                      ? Icons.movie_outlined
                      : Icons.live_tv_outlined,
                ),
                title: Text(
                  entries[index].title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  joinFacts([
                    entries[index].key.kind == WorkKind.movie
                        ? l10n.kindMovie
                        : l10n.kindTv,
                    entries[index].year?.toString(),
                  ]),
                ),
                onTap: () => onSelected(entries[index]),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: l10n.searchHistoryRemove,
                  onPressed: () => notifier.remove(entries[index].key),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
