import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/source_failure.dart';
import '../../data/sources/providers.dart';
import '../../data/sources/tmdb/tmdb_models.dart';

final class SearchState {
  const SearchState({
    this.query = '',
    this.results = const [],
    this.page = 0,
    this.pages = 0,
    this.loading = false,
    this.failure,
  });

  final String query;
  final List<TitleSummary> results;

  /// How many TMDB pages are loaded, and how many there are.
  final int page;
  final int pages;
  final bool loading;

  /// The last load failed, whether the first page or a later one.
  final SourceFailure? failure;

  bool get hasMore => page < pages;

  SearchState copyWith({bool? loading, SourceFailure? Function()? failure}) =>
      SearchState(
        query: query,
        results: results,
        page: page,
        pages: pages,
        loading: loading ?? this.loading,
        failure: failure == null ? this.failure : failure(),
      );
}

/// Search as you type: the request goes out once the user stops typing.
/// Lives as long as the app is open, so coming back to the tab shows the
/// same results.
class SearchNotifier extends Notifier<SearchState> {
  static const debounce = Duration(milliseconds: 400);

  Timer? _debounce;

  /// The answer to an outdated query (the user kept typing) is dropped.
  int _generation = 0;

  @override
  SearchState build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchState();
  }

  void typed(String text) {
    final query = text.trim();
    if (query == state.query && state.failure == null) return;
    _debounce?.cancel();
    if (query.isEmpty) {
      _generation++;
      state = const SearchState();
      return;
    }
    _generation++;
    state = SearchState(query: query, loading: true);
    _debounce = Timer(debounce, () => _load(query, 1));
  }

  /// The keyboard's search button — no waiting.
  void submit(String text) {
    _debounce?.cancel();
    final query = text.trim();
    if (query.isNotEmpty) _load(query, 1);
  }

  void loadMore() {
    if (state.loading || !state.hasMore || state.failure != null) return;
    _load(state.query, state.page + 1);
  }

  /// Retries what failed to load: the first page or the next one.
  void retry() {
    if (state.query.isEmpty) return;
    _load(state.query, state.page + 1);
  }

  Future<void> _load(String query, int page) async {
    final generation = ++_generation;
    final tmdb = ref.read(tmdbProvider);
    state = page == 1
        ? SearchState(query: query, loading: true)
        : state.copyWith(loading: true, failure: () => null);
    try {
      final found = await tmdb.search(query, page: page);
      if (!ref.mounted || generation != _generation) return;
      // Results can shift between pages; skip duplicates.
      final seen = {for (final r in state.results) r.key};
      state = SearchState(
        query: query,
        results: [
          ...state.results,
          ...found.results.where((r) => seen.add(r.key)),
        ],
        page: found.page,
        pages: found.pages,
      );
    } on SourceException catch (e) {
      if (!ref.mounted || generation != _generation) return;
      state = state.copyWith(loading: false, failure: () => e.failure);
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
