import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/drive_remote.dart';
import 'package:framebook/data/sync/sync_engine.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  Map<String, Object> file(String id) => {
    'id': id,
    'name': 'framebook.json.gz',
    'modifiedTime': '2026-01-02T03:04:05Z',
    'createdTime': '2026-01-01T00:00:00Z',
  };
  http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
    jsonEncode(body),
    status,
    headers: {'content-type': 'application/json'},
  );

  test(
    'list reads all pages from appDataFolder with stable metadata',
    () async {
      final requests = <http.Request>[];
      final remote = DriveRemote(
        MockClient((request) async {
          requests.add(request);
          expect(request.url.queryParameters['spaces'], 'appDataFolder');
          expect(request.url.queryParameters['pageSize'], '100');
          return jsonResponse(
            request.url.queryParameters['pageToken'] == null
                ? {
                    'files': [file('one')],
                    'nextPageToken': 'next',
                  }
                : {
                    'files': [file('two')],
                  },
          );
        }),
      );
      final files = await remote.list();
      expect(files.map((f) => f.id), ['one', 'two']);
      expect(files.first.name, 'framebook.json.gz');
      expect(files.first.modifiedTime, '2026-01-02T03:04:05.000Z');
      expect(files.first.createdTime, '2026-01-01T00:00:00.000Z');
      expect(requests.length, 2);
      expect(requests.last.url.queryParameters['pageToken'], 'next');
    },
  );

  test('an empty listing is valid', () async {
    final remote = DriveRemote(MockClient((_) async => jsonResponse({})));
    expect(await remote.list(), isEmpty);
  });

  test('metadata and delete address the requested file', () async {
    final methods = <String>[];
    final remote = DriveRemote(
      MockClient((request) async {
        methods.add(request.method);
        expect(request.url.path, '/drive/v3/files/selected');
        return request.method == 'DELETE'
            ? http.Response('', 204)
            : jsonResponse(file('selected'));
      }),
    );
    expect((await remote.metadata('selected')).id, 'selected');
    await remote.delete('selected');
    expect(methods, ['GET', 'DELETE']);
  });

  test('download returns binary media without JSON conversion', () async {
    final bytes = [0, 255, 31, 139, 8];
    final remote = DriveRemote(
      MockClient((request) async {
        expect(request.url.queryParameters['alt'], 'media');
        return http.Response.bytes(
          bytes,
          200,
          headers: {'content-type': 'application/gzip'},
        );
      }),
    );
    expect(await remote.download('selected'), bytes);
  });

  test(
    'download accepts the size boundary and rejects one extra byte',
    () async {
      for (final length in [4, 5]) {
        final remote = DriveRemote(
          MockClient(
            (_) async => http.Response.bytes(
              List.filled(length, 42),
              200,
              headers: {'content-type': 'application/gzip'},
            ),
          ),
          downloadLimit: 4,
        );
        if (length == 4) {
          expect(await remote.download('selected'), List.filled(4, 42));
        } else {
          await expectLater(
            remote.download('selected'),
            throwsA(
              isA<SyncException>().having(
                (e) => e.failure,
                'failure',
                SyncFailure.tooLarge,
              ),
            ),
          );
        }
      }
    },
  );

  for (final create in [true, false]) {
    test(
      '${create ? 'create' : 'update'} uploads gzip bytes with the correct target',
      () async {
        final remote = DriveRemote(
          MockClient((request) async {
            expect(request.method, create ? 'POST' : 'PATCH');
            expect(request.url.queryParameters['uploadType'], 'multipart');
            expect(
              request.url.path,
              create
                  ? '/upload/drive/v3/files'
                  : '/upload/drive/v3/files/selected',
            );
            final body = utf8.decode(request.bodyBytes);
            expect(body, contains('application/gzip'));
            expect(body, contains(base64Encode(utf8.encode('payload'))));
            if (create) {
              expect(body, contains('appDataFolder'));
              expect(body, contains('backup.gz'));
            }
            return jsonResponse(file('selected'));
          }),
        );
        final result = create
            ? await remote.create('backup.gz', utf8.encode('payload'))
            : await remote.update('selected', utf8.encode('payload'));
        expect(result.id, 'selected');
      },
    );
  }

  for (final example in [
    (401, 'authError', SyncFailure.unauthorized),
    (403, 'storageQuotaExceeded', SyncFailure.quotaExceeded),
    (403, 'insufficientPermissions', SyncFailure.unauthorized),
    (403, 'rateLimitExceeded', SyncFailure.failed),
    (404, 'notFound', SyncFailure.failed),
    (500, 'backendError', SyncFailure.failed),
  ]) {
    test(
      'HTTP ${example.$1} ${example.$2} maps to ${example.$3.name}',
      () async {
        final remote = DriveRemote(
          MockClient(
            (_) async => jsonResponse({
              'error': {
                'code': example.$1,
                'message': 'Rejected',
                'errors': [
                  {
                    'domain': 'global',
                    'reason': example.$2,
                    'message': 'Rejected',
                  },
                ],
              },
            }, example.$1),
          ),
        );
        await expectLater(
          remote.list(),
          throwsA(
            isA<SyncException>().having(
              (e) => e.failure,
              'failure',
              example.$3,
            ),
          ),
        );
      },
    );
  }

  for (final error in [
    const SocketException('offline'),
    http.ClientException('disconnected'),
  ]) {
    test('${error.runtimeType} maps to offline', () async {
      final remote = DriveRemote(MockClient((_) async => throw error));
      await expectLater(
        remote.list(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.failure,
            'failure',
            SyncFailure.offline,
          ),
        ),
      );
    });
  }

  test('a stalled Drive request times out as offline', () async {
    final client = MockClient((_) => Completer<http.Response>().future);
    final remote = DriveRemote(
      client,
      timeout: const Duration(milliseconds: 10),
    );

    await expectLater(
      remote.list(),
      throwsA(
        isA<SyncException>().having(
          (error) => error.failure,
          'failure',
          SyncFailure.offline,
        ),
      ),
    );
  });
}
