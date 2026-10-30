import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/api_source.dart';

import '../support/memory_key_storage.dart';

class PausingStorage implements KeyStorage {
  final values = <String, String>{};
  final started = Completer<void>();
  final proceed = Completer<void>();
  bool pause = false;
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<void> write(String key, String value) async {
    if (pause) {
      pause = false;
      started.complete();
      await proceed.future;
    }
    values[key] = value;
  }
}

void main() {
  test('cancelled remote replacement rolls back storage and state', () async {
    final storage = PausingStorage();
    final store = ApiKeyStore(storage);
    await store.save(ApiSource.tmdb, const StoredKey('old', verified: true));
    final initial = await store.load();
    final container = ProviderContainer(
      overrides: [
        apiKeyStoreProvider.overrideWithValue(store),
        initialApiKeysProvider.overrideWithValue(initial),
      ],
    );
    addTearDown(container.dispose);
    var current = true;
    storage.pause = true;
    final update = container.read(apiKeysProvider.notifier).replaceRemote({
      ApiSource.tmdb: const StoredKey('new', verified: false),
      ApiSource.omdb: const StoredKey('other', verified: true),
    }, stillValid: () => current);
    await storage.started.future;
    current = false;
    storage.proceed.complete();
    await update;
    expect(container.read(apiKeysProvider)[ApiSource.tmdb]!.value, 'old');
    final loaded = await store.load();
    expect(loaded[ApiSource.tmdb]!.value, 'old');
    expect(loaded[ApiSource.tmdb]!.verified, isTrue);
    expect(loaded.has(ApiSource.omdb), isFalse);
  });

  test('saves, loads and removes keys with their verified flag', () async {
    final storage = MemoryKeyStorage();
    final store = ApiKeyStore(storage);

    expect((await store.load()).has(ApiSource.tmdb), isFalse);

    await store.save(ApiSource.tmdb, const StoredKey('eyJ', verified: true));
    await store.save(ApiSource.omdb, const StoredKey('abc', verified: false));

    final loaded = await ApiKeyStore(storage).load();
    expect(loaded[ApiSource.tmdb]?.value, 'eyJ');
    expect(loaded[ApiSource.tmdb]?.verified, isTrue);
    expect(loaded[ApiSource.omdb]?.verified, isFalse);
    expect(loaded.has(ApiSource.poiskkino), isFalse);

    await store.remove(ApiSource.tmdb);
    expect((await store.load()).has(ApiSource.tmdb), isFalse);
    expect(storage.values.keys, everyElement(startsWith('api_key.omdb')));
  });
}
