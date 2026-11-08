import 'dart:convert';
import 'dart:io' show gzip;
import 'dart:math';

import 'package:drift/drift.dart' show Value, driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/library.dart';
import 'package:framebook/data/library/work_snapshot.dart';
import 'package:framebook/data/library/pair_calibration.dart';
import 'package:framebook/data/library/pair_calibration_store.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';
import 'package:framebook/data/sync/sync_engine.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/work_key.dart';

import 'insights_test.dart' show rated;
import 'pair_calibration_test.dart' show evidence;
import '../support/memory_remote.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late Library library;
  late PairCalibrationStore store;
  var now = DateTime(2026, 11, 7, 12);
  Future<CalibrationPair> pair(int a, int b) async {
    final rows = await library.watchRatings().first;
    return CalibrationPair(
      rows.firstWhere((r) => r.key == WorkKey.movie(a)),
      rows.firstWhere((r) => r.key == WorkKey.movie(b)),
    );
  }

  setUp(() async {
    now = DateTime(2026, 11, 7, 12);
    db = AppDatabase(NativeDatabase.memory());
    library = Library(db, deviceId: 'a', clock: () => now);
    store = PairCalibrationStore(db, library, clock: () => now);
    for (var id = 1; id <= 12; id++) {
      await library.rate(
        [WorkSnapshot(key: WorkKey.movie(id), tmdbId: id, title: 'Film $id')],
        scoreHalf: 16,
        note: 'Note $id',
      );
    }
  });
  tearDown(() => db.close());

  for (final preference in PairPreference.values) {
    test('a $preference correction preserves diary dates and syncs', () async {
      // An inverted order offers a correction to both films; equality offers
      // a one-film correction. All paths must preserve each film's own date.
      await library.rescore(
        const WorkKey.movie(1),
        preference == PairPreference.right ? 18 : 14,
      );
      now = now.add(const Duration(days: 1));
      await library.rescore(
        const WorkKey.movie(2),
        preference == PairPreference.right ? 14 : 18,
      );
      final original = await pair(1, 2);
      final before = await SyncStore(db).read();
      now = now.add(const Duration(days: 7));
      final changes = calibrationCorrections(original, preference).last;
      final event = await store.answer(original, preference, changes: changes);
      final after = await SyncStore(db).read();
      for (final previous in before.ratings) {
        final current = after.ratings.singleWhere(
          (r) => r.workKey == previous.workKey,
        );
        if (changes.containsKey(previous.workKey)) {
          expect(current.scoreHalf, changes[previous.workKey]);
          expect(current.createdAt, previous.createdAt);
          expect(current.scoredAt, previous.scoredAt);
          expect(current.note, previous.note);
          expect(current.updatedAt, greaterThan(previous.updatedAt));
          expect(current.updatedBy, library.deviceId);
        } else {
          expect(current, previous);
        }
      }
      expect(event.leftResultScoredAt, original.left.rating.scoredAt);
      expect(event.rightResultScoredAt, original.right.rating.scoredAt);
      expect(event.answeredAt, now.toUtc().millisecondsSinceEpoch);
      expect(comparisonResultVersion(event), (await pair(1, 2)).version);
      await expectLater(
        store.answer(original, preference, changes: changes),
        throwsA(isA<CalibrationStale>()),
      );
      await expectLater(
        store.answer(await pair(1, 2), preference),
        throwsA(isA<CalibrationStale>()),
      );

      final decoded = SyncFile.decode(
        SyncFile.encode(
          after,
          writtenAt: now.toUtc().millisecondsSinceEpoch,
          writtenBy: 'a',
          appVersion: 'test',
        ),
      );
      // A device with the old scores must accept the new score without
      // needing a newer diary date, regardless of merge direction.
      expect(mergeStates(before, decoded).ratings, after.ratings);
      expect(mergeStates(decoded, before).ratings, after.ratings);
    });
  }

  test(
    'an answer alone preserves scores; equality correction is explicit',
    () async {
      final original = await pair(1, 2);
      final before = (await db.select(db.ratings).get()).toList();
      await store.answer(original, PairPreference.equal);
      expect(await db.select(db.ratings).get(), before);
      now = now.add(const Duration(seconds: 1));
      await library.rescore(const WorkKey.movie(3), 18);
      final unequal = await pair(3, 4);
      final option = calibrationCorrections(
        unequal,
        PairPreference.equal,
      ).first;
      final event = await store.answer(
        unequal,
        PairPreference.equal,
        changes: option,
      );
      expect(event.leftResultScoreHalf, event.rightResultScoreHalf);
      final rows = await library.watchRatings().first;
      expect(
        rows.firstWhere((r) => r.key == const WorkKey.movie(3)).rating.note,
        'Note 3',
      );
      expect(
        rows.firstWhere((r) => r.key == const WorkKey.movie(4)).rating.note,
        'Note 4',
      );
      expect(comparisonResultVersion(event), (await pair(3, 4)).version);
      await expectLater(
        store.answer(await pair(3, 4), PairPreference.equal),
        throwsA(isA<CalibrationStale>()),
      );
    },
  );

  test(
    'quota survives reopening, counts equality and resets by local day',
    () async {
      for (var id = 1; id <= 9; id += 2) {
        await store.answer(await pair(id, id + 1), PairPreference.equal);
      }
      final reopened = PairCalibrationStore(db, library, clock: () => now);
      final sixth = await pair(11, 12);
      await expectLater(
        reopened.answer(
          sixth,
          PairPreference.left,
          changes: calibrationCorrections(sixth, PairPreference.left).first,
        ),
        throwsA(isA<CalibrationLimitReached>()),
      );
      expect((await pair(11, 12)).version, sixth.version);
      expect(await db.select(db.pairComparisons).get(), hasLength(5));
      now = now.add(const Duration(days: 1));
      await reopened.answer(sixth, PairPreference.equal);
      expect(await db.select(db.pairComparisons).get(), hasLength(6));
    },
  );

  test('double submission and concurrent quota attempts are atomic', () async {
    final p = await pair(1, 2);
    final results = await Future.wait([
      for (var i = 0; i < 2; i++)
        store
            .answer(p, PairPreference.equal)
            .then<Object>((v) => v, onError: (Object e) => e),
    ]);
    expect(results.whereType<PairComparison>(), hasLength(1));
    expect(results.whereType<CalibrationStale>(), hasLength(1));
    for (var id = 3; id <= 7; id += 2) {
      await store.answer(await pair(id, id + 1), PairPreference.equal);
    }
    final a = await pair(9, 10), b = await pair(11, 12);
    final last = await Future.wait([
      for (final p in [a, b])
        store
            .answer(p, PairPreference.equal)
            .then<Object>((v) => v, onError: (Object e) => e),
    ]);
    expect(last.whereType<PairComparison>(), hasLength(1));
    expect(last.whereType<CalibrationLimitReached>(), hasLength(1));
    expect(await db.select(db.pairComparisons).get(), hasLength(5));
  });

  test(
    'changed or deleted ratings reject stale corrections; note edits survive',
    () async {
      final old = await pair(1, 2);
      now = now.add(const Duration(seconds: 1));
      await library.rescore(const WorkKey.movie(2), 18);
      await expectLater(
        store.answer(old, PairPreference.left),
        throwsA(isA<CalibrationStale>()),
      );
      final current = await pair(1, 2);
      await (db.update(
        db.ratings,
      )..where((r) => r.workKey.equals('tmdb:movie:1'))).write(
        const RatingsCompanion(
          note: Value('Edited during comparison'),
          updatedAt: Value(999),
        ),
      );
      await store.answer(
        current,
        PairPreference.left,
        changes: calibrationCorrections(current, PairPreference.left).first,
      );
      expect((await pair(1, 2)).left.rating.note, 'Edited during comparison');
      final deleted = await pair(3, 4);
      await library.deleteRating(const WorkKey.movie(4));
      await expectLater(
        store.answer(deleted, PairPreference.equal),
        throwsA(isA<CalibrationStale>()),
      );
      expect(await db.select(db.pairComparisons).get(), hasLength(1));
    },
  );

  test(
    'history syncs, exports, restores and retains the shared daily quota',
    () async {
      for (var id = 1; id <= 9; id += 2) {
        await store.answer(await pair(id, id + 1), PairPreference.equal);
      }
      final remote = MemoryRemote();
      final source = SyncStore(db);
      final engine = SyncEngine(
        source,
        remote,
        deviceId: 'a',
        appVersion: 'test',
        clock: () => now,
      );
      await engine.sync();
      final second = AppDatabase(NativeDatabase.memory());
      addTearDown(second.close);
      final secondStore = SyncStore(second);
      await SyncEngine(
        secondStore,
        remote,
        deviceId: 'b',
        appVersion: 'test',
        clock: () => now,
      ).sync();
      final history = (await secondStore.read()).pairComparisons;
      expect(history, hasLength(5));
      final secondLibrary = Library(second, deviceId: 'b', clock: () => now);
      final rows = await secondLibrary.watchRatings().first;
      final pending = CalibrationPair(
        rows.firstWhere((r) => r.key == const WorkKey.movie(11)),
        rows.firstWhere((r) => r.key == const WorkKey.movie(12)),
      );
      await expectLater(
        PairCalibrationStore(
          second,
          secondLibrary,
          clock: () => now,
        ).answer(pending, PairPreference.equal),
        throwsA(isA<CalibrationLimitReached>()),
      );
      final encoded = SyncFile.encode(
        await source.read(),
        writtenAt: 1,
        writtenBy: 'a',
        appVersion: 'test',
      );
      expect(SyncFile.decode(encoded).pairComparisons, history);
      await secondStore.replaceWith(
        const SyncState(),
        deviceId: 'b',
        now: now.millisecondsSinceEpoch,
      );
      expect(
        (await secondStore.read()).pairComparisons,
        history,
        reason:
            'An old backup must not reset completed comparisons and the quota',
      );
    },
  );

  test('v6 validates comparison rows and reads v5 without history', () {
    final p = evidence(
      CalibrationPair(rated(1, 16), rated(2, 16)),
      PairPreference.equal,
    );
    final encoded = SyncFile.encode(
      SyncState(pairComparisons: [p]),
      writtenAt: 1,
      writtenBy: 'a',
      appVersion: 'test',
    );
    final json =
        jsonDecode(utf8.decode(gzip.decode(encoded))) as Map<String, dynamic>;
    expect(SyncFile.decode(encoded).pairComparisons.single, p);
    List<int> bytes(Map<String, dynamic> value) =>
        gzip.encode(utf8.encode(jsonEncode(value)));
    final old = {...json, 'format_version': 5}..remove('pair_comparisons');
    expect(SyncFile.decode(bytes(old)).pairComparisons, isEmpty);
    final missing = {...json}..remove('pair_comparisons');
    expect(
      () => SyncFile.decode(bytes(missing)),
      throwsA(isA<SyncFileBroken>()),
    );
    final duplicate = {
      ...json,
      'pair_comparisons': [
        SyncFile.comparisonToJson(p),
        SyncFile.comparisonToJson(p),
      ],
    };
    expect(
      () => SyncFile.decode(bytes(duplicate)),
      throwsA(isA<SyncFileBroken>()),
    );
    for (final bad in [
      {'day': '2026-02-30'},
      {'left_result_score_half': 21},
      {'left_key': 'tmdb:tv:1'},
      {'preference': 'skip'},
      {'answered_at': -1},
    ]) {
      final broken = {
        ...json,
        'pair_comparisons': [
          {...SyncFile.comparisonToJson(p), ...bad},
        ],
      };
      expect(
        () => SyncFile.decode(bytes(broken)),
        throwsA(isA<SyncFileBroken>()),
      );
    }
  });

  test(
    'comparison-register merge is commutative, associative and idempotent',
    () {
      final random = Random(7);
      for (var round = 0; round < 100; round++) {
        SyncState state() => SyncState(
          pairComparisons: [
            for (var i = 1; i <= 4; i++)
              evidence(
                CalibrationPair(rated(i, 16), rated(i + 10, 16)),
                PairPreference.values[random.nextInt(3)],
                at: random.nextInt(4),
                by: 'd${random.nextInt(3)}',
              ),
          ],
        );
        final a = state(), b = state(), c = state();
        List<PairComparison> merge(SyncState a, SyncState b) =>
            mergeStates(a, b).pairComparisons;
        expect(merge(a, b), merge(b, a));
        expect(merge(a, a), merge(a, const SyncState()));
        expect(merge(mergeStates(a, b), c), merge(a, mergeStates(b, c)));
        expect(remoteBehind(a, const SyncState()), isTrue);
      }
    },
  );
}
