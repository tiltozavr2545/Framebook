import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/api_source.dart';

import '../support/memory_key_storage.dart';

void main() {
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
