import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/sync/sync_file.dart';

void main() {
  for (final table in [
    'works',
    'favorite_people',
    'rating_deletions',
    'watchlist_deletions',
    'watchlist_fences',
  ]) {
    test('rejects overflowing $table version timestamps', () {
      final raw = <String, Object?>{
        'format_version': 6,
        'purged_before': 0,
        for (final name in [
          'works',
          'ratings',
          'watchlist',
          'favorite_people',
          'rating_deletions',
          'watchlist_deletions',
          'watchlist_fences',
          'pair_comparisons',
        ])
          name: <Object>[],
      };
      raw[table] = [
        switch (table) {
          'works' => {
            'work_key': 'tmdb:movie:603',
            'kind': 'movie',
            'tmdb_id': 603,
            'title': 'Film',
            'snapshot_updated_at': 0x7fffffffffffffff,
          },
          'favorite_people' => {
            'person_id': 1,
            'name': 'Person',
            'updated_at': 0x7fffffffffffffff,
            'updated_by': 'a',
          },
          'watchlist_fences' => {
            'series_key': 'tmdb:tv:1',
            'season': true,
            'updated_at': 0x7fffffffffffffff,
            'updated_by': 'a',
          },
          _ => {
            'work_key': 'tmdb:movie:603',
            'tie_break': 'a' * 64,
            'updated_at': 0x7fffffffffffffff,
            'updated_by': 'a',
          },
        },
      ];
      expect(
        () => SyncFile.decode(gzip.encode(utf8.encode(jsonEncode(raw)))),
        throwsA(isA<SyncFileBroken>()),
      );
    });
  }

  for (final table in ['ratings', 'watchlist']) {
    final fields = table == 'ratings'
        ? ['created_at', 'scored_at', 'updated_at', 'deleted_at']
        : ['added_at', 'updated_at', 'deleted_at'];
    for (final field in fields) {
      test('rejects unrenderable $table.$field before import', () async {
        for (final timestamp in [
          -8640000000000001,
          8640000000000001,
          if (!['updated_at', 'deleted_at'].contains(field)) ...[
            -8640000000000000,
            8640000000000000,
          ],
          0x7fffffffffffffff,
        ]) {
          final raw = {
            'format_version': 1,
            'works': [
              {
                'work_key': 'tmdb:movie:603',
                'kind': 'movie',
                'tmdb_id': 603,
                'title': 'Film',
                'snapshot_updated_at': 1,
              },
            ],
            'ratings': <Object>[],
            'watchlist': <Object>[],
          };
          raw[table] = [
            {
              'work_key': 'tmdb:movie:603',
              if (table == 'ratings') ...{
                'score_half': 10,
                'created_at': 1,
                'scored_at': 1,
              } else
                'added_at': 1,
              'updated_at': 1,
              'updated_by': 'a',
              field: timestamp,
            },
          ];
          final bytes = gzip.encode(utf8.encode(jsonEncode(raw)));
          expect(() => SyncFile.decode(bytes), throwsA(isA<SyncFileBroken>()));
          await expectLater(
            SyncFile.decodeAsync(bytes),
            throwsA(isA<SyncFileBroken>()),
          );
        }
      });
    }
  }

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
