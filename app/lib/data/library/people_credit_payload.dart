import '../sources/tmdb/tmdb_models.dart';

/// Share equal immutable leaves before sending a large credit graph to a worker.
/// Yield between bounded batches so preparing the message cannot monopolize UI.
Future<Map<String, List<PeopleCredit>>?> sharedPeopleCreditPayload(
  Map<String, List<PeopleCredit>> entries, {
  bool Function()? active,
}) async {
  if (active?.call() == false) return null;
  // Avoid allocating a full intern table when a diverse graph cannot benefit.
  final sample = <(int, FilmographyRole, String, String?)>{};
  var sampled = 0;
  var repeated = 0;
  var total = 0;
  for (final row in entries.values) {
    total += row.length;
    final count = row.length < 16 ? row.length : 16;
    for (var index = 0; index < count; index++) {
      final person =
          row[count == 1 ? 0 : index * (row.length - 1) ~/ (count - 1)];
      if (!sample.add((
        person.id,
        person.role,
        person.name,
        person.profilePath,
      ))) {
        repeated++;
      }
      if (++sampled % 512 == 0) {
        await Future<void>.delayed(Duration.zero);
        if (active?.call() == false) return null;
      }
    }
  }
  if (total > 512 && sampled % 512 != 0) {
    await Future<void>.delayed(Duration.zero);
    if (active?.call() == false) return null;
  }
  if (sampled == 0 || repeated * 20 < sampled) return entries;
  final people = <(int, FilmographyRole, String, String?), PeopleCredit>{};
  final result = <String, List<PeopleCredit>>{};
  var processed = 0;
  for (final entry in entries.entries) {
    final row = <PeopleCredit>[];
    for (final person in entry.value) {
      final key = (person.id, person.role, person.name, person.profilePath);
      final shared = people[key];
      if (shared == null) people[key] = person;
      row.add(shared ?? person);
      if (++processed % 512 == 0) {
        await Future<void>.delayed(Duration.zero);
        if (active?.call() == false) return null;
      }
    }
    result[entry.key] = List.unmodifiable(row);
  }
  return Map.unmodifiable(result);
}
