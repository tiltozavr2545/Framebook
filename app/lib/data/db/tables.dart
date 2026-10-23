// `kind.isIn(...)` внутри `get kind` — документированный в drift способ
// задать CHECK колонки: геттер здесь не вызывается рекурсивно, его читает
// генератор. Линтер этого не знает.
// ignore_for_file: recursive_getters

import 'package:drift/drift.dart';

import '../api_source.dart';
import '../work_key.dart';

// Схема — docs/data-model.md, там же «почему». Время везде — мс UTC в int,
// а не DateTime: формат хранения должен совпадать с файлом синхронизации
// байт в байт (docs/sync.md), и решать его за нас драйвер не должен.
//
// CHECK-ограничения дублируют инварианты, которые держит и код: поломанный
// клиент или кривой импорт должны упасть на вставке, а не тихо записать
// оценку 0 или тип «film».

/// Мини-снимок произведения. Синхронизируется вместе со ссылающимися
/// строками; tombstone у него нет — это производные данные.
@DataClassName('Work')
@TableIndex(name: 'works_kind', columns: {#kind})
@TableIndex(name: 'works_parent_key', columns: {#parentKey})
@TableIndex(name: 'works_year', columns: {#year})
class Works extends Table {
  TextColumn get workKey => text()();
  TextColumn get kind => textEnum<WorkKind>().check(
    kind.isIn(WorkKind.values.map((k) => k.name)),
  )();
  TextColumn get parentKey => text().nullable()();
  IntColumn get tmdbId => integer().check(tmdbId.isBiggerThanValue(0))();
  IntColumn get seasonNumber =>
      integer().nullable().check(seasonNumber.isBiggerOrEqualValue(0))();
  IntColumn get episodeNumber =>
      integer().nullable().check(episodeNumber.isBiggerThanValue(0))();
  TextColumn get imdbId => text().nullable()();
  IntColumn get kpId => integer().nullable()();
  TextColumn get title => text()();
  TextColumn get originalTitle => text().nullable()();

  /// `YYYY-MM-DD` как пришло из API, без часового пояса.
  TextColumn get releaseDate => text().nullable()();
  IntColumn get year => integer().nullable()();

  /// Относительный путь TMDB (`/abc.jpg`), не URL.
  TextColumn get posterPath => text().nullable()();

  /// JSON-массив id жанров TMDB.
  TextColumn get genreIds => text().withDefault(const Constant('[]'))();
  IntColumn get snapshotUpdatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {workKey};
}

/// Оценки. Синхронизируются; удаление — только `deleted_at`.
@DataClassName('Rating')
@TableIndex(name: 'ratings_live_score', columns: {#deletedAt, #scoreHalf})
@TableIndex(name: 'ratings_scored_at', columns: {#scoredAt})
class Ratings extends Table {
  TextColumn get workKey => text().references(Works, #workKey)();

  /// Оценка × 2: 2…20 = 1.0…10.0. Целое, чтобы «та же оценка» в окне
  /// калибровки сравнивалась точно.
  IntColumn get scoreHalf =>
      integer().check(scoreHalf.isBetweenValues(2, 20))();
  TextColumn get note =>
      text().nullable().check(note.length.isSmallerOrEqualValue(10000))();
  IntColumn get createdAt => integer()();

  /// Последнее изменение именно оценки, не заметки.
  IntColumn get scoredAt => integer()();

  /// Последнее любое пользовательское изменение — по нему идёт слияние.
  IntColumn get updatedAt => integer()();

  /// `device_id` последнего изменившего — разрешает ничью при равном
  /// `updated_at`.
  TextColumn get updatedBy => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {workKey};
}

/// «Хочу посмотреть». Синхронизируется; удаление — только `deleted_at`.
@DataClassName('WatchlistEntry')
class Watchlist extends Table {
  TextColumn get workKey => text().references(Works, #workKey)();
  IntColumn get addedAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get updatedBy => text()();
  IntColumn get deletedAt => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {workKey};
}

/// Кэш внешних рейтингов. Только локальный; без внешнего ключа на `works`,
/// потому что кэшируется и то, что открывали, но не оценивали.
@DataClassName('ExternalRating')
class ExternalRatings extends Table {
  TextColumn get workKey => text()();
  TextColumn get source => textEnum<RatingSource>().check(
    source.isIn(RatingSource.values.map((s) => s.name)),
  )();
  TextColumn get status => textEnum<RatingStatus>().check(
    status.isIn(RatingStatus.values.map((s) => s.name)),
  )();
  RealColumn get value => real().nullable()();

  /// 10 или 100: RT в процентах, Metacritic 0–100.
  IntColumn get scale => integer().check(scale.isIn(const [10, 100]))();
  IntColumn get votes => integer().nullable()();
  TextColumn get via => textEnum<ApiSource>().check(
    via.isIn(ApiSource.values.map((s) => s.name)),
  )();
  IntColumn get fetchedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {workKey, source};
}

/// Расход суточных лимитов внешних API.
@DataClassName('ApiBudgetRow')
class ApiBudget extends Table {
  TextColumn get source => textEnum<ApiSource>().check(
    source.isIn(ApiSource.values.map((s) => s.name)),
  )();

  /// `YYYY-MM-DD`, сутки по UTC.
  TextColumn get day => text()();
  IntColumn get used => integer()
      .withDefault(const Constant(0))
      .check(used.isBiggerOrEqualValue(0))();

  @override
  Set<Column<Object>> get primaryKey => {source, day};
}

/// Ключ-значение: `device_id`, состояние синхронизации.
@DataClassName('SyncStateEntry')
class SyncState extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
