import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_source.dart';

/// A user's key for one API. `verified == false` means it was saved unchecked
/// because there was no connection (docs/external-sources.md, "Key checks").
final class StoredKey {
  const StoredKey(this.value, {required this.verified});

  final String value;
  final bool verified;
}

/// All of the user's keys. An immutable snapshot: changes go through
/// [ApiKeysNotifier].
final class ApiKeys {
  const ApiKeys(this._keys);

  static const empty = ApiKeys({});

  final Map<ApiSource, StoredKey> _keys;

  StoredKey? operator [](ApiSource source) => _keys[source];

  bool has(ApiSource source) => _keys.containsKey(source);

  ApiKeys withKey(ApiSource source, StoredKey key) =>
      ApiKeys({..._keys, source: key});

  ApiKeys without(ApiSource source) => ApiKeys({..._keys}..remove(source));
}

/// Where the keys physically live: the OS secure storage in the app, memory in
/// tests.
abstract interface class KeyStorage {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

final class SecureKeyStorage implements KeyStorage {
  SecureKeyStorage([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Reads and writes keys. Keys never reach SQLite or the sync file (AGENTS.md,
/// invariants).
final class ApiKeyStore {
  ApiKeyStore(this._storage);

  final KeyStorage _storage;

  static String _valueKey(ApiSource source) => 'api_key.${source.name}';
  static String _verifiedKey(ApiSource source) =>
      'api_key.${source.name}.verified';

  Future<ApiKeys> load() async {
    var keys = ApiKeys.empty;
    for (final source in ApiSource.values) {
      final value = await _storage.read(_valueKey(source));
      if (value == null || value.isEmpty) continue;
      final verified = await _storage.read(_verifiedKey(source)) == 'true';
      keys = keys.withKey(source, StoredKey(value, verified: verified));
    }
    return keys;
  }

  Future<void> save(ApiSource source, StoredKey key) async {
    await _storage.write(_valueKey(source), key.value);
    await _storage.write(_verifiedKey(source), key.verified.toString());
  }

  Future<void> remove(ApiSource source) async {
    await _storage.delete(_valueKey(source));
    await _storage.delete(_verifiedKey(source));
  }
}

final apiKeyStoreProvider = Provider<ApiKeyStore>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

/// Keys read before `runApp`: the router must know synchronously whether there
/// is a TMDB key, so as not to flash the main screen before onboarding.
final initialApiKeysProvider = Provider<ApiKeys>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);

class ApiKeysNotifier extends Notifier<ApiKeys> {
  @override
  ApiKeys build() => ref.watch(initialApiKeysProvider);

  Future<void> _queue = Future.value();
  Future<void> _serialize(Future<void> Function() action) {
    final result = _queue.then((_) => action());
    _queue = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> save(ApiSource source, StoredKey key) => _serialize(() async {
    await ref.read(apiKeyStoreProvider).save(source, key);
    state = state.withKey(source, key);
  });

  Future<void> remove(ApiSource source) => _serialize(() async {
    await ref.read(apiKeyStoreProvider).remove(source);
    state = state.without(source);
  });

  Future<void> replaceRemote(
    Map<ApiSource, StoredKey> keys, {
    bool Function()? stillValid,
  }) => _serialize(() async {
    if (stillValid != null && !stillValid()) return;
    final store = ref.read(apiKeyStoreProvider);
    final previous = state;
    Future<void> apply(ApiKeys values) async {
      for (final source in ApiSource.values) {
        final key = values[source];
        if (key == null) {
          await store.remove(source);
        } else {
          await store.save(source, key);
        }
      }
    }

    try {
      final next = ApiKeys(Map.unmodifiable(keys));
      await apply(next);
      if (stillValid != null && !stillValid()) {
        await apply(previous);
        return;
      }
      state = next;
    } catch (_) {
      await apply(previous);
      rethrow;
    }
  });
}

final apiKeysProvider = NotifierProvider<ApiKeysNotifier, ApiKeys>(
  ApiKeysNotifier.new,
);
