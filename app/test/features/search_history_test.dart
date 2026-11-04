import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/app/preferences.dart';
import 'package:framebook/data/work_key.dart';
import 'package:framebook/features/search/search_history.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test(
    'recent titles deduplicate by typed id, stay bounded and persist',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      ProviderContainer create() => ProviderContainer(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      );
      final container = create();
      final history = container.read(searchHistoryProvider.notifier);
      for (var i = 1; i <= 25; i++) {
        await history.remember(
          SearchHistoryEntry(key: WorkKey.movie(i), title: 'Title $i'),
        );
      }
      expect(container.read(searchHistoryProvider).length, 20);
      expect(
        container.read(searchHistoryProvider).last.key,
        const WorkKey.movie(6),
      );
      await history.remember(
        const SearchHistoryEntry(
          key: WorkKey.movie(10),
          title: 'Updated title',
          year: 2000,
          posterPath: '/poster.jpg',
        ),
      );
      expect(
        container.read(searchHistoryProvider).first.title,
        'Updated title',
      );
      expect(container.read(searchHistoryProvider).length, 20);
      await history.remember(
        const SearchHistoryEntry(
          key: WorkKey.tv(10),
          title: 'Same number, different type',
        ),
      );
      expect(container.read(searchHistoryProvider).take(2).map((e) => e.key), [
        const WorkKey.tv(10),
        const WorkKey.movie(10),
      ]);
      await history.remove(const WorkKey.movie(25));
      container.dispose();

      final restarted = create();
      addTearDown(restarted.dispose);
      final entries = restarted.read(searchHistoryProvider);
      expect(entries.first.key, const WorkKey.tv(10));
      expect(entries[1].title, 'Updated title');
      expect(entries[1].year, 2000);
      expect(entries[1].posterPath, '/poster.jpg');
      expect(
        entries.map((e) => e.key),
        isNot(contains(const WorkKey.movie(25))),
      );
      await restarted.read(searchHistoryProvider.notifier).clear();
      expect(prefs.getStringList(SearchHistoryNotifier.storageKey), isEmpty);
    },
  );

  test('damaged entries do not hide valid recent titles', () async {
    SharedPreferences.setMockInitialValues({
      SearchHistoryNotifier.storageKey: [
        'broken json',
        '[]',
        '{"key":123}',
        jsonEncode({'key': 'tmdb:tv:1:s1', 'title': 'Season'}),
        jsonEncode({'key': 'tmdb:movie:1', 'title': 'Film'}),
        jsonEncode({'key': 'tmdb:movie:1', 'title': 'Duplicate'}),
      ],
    });
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    expect(container.read(searchHistoryProvider).map((e) => e.title), ['Film']);
  });
}
