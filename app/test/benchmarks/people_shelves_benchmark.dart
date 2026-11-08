// Optional host microbenchmark; this does not measure Android frame times.
import 'package:flutter_test/flutter_test.dart';
import 'package:framebook/data/library/insights.dart';
import 'package:framebook/data/sources/tmdb/tmdb_models.dart';

import '../data/insights_test.dart' show rated;

Map<FilmographyRole, List<PersonInsight>> _legacy(LibraryInsights insights) => {
  for (final role in FilmographyRole.values)
    if (insights.people.where((p) => p.roles.containsKey(role)).toList()
        case final group when group.isNotEmpty)
      role:
          (group..sort(
                (a, b) => b.roles[role]!.count.compareTo(a.roles[role]!.count),
              ))
              .take(20)
              .toList(),
};

void main() {
  test('role shelves reuse worker-prepared lists for 30000 contributors', () {
    final title = rated(1, 16);
    final insights = LibraryInsights(
      genres: {},
      decades: {},
      duos: [],
      covered: 1,
      people: [
        for (var id = 1; id <= 30000; id++)
          PersonInsight(
            PeopleCredit(
              id: id,
              name: 'Person $id',
              role: FilmographyRole.acting,
            ),
            [title],
            {
              for (var offset = 0; offset < 3; offset++)
                FilmographyRole.values[(id + offset) %
                    FilmographyRole.values.length]: [
                  title,
                ],
            },
          ),
      ],
    );
    final legacy = <int>[];
    final prepared = <int>[];
    for (var run = 0; run < 7; run++) {
      final clock = Stopwatch()..start();
      final expected = _legacy(insights);
      clock.stop();
      if (run >= 2) legacy.add(clock.elapsedMicroseconds);
      clock.reset();
      clock.start();
      final actual = insights.discoveryPeopleByRole;
      // Match the bounded traversal performed by the widget after preparation.
      final ids = {
        for (final entry in actual.entries)
          entry.key: [for (final person in entry.value) person.person.id],
      };
      clock.stop();
      if (run >= 2) prepared.add(clock.elapsedMicroseconds);
      for (final role in FilmographyRole.values) {
        expect(ids[role], expected[role]!.map((person) => person.person.id));
      }
      expect(insights.people, hasLength(30000));
    }
    final sortedLegacy = [...legacy]..sort();
    final sortedPrepared = [...prepared]..sort();
    // ignore: avoid_print
    print(
      'Host people shelf preparation: legacy median ${sortedLegacy[2]} us; '
      'prepared traversal median ${sortedPrepared[2]} us; samples $legacy / $prepared',
    );
  });
}
