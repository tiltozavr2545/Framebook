// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $WorksTable extends Works with TableInfo<$WorksTable, Work> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workKeyMeta = const VerificationMeta(
    'workKey',
  );
  @override
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<WorkKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        check: () => kind.isIn(WorkKind.values.map((k) => k.name)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<WorkKind>($WorksTable.$converterkind);
  static const VerificationMeta _parentKeyMeta = const VerificationMeta(
    'parentKey',
  );
  @override
  late final GeneratedColumn<String> parentKey = GeneratedColumn<String>(
    'parent_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tmdbIdMeta = const VerificationMeta('tmdbId');
  @override
  late final GeneratedColumn<int> tmdbId = GeneratedColumn<int>(
    'tmdb_id',
    aliasedName,
    false,
    check: () => ComparableExpr(tmdbId).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _seasonNumberMeta = const VerificationMeta(
    'seasonNumber',
  );
  @override
  late final GeneratedColumn<int> seasonNumber = GeneratedColumn<int>(
    'season_number',
    aliasedName,
    true,
    check: () => ComparableExpr(seasonNumber).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _episodeNumberMeta = const VerificationMeta(
    'episodeNumber',
  );
  @override
  late final GeneratedColumn<int> episodeNumber = GeneratedColumn<int>(
    'episode_number',
    aliasedName,
    true,
    check: () => ComparableExpr(episodeNumber).isBiggerThanValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imdbIdMeta = const VerificationMeta('imdbId');
  @override
  late final GeneratedColumn<String> imdbId = GeneratedColumn<String>(
    'imdb_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kpIdMeta = const VerificationMeta('kpId');
  @override
  late final GeneratedColumn<int> kpId = GeneratedColumn<int>(
    'kp_id',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _originalTitleMeta = const VerificationMeta(
    'originalTitle',
  );
  @override
  late final GeneratedColumn<String> originalTitle = GeneratedColumn<String>(
    'original_title',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _releaseDateMeta = const VerificationMeta(
    'releaseDate',
  );
  @override
  late final GeneratedColumn<String> releaseDate = GeneratedColumn<String>(
    'release_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _yearMeta = const VerificationMeta('year');
  @override
  late final GeneratedColumn<int> year = GeneratedColumn<int>(
    'year',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _posterPathMeta = const VerificationMeta(
    'posterPath',
  );
  @override
  late final GeneratedColumn<String> posterPath = GeneratedColumn<String>(
    'poster_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _genreIdsMeta = const VerificationMeta(
    'genreIds',
  );
  @override
  late final GeneratedColumn<String> genreIds = GeneratedColumn<String>(
    'genre_ids',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('[]'),
  );
  static const VerificationMeta _snapshotUpdatedAtMeta = const VerificationMeta(
    'snapshotUpdatedAt',
  );
  @override
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
  VerificationContext validateIntegrity(
    Insertable<Work> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_key')) {
      context.handle(
        _workKeyMeta,
        workKey.isAcceptableOrUnknown(data['work_key']!, _workKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_workKeyMeta);
    }
    if (data.containsKey('parent_key')) {
      context.handle(
        _parentKeyMeta,
        parentKey.isAcceptableOrUnknown(data['parent_key']!, _parentKeyMeta),
      );
    }
    if (data.containsKey('tmdb_id')) {
      context.handle(
        _tmdbIdMeta,
        tmdbId.isAcceptableOrUnknown(data['tmdb_id']!, _tmdbIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tmdbIdMeta);
    }
    if (data.containsKey('season_number')) {
      context.handle(
        _seasonNumberMeta,
        seasonNumber.isAcceptableOrUnknown(
          data['season_number']!,
          _seasonNumberMeta,
        ),
      );
    }
    if (data.containsKey('episode_number')) {
      context.handle(
        _episodeNumberMeta,
        episodeNumber.isAcceptableOrUnknown(
          data['episode_number']!,
          _episodeNumberMeta,
        ),
      );
    }
    if (data.containsKey('imdb_id')) {
      context.handle(
        _imdbIdMeta,
        imdbId.isAcceptableOrUnknown(data['imdb_id']!, _imdbIdMeta),
      );
    }
    if (data.containsKey('kp_id')) {
      context.handle(
        _kpIdMeta,
        kpId.isAcceptableOrUnknown(data['kp_id']!, _kpIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('original_title')) {
      context.handle(
        _originalTitleMeta,
        originalTitle.isAcceptableOrUnknown(
          data['original_title']!,
          _originalTitleMeta,
        ),
      );
    }
    if (data.containsKey('release_date')) {
      context.handle(
        _releaseDateMeta,
        releaseDate.isAcceptableOrUnknown(
          data['release_date']!,
          _releaseDateMeta,
        ),
      );
    }
    if (data.containsKey('year')) {
      context.handle(
        _yearMeta,
        year.isAcceptableOrUnknown(data['year']!, _yearMeta),
      );
    }
    if (data.containsKey('poster_path')) {
      context.handle(
        _posterPathMeta,
        posterPath.isAcceptableOrUnknown(data['poster_path']!, _posterPathMeta),
      );
    }
    if (data.containsKey('genre_ids')) {
      context.handle(
        _genreIdsMeta,
        genreIds.isAcceptableOrUnknown(data['genre_ids']!, _genreIdsMeta),
      );
    }
    if (data.containsKey('snapshot_updated_at')) {
      context.handle(
        _snapshotUpdatedAtMeta,
        snapshotUpdatedAt.isAcceptableOrUnknown(
          data['snapshot_updated_at']!,
          _snapshotUpdatedAtMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_snapshotUpdatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  Work map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Work(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      kind: $WorksTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
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
  $WorksTable createAlias(String alias) {
    return $WorksTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<WorkKind, String, String> $converterkind =
      const EnumNameConverter<WorkKind>(WorkKind.values);
}

class Work extends DataClass implements Insertable<Work> {
  final String workKey;
  final WorkKind kind;
  final String? parentKey;
  final int tmdbId;
  final int? seasonNumber;
  final int? episodeNumber;
  final String? imdbId;
  final int? kpId;
  final String title;
  final String? originalTitle;

  /// `YYYY-MM-DD` as the API sent it, without a time zone.
  final String? releaseDate;
  final int? year;

  /// A TMDB relative path (`/abc.jpg`), not a URL.
  final String? posterPath;

  /// JSON array of TMDB genre ids.
  final String genreIds;
  final int snapshotUpdatedAt;
  const Work({
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
    {
      map['kind'] = Variable<String>($WorksTable.$converterkind.toSql(kind));
    }
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

  factory Work.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Work(
      workKey: serializer.fromJson<String>(json['workKey']),
      kind: $WorksTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
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
      'kind': serializer.toJson<String>(
        $WorksTable.$converterkind.toJson(kind),
      ),
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

  Work copyWith({
    String? workKey,
    WorkKind? kind,
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
  }) => Work(
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
  Work copyWithCompanion(WorksCompanion data) {
    return Work(
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
    return (StringBuffer('Work(')
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
      (other is Work &&
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

class WorksCompanion extends UpdateCompanion<Work> {
  final Value<String> workKey;
  final Value<WorkKind> kind;
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
    required WorkKind kind,
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
  static Insertable<Work> custom({
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
    Value<WorkKind>? kind,
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
      map['kind'] = Variable<String>(
        $WorksTable.$converterkind.toSql(kind.value),
      );
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

class $RatingsTable extends Ratings with TableInfo<$RatingsTable, Rating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $RatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workKeyMeta = const VerificationMeta(
    'workKey',
  );
  @override
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
  static const VerificationMeta _scoreHalfMeta = const VerificationMeta(
    'scoreHalf',
  );
  @override
  late final GeneratedColumn<int> scoreHalf = GeneratedColumn<int>(
    'score_half',
    aliasedName,
    false,
    check: () => ComparableExpr(scoreHalf).isBetweenValues(2, 20),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    check: () => ComparableExpr(note.length).isSmallerOrEqualValue(10000),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoredAtMeta = const VerificationMeta(
    'scoredAt',
  );
  @override
  late final GeneratedColumn<int> scoredAt = GeneratedColumn<int>(
    'scored_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
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
  VerificationContext validateIntegrity(
    Insertable<Rating> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_key')) {
      context.handle(
        _workKeyMeta,
        workKey.isAcceptableOrUnknown(data['work_key']!, _workKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_workKeyMeta);
    }
    if (data.containsKey('score_half')) {
      context.handle(
        _scoreHalfMeta,
        scoreHalf.isAcceptableOrUnknown(data['score_half']!, _scoreHalfMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreHalfMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('scored_at')) {
      context.handle(
        _scoredAtMeta,
        scoredAt.isAcceptableOrUnknown(data['scored_at']!, _scoredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_scoredAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  Rating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Rating(
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
  $RatingsTable createAlias(String alias) {
    return $RatingsTable(attachedDatabase, alias);
  }
}

class Rating extends DataClass implements Insertable<Rating> {
  final String workKey;

  /// Score × 2: 2…20 = 1.0…10.0. An integer, so that "the same score" in the
  /// calibration sheet compares exactly.
  final int scoreHalf;
  final String? note;
  final int createdAt;

  /// The last change of the score itself, not of the note.
  final int scoredAt;

  /// The last user change of any kind; merging goes by it.
  final int updatedAt;

  /// `device_id` of the last writer; breaks ties on equal `updated_at`.
  final String updatedBy;
  final int? deletedAt;
  const Rating({
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

  factory Rating.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Rating(
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

  Rating copyWith({
    String? workKey,
    int? scoreHalf,
    Value<String?> note = const Value.absent(),
    int? createdAt,
    int? scoredAt,
    int? updatedAt,
    String? updatedBy,
    Value<int?> deletedAt = const Value.absent(),
  }) => Rating(
    workKey: workKey ?? this.workKey,
    scoreHalf: scoreHalf ?? this.scoreHalf,
    note: note.present ? note.value : this.note,
    createdAt: createdAt ?? this.createdAt,
    scoredAt: scoredAt ?? this.scoredAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  Rating copyWithCompanion(RatingsCompanion data) {
    return Rating(
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
    return (StringBuffer('Rating(')
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
      (other is Rating &&
          other.workKey == this.workKey &&
          other.scoreHalf == this.scoreHalf &&
          other.note == this.note &&
          other.createdAt == this.createdAt &&
          other.scoredAt == this.scoredAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt);
}

class RatingsCompanion extends UpdateCompanion<Rating> {
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
  static Insertable<Rating> custom({
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

class $WatchlistTable extends Watchlist
    with TableInfo<$WatchlistTable, WatchlistEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WatchlistTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workKeyMeta = const VerificationMeta(
    'workKey',
  );
  @override
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
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<int> addedAt = GeneratedColumn<int>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedByMeta = const VerificationMeta(
    'updatedBy',
  );
  @override
  late final GeneratedColumn<String> updatedBy = GeneratedColumn<String>(
    'updated_by',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
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
  VerificationContext validateIntegrity(
    Insertable<WatchlistEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_key')) {
      context.handle(
        _workKeyMeta,
        workKey.isAcceptableOrUnknown(data['work_key']!, _workKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_workKeyMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_addedAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('updated_by')) {
      context.handle(
        _updatedByMeta,
        updatedBy.isAcceptableOrUnknown(data['updated_by']!, _updatedByMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedByMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workKey};
  @override
  WatchlistEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WatchlistEntry(
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
  $WatchlistTable createAlias(String alias) {
    return $WatchlistTable(attachedDatabase, alias);
  }
}

class WatchlistEntry extends DataClass implements Insertable<WatchlistEntry> {
  final String workKey;
  final int addedAt;
  final int updatedAt;
  final String updatedBy;
  final int? deletedAt;
  const WatchlistEntry({
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

  factory WatchlistEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WatchlistEntry(
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

  WatchlistEntry copyWith({
    String? workKey,
    int? addedAt,
    int? updatedAt,
    String? updatedBy,
    Value<int?> deletedAt = const Value.absent(),
  }) => WatchlistEntry(
    workKey: workKey ?? this.workKey,
    addedAt: addedAt ?? this.addedAt,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  WatchlistEntry copyWithCompanion(WatchlistCompanion data) {
    return WatchlistEntry(
      workKey: data.workKey.present ? data.workKey.value : this.workKey,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      updatedBy: data.updatedBy.present ? data.updatedBy.value : this.updatedBy,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WatchlistEntry(')
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
      (other is WatchlistEntry &&
          other.workKey == this.workKey &&
          other.addedAt == this.addedAt &&
          other.updatedAt == this.updatedAt &&
          other.updatedBy == this.updatedBy &&
          other.deletedAt == this.deletedAt);
}

class WatchlistCompanion extends UpdateCompanion<WatchlistEntry> {
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
  static Insertable<WatchlistEntry> custom({
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

class $ExternalRatingsTable extends ExternalRatings
    with TableInfo<$ExternalRatingsTable, ExternalRating> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExternalRatingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _workKeyMeta = const VerificationMeta(
    'workKey',
  );
  @override
  late final GeneratedColumn<String> workKey = GeneratedColumn<String>(
    'work_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<RatingSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        check: () => source.isIn(RatingSource.values.map((s) => s.name)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RatingSource>($ExternalRatingsTable.$convertersource);
  @override
  late final GeneratedColumnWithTypeConverter<RatingStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        check: () => status.isIn(RatingStatus.values.map((s) => s.name)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<RatingStatus>($ExternalRatingsTable.$converterstatus);
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _scaleMeta = const VerificationMeta('scale');
  @override
  late final GeneratedColumn<int> scale = GeneratedColumn<int>(
    'scale',
    aliasedName,
    false,
    check: () => scale.isIn(const [10, 100]),
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _votesMeta = const VerificationMeta('votes');
  @override
  late final GeneratedColumn<int> votes = GeneratedColumn<int>(
    'votes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ApiSource, String> via =
      GeneratedColumn<String>(
        'via',
        aliasedName,
        false,
        check: () => via.isIn(ApiSource.values.map((s) => s.name)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ApiSource>($ExternalRatingsTable.$convertervia);
  static const VerificationMeta _fetchedAtMeta = const VerificationMeta(
    'fetchedAt',
  );
  @override
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
  VerificationContext validateIntegrity(
    Insertable<ExternalRating> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('work_key')) {
      context.handle(
        _workKeyMeta,
        workKey.isAcceptableOrUnknown(data['work_key']!, _workKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_workKeyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    if (data.containsKey('scale')) {
      context.handle(
        _scaleMeta,
        scale.isAcceptableOrUnknown(data['scale']!, _scaleMeta),
      );
    } else if (isInserting) {
      context.missing(_scaleMeta);
    }
    if (data.containsKey('votes')) {
      context.handle(
        _votesMeta,
        votes.isAcceptableOrUnknown(data['votes']!, _votesMeta),
      );
    }
    if (data.containsKey('fetched_at')) {
      context.handle(
        _fetchedAtMeta,
        fetchedAt.isAcceptableOrUnknown(data['fetched_at']!, _fetchedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_fetchedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {workKey, source};
  @override
  ExternalRating map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ExternalRating(
      workKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}work_key'],
      )!,
      source: $ExternalRatingsTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
      status: $ExternalRatingsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
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
      via: $ExternalRatingsTable.$convertervia.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}via'],
        )!,
      ),
      fetchedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fetched_at'],
      )!,
    );
  }

  @override
  $ExternalRatingsTable createAlias(String alias) {
    return $ExternalRatingsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<RatingSource, String, String> $convertersource =
      const EnumNameConverter<RatingSource>(RatingSource.values);
  static JsonTypeConverter2<RatingStatus, String, String> $converterstatus =
      const EnumNameConverter<RatingStatus>(RatingStatus.values);
  static JsonTypeConverter2<ApiSource, String, String> $convertervia =
      const EnumNameConverter<ApiSource>(ApiSource.values);
}

class ExternalRating extends DataClass implements Insertable<ExternalRating> {
  final String workKey;
  final RatingSource source;
  final RatingStatus status;
  final double? value;

  /// 10 or 100: RT in percent, Metacritic 0–100.
  final int scale;
  final int? votes;
  final ApiSource via;
  final int fetchedAt;
  const ExternalRating({
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
    {
      map['source'] = Variable<String>(
        $ExternalRatingsTable.$convertersource.toSql(source),
      );
    }
    {
      map['status'] = Variable<String>(
        $ExternalRatingsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<double>(value);
    }
    map['scale'] = Variable<int>(scale);
    if (!nullToAbsent || votes != null) {
      map['votes'] = Variable<int>(votes);
    }
    {
      map['via'] = Variable<String>(
        $ExternalRatingsTable.$convertervia.toSql(via),
      );
    }
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

  factory ExternalRating.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ExternalRating(
      workKey: serializer.fromJson<String>(json['workKey']),
      source: $ExternalRatingsTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      status: $ExternalRatingsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      value: serializer.fromJson<double?>(json['value']),
      scale: serializer.fromJson<int>(json['scale']),
      votes: serializer.fromJson<int?>(json['votes']),
      via: $ExternalRatingsTable.$convertervia.fromJson(
        serializer.fromJson<String>(json['via']),
      ),
      fetchedAt: serializer.fromJson<int>(json['fetchedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'workKey': serializer.toJson<String>(workKey),
      'source': serializer.toJson<String>(
        $ExternalRatingsTable.$convertersource.toJson(source),
      ),
      'status': serializer.toJson<String>(
        $ExternalRatingsTable.$converterstatus.toJson(status),
      ),
      'value': serializer.toJson<double?>(value),
      'scale': serializer.toJson<int>(scale),
      'votes': serializer.toJson<int?>(votes),
      'via': serializer.toJson<String>(
        $ExternalRatingsTable.$convertervia.toJson(via),
      ),
      'fetchedAt': serializer.toJson<int>(fetchedAt),
    };
  }

  ExternalRating copyWith({
    String? workKey,
    RatingSource? source,
    RatingStatus? status,
    Value<double?> value = const Value.absent(),
    int? scale,
    Value<int?> votes = const Value.absent(),
    ApiSource? via,
    int? fetchedAt,
  }) => ExternalRating(
    workKey: workKey ?? this.workKey,
    source: source ?? this.source,
    status: status ?? this.status,
    value: value.present ? value.value : this.value,
    scale: scale ?? this.scale,
    votes: votes.present ? votes.value : this.votes,
    via: via ?? this.via,
    fetchedAt: fetchedAt ?? this.fetchedAt,
  );
  ExternalRating copyWithCompanion(ExternalRatingsCompanion data) {
    return ExternalRating(
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
    return (StringBuffer('ExternalRating(')
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
      (other is ExternalRating &&
          other.workKey == this.workKey &&
          other.source == this.source &&
          other.status == this.status &&
          other.value == this.value &&
          other.scale == this.scale &&
          other.votes == this.votes &&
          other.via == this.via &&
          other.fetchedAt == this.fetchedAt);
}

class ExternalRatingsCompanion extends UpdateCompanion<ExternalRating> {
  final Value<String> workKey;
  final Value<RatingSource> source;
  final Value<RatingStatus> status;
  final Value<double?> value;
  final Value<int> scale;
  final Value<int?> votes;
  final Value<ApiSource> via;
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
    required RatingSource source,
    required RatingStatus status,
    this.value = const Value.absent(),
    required int scale,
    this.votes = const Value.absent(),
    required ApiSource via,
    required int fetchedAt,
    this.rowid = const Value.absent(),
  }) : workKey = Value(workKey),
       source = Value(source),
       status = Value(status),
       scale = Value(scale),
       via = Value(via),
       fetchedAt = Value(fetchedAt);
  static Insertable<ExternalRating> custom({
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
    Value<RatingSource>? source,
    Value<RatingStatus>? status,
    Value<double?>? value,
    Value<int>? scale,
    Value<int?>? votes,
    Value<ApiSource>? via,
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
      map['source'] = Variable<String>(
        $ExternalRatingsTable.$convertersource.toSql(source.value),
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $ExternalRatingsTable.$converterstatus.toSql(status.value),
      );
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
      map['via'] = Variable<String>(
        $ExternalRatingsTable.$convertervia.toSql(via.value),
      );
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

class $ApiBudgetTable extends ApiBudget
    with TableInfo<$ApiBudgetTable, ApiBudgetRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ApiBudgetTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<ApiSource, String> source =
      GeneratedColumn<String>(
        'source',
        aliasedName,
        false,
        check: () => source.isIn(ApiSource.values.map((s) => s.name)),
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ApiSource>($ApiBudgetTable.$convertersource);
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usedMeta = const VerificationMeta('used');
  @override
  late final GeneratedColumn<int> used = GeneratedColumn<int>(
    'used',
    aliasedName,
    false,
    check: () => ComparableExpr(used).isBiggerOrEqualValue(0),
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [source, day, used];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'api_budget';
  @override
  VerificationContext validateIntegrity(
    Insertable<ApiBudgetRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('used')) {
      context.handle(
        _usedMeta,
        used.isAcceptableOrUnknown(data['used']!, _usedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {source, day};
  @override
  ApiBudgetRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ApiBudgetRow(
      source: $ApiBudgetTable.$convertersource.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}source'],
        )!,
      ),
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
  $ApiBudgetTable createAlias(String alias) {
    return $ApiBudgetTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ApiSource, String, String> $convertersource =
      const EnumNameConverter<ApiSource>(ApiSource.values);
}

class ApiBudgetRow extends DataClass implements Insertable<ApiBudgetRow> {
  final ApiSource source;

  /// `YYYY-MM-DD`, a UTC day.
  final String day;
  final int used;
  const ApiBudgetRow({
    required this.source,
    required this.day,
    required this.used,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['source'] = Variable<String>(
        $ApiBudgetTable.$convertersource.toSql(source),
      );
    }
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

  factory ApiBudgetRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ApiBudgetRow(
      source: $ApiBudgetTable.$convertersource.fromJson(
        serializer.fromJson<String>(json['source']),
      ),
      day: serializer.fromJson<String>(json['day']),
      used: serializer.fromJson<int>(json['used']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'source': serializer.toJson<String>(
        $ApiBudgetTable.$convertersource.toJson(source),
      ),
      'day': serializer.toJson<String>(day),
      'used': serializer.toJson<int>(used),
    };
  }

  ApiBudgetRow copyWith({ApiSource? source, String? day, int? used}) =>
      ApiBudgetRow(
        source: source ?? this.source,
        day: day ?? this.day,
        used: used ?? this.used,
      );
  ApiBudgetRow copyWithCompanion(ApiBudgetCompanion data) {
    return ApiBudgetRow(
      source: data.source.present ? data.source.value : this.source,
      day: data.day.present ? data.day.value : this.day,
      used: data.used.present ? data.used.value : this.used,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ApiBudgetRow(')
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
      (other is ApiBudgetRow &&
          other.source == this.source &&
          other.day == this.day &&
          other.used == this.used);
}

class ApiBudgetCompanion extends UpdateCompanion<ApiBudgetRow> {
  final Value<ApiSource> source;
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
    required ApiSource source,
    required String day,
    this.used = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : source = Value(source),
       day = Value(day);
  static Insertable<ApiBudgetRow> custom({
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
    Value<ApiSource>? source,
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
      map['source'] = Variable<String>(
        $ApiBudgetTable.$convertersource.toSql(source.value),
      );
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

class $SyncStateTable extends SyncState
    with TableInfo<$SyncStateTable, SyncStateEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncStateTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
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
  VerificationContext validateIntegrity(
    Insertable<SyncStateEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  SyncStateEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncStateEntry(
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
  $SyncStateTable createAlias(String alias) {
    return $SyncStateTable(attachedDatabase, alias);
  }
}

class SyncStateEntry extends DataClass implements Insertable<SyncStateEntry> {
  final String key;
  final String value;
  const SyncStateEntry({required this.key, required this.value});
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

  factory SyncStateEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncStateEntry(
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

  SyncStateEntry copyWith({String? key, String? value}) =>
      SyncStateEntry(key: key ?? this.key, value: value ?? this.value);
  SyncStateEntry copyWithCompanion(SyncStateCompanion data) {
    return SyncStateEntry(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncStateEntry(')
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
      (other is SyncStateEntry &&
          other.key == this.key &&
          other.value == this.value);
}

class SyncStateCompanion extends UpdateCompanion<SyncStateEntry> {
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
  static Insertable<SyncStateEntry> custom({
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $WorksTable works = $WorksTable(this);
  late final $RatingsTable ratings = $RatingsTable(this);
  late final $WatchlistTable watchlist = $WatchlistTable(this);
  late final $ExternalRatingsTable externalRatings = $ExternalRatingsTable(
    this,
  );
  late final $ApiBudgetTable apiBudget = $ApiBudgetTable(this);
  late final $SyncStateTable syncState = $SyncStateTable(this);
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
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    works,
    ratings,
    watchlist,
    externalRatings,
    apiBudget,
    syncState,
    worksKind,
    worksParentKey,
    worksYear,
    ratingsLiveScore,
    ratingsScoredAt,
  ];
}

typedef $$WorksTableCreateCompanionBuilder =
    WorksCompanion Function({
      required String workKey,
      required WorkKind kind,
      Value<String?> parentKey,
      required int tmdbId,
      Value<int?> seasonNumber,
      Value<int?> episodeNumber,
      Value<String?> imdbId,
      Value<int?> kpId,
      required String title,
      Value<String?> originalTitle,
      Value<String?> releaseDate,
      Value<int?> year,
      Value<String?> posterPath,
      Value<String> genreIds,
      required int snapshotUpdatedAt,
      Value<int> rowid,
    });
typedef $$WorksTableUpdateCompanionBuilder =
    WorksCompanion Function({
      Value<String> workKey,
      Value<WorkKind> kind,
      Value<String?> parentKey,
      Value<int> tmdbId,
      Value<int?> seasonNumber,
      Value<int?> episodeNumber,
      Value<String?> imdbId,
      Value<int?> kpId,
      Value<String> title,
      Value<String?> originalTitle,
      Value<String?> releaseDate,
      Value<int?> year,
      Value<String?> posterPath,
      Value<String> genreIds,
      Value<int> snapshotUpdatedAt,
      Value<int> rowid,
    });

final class $$WorksTableReferences
    extends BaseReferences<_$AppDatabase, $WorksTable, Work> {
  $$WorksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$RatingsTable, List<Rating>> _ratingsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.ratings,
    aliasName: $_aliasNameGenerator(db.works.workKey, db.ratings.workKey),
  );

  $$RatingsTableProcessedTableManager get ratingsRefs {
    final manager = $$RatingsTableTableManager($_db, $_db.ratings).filter(
      (f) => f.workKey.workKey.sqlEquals($_itemColumn<String>('work_key')!),
    );

    final cache = $_typedResult.readTableOrNull(_ratingsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$WatchlistTable, List<WatchlistEntry>>
  _watchlistRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.watchlist,
    aliasName: $_aliasNameGenerator(db.works.workKey, db.watchlist.workKey),
  );

  $$WatchlistTableProcessedTableManager get watchlistRefs {
    final manager = $$WatchlistTableTableManager($_db, $_db.watchlist).filter(
      (f) => f.workKey.workKey.sqlEquals($_itemColumn<String>('work_key')!),
    );

    final cache = $_typedResult.readTableOrNull(_watchlistRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorksTableFilterComposer extends Composer<_$AppDatabase, $WorksTable> {
  $$WorksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workKey => $composableBuilder(
    column: $table.workKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<WorkKind, WorkKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get parentKey => $composableBuilder(
    column: $table.parentKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get kpId => $composableBuilder(
    column: $table.kpId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get genreIds => $composableBuilder(
    column: $table.genreIds,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snapshotUpdatedAt => $composableBuilder(
    column: $table.snapshotUpdatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> ratingsRefs(
    Expression<bool> Function($$RatingsTableFilterComposer f) f,
  ) {
    final $$RatingsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableFilterComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> watchlistRefs(
    Expression<bool> Function($$WatchlistTableFilterComposer f) f,
  ) {
    final $$WatchlistTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.watchlist,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchlistTableFilterComposer(
            $db: $db,
            $table: $db.watchlist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorksTableOrderingComposer
    extends Composer<_$AppDatabase, $WorksTable> {
  $$WorksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workKey => $composableBuilder(
    column: $table.workKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentKey => $composableBuilder(
    column: $table.parentKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tmdbId => $composableBuilder(
    column: $table.tmdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imdbId => $composableBuilder(
    column: $table.imdbId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get kpId => $composableBuilder(
    column: $table.kpId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get year => $composableBuilder(
    column: $table.year,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get genreIds => $composableBuilder(
    column: $table.genreIds,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snapshotUpdatedAt => $composableBuilder(
    column: $table.snapshotUpdatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorksTable> {
  $$WorksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workKey =>
      $composableBuilder(column: $table.workKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<WorkKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get parentKey =>
      $composableBuilder(column: $table.parentKey, builder: (column) => column);

  GeneratedColumn<int> get tmdbId =>
      $composableBuilder(column: $table.tmdbId, builder: (column) => column);

  GeneratedColumn<int> get seasonNumber => $composableBuilder(
    column: $table.seasonNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get episodeNumber => $composableBuilder(
    column: $table.episodeNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get imdbId =>
      $composableBuilder(column: $table.imdbId, builder: (column) => column);

  GeneratedColumn<int> get kpId =>
      $composableBuilder(column: $table.kpId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get originalTitle => $composableBuilder(
    column: $table.originalTitle,
    builder: (column) => column,
  );

  GeneratedColumn<String> get releaseDate => $composableBuilder(
    column: $table.releaseDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get year =>
      $composableBuilder(column: $table.year, builder: (column) => column);

  GeneratedColumn<String> get posterPath => $composableBuilder(
    column: $table.posterPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get genreIds =>
      $composableBuilder(column: $table.genreIds, builder: (column) => column);

  GeneratedColumn<int> get snapshotUpdatedAt => $composableBuilder(
    column: $table.snapshotUpdatedAt,
    builder: (column) => column,
  );

  Expression<T> ratingsRefs<T extends Object>(
    Expression<T> Function($$RatingsTableAnnotationComposer a) f,
  ) {
    final $$RatingsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.ratings,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$RatingsTableAnnotationComposer(
            $db: $db,
            $table: $db.ratings,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> watchlistRefs<T extends Object>(
    Expression<T> Function($$WatchlistTableAnnotationComposer a) f,
  ) {
    final $$WatchlistTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.watchlist,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WatchlistTableAnnotationComposer(
            $db: $db,
            $table: $db.watchlist,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorksTable,
          Work,
          $$WorksTableFilterComposer,
          $$WorksTableOrderingComposer,
          $$WorksTableAnnotationComposer,
          $$WorksTableCreateCompanionBuilder,
          $$WorksTableUpdateCompanionBuilder,
          (Work, $$WorksTableReferences),
          Work,
          PrefetchHooks Function({bool ratingsRefs, bool watchlistRefs})
        > {
  $$WorksTableTableManager(_$AppDatabase db, $WorksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workKey = const Value.absent(),
                Value<WorkKind> kind = const Value.absent(),
                Value<String?> parentKey = const Value.absent(),
                Value<int> tmdbId = const Value.absent(),
                Value<int?> seasonNumber = const Value.absent(),
                Value<int?> episodeNumber = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<int?> kpId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> originalTitle = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String> genreIds = const Value.absent(),
                Value<int> snapshotUpdatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorksCompanion(
                workKey: workKey,
                kind: kind,
                parentKey: parentKey,
                tmdbId: tmdbId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                imdbId: imdbId,
                kpId: kpId,
                title: title,
                originalTitle: originalTitle,
                releaseDate: releaseDate,
                year: year,
                posterPath: posterPath,
                genreIds: genreIds,
                snapshotUpdatedAt: snapshotUpdatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workKey,
                required WorkKind kind,
                Value<String?> parentKey = const Value.absent(),
                required int tmdbId,
                Value<int?> seasonNumber = const Value.absent(),
                Value<int?> episodeNumber = const Value.absent(),
                Value<String?> imdbId = const Value.absent(),
                Value<int?> kpId = const Value.absent(),
                required String title,
                Value<String?> originalTitle = const Value.absent(),
                Value<String?> releaseDate = const Value.absent(),
                Value<int?> year = const Value.absent(),
                Value<String?> posterPath = const Value.absent(),
                Value<String> genreIds = const Value.absent(),
                required int snapshotUpdatedAt,
                Value<int> rowid = const Value.absent(),
              }) => WorksCompanion.insert(
                workKey: workKey,
                kind: kind,
                parentKey: parentKey,
                tmdbId: tmdbId,
                seasonNumber: seasonNumber,
                episodeNumber: episodeNumber,
                imdbId: imdbId,
                kpId: kpId,
                title: title,
                originalTitle: originalTitle,
                releaseDate: releaseDate,
                year: year,
                posterPath: posterPath,
                genreIds: genreIds,
                snapshotUpdatedAt: snapshotUpdatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$WorksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({ratingsRefs = false, watchlistRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (ratingsRefs) db.ratings,
                    if (watchlistRefs) db.watchlist,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (ratingsRefs)
                        await $_getPrefetchedData<Work, $WorksTable, Rating>(
                          currentTable: table,
                          referencedTable: $$WorksTableReferences
                              ._ratingsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorksTableReferences(db, table, p0).ratingsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workKey == item.workKey,
                              ),
                          typedResults: items,
                        ),
                      if (watchlistRefs)
                        await $_getPrefetchedData<
                          Work,
                          $WorksTable,
                          WatchlistEntry
                        >(
                          currentTable: table,
                          referencedTable: $$WorksTableReferences
                              ._watchlistRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$WorksTableReferences(
                                db,
                                table,
                                p0,
                              ).watchlistRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.workKey == item.workKey,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$WorksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorksTable,
      Work,
      $$WorksTableFilterComposer,
      $$WorksTableOrderingComposer,
      $$WorksTableAnnotationComposer,
      $$WorksTableCreateCompanionBuilder,
      $$WorksTableUpdateCompanionBuilder,
      (Work, $$WorksTableReferences),
      Work,
      PrefetchHooks Function({bool ratingsRefs, bool watchlistRefs})
    >;
typedef $$RatingsTableCreateCompanionBuilder =
    RatingsCompanion Function({
      required String workKey,
      required int scoreHalf,
      Value<String?> note,
      required int createdAt,
      required int scoredAt,
      required int updatedAt,
      required String updatedBy,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$RatingsTableUpdateCompanionBuilder =
    RatingsCompanion Function({
      Value<String> workKey,
      Value<int> scoreHalf,
      Value<String?> note,
      Value<int> createdAt,
      Value<int> scoredAt,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$RatingsTableReferences
    extends BaseReferences<_$AppDatabase, $RatingsTable, Rating> {
  $$RatingsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorksTable _workKeyTable(_$AppDatabase db) => db.works.createAlias(
    $_aliasNameGenerator(db.ratings.workKey, db.works.workKey),
  );

  $$WorksTableProcessedTableManager get workKey {
    final $_column = $_itemColumn<String>('work_key')!;

    final manager = $$WorksTableTableManager(
      $_db,
      $_db.works,
    ).filter((f) => f.workKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$RatingsTableFilterComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get scoreHalf => $composableBuilder(
    column: $table.scoreHalf,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scoredAt => $composableBuilder(
    column: $table.scoredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorksTableFilterComposer get workKey {
    final $$WorksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableFilterComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get scoreHalf => $composableBuilder(
    column: $table.scoreHalf,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scoredAt => $composableBuilder(
    column: $table.scoredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorksTableOrderingComposer get workKey {
    final $$WorksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableOrderingComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $RatingsTable> {
  $$RatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get scoreHalf =>
      $composableBuilder(column: $table.scoreHalf, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get scoredAt =>
      $composableBuilder(column: $table.scoredAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$WorksTableAnnotationComposer get workKey {
    final $$WorksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableAnnotationComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$RatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $RatingsTable,
          Rating,
          $$RatingsTableFilterComposer,
          $$RatingsTableOrderingComposer,
          $$RatingsTableAnnotationComposer,
          $$RatingsTableCreateCompanionBuilder,
          $$RatingsTableUpdateCompanionBuilder,
          (Rating, $$RatingsTableReferences),
          Rating,
          PrefetchHooks Function({bool workKey})
        > {
  $$RatingsTableTableManager(_$AppDatabase db, $RatingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$RatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$RatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$RatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workKey = const Value.absent(),
                Value<int> scoreHalf = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> scoredAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingsCompanion(
                workKey: workKey,
                scoreHalf: scoreHalf,
                note: note,
                createdAt: createdAt,
                scoredAt: scoredAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workKey,
                required int scoreHalf,
                Value<String?> note = const Value.absent(),
                required int createdAt,
                required int scoredAt,
                required int updatedAt,
                required String updatedBy,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => RatingsCompanion.insert(
                workKey: workKey,
                scoreHalf: scoreHalf,
                note: note,
                createdAt: createdAt,
                scoredAt: scoredAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$RatingsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workKey) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workKey,
                                referencedTable: $$RatingsTableReferences
                                    ._workKeyTable(db),
                                referencedColumn: $$RatingsTableReferences
                                    ._workKeyTable(db)
                                    .workKey,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$RatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $RatingsTable,
      Rating,
      $$RatingsTableFilterComposer,
      $$RatingsTableOrderingComposer,
      $$RatingsTableAnnotationComposer,
      $$RatingsTableCreateCompanionBuilder,
      $$RatingsTableUpdateCompanionBuilder,
      (Rating, $$RatingsTableReferences),
      Rating,
      PrefetchHooks Function({bool workKey})
    >;
typedef $$WatchlistTableCreateCompanionBuilder =
    WatchlistCompanion Function({
      required String workKey,
      required int addedAt,
      required int updatedAt,
      required String updatedBy,
      Value<int?> deletedAt,
      Value<int> rowid,
    });
typedef $$WatchlistTableUpdateCompanionBuilder =
    WatchlistCompanion Function({
      Value<String> workKey,
      Value<int> addedAt,
      Value<int> updatedAt,
      Value<String> updatedBy,
      Value<int?> deletedAt,
      Value<int> rowid,
    });

final class $$WatchlistTableReferences
    extends BaseReferences<_$AppDatabase, $WatchlistTable, WatchlistEntry> {
  $$WatchlistTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $WorksTable _workKeyTable(_$AppDatabase db) => db.works.createAlias(
    $_aliasNameGenerator(db.watchlist.workKey, db.works.workKey),
  );

  $$WorksTableProcessedTableManager get workKey {
    final $_column = $_itemColumn<String>('work_key')!;

    final manager = $$WorksTableTableManager(
      $_db,
      $_db.works,
    ).filter((f) => f.workKey.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_workKeyTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WatchlistTableFilterComposer
    extends Composer<_$AppDatabase, $WatchlistTable> {
  $$WatchlistTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$WorksTableFilterComposer get workKey {
    final $$WorksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableFilterComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchlistTableOrderingComposer
    extends Composer<_$AppDatabase, $WatchlistTable> {
  $$WatchlistTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get updatedBy => $composableBuilder(
    column: $table.updatedBy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorksTableOrderingComposer get workKey {
    final $$WorksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableOrderingComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchlistTableAnnotationComposer
    extends Composer<_$AppDatabase, $WatchlistTable> {
  $$WatchlistTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get updatedBy =>
      $composableBuilder(column: $table.updatedBy, builder: (column) => column);

  GeneratedColumn<int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  $$WorksTableAnnotationComposer get workKey {
    final $$WorksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.workKey,
      referencedTable: $db.works,
      getReferencedColumn: (t) => t.workKey,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorksTableAnnotationComposer(
            $db: $db,
            $table: $db.works,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WatchlistTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WatchlistTable,
          WatchlistEntry,
          $$WatchlistTableFilterComposer,
          $$WatchlistTableOrderingComposer,
          $$WatchlistTableAnnotationComposer,
          $$WatchlistTableCreateCompanionBuilder,
          $$WatchlistTableUpdateCompanionBuilder,
          (WatchlistEntry, $$WatchlistTableReferences),
          WatchlistEntry,
          PrefetchHooks Function({bool workKey})
        > {
  $$WatchlistTableTableManager(_$AppDatabase db, $WatchlistTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WatchlistTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WatchlistTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WatchlistTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workKey = const Value.absent(),
                Value<int> addedAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<String> updatedBy = const Value.absent(),
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchlistCompanion(
                workKey: workKey,
                addedAt: addedAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workKey,
                required int addedAt,
                required int updatedAt,
                required String updatedBy,
                Value<int?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WatchlistCompanion.insert(
                workKey: workKey,
                addedAt: addedAt,
                updatedAt: updatedAt,
                updatedBy: updatedBy,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WatchlistTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({workKey = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (workKey) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.workKey,
                                referencedTable: $$WatchlistTableReferences
                                    ._workKeyTable(db),
                                referencedColumn: $$WatchlistTableReferences
                                    ._workKeyTable(db)
                                    .workKey,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WatchlistTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WatchlistTable,
      WatchlistEntry,
      $$WatchlistTableFilterComposer,
      $$WatchlistTableOrderingComposer,
      $$WatchlistTableAnnotationComposer,
      $$WatchlistTableCreateCompanionBuilder,
      $$WatchlistTableUpdateCompanionBuilder,
      (WatchlistEntry, $$WatchlistTableReferences),
      WatchlistEntry,
      PrefetchHooks Function({bool workKey})
    >;
typedef $$ExternalRatingsTableCreateCompanionBuilder =
    ExternalRatingsCompanion Function({
      required String workKey,
      required RatingSource source,
      required RatingStatus status,
      Value<double?> value,
      required int scale,
      Value<int?> votes,
      required ApiSource via,
      required int fetchedAt,
      Value<int> rowid,
    });
typedef $$ExternalRatingsTableUpdateCompanionBuilder =
    ExternalRatingsCompanion Function({
      Value<String> workKey,
      Value<RatingSource> source,
      Value<RatingStatus> status,
      Value<double?> value,
      Value<int> scale,
      Value<int?> votes,
      Value<ApiSource> via,
      Value<int> fetchedAt,
      Value<int> rowid,
    });

class $$ExternalRatingsTableFilterComposer
    extends Composer<_$AppDatabase, $ExternalRatingsTable> {
  $$ExternalRatingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get workKey => $composableBuilder(
    column: $table.workKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<RatingSource, RatingSource, String>
  get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnWithTypeConverterFilters<RatingStatus, RatingStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get votes => $composableBuilder(
    column: $table.votes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ApiSource, ApiSource, String> get via =>
      $composableBuilder(
        column: $table.via,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ExternalRatingsTableOrderingComposer
    extends Composer<_$AppDatabase, $ExternalRatingsTable> {
  $$ExternalRatingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get workKey => $composableBuilder(
    column: $table.workKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get scale => $composableBuilder(
    column: $table.scale,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get votes => $composableBuilder(
    column: $table.votes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get via => $composableBuilder(
    column: $table.via,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fetchedAt => $composableBuilder(
    column: $table.fetchedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExternalRatingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExternalRatingsTable> {
  $$ExternalRatingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get workKey =>
      $composableBuilder(column: $table.workKey, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RatingSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumnWithTypeConverter<RatingStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<int> get scale =>
      $composableBuilder(column: $table.scale, builder: (column) => column);

  GeneratedColumn<int> get votes =>
      $composableBuilder(column: $table.votes, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ApiSource, String> get via =>
      $composableBuilder(column: $table.via, builder: (column) => column);

  GeneratedColumn<int> get fetchedAt =>
      $composableBuilder(column: $table.fetchedAt, builder: (column) => column);
}

class $$ExternalRatingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExternalRatingsTable,
          ExternalRating,
          $$ExternalRatingsTableFilterComposer,
          $$ExternalRatingsTableOrderingComposer,
          $$ExternalRatingsTableAnnotationComposer,
          $$ExternalRatingsTableCreateCompanionBuilder,
          $$ExternalRatingsTableUpdateCompanionBuilder,
          (
            ExternalRating,
            BaseReferences<
              _$AppDatabase,
              $ExternalRatingsTable,
              ExternalRating
            >,
          ),
          ExternalRating,
          PrefetchHooks Function()
        > {
  $$ExternalRatingsTableTableManager(
    _$AppDatabase db,
    $ExternalRatingsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExternalRatingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExternalRatingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExternalRatingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> workKey = const Value.absent(),
                Value<RatingSource> source = const Value.absent(),
                Value<RatingStatus> status = const Value.absent(),
                Value<double?> value = const Value.absent(),
                Value<int> scale = const Value.absent(),
                Value<int?> votes = const Value.absent(),
                Value<ApiSource> via = const Value.absent(),
                Value<int> fetchedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExternalRatingsCompanion(
                workKey: workKey,
                source: source,
                status: status,
                value: value,
                scale: scale,
                votes: votes,
                via: via,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String workKey,
                required RatingSource source,
                required RatingStatus status,
                Value<double?> value = const Value.absent(),
                required int scale,
                Value<int?> votes = const Value.absent(),
                required ApiSource via,
                required int fetchedAt,
                Value<int> rowid = const Value.absent(),
              }) => ExternalRatingsCompanion.insert(
                workKey: workKey,
                source: source,
                status: status,
                value: value,
                scale: scale,
                votes: votes,
                via: via,
                fetchedAt: fetchedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ExternalRatingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExternalRatingsTable,
      ExternalRating,
      $$ExternalRatingsTableFilterComposer,
      $$ExternalRatingsTableOrderingComposer,
      $$ExternalRatingsTableAnnotationComposer,
      $$ExternalRatingsTableCreateCompanionBuilder,
      $$ExternalRatingsTableUpdateCompanionBuilder,
      (
        ExternalRating,
        BaseReferences<_$AppDatabase, $ExternalRatingsTable, ExternalRating>,
      ),
      ExternalRating,
      PrefetchHooks Function()
    >;
typedef $$ApiBudgetTableCreateCompanionBuilder =
    ApiBudgetCompanion Function({
      required ApiSource source,
      required String day,
      Value<int> used,
      Value<int> rowid,
    });
typedef $$ApiBudgetTableUpdateCompanionBuilder =
    ApiBudgetCompanion Function({
      Value<ApiSource> source,
      Value<String> day,
      Value<int> used,
      Value<int> rowid,
    });

class $$ApiBudgetTableFilterComposer
    extends Composer<_$AppDatabase, $ApiBudgetTable> {
  $$ApiBudgetTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<ApiSource, ApiSource, String> get source =>
      $composableBuilder(
        column: $table.source,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ApiBudgetTableOrderingComposer
    extends Composer<_$AppDatabase, $ApiBudgetTable> {
  $$ApiBudgetTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get used => $composableBuilder(
    column: $table.used,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ApiBudgetTableAnnotationComposer
    extends Composer<_$AppDatabase, $ApiBudgetTable> {
  $$ApiBudgetTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<ApiSource, String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get used =>
      $composableBuilder(column: $table.used, builder: (column) => column);
}

class $$ApiBudgetTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ApiBudgetTable,
          ApiBudgetRow,
          $$ApiBudgetTableFilterComposer,
          $$ApiBudgetTableOrderingComposer,
          $$ApiBudgetTableAnnotationComposer,
          $$ApiBudgetTableCreateCompanionBuilder,
          $$ApiBudgetTableUpdateCompanionBuilder,
          (
            ApiBudgetRow,
            BaseReferences<_$AppDatabase, $ApiBudgetTable, ApiBudgetRow>,
          ),
          ApiBudgetRow,
          PrefetchHooks Function()
        > {
  $$ApiBudgetTableTableManager(_$AppDatabase db, $ApiBudgetTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ApiBudgetTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ApiBudgetTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ApiBudgetTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<ApiSource> source = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> used = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiBudgetCompanion(
                source: source,
                day: day,
                used: used,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required ApiSource source,
                required String day,
                Value<int> used = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ApiBudgetCompanion.insert(
                source: source,
                day: day,
                used: used,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ApiBudgetTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ApiBudgetTable,
      ApiBudgetRow,
      $$ApiBudgetTableFilterComposer,
      $$ApiBudgetTableOrderingComposer,
      $$ApiBudgetTableAnnotationComposer,
      $$ApiBudgetTableCreateCompanionBuilder,
      $$ApiBudgetTableUpdateCompanionBuilder,
      (
        ApiBudgetRow,
        BaseReferences<_$AppDatabase, $ApiBudgetTable, ApiBudgetRow>,
      ),
      ApiBudgetRow,
      PrefetchHooks Function()
    >;
typedef $$SyncStateTableCreateCompanionBuilder =
    SyncStateCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$SyncStateTableUpdateCompanionBuilder =
    SyncStateCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$SyncStateTableFilterComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncStateTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncStateTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncStateTable> {
  $$SyncStateTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$SyncStateTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncStateTable,
          SyncStateEntry,
          $$SyncStateTableFilterComposer,
          $$SyncStateTableOrderingComposer,
          $$SyncStateTableAnnotationComposer,
          $$SyncStateTableCreateCompanionBuilder,
          $$SyncStateTableUpdateCompanionBuilder,
          (
            SyncStateEntry,
            BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateEntry>,
          ),
          SyncStateEntry,
          PrefetchHooks Function()
        > {
  $$SyncStateTableTableManager(_$AppDatabase db, $SyncStateTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncStateTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncStateTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncStateTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => SyncStateCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncStateTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncStateTable,
      SyncStateEntry,
      $$SyncStateTableFilterComposer,
      $$SyncStateTableOrderingComposer,
      $$SyncStateTableAnnotationComposer,
      $$SyncStateTableCreateCompanionBuilder,
      $$SyncStateTableUpdateCompanionBuilder,
      (
        SyncStateEntry,
        BaseReferences<_$AppDatabase, $SyncStateTable, SyncStateEntry>,
      ),
      SyncStateEntry,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$WorksTableTableManager get works =>
      $$WorksTableTableManager(_db, _db.works);
  $$RatingsTableTableManager get ratings =>
      $$RatingsTableTableManager(_db, _db.ratings);
  $$WatchlistTableTableManager get watchlist =>
      $$WatchlistTableTableManager(_db, _db.watchlist);
  $$ExternalRatingsTableTableManager get externalRatings =>
      $$ExternalRatingsTableTableManager(_db, _db.externalRatings);
  $$ApiBudgetTableTableManager get apiBudget =>
      $$ApiBudgetTableTableManager(_db, _db.apiBudget);
  $$SyncStateTableTableManager get syncState =>
      $$SyncStateTableTableManager(_db, _db.syncState);
}
