import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sources/providers.dart';
import 'package:framebook/data/sources/tmdb/tmdb_client.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/features/search/search_controller.dart';

class _SearchApi implements TmdbApi {
  final requests = <String, Completer<SearchPage>>{};

  @override
  Future<SearchPage> search(String query, {int page = 1}) =>
      requests.putIfAbsent(query, Completer<SearchPage>.new).future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('client changes restart the query and reject old answers', () async {
    final oldApi = _SearchApi(), newApi = _SearchApi();
    final container = ProviderContainer(
      overrides: [tmdbProvider.overrideWithValue(oldApi)],
    );
    addTearDown(container.dispose);
    final search = container.read(searchProvider.notifier);
    search.submit('matrix');
    container.updateOverrides([tmdbProvider.overrideWithValue(newApi)]);
    await pumpEventQueue();
    expect(newApi.requests.containsKey('matrix'), isTrue);
    oldApi.requests['matrix']!.complete(
      const SearchPage([], page: 9, pages: 9),
    );
    await pumpEventQueue();
    expect(container.read(searchProvider).page, 0);
    newApi.requests['matrix']!.complete(
      const SearchPage([], page: 1, pages: 1),
    );
    await pumpEventQueue();
    expect(container.read(searchProvider).query, 'matrix');
    expect(container.read(searchProvider).page, 1);
  });

  test(
    'typing a new query immediately invalidates the previous answer',
    () async {
      final api = _SearchApi();
      final container = ProviderContainer(
        overrides: [tmdbProvider.overrideWithValue(api)],
      );
      addTearDown(container.dispose);
      final search = container.read(searchProvider.notifier);
      search.submit('old');
      search.typed('new');
      search.typed('new ');
      api.requests['old']!.complete(const SearchPage([], page: 1, pages: 1));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(searchProvider).query, 'new');
      expect(container.read(searchProvider).loading, isTrue);
      await Future<void>.delayed(
        SearchNotifier.debounce + const Duration(milliseconds: 20),
      );
      api.requests['new']!.complete(const SearchPage([], page: 1, pages: 1));
      await Future<void>.delayed(Duration.zero);
      expect(container.read(searchProvider).query, 'new');
      expect(container.read(searchProvider).loading, isFalse);
    },
  );
}
