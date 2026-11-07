// dart format width=80
import 'package:framebook/data/work_key.dart' as i2;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i3;
import 'package:framebook/data/library/pair_preference.dart' as i4;
import 'package:framebook/data/api_source.dart' as i5;
// GENERATED CODE, DO NOT EDIT BY HAND.
// ignore_for_file: type=lint
import 'package:drift/drift.dart';

class Works extends Table with TableInfo<Works, WorksData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Works(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    check: () => kind.isIn(i2.WorkKind.values.map((k) => k.name)),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> parentKey = GeneratedColumn<String>(
    'parent_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(tmdbId).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    true,
    check: () => i3.ComparableExpr(seasonNumber).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    true,
    check: () => i3.ComparableExpr(episodeNumber).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> imdbId = GeneratedColumn<String>(
    'imdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> kpId = GeneratedColumn<int>(
    'kp_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> genreIds = GeneratedColumn<String>(
    'genre_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('\'[]\''),
  );
  late final GeneratedColumn<int> snapshotUpdatedAt = GeneratedColumn<int>(
    'snapshot_updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    workKey,
    kind,
    parentKey,
    tmdbId,
    seasonNumber,
    episodeNumber,
    imdbId,
    kpId,
    title,
    originalTitle,
    releaseDate,
    year,
    posterPath,
    genreIds,
    snapshotUpdatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'works';
  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  WorksData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorksData(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      parentKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_key'],
      ),
      tmdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tmdb_id'],
      )!,
      seasonNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}season_number'],
      ),
      episodeNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}episode_number'],
      ),
      imdbId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}imdb_id'],
      ),
      kpId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}kp_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      originalTitle: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_title'],
      ),
      releaseDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}release_date'],
      ),
      year: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}year'],
      ),
      posterPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}poster_path'],
      ),
      genreIds: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}genre_ids'],
      )!,
      snapshotUpdatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snapshot_updated_at'],
      )!,
    );
  }

  @override
  Works createAlias(String alias) {
    return Works(attachedDatabase, alias);
  }
}

class WorksData extends DataClass implements Insertable<WorksData> {
  final String workKey;
  final String kind;
  final String? parentKey;
  final int tmdbId;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? imdbId;
  final int? kpId;
  final String title;
  final String? originalTitle;
  final String? releaseDate;
  final int? year;
  final String? posterPath;
  final String genreIds;
  final int snapshotUpdatedAt;
  const WorksData({
    required this.workKey,
    required this.kind,
    this.parentKey,
    required this.tmdbId,
    this.seasonNumber,
    this.episodeNumber,
    this.imdbId,
    this.kpId,
    required this.title,
    this.originalTitle,
    this.releaseDate,
    this.year,
    this.posterPath,
    required this.genreIds,
    required this.snapshotUpdatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_key'] = Variable<String>(workKey);
    map['kind'] = Variable<String>(kind);
    if (!nullToAbsent || parentKey != null) {
      map['parent_key'] = Variable<String>(parentKey);
    }
    map['tmdb_id'] = Variable<int>(tmdbId);
    if (!nullToAbsent || seasonNumber != null) {
      map['season_number'] = Variable<int>(seasonNumber);
    }
    if (!nullToAbsent || episodeNumber != null) {
      map['episode_number'] = Variable<int>(episodeNumber);
    }
    if (!nullToAbsent || imdbId != null) {
      map['imdb_id'] = Variable<String>(imdbId);
    }
    if (!nullToAbsent || kpId != null) {
      map['kp_id'] = Variable<int>(kpId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || originalTitle != null) {
      map['original_title'] = Variable<String>(originalTitle);
    }
    if (!nullToAbsent || releaseDate != null) {
      map['release_date'] = Variable<String>(releaseDate);
    }
    if (!nullToAbsent || year != null) {
      map['year'] = Variable<int>(year);
    }
    if (!nullToAbsent || posterPath != null) {
      map['poster_path'] = Variable<String>(posterPath);
    }
    map['genre_ids'] = Variable<String>(genreIds);
    map['snapshot_updated_at'] = Variable<int>(snapshotUpdatedAt);
    return map;
  }

  WorksCompanion toCompanion(bool nullToAbsent) {
    return WorksCompanion(
      workKey: Value(workKey),
      kind: Value(kind),
      parentKey: parentKey == null && nullToAbsent
          ? const Value.absent()
          : Value(parentKey),
      tmdbId: Value(tmdbId),
      seasonNumber: seasonNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(seasonNumber),
      episodeNumber: episodeNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(episodeNumber),
      imdbId: imdbId == null && nullToAbsent
          ? const Value.absent()
          : Value(imdbId),
      kpId: kpId == null && nullToAbsent ? const Value.absent() : Value(kpId),
      title: Value(title),
      originalTitle: originalTitle == null && nullToAbsent
          ? const Value.absent()
          : Value(originalTitle),
      releaseDate: releaseDate == null && nullToAbsent
          ? const Value.absent()
          : Value(releaseDate),
      year: year == null && nullToAbsent ? const Value.absent() : Value(year),
      posterPath: posterPath == null && nullToAbsent
          ? const Value.absent()
          : Value(posterPath),
      genreIds: Value(genreIds),
      snapshotUpdatedAt: Value(snapshotUpdatedAt),
    );
  }

  factory WorksData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorksData(
      workKey: serializer.fromJson<String>(json['workKey']),
      kind: serializer.fromJson<String>(json['kind']),
      parentKey: serializer.fromJson<String?>(json['parentKey']),
      tmdbId: serializer.fromJson<int>(json['tmdbId']),
      seasonNumber: serializer.fromJson<int?>(json['seasonNumber']),
      episodeNumber: serializer.fromJson<int?>(json['episodeNumber']),
      imdbId: serializer.fromJson<String?>(json['imdbId']),
      kpId: serializer.fromJson<int?>(json['kpId']),
      title: serializer.fromJson<String>(json['title']),
      originalTitle: serializer.fromJson<String?>(json['originalTitle']),
      releaseDate: serializer.fromJson<String?>(json['releaseDate']),
      year: serializer.fromJson<int?>(json['year']),
      posterPath: serializer.fromJson<String?>(json['posterPath']),
      genreIds: serializer.fromJson<String>(json['genreIds']),
      snapshotUpdatedAt: serializer.fromJson<int>(json['snapshotUpdatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workKey': serializer.toJson<String>(workKey),
      'kind': serializer.toJson<String>(kind),
      'parentKey': serializer.toJson<String?>(parentKey),
      'tmdbId': serializer.toJson<int>(tmdbId),
      'seasonNumber': serializer.toJson<int?>(seasonNumber),
      'episodeNumber': serializer.toJson<int?>(episodeNumber),
      'imdbId': serializer.toJson<String?>(imdbId),
      'kpId': serializer.toJson<int?>(kpId),
      'title': serializer.toJson<String>(title),
      'originalTitle': serializer.toJson<String?>(originalTitle),
      'releaseDate': serializer.toJson<String?>(releaseDate),
      'year': serializer.toJson<int?>(year),
      'posterPath': serializer.toJson<String?>(posterPath),
      'genreIds': serializer.toJson<String>(genreIds),
      'snapshotUpdatedAt': serializer.toJson<int>(snapshotUpdatedAt),
    };
  }

  WorksData copyWith({
    String? workKey,
    String? kind,
    Value<String?> parentKey = const Value.absent(),
    int? tmdbId,
    Value<int?> seasonNumber = const Value.absent(),
    Value<int?> episodeNumber = const Value.absent(),
    Value<String?> imdbId = const Value.absent(),
    Value<int?> kpId = const Value.absent(),
    String? title,
    Value<String?> originalTitle = const Value.absent(),
    Value<String?> releaseDate = const Value.absent(),
    Value<int?> year = const Value.absent(),
    Value<String?> posterPath = const Value.absent(),
    String? genreIds,
    int? snapshotUpdatedAt,
  }) => WorksData(
    workKey: workKey ?? this.workKey,
    kind: kind ?? this.kind,
    parentKey: parentKey.present ? parentKey.value : this.parentKey,
    tmdbId: tmdbId ?? this.tmdbId,
    seasonNumber: seasonNumber.present ? seasonNumber.value : this.seasonNumber,
    episodeNumber: episodeNumber.present
        ? episodeNumber.value
        : this.episodeNumber,
    imdbId: imdbId.present ? imdbId.value : this.imdbId,
    kpId: kpId.present ? kpId.value : this.kpId,
    title: title ?? this.title,
    originalTitle: originalTitle.present
        ? originalTitle.value
        : this.originalTitle,
    releaseDate: releaseDate.present ? releaseDate.value : this.releaseDate,
    year: year.present ? year.value : this.year,
    posterPath: posterPath.present ? posterPath.value : this.posterPath,
    genreIds: genreIds ?? this.genreIds,
    snapshotUpdatedAt: snapshotUpdatedAt ?? this.snapshotUpdatedAt,
  );
  WorksData copyWithCompanion(WorksCompanion data) {
    return WorksData(
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      kind: data.kind.present ? data.kind.value : this.kind,
      parentKey: data.parentKey.present ? data.parentKey.value : this.parentKey,
      tmdbId: data.tmdbId.present ? data.tmdbId.value : this.tmdbId,
      seasonNumber: data.seasonNumber.present
          ? data.seasonNumber.value
          : this.seasonNumber,
      episodeNumber: data.episodeNumber.present
          ? data.episodeNumber.value
          : this.episodeNumber,
      imdbId: data.imdbId.present ? data.imdbId.value : this.imdbId,
      kpId: data.kpId.present ? data.kpId.value : this.kpId,
      title: data.title.present ? data.title.value : this.title,
      originalTitle: data.originalTitle.present
          ? data.originalTitle.value
          : this.originalTitle,
      releaseDate: data.releaseDate.present
          ? data.releaseDate.value
          : this.releaseDate,
      year: data.year.present ? data.year.value : this.year,
      posterPath: data.posterPath.present
          ? data.posterPath.value
          : this.posterPath,
      genreIds: data.genreIds.present ? data.genreIds.value : this.genreIds,
      snapshotUpdatedAt: data.snapshotUpdatedAt.present
          ? data.snapshotUpdatedAt.value
          : this.snapshotUpdatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorksData(')
          ..write('workKey: $workKey, ')
          ..write('kind: $kind, ')
          ..write('parentKey: $parentKey, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('imdbId: $imdbId, ')
          ..write('kpId: $kpId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('year: $year, ')
          ..write('posterPath: $posterPath, ')
          ..write('genreIds: $genreIds, ')
          ..write('snapshotUpdatedAt: $snapshotUpdatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workKey,
    kind,
    parentKey,
    tmdbId,
    seasonNumber,
    episodeNumber,
    imdbId,
    kpId,
    title,
    originalTitle,
    releaseDate,
    year,
    posterPath,
    genreIds,
    snapshotUpdatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorksData &&
          other.workKey == this.workKey &&
          other.kind == this.kind &&
          other.parentKey == this.parentKey &&
          other.tmdbId == this.tmdbId &&
          other.seasonNumber == this.seasonNumber &&
          other.episodeNumber == this.episodeNumber &&
          other.imdbId == this.imdbId &&
          other.kpId == this.kpId &&
          other.title == this.title &&
          other.originalTitle == this.originalTitle &&
          other.releaseDate == this.releaseDate &&
          other.year == this.year &&
          other.posterPath == this.posterPath &&
          other.genreIds == this.genreIds &&
          other.snapshotUpdatedAt == this.snapshotUpdatedAt);
}

class WorksCompanion extends UpdateCompanion<WorksData> {
  final Value<String> workKey;
  final Value<String> kind;
  final Value<String?> parentKey;
  final Value<int> tmdbId;
  final Value<int?> seasonNumber;
  final Value<int?> episodeNumber;
  final Value<String?> imdbId;
  final Value<int?> kpId;
  final Value<String> title;
  final Value<String?> originalTitle;
  final Value<String?> releaseDate;
  final Value<int?> year;
  final Value<String?> posterPath;
  final Value<String> genreIds;
  final Value<int> snapshotUpdatedAt;
  final Value<int> rowid;
  const WorksCompanion({
    this.workKey = const Value.absent(),
    this.kind = const Value.absent(),
    this.parentKey = const Value.absent(),
    this.tmdbId = const Value.absent(),
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.kpId = const Value.absent(),
    this.title = const Value.absent(),
    this.originalTitle = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.year = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.genreIds = const Value.absent(),
    this.snapshotUpdatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorksCompanion.insert({
    required String workKey,
    required String kind,
    this.parentKey = const Value.absent(),
    required int tmdbId,
    this.seasonNumber = const Value.absent(),
    this.episodeNumber = const Value.absent(),
    this.imdbId = const Value.absent(),
    this.kpId = const Value.absent(),
    required String title,
    this.originalTitle = const Value.absent(),
    this.releaseDate = const Value.absent(),
    this.year = const Value.absent(),
    this.posterPath = const Value.absent(),
    this.genreIds = const Value.absent(),
    required int snapshotUpdatedAt,
    this.rowid = const Value.absent(),
  }) : workKey = Value(workKey),
       kind = Value(kind),
       tmdbId = Value(tmdbId),
       title = Value(title),
       snapshotUpdatedAt = Value(snapshotUpdatedAt);
  static Insertable<WorksData> custom({
    Expression<String>? workKey,
    Expression<String>? kind,
    Expression<String>? parentKey,
    Expression<int>? tmdbId,
    Expression<int>? seasonNumber,
    Expression<int>? episodeNumber,
    Expression<String>? imdbId,
    Expression<int>? kpId,
    Expression<String>? title,
    Expression<String>? originalTitle,
    Expression<String>? releaseDate,
    Expression<int>? year,
    Expression<String>? posterPath,
    Expression<String>? genreIds,
    Expression<int>? snapshotUpdatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workKey != null) 'work_key': workKey,
      if (kind != null) 'kind': kind,
      if (parentKey != null) 'parent_key': parentKey,
      if (tmdbId != null) 'tmdb_id': tmdbId,
      if (seasonNumber != null) 'season_number': seasonNumber,
      if (episodeNumber != null) 'episode_number': episodeNumber,
      if (imdbId != null) 'imdb_id': imdbId,
      if (kpId != null) 'kp_id': kpId,
      if (title != null) 'title': title,
      if (originalTitle != null) 'original_title': originalTitle,
      if (releaseDate != null) 'release_date': releaseDate,
      if (year != null) 'year': year,
      if (posterPath != null) 'poster_path': posterPath,
      if (genreIds != null) 'genre_ids': genreIds,
      if (snapshotUpdatedAt != null) 'snapshot_updated_at': snapshotUpdatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorksCompanion copyWith({
    Value<String>? workKey,
    Value<String>? kind,
    Value<String?>? parentKey,
    Value<int>? tmdbId,
    Value<int?>? seasonNumber,
    Value<int?>? episodeNumber,
    Value<String?>? imdbId,
    Value<int?>? kpId,
    Value<String>? title,
    Value<String?>? originalTitle,
    Value<String?>? releaseDate,
    Value<int?>? year,
    Value<String?>? posterPath,
    Value<String>? genreIds,
    Value<int>? snapshotUpdatedAt,
    Value<int>? rowid,
  }) {
    return WorksCompanion(
      workKey: workKey ?? this.workKey,
      kind: kind ?? this.kind,
      parentKey: parentKey ?? this.parentKey,
      tmdbId: tmdbId ?? this.tmdbId,
      seasonNumber: seasonNumber ?? this.seasonNumber,
      episodeNumber: episodeNumber ?? this.episodeNumber,
      imdbId: imdbId ?? this.imdbId,
      kpId: kpId ?? this.kpId,
      title: title ?? this.title,
      originalTitle: originalTitle ?? this.originalTitle,
      releaseDate: releaseDate ?? this.releaseDate,
      year: year ?? this.year,
      posterPath: posterPath ?? this.posterPath,
      genreIds: genreIds ?? this.genreIds,
      snapshotUpdatedAt: snapshotUpdatedAt ?? this.snapshotUpdatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workKey.present) {
      map['work_key'] = Variable<String>(workKey.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (parentKey.present) {
      map['parent_key'] = Variable<String>(parentKey.value);
    }
    if (tmdbId.present) {
      map['tmdb_id'] = Variable<int>(tmdbId.value);
    }
    if (seasonNumber.present) {
      map['season_number'] = Variable<int>(seasonNumber.value);
    }
    if (episodeNumber.present) {
      map['episode_number'] = Variable<int>(episodeNumber.value);
    }
    if (imdbId.present) {
      map['imdb_id'] = Variable<String>(imdbId.value);
    }
    if (kpId.present) {
      map['kp_id'] = Variable<int>(kpId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (originalTitle.present) {
      map['original_title'] = Variable<String>(originalTitle.value);
    }
    if (releaseDate.present) {
      map['release_date'] = Variable<String>(releaseDate.value);
    }
    if (year.present) {
      map['year'] = Variable<int>(year.value);
    }
    if (posterPath.present) {
      map['poster_path'] = Variable<String>(posterPath.value);
    }
    if (genreIds.present) {
      map['genre_ids'] = Variable<String>(genreIds.value);
    }
    if (snapshotUpdatedAt.present) {
      map['snapshot_updated_at'] = Variable<int>(snapshotUpdatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorksCompanion(')
          ..write('workKey: $workKey, ')
          ..write('kind: $kind, ')
          ..write('parentKey: $parentKey, ')
          ..write('tmdbId: $tmdbId, ')
          ..write('seasonNumber: $seasonNumber, ')
          ..write('episodeNumber: $episodeNumber, ')
          ..write('imdbId: $imdbId, ')
          ..write('kpId: $kpId, ')
          ..write('title: $title, ')
          ..write('originalTitle: $originalTitle, ')
          ..write('releaseDate: $releaseDate, ')
          ..write('year: $year, ')
          ..write('posterPath: $posterPath, ')
          ..write('genreIds: $genreIds, ')
          ..write('snapshotUpdatedAt: $snapshotUpdatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Ratings extends Table with TableInfo<Ratings, RatingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Ratings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES works (work_key)',
    ),
  );
  late final GeneratedColumn<int> scoreHalf = GeneratedColumn<int>(
    'score_half',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(scoreHalf).isBetweenValues(2, 20),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    check: () => i3.ComparableExpr(note.length).isSmallerOrEqualValue(10000),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> scoredAt = GeneratedColumn<int>(
    'scored_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    workKey,
    scoreHalf,
    note,
    createdAt,
    scoredAt,
    updatedAt,
    updatedBy,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ratings';
  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  RatingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RatingsData(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      scoreHalf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score_half'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      scoredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scored_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Ratings createAlias(String alias) {
    return Ratings(attachedDatabase, alias);
  }
}

class RatingsData extends DataClass implements Insertable<RatingsData> {
  final String workKey;
  final int scoreHalf;
  final String? note;
  final int createdAt;
  final int scoredAt;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;
  const RatingsData({
    required this.workKey,
    required this.scoreHalf,
    this.note,
    required this.createdAt,
    required this.scoredAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_key'] = Variable<String>(workKey);
    map['score_half'] = Variable<int>(scoreHalf);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['created_at'] = Variable<int>(createdAt);
    map['scored_at'] = Variable<int>(scoredAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  RatingsCompanion toCompanion(bool nullToAbsent) {
    return RatingsCompanion(
      workKey: Value(workKey),
      scoreHalf: Value(scoreHalf),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      createdAt: Value(createdAt),
      scoredAt: Value(scoredAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory RatingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RatingsData(
      workKey: serializer.fromJson<String>(json['workKey']),
      scoreHalf: serializer.fromJson<int>(json['scoreHalf']),
      note: serializer.fromJson<String?>(json['note']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      scoredAt: serializer.fromJson<int>(json['scoredAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workKey': serializer.toJson<String>(workKey),
      'scoreHalf': serializer.toJson<int>(scoreHalf),
      'note': serializer.toJson<String?>(note),
      'createdAt': serializer.toJson<int>(createdAt),
      'scoredAt': serializer.toJson<int>(scoredAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  RatingsData copyWith({
    String? workKey,
    int? scoreHalf,
    Value<String?> note = const Value.absent(),
    int? createdAt,
    int? scoredAt,
    int? updatedAt,
    String? updatedBy,
    Value<int?> deletedAt = const Value.absent(),
  }) => RatingsData(
    workKey: workKey ?? this.workKey,
    scoreHalf: scoreHalf ?? this.scoreHalf,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    scoredAt: scoredAt ?? this.scoredAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  RatingsData copyWithCompanion(RatingsCompanion data) {
    return RatingsData(
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      scoreHalf: data.scoreHalf.present ? data.scoreHalf.value : this.scoreHalf,
      note: data.note.present ? data.note.value : this.note,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      scoredAt: data.scoredAt.present ? data.scoredAt.value : this.scoredAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RatingsData(')
          ..write('workKey: $workKey, ')
          ..write('scoreHalf: $scoreHalf, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('scoredAt: $scoredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    workKey,
    scoreHalf,
    note,
    createdAt,
    scoredAt,
    updatedAt,
    updatedBy,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RatingsData &&
          other.workKey == this.workKey &&
          other.scoreHalf == this.scoreHalf &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.scoredAt == this.scoredAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt);
}

class RatingsCompanion extends UpdateCompanion<RatingsData> {
  final Value<String> workKey;
  final Value<int> scoreHalf;
  final Value<String?> note;
  final Value<int> createdAt;
  final Value<int> scoredAt;
  final Value<int> updatedAt;
  final Value<String> updatedBy;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const RatingsCompanion({
    this.workKey = const Value.absent(),
    this.scoreHalf = const Value.absent(),
    this.note = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.scoredAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RatingsCompanion.insert({
    required String workKey,
    required int scoreHalf,
    this.note = const Value.absent(),
    required int createdAt,
    required int scoredAt,
    required int updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workKey = Value(workKey),
       scoreHalf = Value(scoreHalf),
       createdAt = Value(createdAt),
       scoredAt = Value(scoredAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy);
  static Insertable<RatingsData> custom({
    Expression<String>? workKey,
    Expression<int>? scoreHalf,
    Expression<String>? note,
    Expression<int>? createdAt,
    Expression<int>? scoredAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedBy,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workKey != null) 'work_key': workKey,
      if (scoreHalf != null) 'score_half': scoreHalf,
      if (note != null) 'note': note,
      if (createdAt != null) 'created_at': createdAt,
      if (scoredAt != null) 'scored_at': scoredAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RatingsCompanion copyWith({
    Value<String>? workKey,
    Value<int>? scoreHalf,
    Value<String?>? note,
    Value<int>? createdAt,
    Value<int>? scoredAt,
    Value<int>? updatedAt,
    Value<String>? updatedBy,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return RatingsCompanion(
      workKey: workKey ?? this.workKey,
      scoreHalf: scoreHalf ?? this.scoreHalf,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
      scoredAt: scoredAt ?? this.scoredAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workKey.present) {
      map['work_key'] = Variable<String>(workKey.value);
    }
    if (scoreHalf.present) {
      map['score_half'] = Variable<int>(scoreHalf.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (scoredAt.present) {
      map['scored_at'] = Variable<int>(scoredAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RatingsCompanion(')
          ..write('workKey: $workKey, ')
          ..write('scoreHalf: $scoreHalf, ')
          ..write('note: $note, ')
          ..write('createdAt: $createdAt, ')
          ..write('scoredAt: $scoredAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Watchlist extends Table with TableInfo<Watchlist, WatchlistData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Watchlist(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES works (work_key)',
    ),
  );
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    workKey,
    addedAt,
    updatedAt,
    updatedBy,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'watchlist';
  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  WatchlistData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchlistData(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}added_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  Watchlist createAlias(String alias) {
    return Watchlist(attachedDatabase, alias);
  }
}

class WatchlistData extends DataClass implements Insertable<WatchlistData> {
  final String workKey;
  final int addedAt;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;
  const WatchlistData({
    required this.workKey,
    required this.addedAt,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_key'] = Variable<String>(workKey);
    map['added_at'] = Variable<int>(addedAt);
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  WatchlistCompanion toCompanion(bool nullToAbsent) {
    return WatchlistCompanion(
      workKey: Value(workKey),
      addedAt: Value(addedAt),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory WatchlistData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchlistData(
      workKey: serializer.fromJson<String>(json['workKey']),
      addedAt: serializer.fromJson<int>(json['addedAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workKey': serializer.toJson<String>(workKey),
      'addedAt': serializer.toJson<int>(addedAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  WatchlistData copyWith({
    String? workKey,
    int? addedAt,
    int? updatedAt,
    String? updatedBy,
    Value<int?> deletedAt = const Value.absent(),
  }) => WatchlistData(
    workKey: workKey ?? this.workKey,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WatchlistData copyWithCompanion(WatchlistCompanion data) {
    return WatchlistData(
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistData(')
          ..write('workKey: $workKey, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(workKey, addedAt, updatedAt, updatedBy, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WatchlistData &&
          other.workKey == this.workKey &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt);
}

class WatchlistCompanion extends UpdateCompanion<WatchlistData> {
  final Value<String> workKey;
  final Value<int> addedAt;
  final Value<int> updatedAt;
  final Value<String> updatedBy;
  final Value<int?> deletedAt;
  final Value<int> rowid;
  const WatchlistCompanion({
    this.workKey = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WatchlistCompanion.insert({
    required String workKey,
    required int addedAt,
    required int updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : workKey = Value(workKey),
       addedAt = Value(addedAt),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy);
  static Insertable<WatchlistData> custom({
    Expression<String>? workKey,
    Expression<int>? addedAt,
    Expression<int>? updatedAt,
    Expression<String>? updatedBy,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workKey != null) 'work_key': workKey,
      if (addedAt != null) 'added_at': addedAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WatchlistCompanion copyWith({
    Value<String>? workKey,
    Value<int>? addedAt,
    Value<int>? updatedAt,
    Value<String>? updatedBy,
    Value<int?>? deletedAt,
    Value<int>? rowid,
  }) {
    return WatchlistCompanion(
      workKey: workKey ?? this.workKey,
      addedAt: addedAt ?? this.addedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workKey.present) {
      map['work_key'] = Variable<String>(workKey.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<int>(addedAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistCompanion(')
          ..write('workKey: $workKey, ')
          ..write('addedAt: $addedAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class FavoritePeople extends Table
    with TableInfo<FavoritePeople, FavoritePeopleData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  FavoritePeople(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<int> personId = GeneratedColumn<int>(
    'person_id',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(personId).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> profilePath = GeneratedColumn<String>(
    'profile_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> deletedAt = GeneratedColumn<int>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    personId,
    name,
    profilePath,
    updatedAt,
    updatedBy,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'favorite_people';
  @override
  Set<GeneratedColumn> get $primaryKey => {personId};
  @override
  FavoritePeopleData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FavoritePeopleData(
      personId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}person_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      profilePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_path'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
      updatedBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}updated_by'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}deleted_at'],
      ),
    );
  }

  @override
  FavoritePeople createAlias(String alias) {
    return FavoritePeople(attachedDatabase, alias);
  }
}

class FavoritePeopleData extends DataClass
    implements Insertable<FavoritePeopleData> {
  final int personId;
  final String name;
  final String? profilePath;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;
  const FavoritePeopleData({
    required this.personId,
    required this.name,
    this.profilePath,
    required this.updatedAt,
    required this.updatedBy,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['person_id'] = Variable<int>(personId);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || profilePath != null) {
      map['profile_path'] = Variable<String>(profilePath);
    }
    map['updated_at'] = Variable<int>(updatedAt);
    map['updated_by'] = Variable<String>(updatedBy);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(deletedAt);
    }
    return map;
  }

  FavoritePeopleCompanion toCompanion(bool nullToAbsent) {
    return FavoritePeopleCompanion(
      personId: Value(personId),
      name: Value(name),
      profilePath: profilePath == null && nullToAbsent
          ? const Value.absent()
          : Value(profilePath),
      updatedAt: Value(updatedAt),
      updatedBy: Value(updatedBy),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory FavoritePeopleData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FavoritePeopleData(
      personId: serializer.fromJson<int>(json['personId']),
      name: serializer.fromJson<String>(json['name']),
      profilePath: serializer.fromJson<String?>(json['profilePath']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
      updatedBy: serializer.fromJson<String>(json['updatedBy']),
      deletedAt: serializer.fromJson<int?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'personId': serializer.toJson<int>(personId),
      'name': serializer.toJson<String>(name),
      'profilePath': serializer.toJson<String?>(profilePath),
      'updatedAt': serializer.toJson<int>(updatedAt),
      'updatedBy': serializer.toJson<String>(updatedBy),
      'deletedAt': serializer.toJson<int?>(deletedAt),
    };
  }

  FavoritePeopleData copyWith({
    int? personId,
    String? name,
    Value<String?> profilePath = const Value.absent(),
    int? updatedAt,
    String? updatedBy,
    Value<int?> deletedAt = const Value.absent(),
  }) => FavoritePeopleData(
    personId: personId ?? this.personId,
    name: name ?? this.name,
    profilePath: profilePath.present ? profilePath.value : this.profilePath,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  FavoritePeopleData copyWithCompanion(FavoritePeopleCompanion data) {
    return FavoritePeopleData(
      personId: data.personId.present ? data.personId.value : this.personId,
      name: data.name.present ? data.name.value : this.name,
      profilePath: data.profilePath.present
          ? data.profilePath.value
          : this.profilePath,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FavoritePeopleData(')
          ..write('personId: $personId, ')
          ..write('name: $name, ')
          ..write('profilePath: $profilePath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(personId, name, profilePath, updatedAt, updatedBy, deletedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FavoritePeopleData &&
          other.personId == this.personId &&
          other.name == this.name &&
          other.profilePath == this.profilePath &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt);
}

class FavoritePeopleCompanion extends UpdateCompanion<FavoritePeopleData> {
  final Value<int> personId;
  final Value<String> name;
  final Value<String?> profilePath;
  final Value<int> updatedAt;
  final Value<String> updatedBy;
  final Value<int?> deletedAt;
  const FavoritePeopleCompanion({
    this.personId = const Value.absent(),
    this.name = const Value.absent(),
    this.profilePath = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.updatedBy = const Value.absent(),
    this.deletedAt = const Value.absent(),
  });
  FavoritePeopleCompanion.insert({
    this.personId = const Value.absent(),
    required String name,
    this.profilePath = const Value.absent(),
    required int updatedAt,
    required String updatedBy,
    this.deletedAt = const Value.absent(),
  }) : name = Value(name),
       updatedAt = Value(updatedAt),
       updatedBy = Value(updatedBy);
  static Insertable<FavoritePeopleData> custom({
    Expression<int>? personId,
    Expression<String>? name,
    Expression<String>? profilePath,
    Expression<int>? updatedAt,
    Expression<String>? updatedBy,
    Expression<int>? deletedAt,
  }) {
    return RawValuesInsertable({
      if (personId != null) 'person_id': personId,
      if (name != null) 'name': name,
      if (profilePath != null) 'profile_path': profilePath,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (updatedBy != null) 'updated_by': updatedBy,
      if (deletedAt != null) 'deleted_at': deletedAt,
    });
  }

  FavoritePeopleCompanion copyWith({
    Value<int>? personId,
    Value<String>? name,
    Value<String?>? profilePath,
    Value<int>? updatedAt,
    Value<String>? updatedBy,
    Value<int?>? deletedAt,
  }) {
    return FavoritePeopleCompanion(
      personId: personId ?? this.personId,
      name: name ?? this.name,
      profilePath: profilePath ?? this.profilePath,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
      deletedAt: deletedAt ?? this.deletedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (personId.present) {
      map['person_id'] = Variable<int>(personId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (profilePath.present) {
      map['profile_path'] = Variable<String>(profilePath.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (updatedBy.present) {
      map['updated_by'] = Variable<String>(updatedBy.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(deletedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FavoritePeopleCompanion(')
          ..write('personId: $personId, ')
          ..write('name: $name, ')
          ..write('profilePath: $profilePath, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('updatedBy: $updatedBy, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }
}

class PairComparisons extends Table
    with TableInfo<PairComparisons, PairComparisonsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  PairComparisons(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> comparisonKey = GeneratedColumn<String>(
    'comparison_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> leftKey = GeneratedColumn<String>(
    'left_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> rightKey = GeneratedColumn<String>(
    'right_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> leftScoreHalf = GeneratedColumn<int>(
    'left_score_half',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(leftScoreHalf).isBetweenValues(2, 20),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> rightScoreHalf = GeneratedColumn<int>(
    'right_score_half',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(rightScoreHalf).isBetweenValues(2, 20),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> leftScoredAt = GeneratedColumn<int>(
    'left_scored_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> rightScoredAt = GeneratedColumn<int>(
    'right_scored_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> leftResultScoreHalf = GeneratedColumn<int>(
    'left_result_score_half',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(leftResultScoreHalf).isBetweenValues(2, 20),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> rightResultScoreHalf = GeneratedColumn<int>(
    'right_result_score_half',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(rightResultScoreHalf).isBetweenValues(2, 20),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> leftResultScoredAt = GeneratedColumn<int>(
    'left_result_scored_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> rightResultScoredAt = GeneratedColumn<int>(
    'right_result_scored_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> preference = GeneratedColumn<String>(
    'preference',
    aliasedName,
    false,
    check: () => preference.isIn(i4.PairPreference.values.map((p) => p.name)),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> answeredAt = GeneratedColumn<int>(
    'answered_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> answeredBy = GeneratedColumn<String>(
    'answered_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    comparisonKey,
    leftKey,
    rightKey,
    leftScoreHalf,
    rightScoreHalf,
    leftScoredAt,
    rightScoredAt,
    leftResultScoreHalf,
    rightResultScoreHalf,
    leftResultScoredAt,
    rightResultScoredAt,
    preference,
    day,
    answeredAt,
    answeredBy,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pair_comparisons';
  @override
  Set<GeneratedColumn> get $primaryKey => {comparisonKey};
  @override
  PairComparisonsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PairComparisonsData(
      comparisonKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}comparison_key'],
      )!,
      leftKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}left_key'],
      )!,
      rightKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}right_key'],
      )!,
      leftScoreHalf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}left_score_half'],
      )!,
      rightScoreHalf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}right_score_half'],
      )!,
      leftScoredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}left_scored_at'],
      )!,
      rightScoredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}right_scored_at'],
      )!,
      leftResultScoreHalf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}left_result_score_half'],
      )!,
      rightResultScoreHalf: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}right_result_score_half'],
      )!,
      leftResultScoredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}left_result_scored_at'],
      )!,
      rightResultScoredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}right_result_scored_at'],
      )!,
      preference: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}preference'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      answeredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}answered_at'],
      )!,
      answeredBy: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}answered_by'],
      )!,
    );
  }

  @override
  PairComparisons createAlias(String alias) {
    return PairComparisons(attachedDatabase, alias);
  }
}

class PairComparisonsData extends DataClass
    implements Insertable<PairComparisonsData> {
  final String comparisonKey;
  final String leftKey;
  final String rightKey;
  final int leftScoreHalf;
  final int rightScoreHalf;
  final int leftScoredAt;
  final int rightScoredAt;
  final int leftResultScoreHalf;
  final int rightResultScoreHalf;
  final int leftResultScoredAt;
  final int rightResultScoredAt;
  final String preference;
  final String day;
  final int answeredAt;
  final String answeredBy;
  const PairComparisonsData({
    required this.comparisonKey,
    required this.leftKey,
    required this.rightKey,
    required this.leftScoreHalf,
    required this.rightScoreHalf,
    required this.leftScoredAt,
    required this.rightScoredAt,
    required this.leftResultScoreHalf,
    required this.rightResultScoreHalf,
    required this.leftResultScoredAt,
    required this.rightResultScoredAt,
    required this.preference,
    required this.day,
    required this.answeredAt,
    required this.answeredBy,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['comparison_key'] = Variable<String>(comparisonKey);
    map['left_key'] = Variable<String>(leftKey);
    map['right_key'] = Variable<String>(rightKey);
    map['left_score_half'] = Variable<int>(leftScoreHalf);
    map['right_score_half'] = Variable<int>(rightScoreHalf);
    map['left_scored_at'] = Variable<int>(leftScoredAt);
    map['right_scored_at'] = Variable<int>(rightScoredAt);
    map['left_result_score_half'] = Variable<int>(leftResultScoreHalf);
    map['right_result_score_half'] = Variable<int>(rightResultScoreHalf);
    map['left_result_scored_at'] = Variable<int>(leftResultScoredAt);
    map['right_result_scored_at'] = Variable<int>(rightResultScoredAt);
    map['preference'] = Variable<String>(preference);
    map['day'] = Variable<String>(day);
    map['answered_at'] = Variable<int>(answeredAt);
    map['answered_by'] = Variable<String>(answeredBy);
    return map;
  }

  PairComparisonsCompanion toCompanion(bool nullToAbsent) {
    return PairComparisonsCompanion(
      comparisonKey: Value(comparisonKey),
      leftKey: Value(leftKey),
      rightKey: Value(rightKey),
      leftScoreHalf: Value(leftScoreHalf),
      rightScoreHalf: Value(rightScoreHalf),
      leftScoredAt: Value(leftScoredAt),
      rightScoredAt: Value(rightScoredAt),
      leftResultScoreHalf: Value(leftResultScoreHalf),
      rightResultScoreHalf: Value(rightResultScoreHalf),
      leftResultScoredAt: Value(leftResultScoredAt),
      rightResultScoredAt: Value(rightResultScoredAt),
      preference: Value(preference),
      day: Value(day),
      answeredAt: Value(answeredAt),
      answeredBy: Value(answeredBy),
    );
  }

  factory PairComparisonsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PairComparisonsData(
      comparisonKey: serializer.fromJson<String>(json['comparisonKey']),
      leftKey: serializer.fromJson<String>(json['leftKey']),
      rightKey: serializer.fromJson<String>(json['rightKey']),
      leftScoreHalf: serializer.fromJson<int>(json['leftScoreHalf']),
      rightScoreHalf: serializer.fromJson<int>(json['rightScoreHalf']),
      leftScoredAt: serializer.fromJson<int>(json['leftScoredAt']),
      rightScoredAt: serializer.fromJson<int>(json['rightScoredAt']),
      leftResultScoreHalf: serializer.fromJson<int>(
        json['leftResultScoreHalf'],
      ),
      rightResultScoreHalf: serializer.fromJson<int>(
        json['rightResultScoreHalf'],
      ),
      leftResultScoredAt: serializer.fromJson<int>(json['leftResultScoredAt']),
      rightResultScoredAt: serializer.fromJson<int>(
        json['rightResultScoredAt'],
      ),
      preference: serializer.fromJson<String>(json['preference']),
      day: serializer.fromJson<String>(json['day']),
      answeredAt: serializer.fromJson<int>(json['answeredAt']),
      answeredBy: serializer.fromJson<String>(json['answeredBy']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'comparisonKey': serializer.toJson<String>(comparisonKey),
      'leftKey': serializer.toJson<String>(leftKey),
      'rightKey': serializer.toJson<String>(rightKey),
      'leftScoreHalf': serializer.toJson<int>(leftScoreHalf),
      'rightScoreHalf': serializer.toJson<int>(rightScoreHalf),
      'leftScoredAt': serializer.toJson<int>(leftScoredAt),
      'rightScoredAt': serializer.toJson<int>(rightScoredAt),
      'leftResultScoreHalf': serializer.toJson<int>(leftResultScoreHalf),
      'rightResultScoreHalf': serializer.toJson<int>(rightResultScoreHalf),
      'leftResultScoredAt': serializer.toJson<int>(leftResultScoredAt),
      'rightResultScoredAt': serializer.toJson<int>(rightResultScoredAt),
      'preference': serializer.toJson<String>(preference),
      'day': serializer.toJson<String>(day),
      'answeredAt': serializer.toJson<int>(answeredAt),
      'answeredBy': serializer.toJson<String>(answeredBy),
    };
  }

  PairComparisonsData copyWith({
    String? comparisonKey,
    String? leftKey,
    String? rightKey,
    int? leftScoreHalf,
    int? rightScoreHalf,
    int? leftScoredAt,
    int? rightScoredAt,
    int? leftResultScoreHalf,
    int? rightResultScoreHalf,
    int? leftResultScoredAt,
    int? rightResultScoredAt,
    String? preference,
    String? day,
    int? answeredAt,
    String? answeredBy,
  }) => PairComparisonsData(
    comparisonKey: comparisonKey ?? this.comparisonKey,
    leftKey: leftKey ?? this.leftKey,
    rightKey: rightKey ?? this.rightKey,
    leftScoreHalf: leftScoreHalf ?? this.leftScoreHalf,
    rightScoreHalf: rightScoreHalf ?? this.rightScoreHalf,
    leftScoredAt: leftScoredAt ?? this.leftScoredAt,
    rightScoredAt: rightScoredAt ?? this.rightScoredAt,
    leftResultScoreHalf: leftResultScoreHalf ?? this.leftResultScoreHalf,
    rightResultScoreHalf: rightResultScoreHalf ?? this.rightResultScoreHalf,
    leftResultScoredAt: leftResultScoredAt ?? this.leftResultScoredAt,
    rightResultScoredAt: rightResultScoredAt ?? this.rightResultScoredAt,
    preference: preference ?? this.preference,
    day: day ?? this.day,
    answeredAt: answeredAt ?? this.answeredAt,
    answeredBy: answeredBy ?? this.answeredBy,
  );
  PairComparisonsData copyWithCompanion(PairComparisonsCompanion data) {
    return PairComparisonsData(
      comparisonKey: data.comparisonKey.present
          ? data.comparisonKey.value
          : this.comparisonKey,
      leftKey: data.leftKey.present ? data.leftKey.value : this.leftKey,
      rightKey: data.rightKey.present ? data.rightKey.value : this.rightKey,
      leftScoreHalf: data.leftScoreHalf.present
          ? data.leftScoreHalf.value
          : this.leftScoreHalf,
      rightScoreHalf: data.rightScoreHalf.present
          ? data.rightScoreHalf.value
          : this.rightScoreHalf,
      leftScoredAt: data.leftScoredAt.present
          ? data.leftScoredAt.value
          : this.leftScoredAt,
      rightScoredAt: data.rightScoredAt.present
          ? data.rightScoredAt.value
          : this.rightScoredAt,
      leftResultScoreHalf: data.leftResultScoreHalf.present
          ? data.leftResultScoreHalf.value
          : this.leftResultScoreHalf,
      rightResultScoreHalf: data.rightResultScoreHalf.present
          ? data.rightResultScoreHalf.value
          : this.rightResultScoreHalf,
      leftResultScoredAt: data.leftResultScoredAt.present
          ? data.leftResultScoredAt.value
          : this.leftResultScoredAt,
      rightResultScoredAt: data.rightResultScoredAt.present
          ? data.rightResultScoredAt.value
          : this.rightResultScoredAt,
      preference: data.preference.present
          ? data.preference.value
          : this.preference,
      day: data.day.present ? data.day.value : this.day,
      answeredAt: data.answeredAt.present
          ? data.answeredAt.value
          : this.answeredAt,
      answeredBy: data.answeredBy.present
          ? data.answeredBy.value
          : this.answeredBy,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PairComparisonsData(')
          ..write('comparisonKey: $comparisonKey, ')
          ..write('leftKey: $leftKey, ')
          ..write('rightKey: $rightKey, ')
          ..write('leftScoreHalf: $leftScoreHalf, ')
          ..write('rightScoreHalf: $rightScoreHalf, ')
          ..write('leftScoredAt: $leftScoredAt, ')
          ..write('rightScoredAt: $rightScoredAt, ')
          ..write('leftResultScoreHalf: $leftResultScoreHalf, ')
          ..write('rightResultScoreHalf: $rightResultScoreHalf, ')
          ..write('leftResultScoredAt: $leftResultScoredAt, ')
          ..write('rightResultScoredAt: $rightResultScoredAt, ')
          ..write('preference: $preference, ')
          ..write('day: $day, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('answeredBy: $answeredBy')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    comparisonKey,
    leftKey,
    rightKey,
    leftScoreHalf,
    rightScoreHalf,
    leftScoredAt,
    rightScoredAt,
    leftResultScoreHalf,
    rightResultScoreHalf,
    leftResultScoredAt,
    rightResultScoredAt,
    preference,
    day,
    answeredAt,
    answeredBy,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PairComparisonsData &&
          other.comparisonKey == this.comparisonKey &&
          other.leftKey == this.leftKey &&
          other.rightKey == this.rightKey &&
          other.leftScoreHalf == this.leftScoreHalf &&
          other.rightScoreHalf == this.rightScoreHalf &&
          other.leftScoredAt == this.leftScoredAt &&
          other.rightScoredAt == this.rightScoredAt &&
          other.leftResultScoreHalf == this.leftResultScoreHalf &&
          other.rightResultScoreHalf == this.rightResultScoreHalf &&
          other.leftResultScoredAt == this.leftResultScoredAt &&
          other.rightResultScoredAt == this.rightResultScoredAt &&
          other.preference == this.preference &&
          other.day == this.day &&
          other.answeredAt == this.answeredAt &&
          other.answeredBy == this.answeredBy);
}

class PairComparisonsCompanion extends UpdateCompanion<PairComparisonsData> {
  final Value<String> comparisonKey;
  final Value<String> leftKey;
  final Value<String> rightKey;
  final Value<int> leftScoreHalf;
  final Value<int> rightScoreHalf;
  final Value<int> leftScoredAt;
  final Value<int> rightScoredAt;
  final Value<int> leftResultScoreHalf;
  final Value<int> rightResultScoreHalf;
  final Value<int> leftResultScoredAt;
  final Value<int> rightResultScoredAt;
  final Value<String> preference;
  final Value<String> day;
  final Value<int> answeredAt;
  final Value<String> answeredBy;
  final Value<int> rowid;
  const PairComparisonsCompanion({
    this.comparisonKey = const Value.absent(),
    this.leftKey = const Value.absent(),
    this.rightKey = const Value.absent(),
    this.leftScoreHalf = const Value.absent(),
    this.rightScoreHalf = const Value.absent(),
    this.leftScoredAt = const Value.absent(),
    this.rightScoredAt = const Value.absent(),
    this.leftResultScoreHalf = const Value.absent(),
    this.rightResultScoreHalf = const Value.absent(),
    this.leftResultScoredAt = const Value.absent(),
    this.rightResultScoredAt = const Value.absent(),
    this.preference = const Value.absent(),
    this.day = const Value.absent(),
    this.answeredAt = const Value.absent(),
    this.answeredBy = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  PairComparisonsCompanion.insert({
    required String comparisonKey,
    required String leftKey,
    required String rightKey,
    required int leftScoreHalf,
    required int rightScoreHalf,
    required int leftScoredAt,
    required int rightScoredAt,
    required int leftResultScoreHalf,
    required int rightResultScoreHalf,
    required int leftResultScoredAt,
    required int rightResultScoredAt,
    required String preference,
    required String day,
    required int answeredAt,
    required String answeredBy,
    this.rowid = const Value.absent(),
  }) : comparisonKey = Value(comparisonKey),
       leftKey = Value(leftKey),
       rightKey = Value(rightKey),
       leftScoreHalf = Value(leftScoreHalf),
       rightScoreHalf = Value(rightScoreHalf),
       leftScoredAt = Value(leftScoredAt),
       rightScoredAt = Value(rightScoredAt),
       leftResultScoreHalf = Value(leftResultScoreHalf),
       rightResultScoreHalf = Value(rightResultScoreHalf),
       leftResultScoredAt = Value(leftResultScoredAt),
       rightResultScoredAt = Value(rightResultScoredAt),
       preference = Value(preference),
       day = Value(day),
       answeredAt = Value(answeredAt),
       answeredBy = Value(answeredBy);
  static Insertable<PairComparisonsData> custom({
    Expression<String>? comparisonKey,
    Expression<String>? leftKey,
    Expression<String>? rightKey,
    Expression<int>? leftScoreHalf,
    Expression<int>? rightScoreHalf,
    Expression<int>? leftScoredAt,
    Expression<int>? rightScoredAt,
    Expression<int>? leftResultScoreHalf,
    Expression<int>? rightResultScoreHalf,
    Expression<int>? leftResultScoredAt,
    Expression<int>? rightResultScoredAt,
    Expression<String>? preference,
    Expression<String>? day,
    Expression<int>? answeredAt,
    Expression<String>? answeredBy,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (comparisonKey != null) 'comparison_key': comparisonKey,
      if (leftKey != null) 'left_key': leftKey,
      if (rightKey != null) 'right_key': rightKey,
      if (leftScoreHalf != null) 'left_score_half': leftScoreHalf,
      if (rightScoreHalf != null) 'right_score_half': rightScoreHalf,
      if (leftScoredAt != null) 'left_scored_at': leftScoredAt,
      if (rightScoredAt != null) 'right_scored_at': rightScoredAt,
      if (leftResultScoreHalf != null)
        'left_result_score_half': leftResultScoreHalf,
      if (rightResultScoreHalf != null)
        'right_result_score_half': rightResultScoreHalf,
      if (leftResultScoredAt != null)
        'left_result_scored_at': leftResultScoredAt,
      if (rightResultScoredAt != null)
        'right_result_scored_at': rightResultScoredAt,
      if (preference != null) 'preference': preference,
      if (day != null) 'day': day,
      if (answeredAt != null) 'answered_at': answeredAt,
      if (answeredBy != null) 'answered_by': answeredBy,
      if (rowid != null) 'rowid': rowid,
    });
  }

  PairComparisonsCompanion copyWith({
    Value<String>? comparisonKey,
    Value<String>? leftKey,
    Value<String>? rightKey,
    Value<int>? leftScoreHalf,
    Value<int>? rightScoreHalf,
    Value<int>? leftScoredAt,
    Value<int>? rightScoredAt,
    Value<int>? leftResultScoreHalf,
    Value<int>? rightResultScoreHalf,
    Value<int>? leftResultScoredAt,
    Value<int>? rightResultScoredAt,
    Value<String>? preference,
    Value<String>? day,
    Value<int>? answeredAt,
    Value<String>? answeredBy,
    Value<int>? rowid,
  }) {
    return PairComparisonsCompanion(
      comparisonKey: comparisonKey ?? this.comparisonKey,
      leftKey: leftKey ?? this.leftKey,
      rightKey: rightKey ?? this.rightKey,
      leftScoreHalf: leftScoreHalf ?? this.leftScoreHalf,
      rightScoreHalf: rightScoreHalf ?? this.rightScoreHalf,
      leftScoredAt: leftScoredAt ?? this.leftScoredAt,
      rightScoredAt: rightScoredAt ?? this.rightScoredAt,
      leftResultScoreHalf: leftResultScoreHalf ?? this.leftResultScoreHalf,
      rightResultScoreHalf: rightResultScoreHalf ?? this.rightResultScoreHalf,
      leftResultScoredAt: leftResultScoredAt ?? this.leftResultScoredAt,
      rightResultScoredAt: rightResultScoredAt ?? this.rightResultScoredAt,
      preference: preference ?? this.preference,
      day: day ?? this.day,
      answeredAt: answeredAt ?? this.answeredAt,
      answeredBy: answeredBy ?? this.answeredBy,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (comparisonKey.present) {
      map['comparison_key'] = Variable<String>(comparisonKey.value);
    }
    if (leftKey.present) {
      map['left_key'] = Variable<String>(leftKey.value);
    }
    if (rightKey.present) {
      map['right_key'] = Variable<String>(rightKey.value);
    }
    if (leftScoreHalf.present) {
      map['left_score_half'] = Variable<int>(leftScoreHalf.value);
    }
    if (rightScoreHalf.present) {
      map['right_score_half'] = Variable<int>(rightScoreHalf.value);
    }
    if (leftScoredAt.present) {
      map['left_scored_at'] = Variable<int>(leftScoredAt.value);
    }
    if (rightScoredAt.present) {
      map['right_scored_at'] = Variable<int>(rightScoredAt.value);
    }
    if (leftResultScoreHalf.present) {
      map['left_result_score_half'] = Variable<int>(leftResultScoreHalf.value);
    }
    if (rightResultScoreHalf.present) {
      map['right_result_score_half'] = Variable<int>(
        rightResultScoreHalf.value,
      );
    }
    if (leftResultScoredAt.present) {
      map['left_result_scored_at'] = Variable<int>(leftResultScoredAt.value);
    }
    if (rightResultScoredAt.present) {
      map['right_result_scored_at'] = Variable<int>(rightResultScoredAt.value);
    }
    if (preference.present) {
      map['preference'] = Variable<String>(preference.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (answeredAt.present) {
      map['answered_at'] = Variable<int>(answeredAt.value);
    }
    if (answeredBy.present) {
      map['answered_by'] = Variable<String>(answeredBy.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PairComparisonsCompanion(')
          ..write('comparisonKey: $comparisonKey, ')
          ..write('leftKey: $leftKey, ')
          ..write('rightKey: $rightKey, ')
          ..write('leftScoreHalf: $leftScoreHalf, ')
          ..write('rightScoreHalf: $rightScoreHalf, ')
          ..write('leftScoredAt: $leftScoredAt, ')
          ..write('rightScoredAt: $rightScoredAt, ')
          ..write('leftResultScoreHalf: $leftResultScoreHalf, ')
          ..write('rightResultScoreHalf: $rightResultScoreHalf, ')
          ..write('leftResultScoredAt: $leftResultScoredAt, ')
          ..write('rightResultScoredAt: $rightResultScoredAt, ')
          ..write('preference: $preference, ')
          ..write('day: $day, ')
          ..write('answeredAt: $answeredAt, ')
          ..write('answeredBy: $answeredBy, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ExternalRatings extends Table
    with TableInfo<ExternalRatings, ExternalRatingsData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ExternalRatings(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    check: () => source.isIn(i5.RatingSource.values.map((s) => s.name)),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    check: () => status.isIn(i5.RatingStatus.values.map((s) => s.name)),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<int> scale = GeneratedColumn<int>(
    'scale',
    aliasedName,
    false,
    check: () => scale.isIn(const [10, 100]),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> votes = GeneratedColumn<int>(
    'votes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  late final GeneratedColumn<String> via = GeneratedColumn<String>(
    'via',
    aliasedName,
    false,
    check: () => via.isIn(i5.ApiSource.values.map((s) => s.name)),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> fetchedAt = GeneratedColumn<int>(
    'fetched_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    workKey,
    source,
    status,
    value,
    scale,
    votes,
    via,
    fetchedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'external_ratings';
  @override
  Set<GeneratedColumn> get $primaryKey => {workKey, source};
  @override
  ExternalRatingsData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExternalRatingsData(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      ),
      scale: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}scale'],
      )!,
      votes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}votes'],
      ),
      via: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}via'],
      )!,
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  ExternalRatings createAlias(String alias) {
    return ExternalRatings(attachedDatabase, alias);
  }
}

class ExternalRatingsData extends DataClass
    implements Insertable<ExternalRatingsData> {
  final String workKey;
  final String source;
  final String status;
  final double? value;
  final int scale;
  final int? votes;
  final String via;
  final int fetchedAt;
  const ExternalRatingsData({
    required this.workKey,
    required this.source,
    required this.status,
    this.value,
    required this.scale,
    this.votes,
    required this.via,
    required this.fetchedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['work_key'] = Variable<String>(workKey);
    map['source'] = Variable<String>(source);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    map['scale'] = Variable<int>(scale);
    if (!nullToAbsent || votes != null) {
      map['votes'] = Variable<int>(votes);
    }
    map['via'] = Variable<String>(via);
    map['fetched_at'] = Variable<int>(fetchedAt);
    return map;
  }

  ExternalRatingsCompanion toCompanion(bool nullToAbsent) {
    return ExternalRatingsCompanion(
      workKey: Value(workKey),
      source: Value(source),
      status: Value(status),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
      scale: Value(scale),
      votes: votes == null && nullToAbsent
          ? const Value.absent()
          : Value(votes),
      via: Value(via),
      fetchedAt: Value(fetchedAt),
    );
  }

  factory ExternalRatingsData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExternalRatingsData(
      workKey: serializer.fromJson<String>(json['workKey']),
      source: serializer.fromJson<String>(json['source']),
      status: serializer.fromJson<String>(json['status']),
      value: serializer.fromJson<double?>(json['value']),
      scale: serializer.fromJson<int>(json['scale']),
      votes: serializer.fromJson<int?>(json['votes']),
      via: serializer.fromJson<String>(json['via']),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workKey': serializer.toJson<String>(workKey),
      'source': serializer.toJson<String>(source),
      'status': serializer.toJson<String>(status),
      'value': serializer.toJson<double?>(value),
      'scale': serializer.toJson<int>(scale),
      'votes': serializer.toJson<int?>(votes),
      'via': serializer.toJson<String>(via),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  ExternalRatingsData copyWith({
    String? workKey,
    String? source,
    String? status,
    Value<double?> value = const Value.absent(),
    int? scale,
    Value<int?> votes = const Value.absent(),
    String? via,
    int? fetchedAt,
  }) => ExternalRatingsData(
    workKey: workKey ?? this.workKey,
    source: source ?? this.source,
    status: status ?? this.status,
    value: value.present ? value.value : this.value,
    scale: scale ?? this.scale,
    votes: votes.present ? votes.value : this.votes,
    via: via ?? this.via,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  ExternalRatingsData copyWithCompanion(ExternalRatingsCompanion data) {
    return ExternalRatingsData(
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      source: data.source.present ? data.source.value : this.source,
      status: data.status.present ? data.status.value : this.status,
      value: data.value.present ? data.value.value : this.value,
      scale: data.scale.present ? data.scale.value : this.scale,
      votes: data.votes.present ? data.votes.value : this.votes,
      via: data.via.present ? data.via.value : this.via,
      fetchedAt: data.fetchedAt.present ? data.fetchedAt.value : this.fetchedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ExternalRatingsData(')
          ..write('workKey: $workKey, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('value: $value, ')
          ..write('scale: $scale, ')
          ..write('votes: $votes, ')
          ..write('via: $via, ')
          ..write('fetchedAt: $fetchedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(workKey, source, status, value, scale, votes, via, fetchedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ExternalRatingsData &&
          other.workKey == this.workKey &&
          other.source == this.source &&
          other.status == this.status &&
          other.value == this.value &&
          other.scale == this.scale &&
          other.votes == this.votes &&
          other.via == this.via &&
          other.fetchedAt == this.fetchedAt);
}

class ExternalRatingsCompanion extends UpdateCompanion<ExternalRatingsData> {
  final Value<String> workKey;
  final Value<String> source;
  final Value<String> status;
  final Value<double?> value;
  final Value<int> scale;
  final Value<int?> votes;
  final Value<String> via;
  final Value<int> fetchedAt;
  final Value<int> rowid;
  const ExternalRatingsCompanion({
    this.workKey = const Value.absent(),
    this.source = const Value.absent(),
    this.status = const Value.absent(),
    this.value = const Value.absent(),
    this.scale = const Value.absent(),
    this.votes = const Value.absent(),
    this.via = const Value.absent(),
    this.fetchedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExternalRatingsCompanion.insert({
    required String workKey,
    required String source,
    required String status,
    this.value = const Value.absent(),
    required int scale,
    this.votes = const Value.absent(),
    required String via,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : workKey = Value(workKey),
       source = Value(source),
       status = Value(status),
       scale = Value(scale),
       via = Value(via),
       fetchedAt = Value(fetchedAt);
  static Insertable<ExternalRatingsData> custom({
    Expression<String>? workKey,
    Expression<String>? source,
    Expression<String>? status,
    Expression<double>? value,
    Expression<int>? scale,
    Expression<int>? votes,
    Expression<String>? via,
    Expression<int>? fetchedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (workKey != null) 'work_key': workKey,
      if (source != null) 'source': source,
      if (status != null) 'status': status,
      if (value != null) 'value': value,
      if (scale != null) 'scale': scale,
      if (votes != null) 'votes': votes,
      if (via != null) 'via': via,
      if (fetchedAt != null) 'fetched_at': fetchedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExternalRatingsCompanion copyWith({
    Value<String>? workKey,
    Value<String>? source,
    Value<String>? status,
    Value<double?>? value,
    Value<int>? scale,
    Value<int?>? votes,
    Value<String>? via,
    Value<int>? fetchedAt,
    Value<int>? rowid,
  }) {
    return ExternalRatingsCompanion(
      workKey: workKey ?? this.workKey,
      source: source ?? this.source,
      status: status ?? this.status,
      value: value ?? this.value,
      scale: scale ?? this.scale,
      votes: votes ?? this.votes,
      via: via ?? this.via,
      fetchedAt: fetchedAt ?? this.fetchedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (workKey.present) {
      map['work_key'] = Variable<String>(workKey.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (scale.present) {
      map['scale'] = Variable<int>(scale.value);
    }
    if (votes.present) {
      map['votes'] = Variable<int>(votes.value);
    }
    if (via.present) {
      map['via'] = Variable<String>(via.value);
    }
    if (fetchedAt.present) {
      map['fetched_at'] = Variable<int>(fetchedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExternalRatingsCompanion(')
          ..write('workKey: $workKey, ')
          ..write('source: $source, ')
          ..write('status: $status, ')
          ..write('value: $value, ')
          ..write('scale: $scale, ')
          ..write('votes: $votes, ')
          ..write('via: $via, ')
          ..write('fetchedAt: $fetchedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class ApiBudget extends Table with TableInfo<ApiBudget, ApiBudgetData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  ApiBudget(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    check: () => source.isIn(i5.ApiSource.values.map((s) => s.name)),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<int> used = GeneratedColumn<int>(
    'used',
    aliasedName,
    false,
    check: () => i3.ComparableExpr(used).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const CustomExpression('0'),
  );
  @override
  List<GeneratedColumn> get $columns => [source, day, used];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_budget';
  @override
  Set<GeneratedColumn> get $primaryKey => {source, day};
  @override
  ApiBudgetData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiBudgetData(
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      used: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used'],
      )!,
    );
  }

  @override
  ApiBudget createAlias(String alias) {
    return ApiBudget(attachedDatabase, alias);
  }
}

class ApiBudgetData extends DataClass implements Insertable<ApiBudgetData> {
  final String source;
  final String day;
  final int used;
  const ApiBudgetData({
    required this.source,
    required this.day,
    required this.used,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['source'] = Variable<String>(source);
    map['day'] = Variable<String>(day);
    map['used'] = Variable<int>(used);
    return map;
  }

  ApiBudgetCompanion toCompanion(bool nullToAbsent) {
    return ApiBudgetCompanion(
      source: Value(source),
      day: Value(day),
      used: Value(used),
    );
  }

  factory ApiBudgetData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiBudgetData(
      source: serializer.fromJson<String>(json['source']),
      day: serializer.fromJson<String>(json['day']),
      used: serializer.fromJson<int>(json['used']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(source),
      'day': serializer.toJson<String>(day),
      'used': serializer.toJson<int>(used),
    };
  }

  ApiBudgetData copyWith({String? source, String? day, int? used}) =>
      ApiBudgetData(
        source: source ?? this.source,
        day: day ?? this.day,
        used: used ?? this.used,
      );
  ApiBudgetData copyWithCompanion(ApiBudgetCompanion data) {
    return ApiBudgetData(
      source: data.source.present ? data.source.value : this.source,
      day: data.day.present ? data.day.value : this.day,
      used: data.used.present ? data.used.value : this.used,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiBudgetData(')
          ..write('source: $source, ')
          ..write('day: $day, ')
          ..write('used: $used')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(source, day, used);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ApiBudgetData &&
          other.source == this.source &&
          other.day == this.day &&
          other.used == this.used);
}

class ApiBudgetCompanion extends UpdateCompanion<ApiBudgetData> {
  final Value<String> source;
  final Value<String> day;
  final Value<int> used;
  final Value<int> rowid;
  const ApiBudgetCompanion({
    this.source = const Value.absent(),
    this.day = const Value.absent(),
    this.used = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ApiBudgetCompanion.insert({
    required String source,
    required String day,
    this.used = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       day = Value(day);
  static Insertable<ApiBudgetData> custom({
    Expression<String>? source,
    Expression<String>? day,
    Expression<int>? used,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (source != null) 'source': source,
      if (day != null) 'day': day,
      if (used != null) 'used': used,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ApiBudgetCompanion copyWith({
    Value<String>? source,
    Value<String>? day,
    Value<int>? used,
    Value<int>? rowid,
  }) {
    return ApiBudgetCompanion(
      source: source ?? this.source,
      day: day ?? this.day,
      used: used ?? this.used,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (used.present) {
      map['used'] = Variable<int>(used.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ApiBudgetCompanion(')
          ..write('source: $source, ')
          ..write('day: $day, ')
          ..write('used: $used, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncState extends Table with TableInfo<SyncState, SyncStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncState(this.attachedDatabase, [this._alias]);
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_state';
  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  SyncState createAlias(String alias) {
    return SyncState(attachedDatabase, alias);
  }
}

class SyncStateData extends DataClass implements Insertable<SyncStateData> {
  final String key;
  final String value;
  const SyncStateData({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SyncStateCompanion toCompanion(bool nullToAbsent) {
    return SyncStateCompanion(key: Value(key), value: Value(value));
  }

  factory SyncStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  SyncStateData copyWith({String? key, String? value}) =>
      SyncStateData(key: key ?? this.key, value: value ?? this.value);
  SyncStateData copyWithCompanion(SyncStateCompanion data) {
    return SyncStateData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateData(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncStateData &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateData> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SyncStateCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncStateCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<SyncStateData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncStateCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SyncStateCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class DatabaseAtV3 extends GeneratedDatabase {
  DatabaseAtV3(QueryExecutor e) : super(e);
  late final Works works = Works(this);
  late final Ratings ratings = Ratings(this);
  late final Watchlist watchlist = Watchlist(this);
  late final FavoritePeople favoritePeople = FavoritePeople(this);
  late final PairComparisons pairComparisons = PairComparisons(this);
  late final ExternalRatings externalRatings = ExternalRatings(this);
  late final ApiBudget apiBudget = ApiBudget(this);
  late final SyncState syncState = SyncState(this);
  late final Index worksKind = Index(
    'works_kind',
    'CREATE INDEX works_kind ON works (kind)',
  );
  late final Index worksParentKey = Index(
    'works_parent_key',
    'CREATE INDEX works_parent_key ON works (parent_key)',
  );
  late final Index worksYear = Index(
    'works_year',
    'CREATE INDEX works_year ON works (year)',
  );
  late final Index ratingsLiveScore = Index(
    'ratings_live_score',
    'CREATE INDEX ratings_live_score ON ratings (deleted_at, score_half)',
  );
  late final Index ratingsScoredAt = Index(
    'ratings_scored_at',
    'CREATE INDEX ratings_scored_at ON ratings (scored_at)',
  );
  late final Index pairComparisonsDay = Index(
    'pair_comparisons_day',
    'CREATE INDEX pair_comparisons_day ON pair_comparisons (day)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    works,
    ratings,
    watchlist,
    favoritePeople,
    pairComparisons,
    externalRatings,
    apiBudget,
    syncState,
    worksKind,
    worksParentKey,
    worksYear,
    ratingsLiveScore,
    ratingsScoredAt,
    pairComparisonsDay,
  ];
  @override
  int get schemaVersion => 3;
}
