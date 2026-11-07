import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// A stored response body and when it was received (UTC ms).
final class CachedResponse {
  const CachedResponse(this.body, this.storedAt);

  final String body;
  final int storedAt;
}

/// On-disk cache of TMDB responses (docs/client-architecture.md, "HTTP").
///
/// Our own rather than `dio_cache_interceptor`: that one extends `maxStale`
/// on every hit, so a card opened often would never refresh. Here the reader
/// decides the lifetime from [CachedResponse.storedAt], and a stale entry
/// stays around for when there is no network.
abstract interface class ResponseCache {
  Future<CachedResponse?> read(String key);
  Future<void> write(String key, CachedResponse response);
}

/// One file per key in the app's cache directory. The OS may wipe it, and
/// that is fine: everything is fetched again.
final class FileResponseCache implements ResponseCache {
  FileResponseCache(this.directory);

  final Directory directory;

  // The file name is a hash; the key itself is stored inside and checked on
  // read. Keys carry search queries, which can be long and contain anything.
  File _file(String key) =>
      File(p.join(directory.path, '${sha1.convert(utf8.encode(key))}.json'));

  @override
  Future<CachedResponse?> read(String key) async {
    try {
      final raw = await _file(key).readAsString();
      final input = (key, raw);
      return raw.length < 64 * 1024
          ? _decodeEnvelope(input)
          : await compute(
              _decodeEnvelope,
              input,
              debugLabel: 'cache JSON read',
            );
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedResponse response) async {
    final file = _file(key);
    Directory? staging;
    try {
      await directory.create(recursive: true);
      // Each writer owns its staging file, including across client instances
      // and isolates. Sharing a .tmp file can publish another writer mid-write.
      staging = await directory.createTemp('response-');
      final temp = File(p.join(staging.path, 'response.json'));
      final input = (key, response);
      final encoded = response.body.length < 64 * 1024
          ? _encodeEnvelope(input)
          : await compute(
              _encodeEnvelope,
              input,
              debugLabel: 'cache JSON write',
            );
      await temp.writeAsString(encoded, flush: true);
      // Rename is atomic: a crash mid-write never leaves half a file.
      await temp.rename(file.path);
    } on FileSystemException {
      // A cache is not data: if it wasn't written, the next read goes to the
      // network.
    } finally {
      try {
        await staging?.delete(recursive: true);
      } on FileSystemException {
        // The OS may have already evicted the staging directory.
      }
    }
  }

  /// Deletes entries older than [maxAge]: past the longest TTL nobody needs
  /// them, not even offline.
  Future<void> prune(Duration maxAge, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    try {
      await for (final entry in directory.list()) {
        // Yield between metadata reads: pruning shares the UI isolate.
        // ignore: avoid_slow_async_io
        if (entry is File && (await entry.lastModified()).isBefore(cutoff)) {
          await entry.delete();
        }
      }
    } on FileSystemException {
      // No directory yet, or the OS is clearing it: nothing to prune.
    }
  }
}

CachedResponse? _decodeEnvelope((String, String) input) {
  final envelope = jsonDecode(input.$2);
  if (envelope is! Map<String, Object?> || envelope['key'] != input.$1) {
    return null;
  }
  final body = envelope['body'];
  final storedAt = envelope['stored_at'];
  return body is String && storedAt is int
      ? CachedResponse(body, storedAt)
      : null;
}

String _encodeEnvelope((String, CachedResponse) input) => jsonEncode({
  'key': input.$1,
  'stored_at': input.$2.storedAt,
  'body': input.$2.body,
});

/// Overridden in `main()`: the cache directory is only known after an await.
final responseCacheProvider = Provider<ResponseCache>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);
