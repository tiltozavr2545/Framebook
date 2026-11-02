import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/sync_file.dart';

void main() {
  test('compressed and expanded size limits are checked independently', () {
    final bytes = gzip.encode(utf8.encode('x' * 10000));
    expect(
      () => SyncFile.decode(bytes, compressedLimit: 1),
      throwsA(isA<SyncFileTooLarge>()),
    );
    expect(
      () => SyncFile.decode(bytes, expandedLimit: 100),
      throwsA(isA<SyncFileTooLarge>()),
    );
  });
  test('bounded stream reading rejects excess chunks', () async {
    await expectLater(
      readSyncBytes(
        Stream.fromIterable([
          [1, 2],
          [3, 4],
        ]),
        limit: 3,
      ),
      throwsA(isA<SyncFileTooLarge>()),
    );
    expect(await readSyncBytes(Stream.value([1, 2]), limit: 2), [1, 2]);
  });
  test(
    '10,000 ratings with substantial notes fit the supported format',
    () async {
      final raw = {
        'format_version': 1,
        'works': [
          for (var id = 1; id <= 10000; id++)
            {
              'work_key': 'tmdb:movie:$id',
              'kind': 'movie',
              'tmdb_id': id,
              'title': 'Film $id',
              'snapshot_updated_at': 1,
            },
        ],
        'ratings': [
          for (var id = 1; id <= 10000; id++)
            {
              'work_key': 'tmdb:movie:$id',
              'score_half': 10,
              'note': 'n' * 1000,
              'created_at': 1,
              'scored_at': 1,
              'updated_at': 1,
              'updated_by': 'a',
            },
        ],
        'watchlist': <Object>[],
      };
      final bytes = gzip.encode(utf8.encode(jsonEncode(raw)));
      final state = await SyncFile.decodeAsync(bytes);
      expect(state.liveRatings, 10000);
      final encoded = await SyncFile.encodeAsync(
        state,
        writtenAt: 1,
        writtenBy: 'a',
        appVersion: 'test',
      );
      expect((await SyncFile.decodeAsync(encoded)).liveRatings, 10000);
    },
  );
}
