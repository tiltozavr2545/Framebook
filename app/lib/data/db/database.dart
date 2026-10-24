import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../api_source.dart';
import '../work_key.dart';
import 'tables.dart';

part 'database.g.dart';

const _deviceIdKey = 'device_id';

@DriftDatabase(
  tables: [Works, Ratings, Watchlist, ExternalRatings, ApiBudget, SyncState],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// The database file on the device. In tests,
  /// `AppDatabase(NativeDatabase.memory())`.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'framebook'));

  /// Any schema change means a new version, a step in [migration] and a `dart
  /// run drift_dev make-migrations` snapshot (AGENTS.md, conventions).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // SQLite turns foreign keys off by default, per connection.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// This installation's id: created on first access and never changed. Sync
  /// merging needs it as `updated_by` (docs/sync.md).
  Future<String> deviceId() => transaction(() async {
    final existing = await (select(
      syncState,
    )..where((s) => s.key.equals(_deviceIdKey))).getSingleOrNull();
    if (existing != null) return existing.value;
    final id = const Uuid().v4();
    await into(
      syncState,
    ).insert(SyncStateCompanion.insert(key: _deviceIdKey, value: id));
    return id;
  });

  /// Spends one request from [source]'s daily budget and returns how much is
  /// spent on [day] including it. The counter goes up BEFORE the request
  /// (docs/external-sources.md, "Request budget").
  Future<int> consumeBudget(ApiSource source, String day) async {
    final row = await into(apiBudget).insertReturning(
      ApiBudgetCompanion.insert(source: source, day: day, used: const Value(1)),
      onConflict: DoUpdate(
        (old) => ApiBudgetCompanion.custom(used: old.used + const Constant(1)),
      ),
    );
    return row.used;
  }

  Future<int> budgetUsed(ApiSource source, String day) async {
    final row =
        await (select(apiBudget)
              ..where((b) => b.source.equalsValue(source) & b.day.equals(day)))
            .getSingleOrNull();
    return row?.used ?? 0;
  }

  /// Spends one request only if less than [ceiling] is used. `false` means
  /// today's budget is over: don't send the request.
  Future<bool> tryConsumeBudget(ApiSource source, String day, int ceiling) =>
      transaction(() async {
        if (await budgetUsed(source, day) >= ceiling) return false;
        await consumeBudget(source, day);
        return true;
      });

  /// The service itself said "limit reached": don't ask again until the day
  /// ends, whatever our counter says.
  Future<void> exhaustBudget(ApiSource source, String day, int daily) =>
      transaction(() async {
        if (await budgetUsed(source, day) >= daily) return;
        await into(apiBudget).insertOnConflictUpdate(
          ApiBudgetCompanion.insert(
            source: source,
            day: day,
            used: Value(daily),
          ),
        );
      });

  /// Budget rows older than a week are of no use.
  Future<void> pruneBudget(DateTime now) {
    final cutoff = budgetDay(now.subtract(const Duration(days: 7)));
    return (delete(
      apiBudget,
    )..where((b) => b.day.isSmallerThanValue(cutoff))).go();
  }

  /// Budget days are UTC (docs/external-sources.md).
  static String budgetDay(DateTime now) =>
      now.toUtc().toIso8601String().substring(0, 10);

  Stream<List<ExternalRating>> watchExternalRatings(String workKey) => (select(
    externalRatings,
  )..where((r) => r.workKey.equals(workKey))).watch();

  Future<List<ExternalRating>> externalRatingsFor(String workKey) =>
      (select(externalRatings)..where((r) => r.workKey.equals(workKey))).get();

  Future<void> putExternalRatings(List<ExternalRating> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(externalRatings, rows));

  /// A known Kinopoisk id exists only for what is in `works` (rated or on
  /// the watchlist). Everything else is matched again: a lookup by imdb id
  /// costs the same single request as a refresh by kp id.
  Future<int?> kpIdFor(String workKey) async {
    final row = await (select(
      works,
    )..where((w) => w.workKey.equals(workKey))).getSingleOrNull();
    return row?.kpId;
  }

  /// Stores the Kinopoisk id on the snapshot, if there is one. Never touches
  /// `updated_at` of user rows (AGENTS.md, invariants).
  Future<void> rememberKpId(String workKey, int kpId) =>
      (update(works)..where((w) => w.workKey.equals(workKey))).write(
        WorksCompanion(kpId: Value(kpId)),
      );
}
