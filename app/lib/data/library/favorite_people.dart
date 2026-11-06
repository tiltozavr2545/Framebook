import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/database.dart';
import '../db/database_provider.dart';
import '../sources/tmdb/tmdb_models.dart';

final favoritePeopleProvider = StreamProvider<List<FavoritePerson>>((ref) {
  final db = ref.watch(databaseProvider);
  return (db.select(db.favoritePeople)
        ..where((p) => p.deletedAt.isNull())
        ..orderBy([(p) => OrderingTerm.asc(p.name)]))
      .watch();
});

final peopleLibraryProvider = Provider<PeopleLibrary>(
  (ref) => PeopleLibrary(ref.watch(databaseProvider)),
);

final class PeopleLibrary {
  PeopleLibrary(this.db, {DateTime Function()? clock})
    : clock = clock ?? DateTime.now;

  final AppDatabase db;
  final DateTime Function() clock;

  Future<void> setFavorite(PersonSummary person, bool favorite) =>
      db.transaction(() async {
        if (person.id <= 0 || person.name.trim().isEmpty) {
          throw ArgumentError('A person needs a positive id and a name');
        }
        final old = await (db.select(
          db.favoritePeople,
        )..where((p) => p.personId.equals(person.id))).getSingleOrNull();
        if ((old != null && old.deletedAt == null) == favorite) return;
        final now = clock().toUtc().millisecondsSinceEpoch;
        final at = now > (old?.updatedAt ?? -1) ? now : old!.updatedAt + 1;
        await db
            .into(db.favoritePeople)
            .insertOnConflictUpdate(
              FavoritePeopleCompanion.insert(
                personId: Value(person.id),
                name: person.name,
                profilePath: Value(person.profilePath),
                updatedAt: at,
                updatedBy: await db.deviceId(),
                deletedAt: Value(favorite ? null : now),
              ),
            );
      });
}
