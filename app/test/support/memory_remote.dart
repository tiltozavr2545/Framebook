import 'package:framebook/data/sync/sync_engine.dart';

/// Google Drive's `appDataFolder` in memory: every write bumps a counter
/// that plays `modifiedTime`.
class MemoryRemote implements SyncRemote {
  final Map<String, ({String name, List<int> bytes, int modified, int created})>
  files = {};
  var _clock = 0;
  var _ids = 0;

  /// Runs right after each download: lets a test write the file "from
  /// another device" between download and upload.
  void Function(String id)? afterDownload;

  /// Set to make every call fail, e.g. with [SyncFailure.offline].
  SyncFailure? failing;

  List<String> get names => [for (final f in files.values) f.name]..sort();

  RemoteFile _file(String id) {
    final f = files[id]!;
    return RemoteFile(
      id: id,
      name: f.name,
      modifiedTime: '${f.modified}',
      createdTime: '${f.created}'.padLeft(8, '0'),
    );
  }

  void _check() {
    if (failing case final failure?) throw SyncException(failure);
  }

  /// Writes a file directly, as another device would.
  RemoteFile put(String name, List<int> bytes, {String? id}) {
    final key = id ?? 'f${_ids++}';
    final old = files[key];
    files[key] = (
      name: name,
      bytes: bytes,
      modified: ++_clock,
      created: old?.created ?? _clock,
    );
    return _file(key);
  }

  @override
  Future<List<RemoteFile>> list() async {
    _check();
    return [for (final id in files.keys) _file(id)];
  }

  @override
  Future<RemoteFile> metadata(String id) async {
    _check();
    return _file(id);
  }

  @override
  Future<List<int>> download(String id) async {
    _check();
    final bytes = files[id]!.bytes;
    afterDownload?.call(id);
    return bytes;
  }

  @override
  Future<RemoteFile> create(String name, List<int> bytes) async {
    _check();
    return put(name, bytes);
  }

  @override
  Future<RemoteFile> update(String id, List<int> bytes) async {
    _check();
    return put(files[id]!.name, bytes, id: id);
  }

  @override
  Future<void> delete(String id) async {
    _check();
    files.remove(id);
  }
}
