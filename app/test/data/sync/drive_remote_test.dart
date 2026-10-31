import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/drive_remote.dart';
import 'package:framebook/data/sync/sync_engine.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
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
