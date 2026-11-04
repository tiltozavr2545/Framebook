import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/preferences.dart';
import '../../data/sources/tmdb/tmdb_models.dart';
import '../../data/work_key.dart';

/// Only the mini snapshot needed to reopen a recently selected search result.
final class SearchHistoryEntry {
  const SearchHistoryEntry({
    required this.key,
    required this.title,
    this.year,
    this.posterPath,
  });
  factory SearchHistoryEntry.fromTitle(TitleSummary title) =>
      SearchHistoryEntry(
        key: title.key,
        title: title.title,
        year: title.year,
        posterPath: title.posterPath,
      );
  final WorkKey key;
  final String title;
  final int? year;
  final String? posterPath;

  Map<String, Object?> toJson() => {
    'key': key.toString(),
    'title': title,
    'year': year,
    'poster_path': posterPath,
  };
}

/// Device-local recent titles, excluded from rating exports and Drive sync.
class SearchHistoryNotifier extends Notifier<List<SearchHistoryEntry>> {
  static const limit = 20;
  static const storageKey = 'recent_search_titles_v1';

  @override
  List<SearchHistoryEntry> build() {
    final stored =
        ref.watch(sharedPreferencesProvider).getStringList(storageKey) ?? [];
    final entries = <SearchHistoryEntry>[];
    final seen = <WorkKey>{};
    for (final raw in stored) {
      try {
        final json = jsonDecode(raw);
        if (json is! Map<String, dynamic>) continue;
        final key = WorkKey.tryParse(
          json['key'] is String ? json['key'] as String : '',
        );
        final title = json['title'];
        if (key == null ||
            (key.kind != WorkKind.movie && key.kind != WorkKind.tv) ||
            title is! String ||
            title.trim().isEmpty ||
            !seen.add(key)) {
          continue;
        }
        entries.add(
          SearchHistoryEntry(
            key: key,
            title: title,
            year: json['year'] is int ? json['year'] as int : null,
            posterPath: json['poster_path'] is String
                ? json['poster_path'] as String
                : null,
          ),
        );
        if (entries.length == limit) break;
      } on FormatException {
        // A damaged preference must not prevent Discover from opening.
      }
    }
    return List.unmodifiable(entries);
  }

  Future<void> remember(SearchHistoryEntry entry) => _save(
    [
      entry,
      ...state.where((other) => other.key != entry.key),
    ].take(limit).toList(),
  );

  Future<void> remove(WorkKey key) =>
      _save(state.where((entry) => entry.key != key).toList());
  Future<void> clear() => _save([]);

  Future<void> _save(List<SearchHistoryEntry> entries) async {
    state = List.unmodifiable(entries);
    await ref
        .read(sharedPreferencesProvider)
        .setStringList(
          storageKey,
          entries.map((entry) => jsonEncode(entry.toJson())).toList(),
        );
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<SearchHistoryEntry>>(
      SearchHistoryNotifier.new,
    );
