import 'dart:io';

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
