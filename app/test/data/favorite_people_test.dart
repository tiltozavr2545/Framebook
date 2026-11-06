import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/native.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/db/database.dart';
import 'package:framebook/data/library/favorite_people.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/sync/merge.dart';
import 'package:framebook/data/sync/sync_file.dart';
import 'package:framebook/data/sync/sync_store.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late AppDatabase db;
  late PeopleLibrary library;
  late DateTime now;
  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    now = DateTime.utc(2026, 11, 6);
    library = PeopleLibrary(db, clock: () => now);
  });
  tearDown(() => db.close());
  const person = PersonSummary(
    id: 138,
    name: 'Quentin Tarantino',
    profilePath: '/q.jpg',
  );
  test(
    'favorite whole person; idempotence, removal, clock skew and re-add',
    () async {
      await library.setFavorite(person, true);
      final first = (await SyncStore(db).read()).favoritePeople.single;
      await library.setFavorite(person, true);
      expect((await SyncStore(db).read()).favoritePeople.single, first);
      now = now.subtract(const Duration(days: 2));
      await library.setFavorite(person, false);
      final deleted = (await SyncStore(db).read()).favoritePeople.single;
      expect(deleted.deletedAt, isNotNull);
      expect(deleted.updatedAt, first.updatedAt + 1);
      await library.setFavorite(person, true);
      final revived = (await SyncStore(db).read()).favoritePeople.single;
      expect(revived.deletedAt, isNull);
      expect(revived.updatedAt, deleted.updatedAt + 1);
      expect(revived.profilePath, person.profilePath);
    },
  );
  test(
    'two devices converge and old device cannot revive a removed favorite',
    () async {
      final other = AppDatabase(NativeDatabase.memory());
      addTearDown(other.close);
      await library.setFavorite(person, true);
      final old = await SyncStore(db).read();
      await SyncStore(other).apply(old);
      await library.setFavorite(person, false);
      await SyncStore(other).apply(await SyncStore(db).read());
      await SyncStore(other).apply(old);
      expect(
        (await SyncStore(other).read()).favoritePeople.single.deletedAt,
        isNotNull,
      );
      await SyncStore(
        db,
      ).purge(now.add(const Duration(days: 365)).millisecondsSinceEpoch);
      expect(
        (await SyncStore(db).read()).favoritePeople.single.deletedAt,
        isNotNull,
      );
    },
  );
  test(
    'favorites-only state uploads, round trips and older exports decode',
    () async {
      await library.setFavorite(person, true);
      final state = await SyncStore(db).read();
      expect(state.isEmpty, isFalse);
      expect(remoteBehind(state, const SyncState()), isTrue);
      final bytes = SyncFile.encode(
        state,
        writtenAt: 1,
        writtenBy: 'a',
        appVersion: 'test',
      );
      expect(SyncFile.decode(bytes).favoritePeople, state.favoritePeople);
      final json =
          jsonDecode(utf8.decode(gzip.decode(bytes))) as Map<String, dynamic>;
      json['format_version'] = 4;
      json.remove('favorite_people');
      expect(
        SyncFile.decode(
          gzip.encode(utf8.encode(jsonEncode(json))),
        ).favoritePeople,
        isEmpty,
      );
    },
  );
  test(
    'format 5 rejects missing, malformed and duplicate favorite records',
    () async {
      await library.setFavorite(person, true);
      Map<String, dynamic> json() =>
          jsonDecode(
                utf8.decode(
                  gzip.decode(
                    SyncFile.encode(
                      // Only the codec is used: valid favorites need no work snapshots.
                      SyncState(
                        favoritePeople: [
                          FavoritePerson(
                            personId: 138,
                            name: 'Quentin',
                            updatedAt: 1,
                            updatedBy: 'a',
                          ),
                        ],
                      ),
                      writtenAt: 1,
                      writtenBy: 'a',
                      appVersion: 'test',
                    ),
                  ),
                ),
              )
              as Map<String, dynamic>;
      void bad(Map<String, dynamic> raw) => expect(
        () => SyncFile.decode(gzip.encode(utf8.encode(jsonEncode(raw)))),
        throwsA(isA<SyncFileBroken>()),
      );
      bad(json()..remove('favorite_people'));
      final duplicate = json();
      (duplicate['favorite_people'] as List<dynamic>).add(
        (duplicate['favorite_people'] as List<dynamic>).first,
      );
      bad(duplicate);
      for (final entry in {
        'person_id': 0,
        'name': ' ',
        'updated_at': -1,
        'profile_path': 'https://bad',
      }.entries) {
        final raw = json();
        ((raw['favorite_people'] as List<dynamic>).first
                as Map<String, dynamic>)[entry.key] =
            entry.value;
        bad(raw);
      }
    },
  );
  test(
    'replace restores favorites and tombstones those absent from backup',
    () async {
      await library.setFavorite(person, true);
      final backup = await SyncStore(db).read();
      await library.setFavorite(
        const PersonSummary(id: 2, name: 'Other'),
        true,
      );
      await library.setFavorite(person, false);
      await SyncStore(db).replaceWith(
        backup,
        deviceId: 'restore',
        now: now.millisecondsSinceEpoch + 100,
      );
      final rows = (await SyncStore(db).read()).favoritePeople;
      expect(rows.singleWhere((p) => p.personId == 138).deletedAt, isNull);
      expect(rows.singleWhere((p) => p.personId == 2).deletedAt, isNotNull);
    },
  );
  test(
    'favorite register merge is commutative, associative and idempotent including ties',
    () {
      final random = Random(5);
      SyncState sample() => SyncState(
        favoritePeople: [
          for (var id = 1; id <= 5; id++)
            if (random.nextBool())
              FavoritePerson(
                personId: id,
                name: 'Name ${random.nextInt(2)}',
                updatedAt: random.nextInt(4),
                updatedBy: '${random.nextInt(2)}',
                deletedAt: random.nextBool() ? null : 0,
              ),
        ],
      );
      List<FavoritePerson> normalize(SyncState s) =>
          mergeStates(s, const SyncState()).favoritePeople;
      for (var i = 0; i < 100; i++) {
        final a = sample(), b = sample(), c = sample();
        expect(
          mergeStates(a, b).favoritePeople,
          mergeStates(b, a).favoritePeople,
        );
        expect(
          mergeStates(mergeStates(a, b), c).favoritePeople,
          mergeStates(a, mergeStates(b, c)).favoritePeople,
        );
        expect(mergeStates(a, a).favoritePeople, normalize(a));
      }
    },
  );
}
