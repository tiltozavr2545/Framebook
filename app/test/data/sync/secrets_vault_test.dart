import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/api_keys.dart';
import 'package:framebook/data/sync/secrets_vault.dart';
import 'package:framebook/data/sync/sync_engine.dart';

class MemoryStorage implements KeyStorage {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }
}

class MemoryRemote implements SyncRemote {
  final values = <String, List<int>>{};
  Future<void> Function()? onDownload;
  Future<void> Function()? onUpdate;
  bool failCreate = false;
  int revision = 0;
  final revisions = <String, int>{};
  RemoteFile file(String id) => RemoteFile(
    id: id,
    name: SecretsVault.filename,
    modifiedTime: '${revisions[id] ?? 0}',
    createdTime: '0',
  );
  @override
  Future<List<RemoteFile>> list() async => [
    for (final id in values.keys) file(id),
  ];
  @override
  Future<RemoteFile> metadata(String id) async => file(id);
  @override
  Future<List<int>> download(String id) async {
    final callback = onDownload;
    onDownload = null;
    if (callback != null) await callback();
    return values[id]!;
  }

  @override
  Future<RemoteFile> create(String name, List<int> bytes) async {
    if (failCreate) throw const SyncException(SyncFailure.offline, 'offline');
    values['1'] = bytes;
    revision++;
    revisions['1'] = revision;
    return file('1');
  }

  @override
  Future<RemoteFile> update(String id, List<int> bytes) async {
    final callback = onUpdate;
    onUpdate = null;
    if (callback != null) await callback();
    values[id] = bytes;
    revision++;
    revisions[id] = revision;
    return file(id);
  }

  @override
  Future<void> delete(String id) async {
    values.remove(id);
  }
}

void main() {
  test(
    'vault roundtrip, deletion, authentication and explicit creation',
    () async {
      final remote = MemoryRemote();
      final storageA = MemoryStorage();
      final a = SecretsVault(
        remote: remote,
        storage: storageA,
        accountId: 'a',
        deviceId: 'a',
      );
      expect(await a.unlock('password'), isNull);
      await a.save({
        'tmdb': const SecretsKey('private api key', verified: true),
      }, 'kp');
      await expectLater(a.sync(), throwsA(isA<SecretsLocked>()));
      remote.failCreate = true;
      await expectLater(
        a.sync(createIfMissing: true),
        throwsA(isA<SyncException>()),
      );
      remote.failCreate = false;
      final restarted = SecretsVault(
        remote: remote,
        storage: storageA,
        accountId: 'a',
        deviceId: 'a',
      );
      await restarted.sync();
      expect(
        utf8.decode(remote.values['1']!),
        isNot(contains('private api key')),
      );
      final b = SecretsVault(
        remote: remote,
        storage: MemoryStorage(),
        accountId: 'a',
        deviceId: 'b',
      );
      await expectLater(
        b.unlock('wrong'),
        throwsA(isA<SecretsWrongPassword>()),
      );
      expect(
        (await b.unlock('password'))!.keys['tmdb']!.value,
        'private api key',
      );
      await a.save({}, null);
      await a.sync();
      expect((await b.sync()).keys, isEmpty);
      await a.save({
        'tmdb': const SecretsKey('stale secret', verified: true),
      }, 'kp');
      await b.save({
        'omdb': const SecretsKey('replacement', verified: true),
      }, 'imdb');
      await b.overwrite('new password');
      await expectLater(a.sync(), throwsA(isA<SecretsLocked>()));
      final restored = await a.unlock('new password');
      expect(restored!.keys.containsKey('tmdb'), isFalse);
      expect(restored.keys['omdb']!.value, 'replacement');
      await a.sync();
      expect((await b.sync()).keys.containsKey('tmdb'), isFalse);
      remote.onDownload = () => a.save({
        'omdb': const SecretsKey('during read', verified: true),
      }, 'imdb');
      expect((await a.sync()).keys['omdb']!.value, 'during read');
      remote.onUpdate = () => a.save({
        'omdb': const SecretsKey('during write', verified: true),
      }, 'imdb');
      expect((await a.sync()).keys['omdb']!.value, 'during write');
      expect((await b.sync()).keys['omdb']!.value, 'during write');
      final original = List<int>.of(remote.values['1']!);
      final nonceBefore =
          (jsonDecode(utf8.decode(original)) as Map<String, dynamic>)['nonce'];
      await a.sync();
      final nonceAfter =
          (jsonDecode(utf8.decode(remote.values['1']!))
              as Map<String, dynamic>)['nonce'];
      expect(nonceBefore, isNot(nonceAfter));
      remote.values['2'] = List.of(remote.values['1']!);
      await a.sync();
      expect(remote.values.length, 1);
      final valid = List<int>.of(remote.values['1']!);
      final future = jsonDecode(utf8.decode(valid)) as Map<String, dynamic>;
      (future['params'] as Map<String, dynamic>)['version'] = 2;
      remote.values['1'] = utf8.encode(jsonEncode(future));
      await expectLater(a.sync(), throwsA(isA<SecretsUnsupported>()));
      remote.values['1'] = valid;
      final changedSalt =
          jsonDecode(utf8.decode(valid)) as Map<String, dynamic>;
      (changedSalt['params'] as Map<String, dynamic>)['salt'] = base64Encode(
        List.filled(16, 3),
      );
      remote.values['2'] = utf8.encode(jsonEncode(changedSalt));
      await expectLater(a.sync(), throwsA(isA<SecretsLocked>()));
      expect(remote.values.length, 2);
      remote.values.remove('2');
      final json =
          jsonDecode(utf8.decode(remote.values['1']!)) as Map<String, dynamic>;
      final tag = base64Decode(json['tag'] as String);
      tag[0] ^= 1;
      json['tag'] = base64Encode(tag);
      remote.values['1'] = utf8.encode(jsonEncode(json));
      await expectLater(b.sync(), throwsA(isA<SecretsWrongPassword>()));
    },
  );
}
