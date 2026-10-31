import 'dart:async';
import 'dart:io' show SocketException;

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart'
    show AccessDeniedException;
import 'package:http/http.dart' as http;

import 'sync_engine.dart';

/// [SyncRemote] on Google Drive's `appDataFolder` (docs/sync.md): a hidden
/// folder only this app sees, through the `drive.appdata` scope.
final class DriveRemote implements SyncRemote {
  DriveRemote(
    http.Client client, {
    Duration timeout = const Duration(seconds: 30),
  }) : _api = drive.DriveApi(client),
       _timeout = timeout;

  final drive.DriveApi _api;
  final Duration _timeout;

  static const _space = 'appDataFolder';
  static const _fields = 'id,name,modifiedTime,createdTime';
  static const _type = 'application/gzip';

  @override
  Future<List<RemoteFile>> list() => _call(() async {
    final files = <RemoteFile>[];
    String? page;
    do {
      final result = await _api.files.list(
        spaces: _space,
        pageSize: 100,
        pageToken: page,
        $fields: 'nextPageToken,files($_fields)',
      );
      files.addAll([
        for (final f in result.files ?? const <drive.File>[]) _file(f),
      ]);
      page = result.nextPageToken;
    } while (page != null);
    return files;
  });

  @override
  Future<RemoteFile> metadata(String id) => _call(
    () async => _file(await _api.files.get(id, $fields: _fields) as drive.File),
  );

  @override
  Future<List<int>> download(String id) => _call(() async {
    final media =
        await _api.files.get(
              id,
              downloadOptions: drive.DownloadOptions.fullMedia,
            )
            as drive.Media;
    final bytes = <int>[];
    await media.stream.forEach(bytes.addAll);
    return bytes;
  });

  @override
  Future<RemoteFile> create(String name, List<int> bytes) => _call(
    () async => _file(
      await _api.files.create(
        drive.File(name: name, parents: const [_space]),
        uploadMedia: _media(bytes),
        $fields: _fields,
      ),
    ),
  );

  @override
  Future<RemoteFile> update(String id, List<int> bytes) => _call(
    () async => _file(
      await _api.files.update(
        drive.File(),
        id,
        uploadMedia: _media(bytes),
        $fields: _fields,
      ),
    ),
  );

  @override
  Future<void> delete(String id) => _call(() => _api.files.delete(id));

  static drive.Media _media(List<int> bytes) =>
      drive.Media(Stream.value(bytes), bytes.length, contentType: _type);

  static RemoteFile _file(drive.File f) => RemoteFile(
    id: f.id!,
    name: f.name ?? '',
    modifiedTime: f.modifiedTime?.toUtc().toIso8601String() ?? '',
    createdTime: f.createdTime?.toUtc().toIso8601String() ?? '',
  );

  /// Drive's errors as [SyncException]s (docs/sync.md, "Errors").
  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request().timeout(_timeout);
    } on drive.DetailedApiRequestError catch (e) {
      final reasons = {for (final error in e.errors) error.reason};
      throw SyncException(switch (e.status) {
        401 => SyncFailure.unauthorized,
        403 when reasons.contains('storageQuotaExceeded') =>
          SyncFailure.quotaExceeded,
        403 when reasons.contains('insufficientPermissions') =>
          SyncFailure.unauthorized,
        _ => SyncFailure.failed,
      }, 'HTTP ${e.status} ${reasons.join(',')}');
    } on AccessDeniedException catch (e) {
      throw SyncException(SyncFailure.unauthorized, e.message);
    } on drive.ApiRequestError catch (e) {
      throw SyncException(SyncFailure.failed, e.message);
    } on SocketException catch (e) {
      throw SyncException(SyncFailure.offline, e.message);
    } on http.ClientException catch (e) {
      throw SyncException(SyncFailure.offline, e.message);
    } on TimeoutException {
      throw const SyncException(SyncFailure.offline, 'timeout');
    }
  }
}
