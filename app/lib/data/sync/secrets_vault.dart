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

final class SecretsVersion {
  const SecretsVersion(this.updatedAt, this.updatedBy);
  final int updatedAt;
  final String updatedBy;

  Map<String, Object> toJson() => {
    'updated_at': updatedAt,
    'updated_by': updatedBy,
  };

  factory SecretsVersion.fromJson(Object? json) {
    if (json is! Map ||
        json['updated_at'] is! int ||
        (json['updated_at'] as int) < 0 ||
        json['updated_by'] is! String ||
        (json['updated_by'] as String).isEmpty) {
      throw const FormatException('Invalid secrets version');
    }
    return SecretsVersion(
      json['updated_at'] as int,
      json['updated_by'] as String,
    );
  }
}

final class SecretsSnapshot {
  const SecretsSnapshot({
    required this.keys,
    this.keyVersions = const {},
    required this.divergenceSource,
    this.divergenceVersion,
    required this.updatedAt,
    required this.updatedBy,
  });
  final Map<String, SecretsKey> keys;
  final Map<String, SecretsVersion> keyVersions;
  final String? divergenceSource;
  final SecretsVersion? divergenceVersion;
  final int updatedAt;
  final String updatedBy;

  Map<String, Object?> toJson() => {
    'keys': {
      for (final e in keys.entries)
        e.key: {'value': e.value.value, 'verified': e.value.verified},
    },
    'key_versions': {
      for (final e in keyVersions.entries) e.key: e.value.toJson(),
    },
    'divergence_source': divergenceSource,
    'divergence_version': divergenceVersion?.toJson(),
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
    final global = SecretsVersion(
      json['updated_at'] as int,
      json['updated_by'] as String,
    );
    final versions = <String, SecretsVersion>{};
    final rawVersions = json['key_versions'];
    if (rawVersions == null) {
      // Legacy snapshots represented the whole map as one LWW value.
      for (final source in const {'tmdb', 'poiskkino', 'omdb'}) {
        versions[source] = global;
      }
    } else if (rawVersions is Map) {
      for (final e in rawVersions.entries) {
        if (e.key is! String ||
            !{'tmdb', 'poiskkino', 'omdb'}.contains(e.key)) {
          throw const FormatException('Invalid secrets key version');
        }
        versions[e.key as String] = SecretsVersion.fromJson(e.value);
      }
    } else {
      throw const FormatException('Invalid secrets key versions');
    }
    if (keys.keys.any((source) => !versions.containsKey(source))) {
      throw const FormatException('Missing secrets key version');
    }
    final sourceVersion = json.containsKey('divergence_version')
        ? (json['divergence_version'] == null
              ? null
              : SecretsVersion.fromJson(json['divergence_version']))
        : global;
    return SecretsSnapshot(
      keys: keys,
      keyVersions: versions,
      divergenceSource: json['divergence_source'] as String?,
      divergenceVersion: sourceVersion,
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
    final updatedAt = max(now, (old?.updatedAt ?? 0) + 1);
    final version = SecretsVersion(updatedAt, deviceId);
    final versions = Map<String, SecretsVersion>.of(
      old?.keyVersions ?? const {},
    );
    for (final source in const {'tmdb', 'poiskkino', 'omdb'}) {
      final before = old?.keys[source];
      final after = keys[source];
      final changed =
          before?.value != after?.value || before?.verified != after?.verified;
      if (changed && (old != null || after != null)) versions[source] = version;
    }
    final sourceChanged = old?.divergenceSource != divergenceSource;
    final snapshot = SecretsSnapshot(
      keys: Map.unmodifiable(keys),
      keyVersions: Map.unmodifiable(versions),
      divergenceSource: divergenceSource,
      divergenceVersion: sourceChanged ? version : old?.divergenceVersion,
      updatedAt: updatedAt,
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

  Map<String, Object> _params(List<int> salt, {int version = 2}) => {
    'version': version,
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
    if (raw['version'] is int && (raw['version'] as int) > 2) {
      throw const SecretsUnsupported();
    }
    if ((raw['version'] != 1 && raw['version'] != 2) ||
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
    return _params(salt, version: raw['version'] as int);
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

  bool _sameParams(Map<String, Object> a, Map<String, Object> b) {
    final left = Map<String, Object>.of(a)..remove('version');
    final right = Map<String, Object>.of(b)..remove('version');
    return jsonEncode(left) == jsonEncode(right);
  }

  int _compareVersion(SecretsVersion? a, SecretsVersion? b) {
    if (a == null) return b == null ? 0 : -1;
    if (b == null) return 1;
    final time = a.updatedAt.compareTo(b.updatedAt);
    return time != 0 ? time : a.updatedBy.compareTo(b.updatedBy);
  }

  SecretsSnapshot _merge(SecretsSnapshot a, SecretsSnapshot b) {
    final keys = <String, SecretsKey>{};
    final versions = <String, SecretsVersion>{};
    for (final source in const {'tmdb', 'poiskkino', 'omdb'}) {
      final comparison = _compareVersion(
        a.keyVersions[source],
        b.keyVersions[source],
      );
      var takeA = comparison > 0;
      if (comparison == 0) {
        String value(SecretsKey? key) =>
            key == null ? '' : '${key.value}\u0000${key.verified ? '1' : '0'}';
        takeA = value(a.keys[source]).compareTo(value(b.keys[source])) >= 0;
      }
      final selected = takeA ? a : b;
      final selectedVersion = selected.keyVersions[source];
      if (selectedVersion != null) versions[source] = selectedVersion;
      final key = selected.keys[source];
      if (key != null) keys[source] = key;
    }
    final sourceComparison = _compareVersion(
      a.divergenceVersion,
      b.divergenceVersion,
    );
    final sourceFromA =
        sourceComparison > 0 ||
        (sourceComparison == 0 &&
            (a.divergenceSource ?? '').compareTo(b.divergenceSource ?? '') >=
                0);
    final sourceSnapshot = sourceFromA ? a : b;
    final latest = _compare(a, b) >= 0 ? a : b;
    return SecretsSnapshot(
      keys: Map.unmodifiable(keys),
      keyVersions: Map.unmodifiable(versions),
      divergenceSource: sourceSnapshot.divergenceSource,
      divergenceVersion: sourceSnapshot.divergenceVersion,
      updatedAt: latest.updatedAt,
      updatedBy: latest.updatedBy,
    );
  }

  bool _sameSnapshot(SecretsSnapshot a, SecretsSnapshot b) =>
      jsonEncode(a.toJson()) == jsonEncode(b.toJson());

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
      winner = winner == null ? s : _merge(winner, s);
    }
    return _atomic(() async {
      final oldCache = await storage.read(_cacheKey);
      var sameIdentity = oldCache == null;
      if (oldCache != null) {
        final previous = jsonDecode(oldCache) as Map;
        sameIdentity = _sameParams(_parseParams(previous['params']), params!);
      }
      await _cache(params!, key!);
      final local = await _local();
      if (!sameIdentity || local == null) {
        await _put(winner!);
        return winner;
      }
      final merged = _merge(local, winner!);
      if (!_sameSnapshot(merged, local)) await _put(merged);
      return merged;
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
    final writeParams = _params(
      base64Decode(params['salt'] as String),
      version: 2,
    );
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
        winner = winner == null ? s : _merge(winner, s);
      }
      local = await _atomic(() async {
        final current = (await _local())!;
        if (winner != null) {
          final merged = _merge(current, winner);
          if (!_sameSnapshot(merged, current)) await _put(merged);
          return merged;
        }
        return current;
      });
      final bytes = await _encrypt(local, writeParams, key);
      if (files.isEmpty) {
        if (!createIfMissing && cache['pending'] != true) {
          throw const SecretsLocked();
        }
        await _cache(writeParams, key, pending: true);
        await remote.create(filename, bytes);
        await _cache(writeParams, key);
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
        await _cache(writeParams, key);
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
