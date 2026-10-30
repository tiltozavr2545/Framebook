import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:crypto/crypto.dart' as hashes;
import 'package:cryptography/cryptography.dart';

import '../api_keys.dart';
import 'sync_engine.dart';

class SecretsLocked implements Exception {
  const SecretsLocked();
}

class SecretsWrongPassword implements Exception {
  const SecretsWrongPassword();
}

class SecretsUnsupported implements Exception {
  const SecretsUnsupported();
}

class SecretsConflict implements Exception {
  const SecretsConflict();
}

final class SecretsKey {
  const SecretsKey(this.value, {required this.verified});
  final String value;
  final bool verified;
}

final class SecretsSnapshot {
  const SecretsSnapshot({
    required this.keys,
    required this.divergenceSource,
    required this.updatedAt,
    required this.updatedBy,
  });
  final Map<String, SecretsKey> keys;
  final String? divergenceSource;
  final int updatedAt;
  final String updatedBy;

  Map<String, Object?> toJson() => {
    'keys': {
      for (final e in keys.entries)
        e.key: {'value': e.value.value, 'verified': e.value.verified},
    },
    'divergence_source': divergenceSource,
    'updated_at': updatedAt,
    'updated_by': updatedBy,
  };
  factory SecretsSnapshot.fromJson(Object? json) {
    if (json is! Map ||
        json['keys'] is! Map ||
        json['updated_at'] is! int ||
        (json['updated_at'] as int) < 0 ||
        json['updated_by'] is! String ||
        (json['updated_by'] as String).isEmpty ||
        (json['divergence_source'] != null &&
            !{'kp', 'imdb'}.contains(json['divergence_source']))) {
      throw const FormatException('Invalid secrets snapshot');
    }
    final keys = <String, SecretsKey>{};
    for (final e in (json['keys'] as Map).entries) {
      final entry = e.value;
      if (e.key is! String ||
          !{'tmdb', 'poiskkino', 'omdb'}.contains(e.key) ||
          entry is! Map ||
          entry['value'] is! String ||
          (entry['value'] as String).isEmpty ||
          entry['verified'] is! bool) {
        throw const FormatException('Invalid secrets key');
      }
      keys[e.key as String] = SecretsKey(
        entry['value'] as String,
        verified: entry['verified'] as bool,
      );
    }
    return SecretsSnapshot(
      keys: keys,
      divergenceSource: json['divergence_source'] as String?,
      updatedAt: json['updated_at'] as int,
      updatedBy: json['updated_by'] as String,
    );
  }
}

/// Encrypted appDataFolder vault. Local metadata and key material stay in secure storage.
final class SecretsVault {
  SecretsVault({
    required this.remote,
    required this.storage,
    required this.accountId,
    required this.deviceId,
  });
  static const filename = 'framebook-secrets.json';
  final SyncRemote remote;
  final KeyStorage storage;
  final String accountId;
  final String deviceId;
  Map<String, Object?>? _pending;
  static final _queues = <String, Future<void>>{};
  static Future<T> _serialized<T>(String account, Future<T> Function() action) {
    final previous = _queues[account] ?? Future<void>.value();
    final result = previous.then((_) => action());
    _queues[account] = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace __) {},
    );
    return result;
  }

  Future<T> _atomic<T>(Future<T> Function() action) =>
      _serialized(accountId, action);
  static Future<void> saveLocal({
    required KeyStorage storage,
    required String accountId,
    required String deviceId,
    required Map<String, SecretsKey> keys,
    required String? divergenceSource,
  }) => _serialized(accountId, () async {
    final key =
        'secrets.${hashes.sha256.convert(utf8.encode(accountId))}.snapshot';
    final raw = await storage.read(key);
    final old = raw == null ? null : SecretsSnapshot.fromJson(jsonDecode(raw));
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final snapshot = SecretsSnapshot(
      keys: Map.unmodifiable(keys),
      divergenceSource: divergenceSource,
      updatedAt: max(now, (old?.updatedAt ?? 0) + 1),
      updatedBy: deviceId,
    );
    await storage.write(key, jsonEncode(snapshot.toJson()));
  });

  static Future<void> resetLocal({
    required KeyStorage storage,
    required String accountId,
  }) => _serialized(accountId, () async {
    final prefix = 'secrets.${hashes.sha256.convert(utf8.encode(accountId))}';
    await storage.delete('$prefix.key');
    await storage.delete('$prefix.snapshot');
  });

  String get _prefix =>
      'secrets.${hashes.sha256.convert(utf8.encode(accountId))}';
  String get _cacheKey => '$_prefix.key';
  String get _snapshotKey => '$_prefix.snapshot';
  Future<bool> get isUnlocked async => await storage.read(_cacheKey) != null;
  Future<SecretsSnapshot?> _local() async {
    final v = await storage.read(_snapshotKey);
    return v == null ? null : SecretsSnapshot.fromJson(jsonDecode(v));
  }

  Future<void> _put(SecretsSnapshot value) =>
      storage.write(_snapshotKey, jsonEncode(value.toJson()));
  List<int> _random(int n) {
    final r = Random.secure();
    return List.generate(n, (_) => r.nextInt(256));
  }

  Map<String, Object> _params(List<int> salt) => {
    'version': 1,
    'kdf': 'argon2id',
    'memory': 19456,
    'iterations': 2,
    'parallelism': 1,
    'salt': base64Encode(salt),
    'cipher': 'aes-256-gcm',
  };
  List<int> _aad(Map<String, Object> params) => utf8.encode(jsonEncode(params));
  Future<List<int>> _derive(String password, List<int> salt) => Isolate.run(
    () async =>
        (await Argon2id(
              memory: 19456,
              iterations: 2,
              parallelism: 1,
              hashLength: 32,
            ).deriveKey(
              secretKey: SecretKey(utf8.encode(password)),
              nonce: salt,
            ))
            .extractBytes(),
  );
  Map<String, Object> _parseParams(Object? raw) {
    if (raw is! Map) throw const FormatException('Invalid vault');
    if (raw['version'] is int && (raw['version'] as int) > 1) {
      throw const SecretsUnsupported();
    }
    if (raw['version'] != 1 ||
        raw['kdf'] != 'argon2id' ||
        raw['memory'] != 19456 ||
        raw['iterations'] != 2 ||
        raw['parallelism'] != 1 ||
        raw['cipher'] != 'aes-256-gcm' ||
        raw['salt'] is! String) {
      throw const FormatException('Invalid vault parameters');
    }
    final salt = base64Decode(raw['salt'] as String);
    if (salt.length != 16) throw const FormatException('Invalid vault salt');
    return _params(salt);
  }

  Map<String, Object?> _decode(List<int> bytes) {
    if (bytes.length > 1024 * 1024) {
      throw const FormatException('Vault too large');
    }
    final raw = jsonDecode(utf8.decode(bytes));
    if (raw is! Map ||
        raw['params'] is! Map ||
        raw['nonce'] is! String ||
        raw['ciphertext'] is! String ||
        raw['tag'] is! String) {
      throw const FormatException('Invalid vault');
    }
    final params = _parseParams(raw['params']);
    final nonce = base64Decode(raw['nonce'] as String),
        ciphertext = base64Decode(raw['ciphertext'] as String),
        tag = base64Decode(raw['tag'] as String);
    if (nonce.length != 12 || tag.length != 16) {
      throw const FormatException('Invalid vault');
    }
    return {
      'params': params,
      'nonce': nonce,
      'ciphertext': ciphertext,
      'tag': tag,
    };
  }

  Future<SecretsSnapshot> _decrypt(
    Map<String, Object?> envelope,
    List<int> key,
  ) async {
    try {
      final bytes = await AesGcm.with256bits().decrypt(
        SecretBox(
          envelope['ciphertext'] as List<int>,
          nonce: envelope['nonce'] as List<int>,
          mac: Mac(envelope['tag'] as List<int>),
        ),
        secretKey: SecretKey(key),
        aad: _aad(envelope['params'] as Map<String, Object>),
      );
      return SecretsSnapshot.fromJson(jsonDecode(utf8.decode(bytes)));
    } on SecretBoxAuthenticationError {
      throw const SecretsWrongPassword();
    }
  }

  Future<List<int>> _encrypt(
    SecretsSnapshot snapshot,
    Map<String, Object> params,
    List<int> key,
  ) async {
    final box = await AesGcm.with256bits().encrypt(
      utf8.encode(jsonEncode(snapshot.toJson())),
      secretKey: SecretKey(key),
      nonce: _random(12),
      aad: _aad(params),
    );
    return utf8.encode(
      jsonEncode({
        'params': params,
        'nonce': base64Encode(box.nonce),
        'ciphertext': base64Encode(box.cipherText),
        'tag': base64Encode(box.mac.bytes),
      }),
    );
  }

  Future<List<RemoteFile>> _files() async =>
      (await remote.list()).where((f) => f.name == filename).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
  Future<void> _cache(
    Map<String, Object> params,
    List<int> key, {
    bool pending = false,
  }) => storage.write(
    _cacheKey,
    jsonEncode({
      'params': params,
      'key': base64Encode(key),
      'pending': pending,
    }),
  );
  Future<Map<String, Object?>> _cached() async {
    final s = await storage.read(_cacheKey);
    if (s == null) throw const SecretsLocked();
    final v = jsonDecode(s) as Map;
    final p = _parseParams(v['params']);
    final k = base64Decode(v['key'] as String);
    if (k.length != 32) throw const SecretsLocked();
    return {'params': p, 'key': k, 'pending': v['pending'] == true};
  }

  bool _sameParams(Map<String, Object> a, Map<String, Object> b) =>
      jsonEncode(a) == jsonEncode(b);
  int _compare(SecretsSnapshot a, SecretsSnapshot b) {
    final n = a.updatedAt.compareTo(b.updatedAt);
    if (n != 0) return n;
    final device = a.updatedBy.compareTo(b.updatedBy);
    if (device != 0) return device;
    String canonical(SecretsSnapshot s) => jsonEncode({
      'keys': {
        for (final k in s.keys.keys.toList()..sort())
          k: {'value': s.keys[k]!.value, 'verified': s.keys[k]!.verified},
      },
      'divergence_source': s.divergenceSource,
    });
    return canonical(a).compareTo(canonical(b));
  }

  Future<SecretsSnapshot?> unlock(String password) async {
    final files = await _files();
    if (files.isEmpty) {
      if (password.length < 8) {
        throw ArgumentError('Password must have at least 8 characters');
      }
      final params = _params(_random(16));
      _pending = {
        'params': params,
        'key': await _derive(password, base64Decode(params['salt'] as String)),
      };
      return null;
    }
    SecretsSnapshot? winner;
    Map<String, Object>? params;
    List<int>? key;
    for (final file in files) {
      final env = _decode(await remote.download(file.id));
      final p = env['params'] as Map<String, Object>;
      if (params != null && !_sameParams(params, p)) {
        throw const SecretsConflict();
      }
      params = p;
      key ??= await _derive(password, base64Decode(p['salt'] as String));
      final s = await _decrypt(env, key);
      if (winner == null || _compare(s, winner) > 0) winner = s;
    }
    return _atomic(() async {
      final oldCache = await storage.read(_cacheKey);
      var sameIdentity = false;
      if (oldCache != null) {
        final previous = jsonDecode(oldCache) as Map;
        sameIdentity = _sameParams(_parseParams(previous['params']), params!);
      }
      await _cache(params!, key!);
      final local = await _local();
      if (!sameIdentity || local == null || _compare(winner!, local) > 0) {
        await _put(winner!);
        return winner;
      }
      return local;
    });
  }

  Future<void> save(Map<String, SecretsKey> keys, String? divergenceSource) =>
      saveLocal(
        storage: storage,
        accountId: accountId,
        deviceId: deviceId,
        keys: keys,
        divergenceSource: divergenceSource,
      );

  Future<SecretsSnapshot> sync({bool createIfMissing = false}) async {
    final cache = createIfMissing && _pending != null
        ? _pending!
        : await _cached();
    final params = cache['params'] as Map<String, Object>;
    final key = cache['key'] as List<int>;
    for (var attempt = 0; attempt < 5; attempt++) {
      var local = await _local();
      if (local == null) throw const SecretsLocked();
      final files = await _files();
      SecretsSnapshot? winner;
      for (final file in files) {
        final env = _decode(await remote.download(file.id));
        if (!_sameParams(params, env['params'] as Map<String, Object>)) {
          throw const SecretsLocked();
        }
        final s = await _decrypt(env, key);
        if (winner == null || _compare(s, winner) > 0) winner = s;
      }
      local = await _atomic(() async {
        final current = (await _local())!;
        if (winner != null && _compare(winner, current) > 0) {
          await _put(winner);
          return winner;
        }
        return current;
      });
      final bytes = await _encrypt(local, params, key);
      if (files.isEmpty) {
        if (!createIfMissing && cache['pending'] != true) {
          throw const SecretsLocked();
        }
        await _cache(params, key, pending: true);
        await remote.create(filename, bytes);
        await _cache(params, key);
        _pending = null;
      } else {
        for (final f in files) {
          if ((await remote.metadata(f.id)).modifiedTime != f.modifiedTime) {
            winner = null;
            break;
          }
        }
        if (winner == null) continue;
        await remote.update(files.first.id, bytes);
        for (final extra in files.skip(1)) {
          if ((await remote.metadata(extra.id)).modifiedTime !=
              extra.modifiedTime) {
            throw const SecretsConflict();
          }
          await remote.delete(extra.id);
        }
      }
      final latest = await _local();
      if (latest != null && _compare(latest, local) > 0) continue;
      final after = await _files();
      if (after.length != 1) continue;
      return latest ?? local;
    }
    throw const SecretsConflict();
  }

  Future<void> overwrite(String password) async {
    if (password.length < 8) {
      throw ArgumentError('Password must have at least 8 characters');
    }
    final local = await _local();
    if (local == null) throw const SecretsLocked();
    final params = _params(_random(16));
    final key = await _derive(password, base64Decode(params['salt'] as String));
    final files = await _files();
    final bytes = await _encrypt(local, params, key);
    if (files.isEmpty) {
      await remote.create(filename, bytes);
    } else {
      for (final f in files) {
        await remote.update(f.id, bytes);
      }
    }
    await _cache(params, key);
  }

  Future<void> reset() async {
    _pending = null;
    await storage.delete(_cacheKey);
    await storage.delete(_snapshotKey);
  }
}
