import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/response_cache.dart';

void main() {
  late Directory dir;
  late FileResponseCache cache;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('framebook_cache_test');
    cache = FileResponseCache(Directory('${dir.path}/http'));
  });

  tearDown(() => dir.delete(recursive: true));

  test('reads back what was written, including long odd keys', () async {
    final key = 'tmdb:/search/multi?query=${'Матрица / ? & ' * 40}';
    await cache.write(key, const CachedResponse('{"a":1}', 42));
    final read = await cache.read(key);
    expect(read!.body, '{"a":1}');
    expect(read.storedAt, 42);
  });

  test('a miss, a missing directory and a broken file are all null', () async {
    expect(await cache.read('nothing'), isNull);
    await cache.write('k', const CachedResponse('{}', 1));
    for (final f in Directory('${dir.path}/http').listSync()) {
      (f as File).writeAsStringSync('not json');
    }
    expect(await cache.read('k'), isNull);
  });

  test('valid JSON with a wrong envelope is ignored', () async {
    await cache.write('k', const CachedResponse('{}', 1));
    final file = (await cache.directory.list().single) as File;
    for (final envelope in [
      [],
      {'key': 'different', 'body': '{}', 'stored_at': 1},
      {'key': 'k', 'body': 42, 'stored_at': 1},
      {'key': 'k', 'body': '{}', 'stored_at': 'yesterday'},
      {'key': 'k'},
    ]) {
      await file.writeAsString(jsonEncode(envelope));
      expect(await cache.read('k'), isNull, reason: '$envelope');
    }
  });

  test(
    'prune uses file age and preserves entries exactly at the cutoff',
    () async {
      await cache.write('old', const CachedResponse('{}', 1));
      final oldFile = (await cache.directory.list().single) as File;
      await cache.write('boundary', const CachedResponse('{}', 1));
      final boundaryFile = (await cache.directory.list().toList())
          .whereType<File>()
          .singleWhere((f) => f.path != oldFile.path);
      final now = DateTime.utc(2026, 11, 4);
      final cutoff = now.subtract(const Duration(days: 30));
      await oldFile.setLastModified(
        cutoff.subtract(const Duration(seconds: 1)),
      );
      await boundaryFile.setLastModified(cutoff);
      await cache.prune(const Duration(days: 30), now: now);
      expect(await cache.read('old'), isNull);
      expect((await cache.read('boundary'))?.body, '{}');
    },
  );

  test(
    'an unavailable cache directory does not break a card request',
    () async {
      final blocker = File('${dir.path}/blocker');
      await blocker.writeAsString('not a directory');
      final unavailable = FileResponseCache(Directory(blocker.path));
      await unavailable.write('k', const CachedResponse('{}', 1));
      expect(await unavailable.read('k'), isNull);
      await unavailable.prune(const Duration(days: 30));
      expect(await blocker.readAsString(), 'not a directory');
    },
  );

  test('prune removes entries older than the limit', () async {
    await cache.write('old', const CachedResponse('{}', 1));
    await cache.prune(
      const Duration(days: 30),
      now: DateTime.now().add(const Duration(days: 31)),
    );
    expect(await cache.read('old'), isNull);
    await cache.prune(const Duration(days: 30));
  });
}
