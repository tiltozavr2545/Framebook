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

  /// Файл БД на устройстве. В тестах — `AppDatabase(NativeDatabase.memory())`.
  factory AppDatabase.open() => AppDatabase(driftDatabase(name: 'framebook'));

  /// Любое изменение схемы — новая версия, шаг в [migration] и снимок
  /// `dart run drift_dev make-migrations` (AGENTS.md, «Конвенции работы»).
  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    beforeOpen: (details) async {
      // SQLite выключает внешние ключи по умолчанию, на каждое соединение.
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  /// Идентификатор этой установки: создаётся при первом обращении и больше
  /// не меняется. Нужен слиянию синхронизации как `updated_by`
  /// (docs/sync.md).
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

  /// Списывает один запрос из суточного бюджета [source] и возвращает,
  /// сколько потрачено за [day] с учётом этого. Счётчик растёт ДО запроса
  /// (docs/external-sources.md, «Бюджет запросов»).
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

  /// Сутки бюджета — по UTC (docs/external-sources.md).
  static String budgetDay(DateTime now) =>
      now.toUtc().toIso8601String().substring(0, 10);
}
