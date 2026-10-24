import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
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
      final envelope = jsonDecode(await _file(key).readAsString());
      if (envelope is! Map<String, Object?> || envelope['key'] != key) {
        return null;
      }
      final body = envelope['body'];
      final storedAt = envelope['stored_at'];
      if (body is! String || storedAt is! int) return null;
      return CachedResponse(body, storedAt);
    } on FileSystemException {
      return null;
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String key, CachedResponse response) async {
    final file = _file(key);
    final temp = File('${file.path}.tmp');
    try {
      await directory.create(recursive: true);
      await temp.writeAsString(
        jsonEncode({
          'key': key,
          'stored_at': response.storedAt,
          'body': response.body,
        }),
        flush: true,
      );
      // Rename is atomic: a crash mid-write never leaves half a file.
      await temp.rename(file.path);
    } on FileSystemException {
      // A cache is not data: if it wasn't written, the next read goes to the
      // network.
    }
  }

  /// Deletes entries older than [maxAge]: past the longest TTL nobody needs
  /// them, not even offline.
  Future<void> prune(Duration maxAge, {DateTime? now}) async {
    final cutoff = (now ?? DateTime.now()).subtract(maxAge);
    try {
      await for (final entry in directory.list()) {
        if (entry is File && entry.lastModifiedSync().isBefore(cutoff)) {
          await entry.delete();
        }
      }
    } on FileSystemException {
      // No directory yet, or the OS is clearing it: nothing to prune.
    }
  }
}

/// Overridden in `main()`: the cache directory is only known after an await.
final responseCacheProvider = Provider<ResponseCache>(
  (ref) => throw UnimplementedError('Overridden in main()'),
);
