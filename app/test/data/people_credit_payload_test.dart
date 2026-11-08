import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/people_credit_payload.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';

void main() {
  test(
    'diverse credits bypass the full sharing table without copying rows',
    () async {
      final entries = {
        for (var row = 0; row < 20; row++)
          '$row': [
            for (var index = 0; index < 100; index++)
              PeopleCredit(
                id: row * 100 + index,
                name: 'Person ${row * 100 + index}',
                role: FilmographyRole.acting,
              ),
          ],
      };
      expect(await sharedPeopleCreditPayload(entries), same(entries));
    },
  );

  test(
    'sharing preserves every credit value, row order and empty rows',
    () async {
      PeopleCredit actor({
        String name = 'Actor',
        FilmographyRole role = FilmographyRole.acting,
        String? path,
      }) => PeopleCredit(id: 1, name: name, role: role, profilePath: path);
      final entries = {
        'first': [
          actor(),
          actor(role: FilmographyRole.directing),
          actor(name: 'Актёр'),
          actor(path: '/photo.jpg'),
        ],
        'second': [actor(), actor()],
        'empty': <PeopleCredit>[],
      };
      final result = (await sharedPeopleCreditPayload(entries))!;
      expect(result.keys, entries.keys);
      for (final key in entries.keys) {
        expect(
          result[key]!.map((p) => p.toJson()).toList(),
          entries[key]!.map((p) => p.toJson()).toList(),
        );
      }
      expect(identical(result['first']![0], result['second']![0]), isTrue);
      expect(identical(result['first']![0], result['first']![1]), isFalse);
      expect(identical(result['first']![0], result['first']![2]), isFalse);
      expect(identical(result['first']![0], result['first']![3]), isFalse);
      expect(() => result['first']!.clear(), throwsUnsupportedError);
      expect(() => result.clear(), throwsUnsupportedError);
    },
  );

  test('large payload preparation yields to queued foreground work', () async {
    var foregroundRan = false;
    Timer.run(() => foregroundRan = true);
    final result = await sharedPeopleCreditPayload({
      'large': [
        for (var id = 0; id < 2000; id++)
          PeopleCredit(id: id, name: 'Actor $id', role: FilmographyRole.acting),
      ],
    });
    expect(foregroundRan, isTrue);
    expect(result!['large'], hasLength(2000));
  });

  test(
    'superseded preparation stops without publishing partial credits',
    () async {
      var active = true;
      final original = {
        'large': [
          for (var id = 0; id < 2000; id++)
            PeopleCredit(
              id: id,
              name: 'Actor $id',
              role: FilmographyRole.acting,
            ),
        ],
      };
      final pending = sharedPeopleCreditPayload(original, active: () => active);
      active = false;
      expect(await pending, isNull);
      expect(original['large'], hasLength(2000));
      expect(
        await sharedPeopleCreditPayload(original, active: () => false),
        isNull,
      );
    },
  );
}
