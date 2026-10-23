import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/work_key.dart';

void main() {
  group('toString', () {
    test('builds the documented format for every kind', () {
      expect(const WorkKey.movie(603).toString(), 'tmdb:movie:603');
      expect(const WorkKey.tv(1399).toString(), 'tmdb:tv:1399');
      expect(const WorkKey.season(1399, 1).toString(), 'tmdb:tv:1399:s1');
      expect(
        const WorkKey.episode(1399, 1, 3).toString(),
        'tmdb:tv:1399:s1:e3',
      );
    });

    test('season 0 (specials) is a valid season', () {
      expect(const WorkKey.season(1399, 0).toString(), 'tmdb:tv:1399:s0');
    });
  });

  group('parse', () {
    test('round-trips every kind', () {
      for (final key in const [
        WorkKey.movie(603),
        WorkKey.tv(1399),
        WorkKey.season(1399, 0),
        WorkKey.season(1399, 12),
        WorkKey.episode(1399, 1, 3),
      ]) {
        expect(WorkKey.parse(key.toString()), key);
      }
    });

    test('movie 603 and series 603 are different works', () {
      // The whole reason the type is part of the key: TMDB numbers movies
      // and series separately (AGENTS.md, «Грабли»).
      expect(
        WorkKey.parse('tmdb:movie:603'),
        isNot(WorkKey.parse('tmdb:tv:603')),
      );
    });

    test('rejects anything toString would not produce', () {
      for (final bad in [
        '',
        'tmdb:movie',
        'tmdb:movie:',
        'tmdb:movie:0',
        'tmdb:movie:0603',
        'tmdb:movie:603:s1',
        'tmdb:film:603',
        'kp:movie:301',
        'TMDB:movie:603',
        ' tmdb:movie:603',
        'tmdb:movie:603 ',
        'tmdb:tv:1399:s01',
        'tmdb:tv:1399:s1:e0',
        'tmdb:tv:1399:e3',
        'tmdb:tv:1399:s1:e3:x',
        'tmdb:tv:-1',
      ]) {
        expect(
          () => WorkKey.parse(bad),
          throwsFormatException,
          reason: '"$bad" must not parse',
        );
        expect(WorkKey.tryParse(bad), isNull);
      }
    });
  });

  group('parent and lineage', () {
    test('parent goes episode → season → series → nothing', () {
      const episode = WorkKey.episode(1399, 1, 3);
      expect(episode.parent, const WorkKey.season(1399, 1));
      expect(episode.parent!.parent, const WorkKey.tv(1399));
      expect(episode.parent!.parent!.parent, isNull);
      expect(const WorkKey.movie(603).parent, isNull);
    });

    test('lineage lists ancestors from the series down', () {
      expect(const WorkKey.episode(1399, 1, 3).lineage, const [
        WorkKey.tv(1399),
        WorkKey.season(1399, 1),
        WorkKey.episode(1399, 1, 3),
      ]);
      expect(const WorkKey.movie(603).lineage, const [WorkKey.movie(603)]);
    });
  });
}
