// Optional host CPU benchmark; timings neither gate CI nor describe phone frames.
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/people_index.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';
import 'package:framebook/data/recommendations/profile.dart';
import '../data/insights_test.dart' show rated;

void main() {
  test('host-only profile cost across library and credit sizes', () {
    for (final count in [20, 80, 500]) {
      final titles = [
        for (var i = 1; i <= count; i++) rated(i, 16, genres: [28, 18]),
      ];
      final entries = {
        for (final title in titles)
          peopleIdentity(title): [
            for (var id = 1; id <= 300; id++)
              PeopleCredit(
                id: id,
                name: 'Actor $id',
                role: FilmographyRole.acting,
              ),
          ],
      };
      final times = <int>[];
      for (var i = 0; i < 7; i++) {
        final watch = Stopwatch()..start();
        final result = TasteProfile(tasteSignals(titles, entries));
        watch.stop();
        expect(result.signals.length, count);
        if (i >= 2) times.add(watch.elapsedMicroseconds);
      }
      times.sort();
      // ignore: avoid_print
      print(
        'Host taste profile: $count titles, ${count * 300} credits, median ${times[2]} us, samples $times',
      );
    }
  });
}
