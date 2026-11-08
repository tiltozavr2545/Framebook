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
  Future<void> _writes = Future.value();
  List<SearchHistoryEntry> _persisted = const [];
  int _revision = 0;

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
    return _persisted = List.unmodifiable(entries);
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

  Future<void> _save(List<SearchHistoryEntry> entries) {
    final next = List<SearchHistoryEntry>.unmodifiable(entries);
    final revision = ++_revision;
    final prefs = ref.read(sharedPreferencesProvider);
    state = next;
    return _writes = _writes.then((_) async {
      try {
        final saved = await prefs.setStringList(
          storageKey,
          next.map((entry) => jsonEncode(entry.toJson())).toList(),
        );
        if (!saved) throw StateError('Could not save search history');
        _persisted = next;
      } on Object {
        // Recent-title metadata must not interrupt opening a title. Roll back
        // only the latest draft; newer queued user actions remain authoritative.
        if (ref.mounted && revision == _revision) state = _persisted;
      }
    });
  }
}

final searchHistoryProvider =
    NotifierProvider<SearchHistoryNotifier, List<SearchHistoryEntry>>(
      SearchHistoryNotifier.new,
    );
