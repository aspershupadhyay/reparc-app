// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $ExercisesTable extends Exercises
    with TableInfo<$ExercisesTable, Exercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _variationMeta = const VerificationMeta(
    'variation',
  );
  @override
  late final GeneratedColumn<String> variation = GeneratedColumn<String>(
    'variation',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetMusclesMeta = const VerificationMeta(
    'targetMuscles',
  );
  @override
  late final GeneratedColumn<String> targetMuscles = GeneratedColumn<String>(
    'target_muscles',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _instructionSourceMeta = const VerificationMeta(
    'instructionSource',
  );
  @override
  late final GeneratedColumn<String> instructionSource =
      GeneratedColumn<String>(
        'instruction_source',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _catalogIdMeta = const VerificationMeta(
    'catalogId',
  );
  @override
  late final GeneratedColumn<String> catalogId = GeneratedColumn<String>(
    'catalog_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    variation,
    equipment,
    targetMuscles,
    note,
    instructionSource,
    catalogId,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<Exercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('variation')) {
      context.handle(
        _variationMeta,
        variation.isAcceptableOrUnknown(data['variation']!, _variationMeta),
      );
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    }
    if (data.containsKey('target_muscles')) {
      context.handle(
        _targetMusclesMeta,
        targetMuscles.isAcceptableOrUnknown(
          data['target_muscles']!,
          _targetMusclesMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('instruction_source')) {
      context.handle(
        _instructionSourceMeta,
        instructionSource.isAcceptableOrUnknown(
          data['instruction_source']!,
          _instructionSourceMeta,
        ),
      );
    }
    if (data.containsKey('catalog_id')) {
      context.handle(
        _catalogIdMeta,
        catalogId.isAcceptableOrUnknown(data['catalog_id']!, _catalogIdMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Exercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Exercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      variation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}variation'],
      ),
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      ),
      targetMuscles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_muscles'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      instructionSource: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}instruction_source'],
      ),
      catalogId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}catalog_id'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $ExercisesTable createAlias(String alias) {
    return $ExercisesTable(attachedDatabase, alias);
  }
}

class Exercise extends DataClass implements Insertable<Exercise> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? variation;
  final String? equipment;
  final String? targetMuscles;
  final String? note;
  final String? instructionSource;

  /// ID of the built-in coached exercise this row logs, if any. Added in v2.
  final String? catalogId;

  /// Archived exercises stay linked to old sessions but leave the library.
  final bool archived;
  const Exercise({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.variation,
    this.equipment,
    this.targetMuscles,
    this.note,
    this.instructionSource,
    this.catalogId,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || variation != null) {
      map['variation'] = Variable<String>(variation);
    }
    if (!nullToAbsent || equipment != null) {
      map['equipment'] = Variable<String>(equipment);
    }
    if (!nullToAbsent || targetMuscles != null) {
      map['target_muscles'] = Variable<String>(targetMuscles);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || instructionSource != null) {
      map['instruction_source'] = Variable<String>(instructionSource);
    }
    if (!nullToAbsent || catalogId != null) {
      map['catalog_id'] = Variable<String>(catalogId);
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  ExercisesCompanion toCompanion(bool nullToAbsent) {
    return ExercisesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      variation: variation == null && nullToAbsent
          ? const Value.absent()
          : Value(variation),
      equipment: equipment == null && nullToAbsent
          ? const Value.absent()
          : Value(equipment),
      targetMuscles: targetMuscles == null && nullToAbsent
          ? const Value.absent()
          : Value(targetMuscles),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      instructionSource: instructionSource == null && nullToAbsent
          ? const Value.absent()
          : Value(instructionSource),
      catalogId: catalogId == null && nullToAbsent
          ? const Value.absent()
          : Value(catalogId),
      archived: Value(archived),
    );
  }

  factory Exercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Exercise(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      variation: serializer.fromJson<String?>(json['variation']),
      equipment: serializer.fromJson<String?>(json['equipment']),
      targetMuscles: serializer.fromJson<String?>(json['targetMuscles']),
      note: serializer.fromJson<String?>(json['note']),
      instructionSource: serializer.fromJson<String?>(
        json['instructionSource'],
      ),
      catalogId: serializer.fromJson<String?>(json['catalogId']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'variation': serializer.toJson<String?>(variation),
      'equipment': serializer.toJson<String?>(equipment),
      'targetMuscles': serializer.toJson<String?>(targetMuscles),
      'note': serializer.toJson<String?>(note),
      'instructionSource': serializer.toJson<String?>(instructionSource),
      'catalogId': serializer.toJson<String?>(catalogId),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  Exercise copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    Value<String?> variation = const Value.absent(),
    Value<String?> equipment = const Value.absent(),
    Value<String?> targetMuscles = const Value.absent(),
    Value<String?> note = const Value.absent(),
    Value<String?> instructionSource = const Value.absent(),
    Value<String?> catalogId = const Value.absent(),
    bool? archived,
  }) => Exercise(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    variation: variation.present ? variation.value : this.variation,
    equipment: equipment.present ? equipment.value : this.equipment,
    targetMuscles: targetMuscles.present
        ? targetMuscles.value
        : this.targetMuscles,
    note: note.present ? note.value : this.note,
    instructionSource: instructionSource.present
        ? instructionSource.value
        : this.instructionSource,
    catalogId: catalogId.present ? catalogId.value : this.catalogId,
    archived: archived ?? this.archived,
  );
  Exercise copyWithCompanion(ExercisesCompanion data) {
    return Exercise(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      variation: data.variation.present ? data.variation.value : this.variation,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      targetMuscles: data.targetMuscles.present
          ? data.targetMuscles.value
          : this.targetMuscles,
      note: data.note.present ? data.note.value : this.note,
      instructionSource: data.instructionSource.present
          ? data.instructionSource.value
          : this.instructionSource,
      catalogId: data.catalogId.present ? data.catalogId.value : this.catalogId,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Exercise(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('variation: $variation, ')
          ..write('equipment: $equipment, ')
          ..write('targetMuscles: $targetMuscles, ')
          ..write('note: $note, ')
          ..write('instructionSource: $instructionSource, ')
          ..write('catalogId: $catalogId, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    variation,
    equipment,
    targetMuscles,
    note,
    instructionSource,
    catalogId,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Exercise &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.variation == this.variation &&
          other.equipment == this.equipment &&
          other.targetMuscles == this.targetMuscles &&
          other.note == this.note &&
          other.instructionSource == this.instructionSource &&
          other.catalogId == this.catalogId &&
          other.archived == this.archived);
}

class ExercisesCompanion extends UpdateCompanion<Exercise> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String?> variation;
  final Value<String?> equipment;
  final Value<String?> targetMuscles;
  final Value<String?> note;
  final Value<String?> instructionSource;
  final Value<String?> catalogId;
  final Value<bool> archived;
  final Value<int> rowid;
  const ExercisesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.variation = const Value.absent(),
    this.equipment = const Value.absent(),
    this.targetMuscles = const Value.absent(),
    this.note = const Value.absent(),
    this.instructionSource = const Value.absent(),
    this.catalogId = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ExercisesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String name,
    this.variation = const Value.absent(),
    this.equipment = const Value.absent(),
    this.targetMuscles = const Value.absent(),
    this.note = const Value.absent(),
    this.instructionSource = const Value.absent(),
    this.catalogId = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name);
  static Insertable<Exercise> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? variation,
    Expression<String>? equipment,
    Expression<String>? targetMuscles,
    Expression<String>? note,
    Expression<String>? instructionSource,
    Expression<String>? catalogId,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (variation != null) 'variation': variation,
      if (equipment != null) 'equipment': equipment,
      if (targetMuscles != null) 'target_muscles': targetMuscles,
      if (note != null) 'note': note,
      if (instructionSource != null) 'instruction_source': instructionSource,
      if (catalogId != null) 'catalog_id': catalogId,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ExercisesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String?>? variation,
    Value<String?>? equipment,
    Value<String?>? targetMuscles,
    Value<String?>? note,
    Value<String?>? instructionSource,
    Value<String?>? catalogId,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return ExercisesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      variation: variation ?? this.variation,
      equipment: equipment ?? this.equipment,
      targetMuscles: targetMuscles ?? this.targetMuscles,
      note: note ?? this.note,
      instructionSource: instructionSource ?? this.instructionSource,
      catalogId: catalogId ?? this.catalogId,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (variation.present) {
      map['variation'] = Variable<String>(variation.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (targetMuscles.present) {
      map['target_muscles'] = Variable<String>(targetMuscles.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (instructionSource.present) {
      map['instruction_source'] = Variable<String>(instructionSource.value);
    }
    if (catalogId.present) {
      map['catalog_id'] = Variable<String>(catalogId.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ExercisesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('variation: $variation, ')
          ..write('equipment: $equipment, ')
          ..write('targetMuscles: $targetMuscles, ')
          ..write('note: $note, ')
          ..write('instructionSource: $instructionSource, ')
          ..write('catalogId: $catalogId, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutTemplatesTable extends WorkoutTemplates
    with TableInfo<$WorkoutTemplatesTable, WorkoutTemplate> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutTemplatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [id, createdAt, updatedAt, name, note];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_templates';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutTemplate> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutTemplate map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutTemplate(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $WorkoutTemplatesTable createAlias(String alias) {
    return $WorkoutTemplatesTable(attachedDatabase, alias);
  }
}

class WorkoutTemplate extends DataClass implements Insertable<WorkoutTemplate> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? note;
  const WorkoutTemplate({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  WorkoutTemplatesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutTemplatesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory WorkoutTemplate.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutTemplate(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'note': serializer.toJson<String?>(note),
    };
  }

  WorkoutTemplate copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    Value<String?> note = const Value.absent(),
  }) => WorkoutTemplate(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    note: note.present ? note.value : this.note,
  );
  WorkoutTemplate copyWithCompanion(WorkoutTemplatesCompanion data) {
    return WorkoutTemplate(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplate(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, createdAt, updatedAt, name, note);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutTemplate &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.note == this.note);
}

class WorkoutTemplatesCompanion extends UpdateCompanion<WorkoutTemplate> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String?> note;
  final Value<int> rowid;
  const WorkoutTemplatesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutTemplatesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String name,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name);
  static Insertable<WorkoutTemplate> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutTemplatesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return WorkoutTemplatesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutTemplatesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TemplateExercisesTable extends TemplateExercises
    with TableInfo<$TemplateExercisesTable, TemplateExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TemplateExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_templates (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetSetsMeta = const VerificationMeta(
    'targetSets',
  );
  @override
  late final GeneratedColumn<int> targetSets = GeneratedColumn<int>(
    'target_sets',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetRepsMeta = const VerificationMeta(
    'targetReps',
  );
  @override
  late final GeneratedColumn<int> targetReps = GeneratedColumn<int>(
    'target_reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    templateId,
    exerciseId,
    position,
    targetSets,
    targetReps,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'template_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<TemplateExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    } else if (isInserting) {
      context.missing(_templateIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('target_sets')) {
      context.handle(
        _targetSetsMeta,
        targetSets.isAcceptableOrUnknown(data['target_sets']!, _targetSetsMeta),
      );
    }
    if (data.containsKey('target_reps')) {
      context.handle(
        _targetRepsMeta,
        targetReps.isAcceptableOrUnknown(data['target_reps']!, _targetRepsMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  TemplateExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return TemplateExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      targetSets: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_sets'],
      ),
      targetReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_reps'],
      ),
    );
  }

  @override
  $TemplateExercisesTable createAlias(String alias) {
    return $TemplateExercisesTable(attachedDatabase, alias);
  }
}

class TemplateExercise extends DataClass
    implements Insertable<TemplateExercise> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String templateId;
  final String exerciseId;
  final int position;
  final int? targetSets;
  final int? targetReps;
  const TemplateExercise({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.templateId,
    required this.exerciseId,
    required this.position,
    this.targetSets,
    this.targetReps,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['template_id'] = Variable<String>(templateId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || targetSets != null) {
      map['target_sets'] = Variable<int>(targetSets);
    }
    if (!nullToAbsent || targetReps != null) {
      map['target_reps'] = Variable<int>(targetReps);
    }
    return map;
  }

  TemplateExercisesCompanion toCompanion(bool nullToAbsent) {
    return TemplateExercisesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      templateId: Value(templateId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      targetSets: targetSets == null && nullToAbsent
          ? const Value.absent()
          : Value(targetSets),
      targetReps: targetReps == null && nullToAbsent
          ? const Value.absent()
          : Value(targetReps),
    );
  }

  factory TemplateExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return TemplateExercise(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      templateId: serializer.fromJson<String>(json['templateId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      targetSets: serializer.fromJson<int?>(json['targetSets']),
      targetReps: serializer.fromJson<int?>(json['targetReps']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'templateId': serializer.toJson<String>(templateId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'targetSets': serializer.toJson<int?>(targetSets),
      'targetReps': serializer.toJson<int?>(targetReps),
    };
  }

  TemplateExercise copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? templateId,
    String? exerciseId,
    int? position,
    Value<int?> targetSets = const Value.absent(),
    Value<int?> targetReps = const Value.absent(),
  }) => TemplateExercise(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    templateId: templateId ?? this.templateId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    targetSets: targetSets.present ? targetSets.value : this.targetSets,
    targetReps: targetReps.present ? targetReps.value : this.targetReps,
  );
  TemplateExercise copyWithCompanion(TemplateExercisesCompanion data) {
    return TemplateExercise(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      targetSets: data.targetSets.present
          ? data.targetSets.value
          : this.targetSets,
      targetReps: data.targetReps.present
          ? data.targetReps.value
          : this.targetReps,
    );
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercise(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    templateId,
    exerciseId,
    position,
    targetSets,
    targetReps,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is TemplateExercise &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.templateId == this.templateId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.targetSets == this.targetSets &&
          other.targetReps == this.targetReps);
}

class TemplateExercisesCompanion extends UpdateCompanion<TemplateExercise> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> templateId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<int?> targetSets;
  final Value<int?> targetReps;
  final Value<int> rowid;
  const TemplateExercisesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.templateId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TemplateExercisesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String templateId,
    required String exerciseId,
    required int position,
    this.targetSets = const Value.absent(),
    this.targetReps = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       templateId = Value(templateId),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<TemplateExercise> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? templateId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<int>? targetSets,
    Expression<int>? targetReps,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (templateId != null) 'template_id': templateId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (targetSets != null) 'target_sets': targetSets,
      if (targetReps != null) 'target_reps': targetReps,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TemplateExercisesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? templateId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<int?>? targetSets,
    Value<int?>? targetReps,
    Value<int>? rowid,
  }) {
    return TemplateExercisesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      templateId: templateId ?? this.templateId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      targetSets: targetSets ?? this.targetSets,
      targetReps: targetReps ?? this.targetReps,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (targetSets.present) {
      map['target_sets'] = Variable<int>(targetSets.value);
    }
    if (targetReps.present) {
      map['target_reps'] = Variable<int>(targetReps.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TemplateExercisesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('templateId: $templateId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('targetSets: $targetSets, ')
          ..write('targetReps: $targetReps, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSession> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SessionStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SessionStatus>($WorkoutSessionsTable.$converterstatus);
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endedAtMeta = const VerificationMeta(
    'endedAt',
  );
  @override
  late final GeneratedColumn<DateTime> endedAt = GeneratedColumn<DateTime>(
    'ended_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pausedMsMeta = const VerificationMeta(
    'pausedMs',
  );
  @override
  late final GeneratedColumn<int> pausedMs = GeneratedColumn<int>(
    'paused_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _pausedAtMeta = const VerificationMeta(
    'pausedAt',
  );
  @override
  late final GeneratedColumn<DateTime> pausedAt = GeneratedColumn<DateTime>(
    'paused_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restStartedAtMeta = const VerificationMeta(
    'restStartedAt',
  );
  @override
  late final GeneratedColumn<DateTime> restStartedAt =
      GeneratedColumn<DateTime>(
        'rest_started_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _restTargetSecMeta = const VerificationMeta(
    'restTargetSec',
  );
  @override
  late final GeneratedColumn<int> restTargetSec = GeneratedColumn<int>(
    'rest_target_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _utcOffsetMinutesMeta = const VerificationMeta(
    'utcOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> utcOffsetMinutes = GeneratedColumn<int>(
    'utc_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timeZoneNameMeta = const VerificationMeta(
    'timeZoneName',
  );
  @override
  late final GeneratedColumn<String> timeZoneName = GeneratedColumn<String>(
    'time_zone_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _programIdMeta = const VerificationMeta(
    'programId',
  );
  @override
  late final GeneratedColumn<String> programId = GeneratedColumn<String>(
    'program_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _programDayMeta = const VerificationMeta(
    'programDay',
  );
  @override
  late final GeneratedColumn<int> programDay = GeneratedColumn<int>(
    'program_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    templateId,
    name,
    status,
    startedAt,
    endedAt,
    pausedMs,
    pausedAt,
    restStartedAt,
    restTargetSec,
    utcOffsetMinutes,
    timeZoneName,
    note,
    programId,
    programDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
    Insertable<WorkoutSession> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(
        _endedAtMeta,
        endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta),
      );
    }
    if (data.containsKey('paused_ms')) {
      context.handle(
        _pausedMsMeta,
        pausedMs.isAcceptableOrUnknown(data['paused_ms']!, _pausedMsMeta),
      );
    }
    if (data.containsKey('paused_at')) {
      context.handle(
        _pausedAtMeta,
        pausedAt.isAcceptableOrUnknown(data['paused_at']!, _pausedAtMeta),
      );
    }
    if (data.containsKey('rest_started_at')) {
      context.handle(
        _restStartedAtMeta,
        restStartedAt.isAcceptableOrUnknown(
          data['rest_started_at']!,
          _restStartedAtMeta,
        ),
      );
    }
    if (data.containsKey('rest_target_sec')) {
      context.handle(
        _restTargetSecMeta,
        restTargetSec.isAcceptableOrUnknown(
          data['rest_target_sec']!,
          _restTargetSecMeta,
        ),
      );
    }
    if (data.containsKey('utc_offset_minutes')) {
      context.handle(
        _utcOffsetMinutesMeta,
        utcOffsetMinutes.isAcceptableOrUnknown(
          data['utc_offset_minutes']!,
          _utcOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_utcOffsetMinutesMeta);
    }
    if (data.containsKey('time_zone_name')) {
      context.handle(
        _timeZoneNameMeta,
        timeZoneName.isAcceptableOrUnknown(
          data['time_zone_name']!,
          _timeZoneNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneNameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('program_id')) {
      context.handle(
        _programIdMeta,
        programId.isAcceptableOrUnknown(data['program_id']!, _programIdMeta),
      );
    }
    if (data.containsKey('program_day')) {
      context.handle(
        _programDayMeta,
        programDay.isAcceptableOrUnknown(data['program_day']!, _programDayMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WorkoutSession map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSession(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      status: $WorkoutSessionsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      )!,
      endedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}ended_at'],
      ),
      pausedMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}paused_ms'],
      )!,
      pausedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}paused_at'],
      ),
      restStartedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}rest_started_at'],
      ),
      restTargetSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_target_sec'],
      ),
      utcOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}utc_offset_minutes'],
      )!,
      timeZoneName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      programId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}program_id'],
      ),
      programDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}program_day'],
      ),
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SessionStatus, String, String> $converterstatus =
      const EnumNameConverter<SessionStatus>(SessionStatus.values);
}

class WorkoutSession extends DataClass implements Insertable<WorkoutSession> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? templateId;
  final String name;
  final SessionStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;

  /// Total paused time before the current pause, in milliseconds.
  final int pausedMs;
  final DateTime? pausedAt;

  /// Rest timer. It is stored so it survives a restart.
  final DateTime? restStartedAt;
  final int? restTargetSec;

  /// UTC offset and zone name when the session started. Used for the day view.
  final int utcOffsetMinutes;
  final String timeZoneName;
  final String? note;

  /// Roadmap day this session came from, if any. Added in v4.
  final String? programId;
  final int? programDay;
  const WorkoutSession({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.templateId,
    required this.name,
    required this.status,
    required this.startedAt,
    this.endedAt,
    required this.pausedMs,
    this.pausedAt,
    this.restStartedAt,
    this.restTargetSec,
    required this.utcOffsetMinutes,
    required this.timeZoneName,
    this.note,
    this.programId,
    this.programDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    map['name'] = Variable<String>(name);
    {
      map['status'] = Variable<String>(
        $WorkoutSessionsTable.$converterstatus.toSql(status),
      );
    }
    map['started_at'] = Variable<DateTime>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<DateTime>(endedAt);
    }
    map['paused_ms'] = Variable<int>(pausedMs);
    if (!nullToAbsent || pausedAt != null) {
      map['paused_at'] = Variable<DateTime>(pausedAt);
    }
    if (!nullToAbsent || restStartedAt != null) {
      map['rest_started_at'] = Variable<DateTime>(restStartedAt);
    }
    if (!nullToAbsent || restTargetSec != null) {
      map['rest_target_sec'] = Variable<int>(restTargetSec);
    }
    map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes);
    map['time_zone_name'] = Variable<String>(timeZoneName);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    if (!nullToAbsent || programId != null) {
      map['program_id'] = Variable<String>(programId);
    }
    if (!nullToAbsent || programDay != null) {
      map['program_day'] = Variable<int>(programDay);
    }
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
      name: Value(name),
      status: Value(status),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      pausedMs: Value(pausedMs),
      pausedAt: pausedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(pausedAt),
      restStartedAt: restStartedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(restStartedAt),
      restTargetSec: restTargetSec == null && nullToAbsent
          ? const Value.absent()
          : Value(restTargetSec),
      utcOffsetMinutes: Value(utcOffsetMinutes),
      timeZoneName: Value(timeZoneName),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      programId: programId == null && nullToAbsent
          ? const Value.absent()
          : Value(programId),
      programDay: programDay == null && nullToAbsent
          ? const Value.absent()
          : Value(programDay),
    );
  }

  factory WorkoutSession.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSession(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      templateId: serializer.fromJson<String?>(json['templateId']),
      name: serializer.fromJson<String>(json['name']),
      status: $WorkoutSessionsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      startedAt: serializer.fromJson<DateTime>(json['startedAt']),
      endedAt: serializer.fromJson<DateTime?>(json['endedAt']),
      pausedMs: serializer.fromJson<int>(json['pausedMs']),
      pausedAt: serializer.fromJson<DateTime?>(json['pausedAt']),
      restStartedAt: serializer.fromJson<DateTime?>(json['restStartedAt']),
      restTargetSec: serializer.fromJson<int?>(json['restTargetSec']),
      utcOffsetMinutes: serializer.fromJson<int>(json['utcOffsetMinutes']),
      timeZoneName: serializer.fromJson<String>(json['timeZoneName']),
      note: serializer.fromJson<String?>(json['note']),
      programId: serializer.fromJson<String?>(json['programId']),
      programDay: serializer.fromJson<int?>(json['programDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'templateId': serializer.toJson<String?>(templateId),
      'name': serializer.toJson<String>(name),
      'status': serializer.toJson<String>(
        $WorkoutSessionsTable.$converterstatus.toJson(status),
      ),
      'startedAt': serializer.toJson<DateTime>(startedAt),
      'endedAt': serializer.toJson<DateTime?>(endedAt),
      'pausedMs': serializer.toJson<int>(pausedMs),
      'pausedAt': serializer.toJson<DateTime?>(pausedAt),
      'restStartedAt': serializer.toJson<DateTime?>(restStartedAt),
      'restTargetSec': serializer.toJson<int?>(restTargetSec),
      'utcOffsetMinutes': serializer.toJson<int>(utcOffsetMinutes),
      'timeZoneName': serializer.toJson<String>(timeZoneName),
      'note': serializer.toJson<String?>(note),
      'programId': serializer.toJson<String?>(programId),
      'programDay': serializer.toJson<int?>(programDay),
    };
  }

  WorkoutSession copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    Value<String?> templateId = const Value.absent(),
    String? name,
    SessionStatus? status,
    DateTime? startedAt,
    Value<DateTime?> endedAt = const Value.absent(),
    int? pausedMs,
    Value<DateTime?> pausedAt = const Value.absent(),
    Value<DateTime?> restStartedAt = const Value.absent(),
    Value<int?> restTargetSec = const Value.absent(),
    int? utcOffsetMinutes,
    String? timeZoneName,
    Value<String?> note = const Value.absent(),
    Value<String?> programId = const Value.absent(),
    Value<int?> programDay = const Value.absent(),
  }) => WorkoutSession(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    templateId: templateId.present ? templateId.value : this.templateId,
    name: name ?? this.name,
    status: status ?? this.status,
    startedAt: startedAt ?? this.startedAt,
    endedAt: endedAt.present ? endedAt.value : this.endedAt,
    pausedMs: pausedMs ?? this.pausedMs,
    pausedAt: pausedAt.present ? pausedAt.value : this.pausedAt,
    restStartedAt: restStartedAt.present
        ? restStartedAt.value
        : this.restStartedAt,
    restTargetSec: restTargetSec.present
        ? restTargetSec.value
        : this.restTargetSec,
    utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
    timeZoneName: timeZoneName ?? this.timeZoneName,
    note: note.present ? note.value : this.note,
    programId: programId.present ? programId.value : this.programId,
    programDay: programDay.present ? programDay.value : this.programDay,
  );
  WorkoutSession copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSession(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
      name: data.name.present ? data.name.value : this.name,
      status: data.status.present ? data.status.value : this.status,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      pausedMs: data.pausedMs.present ? data.pausedMs.value : this.pausedMs,
      pausedAt: data.pausedAt.present ? data.pausedAt.value : this.pausedAt,
      restStartedAt: data.restStartedAt.present
          ? data.restStartedAt.value
          : this.restStartedAt,
      restTargetSec: data.restTargetSec.present
          ? data.restTargetSec.value
          : this.restTargetSec,
      utcOffsetMinutes: data.utcOffsetMinutes.present
          ? data.utcOffsetMinutes.value
          : this.utcOffsetMinutes,
      timeZoneName: data.timeZoneName.present
          ? data.timeZoneName.value
          : this.timeZoneName,
      note: data.note.present ? data.note.value : this.note,
      programId: data.programId.present ? data.programId.value : this.programId,
      programDay: data.programDay.present
          ? data.programDay.value
          : this.programDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSession(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pausedMs: $pausedMs, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('restStartedAt: $restStartedAt, ')
          ..write('restTargetSec: $restTargetSec, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('timeZoneName: $timeZoneName, ')
          ..write('note: $note, ')
          ..write('programId: $programId, ')
          ..write('programDay: $programDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    templateId,
    name,
    status,
    startedAt,
    endedAt,
    pausedMs,
    pausedAt,
    restStartedAt,
    restTargetSec,
    utcOffsetMinutes,
    timeZoneName,
    note,
    programId,
    programDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSession &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.templateId == this.templateId &&
          other.name == this.name &&
          other.status == this.status &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.pausedMs == this.pausedMs &&
          other.pausedAt == this.pausedAt &&
          other.restStartedAt == this.restStartedAt &&
          other.restTargetSec == this.restTargetSec &&
          other.utcOffsetMinutes == this.utcOffsetMinutes &&
          other.timeZoneName == this.timeZoneName &&
          other.note == this.note &&
          other.programId == this.programId &&
          other.programDay == this.programDay);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSession> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String?> templateId;
  final Value<String> name;
  final Value<SessionStatus> status;
  final Value<DateTime> startedAt;
  final Value<DateTime?> endedAt;
  final Value<int> pausedMs;
  final Value<DateTime?> pausedAt;
  final Value<DateTime?> restStartedAt;
  final Value<int?> restTargetSec;
  final Value<int> utcOffsetMinutes;
  final Value<String> timeZoneName;
  final Value<String?> note;
  final Value<String?> programId;
  final Value<int?> programDay;
  final Value<int> rowid;
  const WorkoutSessionsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.templateId = const Value.absent(),
    this.name = const Value.absent(),
    this.status = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.pausedMs = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.restStartedAt = const Value.absent(),
    this.restTargetSec = const Value.absent(),
    this.utcOffsetMinutes = const Value.absent(),
    this.timeZoneName = const Value.absent(),
    this.note = const Value.absent(),
    this.programId = const Value.absent(),
    this.programDay = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.templateId = const Value.absent(),
    required String name,
    required SessionStatus status,
    required DateTime startedAt,
    this.endedAt = const Value.absent(),
    this.pausedMs = const Value.absent(),
    this.pausedAt = const Value.absent(),
    this.restStartedAt = const Value.absent(),
    this.restTargetSec = const Value.absent(),
    required int utcOffsetMinutes,
    required String timeZoneName,
    this.note = const Value.absent(),
    this.programId = const Value.absent(),
    this.programDay = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       status = Value(status),
       startedAt = Value(startedAt),
       utcOffsetMinutes = Value(utcOffsetMinutes),
       timeZoneName = Value(timeZoneName);
  static Insertable<WorkoutSession> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? templateId,
    Expression<String>? name,
    Expression<String>? status,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? endedAt,
    Expression<int>? pausedMs,
    Expression<DateTime>? pausedAt,
    Expression<DateTime>? restStartedAt,
    Expression<int>? restTargetSec,
    Expression<int>? utcOffsetMinutes,
    Expression<String>? timeZoneName,
    Expression<String>? note,
    Expression<String>? programId,
    Expression<int>? programDay,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (templateId != null) 'template_id': templateId,
      if (name != null) 'name': name,
      if (status != null) 'status': status,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (pausedMs != null) 'paused_ms': pausedMs,
      if (pausedAt != null) 'paused_at': pausedAt,
      if (restStartedAt != null) 'rest_started_at': restStartedAt,
      if (restTargetSec != null) 'rest_target_sec': restTargetSec,
      if (utcOffsetMinutes != null) 'utc_offset_minutes': utcOffsetMinutes,
      if (timeZoneName != null) 'time_zone_name': timeZoneName,
      if (note != null) 'note': note,
      if (programId != null) 'program_id': programId,
      if (programDay != null) 'program_day': programDay,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSessionsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String?>? templateId,
    Value<String>? name,
    Value<SessionStatus>? status,
    Value<DateTime>? startedAt,
    Value<DateTime?>? endedAt,
    Value<int>? pausedMs,
    Value<DateTime?>? pausedAt,
    Value<DateTime?>? restStartedAt,
    Value<int?>? restTargetSec,
    Value<int>? utcOffsetMinutes,
    Value<String>? timeZoneName,
    Value<String?>? note,
    Value<String?>? programId,
    Value<int?>? programDay,
    Value<int>? rowid,
  }) {
    return WorkoutSessionsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      templateId: templateId ?? this.templateId,
      name: name ?? this.name,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      pausedMs: pausedMs ?? this.pausedMs,
      pausedAt: pausedAt ?? this.pausedAt,
      restStartedAt: restStartedAt ?? this.restStartedAt,
      restTargetSec: restTargetSec ?? this.restTargetSec,
      utcOffsetMinutes: utcOffsetMinutes ?? this.utcOffsetMinutes,
      timeZoneName: timeZoneName ?? this.timeZoneName,
      note: note ?? this.note,
      programId: programId ?? this.programId,
      programDay: programDay ?? this.programDay,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $WorkoutSessionsTable.$converterstatus.toSql(status.value),
      );
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<DateTime>(endedAt.value);
    }
    if (pausedMs.present) {
      map['paused_ms'] = Variable<int>(pausedMs.value);
    }
    if (pausedAt.present) {
      map['paused_at'] = Variable<DateTime>(pausedAt.value);
    }
    if (restStartedAt.present) {
      map['rest_started_at'] = Variable<DateTime>(restStartedAt.value);
    }
    if (restTargetSec.present) {
      map['rest_target_sec'] = Variable<int>(restTargetSec.value);
    }
    if (utcOffsetMinutes.present) {
      map['utc_offset_minutes'] = Variable<int>(utcOffsetMinutes.value);
    }
    if (timeZoneName.present) {
      map['time_zone_name'] = Variable<String>(timeZoneName.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (programId.present) {
      map['program_id'] = Variable<String>(programId.value);
    }
    if (programDay.present) {
      map['program_day'] = Variable<int>(programDay.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('templateId: $templateId, ')
          ..write('name: $name, ')
          ..write('status: $status, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('pausedMs: $pausedMs, ')
          ..write('pausedAt: $pausedAt, ')
          ..write('restStartedAt: $restStartedAt, ')
          ..write('restTargetSec: $restTargetSec, ')
          ..write('utcOffsetMinutes: $utcOffsetMinutes, ')
          ..write('timeZoneName: $timeZoneName, ')
          ..write('note: $note, ')
          ..write('programId: $programId, ')
          ..write('programDay: $programDay, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SessionExercisesTable extends SessionExercises
    with TableInfo<$SessionExercisesTable, SessionExercise> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SessionExercisesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionIdMeta = const VerificationMeta(
    'sessionId',
  );
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
    'session_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES workout_sessions (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES exercises (id)',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _supersetGroupMeta = const VerificationMeta(
    'supersetGroup',
  );
  @override
  late final GeneratedColumn<String> supersetGroup = GeneratedColumn<String>(
    'superset_group',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _skippedMeta = const VerificationMeta(
    'skipped',
  );
  @override
  late final GeneratedColumn<bool> skipped = GeneratedColumn<bool>(
    'skipped',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("skipped" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    sessionId,
    exerciseId,
    position,
    supersetGroup,
    skipped,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'session_exercises';
  @override
  VerificationContext validateIntegrity(
    Insertable<SessionExercise> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(
        _sessionIdMeta,
        sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('superset_group')) {
      context.handle(
        _supersetGroupMeta,
        supersetGroup.isAcceptableOrUnknown(
          data['superset_group']!,
          _supersetGroupMeta,
        ),
      );
    }
    if (data.containsKey('skipped')) {
      context.handle(
        _skippedMeta,
        skipped.isAcceptableOrUnknown(data['skipped']!, _skippedMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SessionExercise map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SessionExercise(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sessionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      supersetGroup: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}superset_group'],
      ),
      skipped: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}skipped'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $SessionExercisesTable createAlias(String alias) {
    return $SessionExercisesTable(attachedDatabase, alias);
  }
}

class SessionExercise extends DataClass implements Insertable<SessionExercise> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sessionId;
  final String exerciseId;
  final int position;
  final String? supersetGroup;
  final bool skipped;
  final String? note;
  const SessionExercise({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.sessionId,
    required this.exerciseId,
    required this.position,
    this.supersetGroup,
    required this.skipped,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['session_id'] = Variable<String>(sessionId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || supersetGroup != null) {
      map['superset_group'] = Variable<String>(supersetGroup);
    }
    map['skipped'] = Variable<bool>(skipped);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  SessionExercisesCompanion toCompanion(bool nullToAbsent) {
    return SessionExercisesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sessionId: Value(sessionId),
      exerciseId: Value(exerciseId),
      position: Value(position),
      supersetGroup: supersetGroup == null && nullToAbsent
          ? const Value.absent()
          : Value(supersetGroup),
      skipped: Value(skipped),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory SessionExercise.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SessionExercise(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      position: serializer.fromJson<int>(json['position']),
      supersetGroup: serializer.fromJson<String?>(json['supersetGroup']),
      skipped: serializer.fromJson<bool>(json['skipped']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sessionId': serializer.toJson<String>(sessionId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'position': serializer.toJson<int>(position),
      'supersetGroup': serializer.toJson<String?>(supersetGroup),
      'skipped': serializer.toJson<bool>(skipped),
      'note': serializer.toJson<String?>(note),
    };
  }

  SessionExercise copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sessionId,
    String? exerciseId,
    int? position,
    Value<String?> supersetGroup = const Value.absent(),
    bool? skipped,
    Value<String?> note = const Value.absent(),
  }) => SessionExercise(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sessionId: sessionId ?? this.sessionId,
    exerciseId: exerciseId ?? this.exerciseId,
    position: position ?? this.position,
    supersetGroup: supersetGroup.present
        ? supersetGroup.value
        : this.supersetGroup,
    skipped: skipped ?? this.skipped,
    note: note.present ? note.value : this.note,
  );
  SessionExercise copyWithCompanion(SessionExercisesCompanion data) {
    return SessionExercise(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      position: data.position.present ? data.position.value : this.position,
      supersetGroup: data.supersetGroup.present
          ? data.supersetGroup.value
          : this.supersetGroup,
      skipped: data.skipped.present ? data.skipped.value : this.skipped,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercise(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('skipped: $skipped, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    sessionId,
    exerciseId,
    position,
    supersetGroup,
    skipped,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SessionExercise &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sessionId == this.sessionId &&
          other.exerciseId == this.exerciseId &&
          other.position == this.position &&
          other.supersetGroup == this.supersetGroup &&
          other.skipped == this.skipped &&
          other.note == this.note);
}

class SessionExercisesCompanion extends UpdateCompanion<SessionExercise> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> sessionId;
  final Value<String> exerciseId;
  final Value<int> position;
  final Value<String?> supersetGroup;
  final Value<bool> skipped;
  final Value<String?> note;
  final Value<int> rowid;
  const SessionExercisesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.supersetGroup = const Value.absent(),
    this.skipped = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SessionExercisesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String sessionId,
    required String exerciseId,
    required int position,
    this.supersetGroup = const Value.absent(),
    this.skipped = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       sessionId = Value(sessionId),
       exerciseId = Value(exerciseId),
       position = Value(position);
  static Insertable<SessionExercise> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? sessionId,
    Expression<String>? exerciseId,
    Expression<int>? position,
    Expression<String>? supersetGroup,
    Expression<bool>? skipped,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sessionId != null) 'session_id': sessionId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (position != null) 'position': position,
      if (supersetGroup != null) 'superset_group': supersetGroup,
      if (skipped != null) 'skipped': skipped,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SessionExercisesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? sessionId,
    Value<String>? exerciseId,
    Value<int>? position,
    Value<String?>? supersetGroup,
    Value<bool>? skipped,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return SessionExercisesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionId: sessionId ?? this.sessionId,
      exerciseId: exerciseId ?? this.exerciseId,
      position: position ?? this.position,
      supersetGroup: supersetGroup ?? this.supersetGroup,
      skipped: skipped ?? this.skipped,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (supersetGroup.present) {
      map['superset_group'] = Variable<String>(supersetGroup.value);
    }
    if (skipped.present) {
      map['skipped'] = Variable<bool>(skipped.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SessionExercisesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sessionId: $sessionId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('position: $position, ')
          ..write('supersetGroup: $supersetGroup, ')
          ..write('skipped: $skipped, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetEntriesTable extends SetEntries
    with TableInfo<$SetEntriesTable, SetEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sessionExerciseIdMeta = const VerificationMeta(
    'sessionExerciseId',
  );
  @override
  late final GeneratedColumn<String> sessionExerciseId =
      GeneratedColumn<String>(
        'session_exercise_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        defaultConstraints: GeneratedColumn.constraintIsAlways(
          'REFERENCES session_exercises (id) ON DELETE CASCADE',
        ),
      );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<SetType, String> setType =
      GeneratedColumn<String>(
        'set_type',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<SetType>($SetEntriesTable.$convertersetType);
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loadMeta = const VerificationMeta('load');
  @override
  late final GeneratedColumn<double> load = GeneratedColumn<double>(
    'load',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _loadUnitMeta = const VerificationMeta(
    'loadUnit',
  );
  @override
  late final GeneratedColumn<String> loadUnit = GeneratedColumn<String>(
    'load_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _durationSecMeta = const VerificationMeta(
    'durationSec',
  );
  @override
  late final GeneratedColumn<int> durationSec = GeneratedColumn<int>(
    'duration_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceMeta = const VerificationMeta(
    'distance',
  );
  @override
  late final GeneratedColumn<double> distance = GeneratedColumn<double>(
    'distance',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _distanceUnitMeta = const VerificationMeta(
    'distanceUnit',
  );
  @override
  late final GeneratedColumn<String> distanceUnit = GeneratedColumn<String>(
    'distance_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _restSecMeta = const VerificationMeta(
    'restSec',
  );
  @override
  late final GeneratedColumn<int> restSec = GeneratedColumn<int>(
    'rest_sec',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _effortMeta = const VerificationMeta('effort');
  @override
  late final GeneratedColumn<double> effort = GeneratedColumn<double>(
    'effort',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedMeta = const VerificationMeta(
    'completed',
  );
  @override
  late final GeneratedColumn<bool> completed = GeneratedColumn<bool>(
    'completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("completed" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    sessionExerciseId,
    position,
    setType,
    reps,
    load,
    loadUnit,
    durationSec,
    distance,
    distanceUnit,
    restSec,
    effort,
    note,
    completed,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('session_exercise_id')) {
      context.handle(
        _sessionExerciseIdMeta,
        sessionExerciseId.isAcceptableOrUnknown(
          data['session_exercise_id']!,
          _sessionExerciseIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sessionExerciseIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('load')) {
      context.handle(
        _loadMeta,
        load.isAcceptableOrUnknown(data['load']!, _loadMeta),
      );
    }
    if (data.containsKey('load_unit')) {
      context.handle(
        _loadUnitMeta,
        loadUnit.isAcceptableOrUnknown(data['load_unit']!, _loadUnitMeta),
      );
    }
    if (data.containsKey('duration_sec')) {
      context.handle(
        _durationSecMeta,
        durationSec.isAcceptableOrUnknown(
          data['duration_sec']!,
          _durationSecMeta,
        ),
      );
    }
    if (data.containsKey('distance')) {
      context.handle(
        _distanceMeta,
        distance.isAcceptableOrUnknown(data['distance']!, _distanceMeta),
      );
    }
    if (data.containsKey('distance_unit')) {
      context.handle(
        _distanceUnitMeta,
        distanceUnit.isAcceptableOrUnknown(
          data['distance_unit']!,
          _distanceUnitMeta,
        ),
      );
    }
    if (data.containsKey('rest_sec')) {
      context.handle(
        _restSecMeta,
        restSec.isAcceptableOrUnknown(data['rest_sec']!, _restSecMeta),
      );
    }
    if (data.containsKey('effort')) {
      context.handle(
        _effortMeta,
        effort.isAcceptableOrUnknown(data['effort']!, _effortMeta),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    if (data.containsKey('completed')) {
      context.handle(
        _completedMeta,
        completed.isAcceptableOrUnknown(data['completed']!, _completedMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      sessionExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}session_exercise_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      setType: $SetEntriesTable.$convertersetType.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}set_type'],
        )!,
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      ),
      load: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}load'],
      ),
      loadUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}load_unit'],
      ),
      durationSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_sec'],
      ),
      distance: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}distance'],
      ),
      distanceUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}distance_unit'],
      ),
      restSec: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}rest_sec'],
      ),
      effort: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}effort'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
      completed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}completed'],
      )!,
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $SetEntriesTable createAlias(String alias) {
    return $SetEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<SetType, String, String> $convertersetType =
      const EnumNameConverter<SetType>(SetType.values);
}

class SetEntry extends DataClass implements Insertable<SetEntry> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String sessionExerciseId;
  final int position;
  final SetType setType;
  final int? reps;
  final double? load;
  final String? loadUnit;
  final int? durationSec;
  final double? distance;
  final String? distanceUnit;
  final int? restSec;
  final double? effort;
  final String? note;
  final bool completed;
  final DateTime? completedAt;
  const SetEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.sessionExerciseId,
    required this.position,
    required this.setType,
    this.reps,
    this.load,
    this.loadUnit,
    this.durationSec,
    this.distance,
    this.distanceUnit,
    this.restSec,
    this.effort,
    this.note,
    required this.completed,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['session_exercise_id'] = Variable<String>(sessionExerciseId);
    map['position'] = Variable<int>(position);
    {
      map['set_type'] = Variable<String>(
        $SetEntriesTable.$convertersetType.toSql(setType),
      );
    }
    if (!nullToAbsent || reps != null) {
      map['reps'] = Variable<int>(reps);
    }
    if (!nullToAbsent || load != null) {
      map['load'] = Variable<double>(load);
    }
    if (!nullToAbsent || loadUnit != null) {
      map['load_unit'] = Variable<String>(loadUnit);
    }
    if (!nullToAbsent || durationSec != null) {
      map['duration_sec'] = Variable<int>(durationSec);
    }
    if (!nullToAbsent || distance != null) {
      map['distance'] = Variable<double>(distance);
    }
    if (!nullToAbsent || distanceUnit != null) {
      map['distance_unit'] = Variable<String>(distanceUnit);
    }
    if (!nullToAbsent || restSec != null) {
      map['rest_sec'] = Variable<int>(restSec);
    }
    if (!nullToAbsent || effort != null) {
      map['effort'] = Variable<double>(effort);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    map['completed'] = Variable<bool>(completed);
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  SetEntriesCompanion toCompanion(bool nullToAbsent) {
    return SetEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      sessionExerciseId: Value(sessionExerciseId),
      position: Value(position),
      setType: Value(setType),
      reps: reps == null && nullToAbsent ? const Value.absent() : Value(reps),
      load: load == null && nullToAbsent ? const Value.absent() : Value(load),
      loadUnit: loadUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(loadUnit),
      durationSec: durationSec == null && nullToAbsent
          ? const Value.absent()
          : Value(durationSec),
      distance: distance == null && nullToAbsent
          ? const Value.absent()
          : Value(distance),
      distanceUnit: distanceUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(distanceUnit),
      restSec: restSec == null && nullToAbsent
          ? const Value.absent()
          : Value(restSec),
      effort: effort == null && nullToAbsent
          ? const Value.absent()
          : Value(effort),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
      completed: Value(completed),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory SetEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetEntry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      sessionExerciseId: serializer.fromJson<String>(json['sessionExerciseId']),
      position: serializer.fromJson<int>(json['position']),
      setType: $SetEntriesTable.$convertersetType.fromJson(
        serializer.fromJson<String>(json['setType']),
      ),
      reps: serializer.fromJson<int?>(json['reps']),
      load: serializer.fromJson<double?>(json['load']),
      loadUnit: serializer.fromJson<String?>(json['loadUnit']),
      durationSec: serializer.fromJson<int?>(json['durationSec']),
      distance: serializer.fromJson<double?>(json['distance']),
      distanceUnit: serializer.fromJson<String?>(json['distanceUnit']),
      restSec: serializer.fromJson<int?>(json['restSec']),
      effort: serializer.fromJson<double?>(json['effort']),
      note: serializer.fromJson<String?>(json['note']),
      completed: serializer.fromJson<bool>(json['completed']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'sessionExerciseId': serializer.toJson<String>(sessionExerciseId),
      'position': serializer.toJson<int>(position),
      'setType': serializer.toJson<String>(
        $SetEntriesTable.$convertersetType.toJson(setType),
      ),
      'reps': serializer.toJson<int?>(reps),
      'load': serializer.toJson<double?>(load),
      'loadUnit': serializer.toJson<String?>(loadUnit),
      'durationSec': serializer.toJson<int?>(durationSec),
      'distance': serializer.toJson<double?>(distance),
      'distanceUnit': serializer.toJson<String?>(distanceUnit),
      'restSec': serializer.toJson<int?>(restSec),
      'effort': serializer.toJson<double?>(effort),
      'note': serializer.toJson<String?>(note),
      'completed': serializer.toJson<bool>(completed),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  SetEntry copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sessionExerciseId,
    int? position,
    SetType? setType,
    Value<int?> reps = const Value.absent(),
    Value<double?> load = const Value.absent(),
    Value<String?> loadUnit = const Value.absent(),
    Value<int?> durationSec = const Value.absent(),
    Value<double?> distance = const Value.absent(),
    Value<String?> distanceUnit = const Value.absent(),
    Value<int?> restSec = const Value.absent(),
    Value<double?> effort = const Value.absent(),
    Value<String?> note = const Value.absent(),
    bool? completed,
    Value<DateTime?> completedAt = const Value.absent(),
  }) => SetEntry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
    position: position ?? this.position,
    setType: setType ?? this.setType,
    reps: reps.present ? reps.value : this.reps,
    load: load.present ? load.value : this.load,
    loadUnit: loadUnit.present ? loadUnit.value : this.loadUnit,
    durationSec: durationSec.present ? durationSec.value : this.durationSec,
    distance: distance.present ? distance.value : this.distance,
    distanceUnit: distanceUnit.present ? distanceUnit.value : this.distanceUnit,
    restSec: restSec.present ? restSec.value : this.restSec,
    effort: effort.present ? effort.value : this.effort,
    note: note.present ? note.value : this.note,
    completed: completed ?? this.completed,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  SetEntry copyWithCompanion(SetEntriesCompanion data) {
    return SetEntry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      sessionExerciseId: data.sessionExerciseId.present
          ? data.sessionExerciseId.value
          : this.sessionExerciseId,
      position: data.position.present ? data.position.value : this.position,
      setType: data.setType.present ? data.setType.value : this.setType,
      reps: data.reps.present ? data.reps.value : this.reps,
      load: data.load.present ? data.load.value : this.load,
      loadUnit: data.loadUnit.present ? data.loadUnit.value : this.loadUnit,
      durationSec: data.durationSec.present
          ? data.durationSec.value
          : this.durationSec,
      distance: data.distance.present ? data.distance.value : this.distance,
      distanceUnit: data.distanceUnit.present
          ? data.distanceUnit.value
          : this.distanceUnit,
      restSec: data.restSec.present ? data.restSec.value : this.restSec,
      effort: data.effort.present ? data.effort.value : this.effort,
      note: data.note.present ? data.note.value : this.note,
      completed: data.completed.present ? data.completed.value : this.completed,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetEntry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('position: $position, ')
          ..write('setType: $setType, ')
          ..write('reps: $reps, ')
          ..write('load: $load, ')
          ..write('loadUnit: $loadUnit, ')
          ..write('durationSec: $durationSec, ')
          ..write('distance: $distance, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('restSec: $restSec, ')
          ..write('effort: $effort, ')
          ..write('note: $note, ')
          ..write('completed: $completed, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    sessionExerciseId,
    position,
    setType,
    reps,
    load,
    loadUnit,
    durationSec,
    distance,
    distanceUnit,
    restSec,
    effort,
    note,
    completed,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetEntry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.sessionExerciseId == this.sessionExerciseId &&
          other.position == this.position &&
          other.setType == this.setType &&
          other.reps == this.reps &&
          other.load == this.load &&
          other.loadUnit == this.loadUnit &&
          other.durationSec == this.durationSec &&
          other.distance == this.distance &&
          other.distanceUnit == this.distanceUnit &&
          other.restSec == this.restSec &&
          other.effort == this.effort &&
          other.note == this.note &&
          other.completed == this.completed &&
          other.completedAt == this.completedAt);
}

class SetEntriesCompanion extends UpdateCompanion<SetEntry> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> sessionExerciseId;
  final Value<int> position;
  final Value<SetType> setType;
  final Value<int?> reps;
  final Value<double?> load;
  final Value<String?> loadUnit;
  final Value<int?> durationSec;
  final Value<double?> distance;
  final Value<String?> distanceUnit;
  final Value<int?> restSec;
  final Value<double?> effort;
  final Value<String?> note;
  final Value<bool> completed;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const SetEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.sessionExerciseId = const Value.absent(),
    this.position = const Value.absent(),
    this.setType = const Value.absent(),
    this.reps = const Value.absent(),
    this.load = const Value.absent(),
    this.loadUnit = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.distance = const Value.absent(),
    this.distanceUnit = const Value.absent(),
    this.restSec = const Value.absent(),
    this.effort = const Value.absent(),
    this.note = const Value.absent(),
    this.completed = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetEntriesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String sessionExerciseId,
    required int position,
    required SetType setType,
    this.reps = const Value.absent(),
    this.load = const Value.absent(),
    this.loadUnit = const Value.absent(),
    this.durationSec = const Value.absent(),
    this.distance = const Value.absent(),
    this.distanceUnit = const Value.absent(),
    this.restSec = const Value.absent(),
    this.effort = const Value.absent(),
    this.note = const Value.absent(),
    this.completed = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       sessionExerciseId = Value(sessionExerciseId),
       position = Value(position),
       setType = Value(setType);
  static Insertable<SetEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? sessionExerciseId,
    Expression<int>? position,
    Expression<String>? setType,
    Expression<int>? reps,
    Expression<double>? load,
    Expression<String>? loadUnit,
    Expression<int>? durationSec,
    Expression<double>? distance,
    Expression<String>? distanceUnit,
    Expression<int>? restSec,
    Expression<double>? effort,
    Expression<String>? note,
    Expression<bool>? completed,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (sessionExerciseId != null) 'session_exercise_id': sessionExerciseId,
      if (position != null) 'position': position,
      if (setType != null) 'set_type': setType,
      if (reps != null) 'reps': reps,
      if (load != null) 'load': load,
      if (loadUnit != null) 'load_unit': loadUnit,
      if (durationSec != null) 'duration_sec': durationSec,
      if (distance != null) 'distance': distance,
      if (distanceUnit != null) 'distance_unit': distanceUnit,
      if (restSec != null) 'rest_sec': restSec,
      if (effort != null) 'effort': effort,
      if (note != null) 'note': note,
      if (completed != null) 'completed': completed,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? sessionExerciseId,
    Value<int>? position,
    Value<SetType>? setType,
    Value<int?>? reps,
    Value<double?>? load,
    Value<String?>? loadUnit,
    Value<int?>? durationSec,
    Value<double?>? distance,
    Value<String?>? distanceUnit,
    Value<int?>? restSec,
    Value<double?>? effort,
    Value<String?>? note,
    Value<bool>? completed,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return SetEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sessionExerciseId: sessionExerciseId ?? this.sessionExerciseId,
      position: position ?? this.position,
      setType: setType ?? this.setType,
      reps: reps ?? this.reps,
      load: load ?? this.load,
      loadUnit: loadUnit ?? this.loadUnit,
      durationSec: durationSec ?? this.durationSec,
      distance: distance ?? this.distance,
      distanceUnit: distanceUnit ?? this.distanceUnit,
      restSec: restSec ?? this.restSec,
      effort: effort ?? this.effort,
      note: note ?? this.note,
      completed: completed ?? this.completed,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (sessionExerciseId.present) {
      map['session_exercise_id'] = Variable<String>(sessionExerciseId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (setType.present) {
      map['set_type'] = Variable<String>(
        $SetEntriesTable.$convertersetType.toSql(setType.value),
      );
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (load.present) {
      map['load'] = Variable<double>(load.value);
    }
    if (loadUnit.present) {
      map['load_unit'] = Variable<String>(loadUnit.value);
    }
    if (durationSec.present) {
      map['duration_sec'] = Variable<int>(durationSec.value);
    }
    if (distance.present) {
      map['distance'] = Variable<double>(distance.value);
    }
    if (distanceUnit.present) {
      map['distance_unit'] = Variable<String>(distanceUnit.value);
    }
    if (restSec.present) {
      map['rest_sec'] = Variable<int>(restSec.value);
    }
    if (effort.present) {
      map['effort'] = Variable<double>(effort.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (completed.present) {
      map['completed'] = Variable<bool>(completed.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('sessionExerciseId: $sessionExerciseId, ')
          ..write('position: $position, ')
          ..write('setType: $setType, ')
          ..write('reps: $reps, ')
          ..write('load: $load, ')
          ..write('loadUnit: $loadUnit, ')
          ..write('durationSec: $durationSec, ')
          ..write('distance: $distance, ')
          ..write('distanceUnit: $distanceUnit, ')
          ..write('restSec: $restSec, ')
          ..write('effort: $effort, ')
          ..write('note: $note, ')
          ..write('completed: $completed, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FoodsTable extends Foods with TableInfo<$FoodsTable, Food> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FoodsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingAmountMeta = const VerificationMeta(
    'servingAmount',
  );
  @override
  late final GeneratedColumn<double> servingAmount = GeneratedColumn<double>(
    'serving_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingUnitMeta = const VerificationMeta(
    'servingUnit',
  );
  @override
  late final GeneratedColumn<String> servingUnit = GeneratedColumn<String>(
    'serving_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  @override
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
    'sugar_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sodiumMgMeta = const VerificationMeta(
    'sodiumMg',
  );
  @override
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
    'sodium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceCheckedAtMeta = const VerificationMeta(
    'sourceCheckedAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceCheckedAt =
      GeneratedColumn<DateTime>(
        'source_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    brand,
    servingAmount,
    servingUnit,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    sugarG,
    sodiumMg,
    isEstimate,
    source,
    sourceCheckedAt,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'foods';
  @override
  VerificationContext validateIntegrity(
    Insertable<Food> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('serving_amount')) {
      context.handle(
        _servingAmountMeta,
        servingAmount.isAcceptableOrUnknown(
          data['serving_amount']!,
          _servingAmountMeta,
        ),
      );
    }
    if (data.containsKey('serving_unit')) {
      context.handle(
        _servingUnitMeta,
        servingUnit.isAcceptableOrUnknown(
          data['serving_unit']!,
          _servingUnitMeta,
        ),
      );
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('sugar_g')) {
      context.handle(
        _sugarGMeta,
        sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta),
      );
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(
        _sodiumMgMeta,
        sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta),
      );
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_checked_at')) {
      context.handle(
        _sourceCheckedAtMeta,
        sourceCheckedAt.isAcceptableOrUnknown(
          data['source_checked_at']!,
          _sourceCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Food map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Food(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      servingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_amount'],
      ),
      servingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_unit'],
      ),
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      ),
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      ),
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      ),
      sugarG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g'],
      ),
      sodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg'],
      ),
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_checked_at'],
      ),
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $FoodsTable createAlias(String alias) {
    return $FoodsTable(attachedDatabase, alias);
  }
}

class Food extends DataClass implements Insertable<Food> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String? brand;
  final double? servingAmount;
  final String? servingUnit;
  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  /// Added in v4. Null means not recorded.
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final bool isEstimate;
  final String source;
  final DateTime? sourceCheckedAt;
  final String? note;
  const Food({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    this.brand,
    this.servingAmount,
    this.servingUnit,
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    required this.isEstimate,
    required this.source,
    this.sourceCheckedAt,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || servingAmount != null) {
      map['serving_amount'] = Variable<double>(servingAmount);
    }
    if (!nullToAbsent || servingUnit != null) {
      map['serving_unit'] = Variable<String>(servingUnit);
    }
    if (!nullToAbsent || energyKcal != null) {
      map['energy_kcal'] = Variable<double>(energyKcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || carbsG != null) {
      map['carbs_g'] = Variable<double>(carbsG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    if (!nullToAbsent || fiberG != null) {
      map['fiber_g'] = Variable<double>(fiberG);
    }
    if (!nullToAbsent || sugarG != null) {
      map['sugar_g'] = Variable<double>(sugarG);
    }
    if (!nullToAbsent || sodiumMg != null) {
      map['sodium_mg'] = Variable<double>(sodiumMg);
    }
    map['is_estimate'] = Variable<bool>(isEstimate);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceCheckedAt != null) {
      map['source_checked_at'] = Variable<DateTime>(sourceCheckedAt);
    }
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  FoodsCompanion toCompanion(bool nullToAbsent) {
    return FoodsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      servingAmount: servingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(servingAmount),
      servingUnit: servingUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(servingUnit),
      energyKcal: energyKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(energyKcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      carbsG: carbsG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      fiberG: fiberG == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberG),
      sugarG: sugarG == null && nullToAbsent
          ? const Value.absent()
          : Value(sugarG),
      sodiumMg: sodiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumMg),
      isEstimate: Value(isEstimate),
      source: Value(source),
      sourceCheckedAt: sourceCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCheckedAt),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory Food.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Food(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      servingAmount: serializer.fromJson<double?>(json['servingAmount']),
      servingUnit: serializer.fromJson<String?>(json['servingUnit']),
      energyKcal: serializer.fromJson<double?>(json['energyKcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      carbsG: serializer.fromJson<double?>(json['carbsG']),
      fatG: serializer.fromJson<double?>(json['fatG']),
      fiberG: serializer.fromJson<double?>(json['fiberG']),
      sugarG: serializer.fromJson<double?>(json['sugarG']),
      sodiumMg: serializer.fromJson<double?>(json['sodiumMg']),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      source: serializer.fromJson<String>(json['source']),
      sourceCheckedAt: serializer.fromJson<DateTime?>(json['sourceCheckedAt']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'servingAmount': serializer.toJson<double?>(servingAmount),
      'servingUnit': serializer.toJson<String?>(servingUnit),
      'energyKcal': serializer.toJson<double?>(energyKcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'carbsG': serializer.toJson<double?>(carbsG),
      'fatG': serializer.toJson<double?>(fatG),
      'fiberG': serializer.toJson<double?>(fiberG),
      'sugarG': serializer.toJson<double?>(sugarG),
      'sodiumMg': serializer.toJson<double?>(sodiumMg),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'source': serializer.toJson<String>(source),
      'sourceCheckedAt': serializer.toJson<DateTime?>(sourceCheckedAt),
      'note': serializer.toJson<String?>(note),
    };
  }

  Food copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<double?> servingAmount = const Value.absent(),
    Value<String?> servingUnit = const Value.absent(),
    Value<double?> energyKcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> carbsG = const Value.absent(),
    Value<double?> fatG = const Value.absent(),
    Value<double?> fiberG = const Value.absent(),
    Value<double?> sugarG = const Value.absent(),
    Value<double?> sodiumMg = const Value.absent(),
    bool? isEstimate,
    String? source,
    Value<DateTime?> sourceCheckedAt = const Value.absent(),
    Value<String?> note = const Value.absent(),
  }) => Food(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    servingAmount: servingAmount.present
        ? servingAmount.value
        : this.servingAmount,
    servingUnit: servingUnit.present ? servingUnit.value : this.servingUnit,
    energyKcal: energyKcal.present ? energyKcal.value : this.energyKcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    carbsG: carbsG.present ? carbsG.value : this.carbsG,
    fatG: fatG.present ? fatG.value : this.fatG,
    fiberG: fiberG.present ? fiberG.value : this.fiberG,
    sugarG: sugarG.present ? sugarG.value : this.sugarG,
    sodiumMg: sodiumMg.present ? sodiumMg.value : this.sodiumMg,
    isEstimate: isEstimate ?? this.isEstimate,
    source: source ?? this.source,
    sourceCheckedAt: sourceCheckedAt.present
        ? sourceCheckedAt.value
        : this.sourceCheckedAt,
    note: note.present ? note.value : this.note,
  );
  Food copyWithCompanion(FoodsCompanion data) {
    return Food(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      servingAmount: data.servingAmount.present
          ? data.servingAmount.value
          : this.servingAmount,
      servingUnit: data.servingUnit.present
          ? data.servingUnit.value
          : this.servingUnit,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      sugarG: data.sugarG.present ? data.sugarG.value : this.sugarG,
      sodiumMg: data.sodiumMg.present ? data.sodiumMg.value : this.sodiumMg,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      source: data.source.present ? data.source.value : this.source,
      sourceCheckedAt: data.sourceCheckedAt.present
          ? data.sourceCheckedAt.value
          : this.sourceCheckedAt,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Food(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('servingAmount: $servingAmount, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('source: $source, ')
          ..write('sourceCheckedAt: $sourceCheckedAt, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    brand,
    servingAmount,
    servingUnit,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    sugarG,
    sodiumMg,
    isEstimate,
    source,
    sourceCheckedAt,
    note,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Food &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.servingAmount == this.servingAmount &&
          other.servingUnit == this.servingUnit &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.fiberG == this.fiberG &&
          other.sugarG == this.sugarG &&
          other.sodiumMg == this.sodiumMg &&
          other.isEstimate == this.isEstimate &&
          other.source == this.source &&
          other.sourceCheckedAt == this.sourceCheckedAt &&
          other.note == this.note);
}

class FoodsCompanion extends UpdateCompanion<Food> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String?> brand;
  final Value<double?> servingAmount;
  final Value<String?> servingUnit;
  final Value<double?> energyKcal;
  final Value<double?> proteinG;
  final Value<double?> carbsG;
  final Value<double?> fatG;
  final Value<double?> fiberG;
  final Value<double?> sugarG;
  final Value<double?> sodiumMg;
  final Value<bool> isEstimate;
  final Value<String> source;
  final Value<DateTime?> sourceCheckedAt;
  final Value<String?> note;
  final Value<int> rowid;
  const FoodsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.servingAmount = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceCheckedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FoodsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String name,
    this.brand = const Value.absent(),
    this.servingAmount = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.isEstimate = const Value.absent(),
    required String source,
    this.sourceCheckedAt = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       source = Value(source);
  static Insertable<Food> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<double>? servingAmount,
    Expression<String>? servingUnit,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<double>? fiberG,
    Expression<double>? sugarG,
    Expression<double>? sodiumMg,
    Expression<bool>? isEstimate,
    Expression<String>? source,
    Expression<DateTime>? sourceCheckedAt,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (servingAmount != null) 'serving_amount': servingAmount,
      if (servingUnit != null) 'serving_unit': servingUnit,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (source != null) 'source': source,
      if (sourceCheckedAt != null) 'source_checked_at': sourceCheckedAt,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FoodsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String?>? brand,
    Value<double?>? servingAmount,
    Value<String?>? servingUnit,
    Value<double?>? energyKcal,
    Value<double?>? proteinG,
    Value<double?>? carbsG,
    Value<double?>? fatG,
    Value<double?>? fiberG,
    Value<double?>? sugarG,
    Value<double?>? sodiumMg,
    Value<bool>? isEstimate,
    Value<String>? source,
    Value<DateTime?>? sourceCheckedAt,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return FoodsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      servingAmount: servingAmount ?? this.servingAmount,
      servingUnit: servingUnit ?? this.servingUnit,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      sugarG: sugarG ?? this.sugarG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      isEstimate: isEstimate ?? this.isEstimate,
      source: source ?? this.source,
      sourceCheckedAt: sourceCheckedAt ?? this.sourceCheckedAt,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (servingAmount.present) {
      map['serving_amount'] = Variable<double>(servingAmount.value);
    }
    if (servingUnit.present) {
      map['serving_unit'] = Variable<String>(servingUnit.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceCheckedAt.present) {
      map['source_checked_at'] = Variable<DateTime>(sourceCheckedAt.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FoodsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('servingAmount: $servingAmount, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('source: $source, ')
          ..write('sourceCheckedAt: $sourceCheckedAt, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealSlotsTable extends MealSlots
    with TableInfo<$MealSlotsTable, MealSlot> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealSlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 60,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _usualMinuteMeta = const VerificationMeta(
    'usualMinute',
  );
  @override
  late final GeneratedColumn<int> usualMinute = GeneratedColumn<int>(
    'usual_minute',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedMeta = const VerificationMeta(
    'archived',
  );
  @override
  late final GeneratedColumn<bool> archived = GeneratedColumn<bool>(
    'archived',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("archived" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    position,
    usualMinute,
    kind,
    archived,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealSlot> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('usual_minute')) {
      context.handle(
        _usualMinuteMeta,
        usualMinute.isAcceptableOrUnknown(
          data['usual_minute']!,
          _usualMinuteMeta,
        ),
      );
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    }
    if (data.containsKey('archived')) {
      context.handle(
        _archivedMeta,
        archived.isAcceptableOrUnknown(data['archived']!, _archivedMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealSlot map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealSlot(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      usualMinute: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}usual_minute'],
      ),
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      ),
      archived: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}archived'],
      )!,
    );
  }

  @override
  $MealSlotsTable createAlias(String alias) {
    return $MealSlotsTable(attachedDatabase, alias);
  }
}

class MealSlot extends DataClass implements Insertable<MealSlot> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final int position;

  /// Usual time as minutes after midnight. Optional.
  final int? usualMinute;

  /// Icon and colour group: drink, breakfast, snack, lunch, dinner. Added in v2.
  final String? kind;
  final bool archived;
  const MealSlot({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.position,
    this.usualMinute,
    this.kind,
    required this.archived,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['position'] = Variable<int>(position);
    if (!nullToAbsent || usualMinute != null) {
      map['usual_minute'] = Variable<int>(usualMinute);
    }
    if (!nullToAbsent || kind != null) {
      map['kind'] = Variable<String>(kind);
    }
    map['archived'] = Variable<bool>(archived);
    return map;
  }

  MealSlotsCompanion toCompanion(bool nullToAbsent) {
    return MealSlotsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      position: Value(position),
      usualMinute: usualMinute == null && nullToAbsent
          ? const Value.absent()
          : Value(usualMinute),
      kind: kind == null && nullToAbsent ? const Value.absent() : Value(kind),
      archived: Value(archived),
    );
  }

  factory MealSlot.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealSlot(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      position: serializer.fromJson<int>(json['position']),
      usualMinute: serializer.fromJson<int?>(json['usualMinute']),
      kind: serializer.fromJson<String?>(json['kind']),
      archived: serializer.fromJson<bool>(json['archived']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'position': serializer.toJson<int>(position),
      'usualMinute': serializer.toJson<int?>(usualMinute),
      'kind': serializer.toJson<String?>(kind),
      'archived': serializer.toJson<bool>(archived),
    };
  }

  MealSlot copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    int? position,
    Value<int?> usualMinute = const Value.absent(),
    Value<String?> kind = const Value.absent(),
    bool? archived,
  }) => MealSlot(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    position: position ?? this.position,
    usualMinute: usualMinute.present ? usualMinute.value : this.usualMinute,
    kind: kind.present ? kind.value : this.kind,
    archived: archived ?? this.archived,
  );
  MealSlot copyWithCompanion(MealSlotsCompanion data) {
    return MealSlot(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      position: data.position.present ? data.position.value : this.position,
      usualMinute: data.usualMinute.present
          ? data.usualMinute.value
          : this.usualMinute,
      kind: data.kind.present ? data.kind.value : this.kind,
      archived: data.archived.present ? data.archived.value : this.archived,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealSlot(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('usualMinute: $usualMinute, ')
          ..write('kind: $kind, ')
          ..write('archived: $archived')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    position,
    usualMinute,
    kind,
    archived,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealSlot &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.position == this.position &&
          other.usualMinute == this.usualMinute &&
          other.kind == this.kind &&
          other.archived == this.archived);
}

class MealSlotsCompanion extends UpdateCompanion<MealSlot> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<int> position;
  final Value<int?> usualMinute;
  final Value<String?> kind;
  final Value<bool> archived;
  final Value<int> rowid;
  const MealSlotsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.position = const Value.absent(),
    this.usualMinute = const Value.absent(),
    this.kind = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealSlotsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String name,
    required int position,
    this.usualMinute = const Value.absent(),
    this.kind = const Value.absent(),
    this.archived = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       position = Value(position);
  static Insertable<MealSlot> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<int>? position,
    Expression<int>? usualMinute,
    Expression<String>? kind,
    Expression<bool>? archived,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (position != null) 'position': position,
      if (usualMinute != null) 'usual_minute': usualMinute,
      if (kind != null) 'kind': kind,
      if (archived != null) 'archived': archived,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealSlotsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<int>? position,
    Value<int?>? usualMinute,
    Value<String?>? kind,
    Value<bool>? archived,
    Value<int>? rowid,
  }) {
    return MealSlotsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      position: position ?? this.position,
      usualMinute: usualMinute ?? this.usualMinute,
      kind: kind ?? this.kind,
      archived: archived ?? this.archived,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (usualMinute.present) {
      map['usual_minute'] = Variable<int>(usualMinute.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (archived.present) {
      map['archived'] = Variable<bool>(archived.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealSlotsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('position: $position, ')
          ..write('usualMinute: $usualMinute, ')
          ..write('kind: $kind, ')
          ..write('archived: $archived, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MealEntriesTable extends MealEntries
    with TableInfo<$MealEntriesTable, MealEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MealEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _slotIdMeta = const VerificationMeta('slotId');
  @override
  late final GeneratedColumn<String> slotId = GeneratedColumn<String>(
    'slot_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES meal_slots (id)',
    ),
  );
  static const VerificationMeta _foodIdMeta = const VerificationMeta('foodId');
  @override
  late final GeneratedColumn<String> foodId = GeneratedColumn<String>(
    'food_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 160,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _brandMeta = const VerificationMeta('brand');
  @override
  late final GeneratedColumn<String> brand = GeneratedColumn<String>(
    'brand',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingAmountMeta = const VerificationMeta(
    'servingAmount',
  );
  @override
  late final GeneratedColumn<double> servingAmount = GeneratedColumn<double>(
    'serving_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _servingUnitMeta = const VerificationMeta(
    'servingUnit',
  );
  @override
  late final GeneratedColumn<String> servingUnit = GeneratedColumn<String>(
    'serving_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyKcalMeta = const VerificationMeta(
    'energyKcal',
  );
  @override
  late final GeneratedColumn<double> energyKcal = GeneratedColumn<double>(
    'energy_kcal',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _proteinGMeta = const VerificationMeta(
    'proteinG',
  );
  @override
  late final GeneratedColumn<double> proteinG = GeneratedColumn<double>(
    'protein_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carbsGMeta = const VerificationMeta('carbsG');
  @override
  late final GeneratedColumn<double> carbsG = GeneratedColumn<double>(
    'carbs_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fatGMeta = const VerificationMeta('fatG');
  @override
  late final GeneratedColumn<double> fatG = GeneratedColumn<double>(
    'fat_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fiberGMeta = const VerificationMeta('fiberG');
  @override
  late final GeneratedColumn<double> fiberG = GeneratedColumn<double>(
    'fiber_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sugarGMeta = const VerificationMeta('sugarG');
  @override
  late final GeneratedColumn<double> sugarG = GeneratedColumn<double>(
    'sugar_g',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sodiumMgMeta = const VerificationMeta(
    'sodiumMg',
  );
  @override
  late final GeneratedColumn<double> sodiumMg = GeneratedColumn<double>(
    'sodium_mg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _amountUnitMeta = const VerificationMeta(
    'amountUnit',
  );
  @override
  late final GeneratedColumn<String> amountUnit = GeneratedColumn<String>(
    'amount_unit',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isEstimateMeta = const VerificationMeta(
    'isEstimate',
  );
  @override
  late final GeneratedColumn<bool> isEstimate = GeneratedColumn<bool>(
    'is_estimate',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_estimate" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceCheckedAtMeta = const VerificationMeta(
    'sourceCheckedAt',
  );
  @override
  late final GeneratedColumn<DateTime> sourceCheckedAt =
      GeneratedColumn<DateTime>(
        'source_checked_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  late final GeneratedColumnWithTypeConverter<MealStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<MealStatus>($MealEntriesTable.$converterstatus);
  static const VerificationMeta _eatenAtMeta = const VerificationMeta(
    'eatenAt',
  );
  @override
  late final GeneratedColumn<DateTime> eatenAt = GeneratedColumn<DateTime>(
    'eaten_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _timeZoneNameMeta = const VerificationMeta(
    'timeZoneName',
  );
  @override
  late final GeneratedColumn<String> timeZoneName = GeneratedColumn<String>(
    'time_zone_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _noteMeta = const VerificationMeta('note');
  @override
  late final GeneratedColumn<String> note = GeneratedColumn<String>(
    'note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    day,
    slotId,
    foodId,
    name,
    brand,
    servingAmount,
    servingUnit,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    sugarG,
    sodiumMg,
    amount,
    amountUnit,
    isEstimate,
    source,
    sourceCheckedAt,
    status,
    eatenAt,
    timeZoneName,
    note,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'meal_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MealEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('slot_id')) {
      context.handle(
        _slotIdMeta,
        slotId.isAcceptableOrUnknown(data['slot_id']!, _slotIdMeta),
      );
    } else if (isInserting) {
      context.missing(_slotIdMeta);
    }
    if (data.containsKey('food_id')) {
      context.handle(
        _foodIdMeta,
        foodId.isAcceptableOrUnknown(data['food_id']!, _foodIdMeta),
      );
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('brand')) {
      context.handle(
        _brandMeta,
        brand.isAcceptableOrUnknown(data['brand']!, _brandMeta),
      );
    }
    if (data.containsKey('serving_amount')) {
      context.handle(
        _servingAmountMeta,
        servingAmount.isAcceptableOrUnknown(
          data['serving_amount']!,
          _servingAmountMeta,
        ),
      );
    }
    if (data.containsKey('serving_unit')) {
      context.handle(
        _servingUnitMeta,
        servingUnit.isAcceptableOrUnknown(
          data['serving_unit']!,
          _servingUnitMeta,
        ),
      );
    }
    if (data.containsKey('energy_kcal')) {
      context.handle(
        _energyKcalMeta,
        energyKcal.isAcceptableOrUnknown(data['energy_kcal']!, _energyKcalMeta),
      );
    }
    if (data.containsKey('protein_g')) {
      context.handle(
        _proteinGMeta,
        proteinG.isAcceptableOrUnknown(data['protein_g']!, _proteinGMeta),
      );
    }
    if (data.containsKey('carbs_g')) {
      context.handle(
        _carbsGMeta,
        carbsG.isAcceptableOrUnknown(data['carbs_g']!, _carbsGMeta),
      );
    }
    if (data.containsKey('fat_g')) {
      context.handle(
        _fatGMeta,
        fatG.isAcceptableOrUnknown(data['fat_g']!, _fatGMeta),
      );
    }
    if (data.containsKey('fiber_g')) {
      context.handle(
        _fiberGMeta,
        fiberG.isAcceptableOrUnknown(data['fiber_g']!, _fiberGMeta),
      );
    }
    if (data.containsKey('sugar_g')) {
      context.handle(
        _sugarGMeta,
        sugarG.isAcceptableOrUnknown(data['sugar_g']!, _sugarGMeta),
      );
    }
    if (data.containsKey('sodium_mg')) {
      context.handle(
        _sodiumMgMeta,
        sodiumMg.isAcceptableOrUnknown(data['sodium_mg']!, _sodiumMgMeta),
      );
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    }
    if (data.containsKey('amount_unit')) {
      context.handle(
        _amountUnitMeta,
        amountUnit.isAcceptableOrUnknown(data['amount_unit']!, _amountUnitMeta),
      );
    }
    if (data.containsKey('is_estimate')) {
      context.handle(
        _isEstimateMeta,
        isEstimate.isAcceptableOrUnknown(data['is_estimate']!, _isEstimateMeta),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
    }
    if (data.containsKey('source_checked_at')) {
      context.handle(
        _sourceCheckedAtMeta,
        sourceCheckedAt.isAcceptableOrUnknown(
          data['source_checked_at']!,
          _sourceCheckedAtMeta,
        ),
      );
    }
    if (data.containsKey('eaten_at')) {
      context.handle(
        _eatenAtMeta,
        eatenAt.isAcceptableOrUnknown(data['eaten_at']!, _eatenAtMeta),
      );
    }
    if (data.containsKey('time_zone_name')) {
      context.handle(
        _timeZoneNameMeta,
        timeZoneName.isAcceptableOrUnknown(
          data['time_zone_name']!,
          _timeZoneNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_timeZoneNameMeta);
    }
    if (data.containsKey('note')) {
      context.handle(
        _noteMeta,
        note.isAcceptableOrUnknown(data['note']!, _noteMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MealEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MealEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      slotId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}slot_id'],
      )!,
      foodId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}food_id'],
      ),
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      brand: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}brand'],
      ),
      servingAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}serving_amount'],
      ),
      servingUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}serving_unit'],
      ),
      energyKcal: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}energy_kcal'],
      ),
      proteinG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}protein_g'],
      ),
      carbsG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}carbs_g'],
      ),
      fatG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fat_g'],
      ),
      fiberG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}fiber_g'],
      ),
      sugarG: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sugar_g'],
      ),
      sodiumMg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}sodium_mg'],
      ),
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      ),
      amountUnit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}amount_unit'],
      ),
      isEstimate: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_estimate'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      sourceCheckedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}source_checked_at'],
      ),
      status: $MealEntriesTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      eatenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}eaten_at'],
      ),
      timeZoneName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}time_zone_name'],
      )!,
      note: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note'],
      ),
    );
  }

  @override
  $MealEntriesTable createAlias(String alias) {
    return $MealEntriesTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<MealStatus, String, String> $converterstatus =
      const EnumNameConverter<MealStatus>(MealStatus.values);
}

class MealEntry extends DataClass implements Insertable<MealEntry> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String day;
  final String slotId;
  final String? foodId;
  final String name;
  final String? brand;
  final double? servingAmount;
  final String? servingUnit;
  final double? energyKcal;
  final double? proteinG;
  final double? carbsG;
  final double? fatG;

  /// Added in v4. Per source serving, like the values above.
  final double? fiberG;
  final double? sugarG;
  final double? sodiumMg;
  final double? amount;
  final String? amountUnit;
  final bool isEstimate;
  final String source;
  final DateTime? sourceCheckedAt;
  final MealStatus status;
  final DateTime? eatenAt;
  final String timeZoneName;
  final String? note;
  const MealEntry({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.day,
    required this.slotId,
    this.foodId,
    required this.name,
    this.brand,
    this.servingAmount,
    this.servingUnit,
    this.energyKcal,
    this.proteinG,
    this.carbsG,
    this.fatG,
    this.fiberG,
    this.sugarG,
    this.sodiumMg,
    this.amount,
    this.amountUnit,
    required this.isEstimate,
    required this.source,
    this.sourceCheckedAt,
    required this.status,
    this.eatenAt,
    required this.timeZoneName,
    this.note,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['day'] = Variable<String>(day);
    map['slot_id'] = Variable<String>(slotId);
    if (!nullToAbsent || foodId != null) {
      map['food_id'] = Variable<String>(foodId);
    }
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || brand != null) {
      map['brand'] = Variable<String>(brand);
    }
    if (!nullToAbsent || servingAmount != null) {
      map['serving_amount'] = Variable<double>(servingAmount);
    }
    if (!nullToAbsent || servingUnit != null) {
      map['serving_unit'] = Variable<String>(servingUnit);
    }
    if (!nullToAbsent || energyKcal != null) {
      map['energy_kcal'] = Variable<double>(energyKcal);
    }
    if (!nullToAbsent || proteinG != null) {
      map['protein_g'] = Variable<double>(proteinG);
    }
    if (!nullToAbsent || carbsG != null) {
      map['carbs_g'] = Variable<double>(carbsG);
    }
    if (!nullToAbsent || fatG != null) {
      map['fat_g'] = Variable<double>(fatG);
    }
    if (!nullToAbsent || fiberG != null) {
      map['fiber_g'] = Variable<double>(fiberG);
    }
    if (!nullToAbsent || sugarG != null) {
      map['sugar_g'] = Variable<double>(sugarG);
    }
    if (!nullToAbsent || sodiumMg != null) {
      map['sodium_mg'] = Variable<double>(sodiumMg);
    }
    if (!nullToAbsent || amount != null) {
      map['amount'] = Variable<double>(amount);
    }
    if (!nullToAbsent || amountUnit != null) {
      map['amount_unit'] = Variable<String>(amountUnit);
    }
    map['is_estimate'] = Variable<bool>(isEstimate);
    map['source'] = Variable<String>(source);
    if (!nullToAbsent || sourceCheckedAt != null) {
      map['source_checked_at'] = Variable<DateTime>(sourceCheckedAt);
    }
    {
      map['status'] = Variable<String>(
        $MealEntriesTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || eatenAt != null) {
      map['eaten_at'] = Variable<DateTime>(eatenAt);
    }
    map['time_zone_name'] = Variable<String>(timeZoneName);
    if (!nullToAbsent || note != null) {
      map['note'] = Variable<String>(note);
    }
    return map;
  }

  MealEntriesCompanion toCompanion(bool nullToAbsent) {
    return MealEntriesCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      day: Value(day),
      slotId: Value(slotId),
      foodId: foodId == null && nullToAbsent
          ? const Value.absent()
          : Value(foodId),
      name: Value(name),
      brand: brand == null && nullToAbsent
          ? const Value.absent()
          : Value(brand),
      servingAmount: servingAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(servingAmount),
      servingUnit: servingUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(servingUnit),
      energyKcal: energyKcal == null && nullToAbsent
          ? const Value.absent()
          : Value(energyKcal),
      proteinG: proteinG == null && nullToAbsent
          ? const Value.absent()
          : Value(proteinG),
      carbsG: carbsG == null && nullToAbsent
          ? const Value.absent()
          : Value(carbsG),
      fatG: fatG == null && nullToAbsent ? const Value.absent() : Value(fatG),
      fiberG: fiberG == null && nullToAbsent
          ? const Value.absent()
          : Value(fiberG),
      sugarG: sugarG == null && nullToAbsent
          ? const Value.absent()
          : Value(sugarG),
      sodiumMg: sodiumMg == null && nullToAbsent
          ? const Value.absent()
          : Value(sodiumMg),
      amount: amount == null && nullToAbsent
          ? const Value.absent()
          : Value(amount),
      amountUnit: amountUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(amountUnit),
      isEstimate: Value(isEstimate),
      source: Value(source),
      sourceCheckedAt: sourceCheckedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceCheckedAt),
      status: Value(status),
      eatenAt: eatenAt == null && nullToAbsent
          ? const Value.absent()
          : Value(eatenAt),
      timeZoneName: Value(timeZoneName),
      note: note == null && nullToAbsent ? const Value.absent() : Value(note),
    );
  }

  factory MealEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MealEntry(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      day: serializer.fromJson<String>(json['day']),
      slotId: serializer.fromJson<String>(json['slotId']),
      foodId: serializer.fromJson<String?>(json['foodId']),
      name: serializer.fromJson<String>(json['name']),
      brand: serializer.fromJson<String?>(json['brand']),
      servingAmount: serializer.fromJson<double?>(json['servingAmount']),
      servingUnit: serializer.fromJson<String?>(json['servingUnit']),
      energyKcal: serializer.fromJson<double?>(json['energyKcal']),
      proteinG: serializer.fromJson<double?>(json['proteinG']),
      carbsG: serializer.fromJson<double?>(json['carbsG']),
      fatG: serializer.fromJson<double?>(json['fatG']),
      fiberG: serializer.fromJson<double?>(json['fiberG']),
      sugarG: serializer.fromJson<double?>(json['sugarG']),
      sodiumMg: serializer.fromJson<double?>(json['sodiumMg']),
      amount: serializer.fromJson<double?>(json['amount']),
      amountUnit: serializer.fromJson<String?>(json['amountUnit']),
      isEstimate: serializer.fromJson<bool>(json['isEstimate']),
      source: serializer.fromJson<String>(json['source']),
      sourceCheckedAt: serializer.fromJson<DateTime?>(json['sourceCheckedAt']),
      status: $MealEntriesTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      eatenAt: serializer.fromJson<DateTime?>(json['eatenAt']),
      timeZoneName: serializer.fromJson<String>(json['timeZoneName']),
      note: serializer.fromJson<String?>(json['note']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'day': serializer.toJson<String>(day),
      'slotId': serializer.toJson<String>(slotId),
      'foodId': serializer.toJson<String?>(foodId),
      'name': serializer.toJson<String>(name),
      'brand': serializer.toJson<String?>(brand),
      'servingAmount': serializer.toJson<double?>(servingAmount),
      'servingUnit': serializer.toJson<String?>(servingUnit),
      'energyKcal': serializer.toJson<double?>(energyKcal),
      'proteinG': serializer.toJson<double?>(proteinG),
      'carbsG': serializer.toJson<double?>(carbsG),
      'fatG': serializer.toJson<double?>(fatG),
      'fiberG': serializer.toJson<double?>(fiberG),
      'sugarG': serializer.toJson<double?>(sugarG),
      'sodiumMg': serializer.toJson<double?>(sodiumMg),
      'amount': serializer.toJson<double?>(amount),
      'amountUnit': serializer.toJson<String?>(amountUnit),
      'isEstimate': serializer.toJson<bool>(isEstimate),
      'source': serializer.toJson<String>(source),
      'sourceCheckedAt': serializer.toJson<DateTime?>(sourceCheckedAt),
      'status': serializer.toJson<String>(
        $MealEntriesTable.$converterstatus.toJson(status),
      ),
      'eatenAt': serializer.toJson<DateTime?>(eatenAt),
      'timeZoneName': serializer.toJson<String>(timeZoneName),
      'note': serializer.toJson<String?>(note),
    };
  }

  MealEntry copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? day,
    String? slotId,
    Value<String?> foodId = const Value.absent(),
    String? name,
    Value<String?> brand = const Value.absent(),
    Value<double?> servingAmount = const Value.absent(),
    Value<String?> servingUnit = const Value.absent(),
    Value<double?> energyKcal = const Value.absent(),
    Value<double?> proteinG = const Value.absent(),
    Value<double?> carbsG = const Value.absent(),
    Value<double?> fatG = const Value.absent(),
    Value<double?> fiberG = const Value.absent(),
    Value<double?> sugarG = const Value.absent(),
    Value<double?> sodiumMg = const Value.absent(),
    Value<double?> amount = const Value.absent(),
    Value<String?> amountUnit = const Value.absent(),
    bool? isEstimate,
    String? source,
    Value<DateTime?> sourceCheckedAt = const Value.absent(),
    MealStatus? status,
    Value<DateTime?> eatenAt = const Value.absent(),
    String? timeZoneName,
    Value<String?> note = const Value.absent(),
  }) => MealEntry(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    day: day ?? this.day,
    slotId: slotId ?? this.slotId,
    foodId: foodId.present ? foodId.value : this.foodId,
    name: name ?? this.name,
    brand: brand.present ? brand.value : this.brand,
    servingAmount: servingAmount.present
        ? servingAmount.value
        : this.servingAmount,
    servingUnit: servingUnit.present ? servingUnit.value : this.servingUnit,
    energyKcal: energyKcal.present ? energyKcal.value : this.energyKcal,
    proteinG: proteinG.present ? proteinG.value : this.proteinG,
    carbsG: carbsG.present ? carbsG.value : this.carbsG,
    fatG: fatG.present ? fatG.value : this.fatG,
    fiberG: fiberG.present ? fiberG.value : this.fiberG,
    sugarG: sugarG.present ? sugarG.value : this.sugarG,
    sodiumMg: sodiumMg.present ? sodiumMg.value : this.sodiumMg,
    amount: amount.present ? amount.value : this.amount,
    amountUnit: amountUnit.present ? amountUnit.value : this.amountUnit,
    isEstimate: isEstimate ?? this.isEstimate,
    source: source ?? this.source,
    sourceCheckedAt: sourceCheckedAt.present
        ? sourceCheckedAt.value
        : this.sourceCheckedAt,
    status: status ?? this.status,
    eatenAt: eatenAt.present ? eatenAt.value : this.eatenAt,
    timeZoneName: timeZoneName ?? this.timeZoneName,
    note: note.present ? note.value : this.note,
  );
  MealEntry copyWithCompanion(MealEntriesCompanion data) {
    return MealEntry(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      day: data.day.present ? data.day.value : this.day,
      slotId: data.slotId.present ? data.slotId.value : this.slotId,
      foodId: data.foodId.present ? data.foodId.value : this.foodId,
      name: data.name.present ? data.name.value : this.name,
      brand: data.brand.present ? data.brand.value : this.brand,
      servingAmount: data.servingAmount.present
          ? data.servingAmount.value
          : this.servingAmount,
      servingUnit: data.servingUnit.present
          ? data.servingUnit.value
          : this.servingUnit,
      energyKcal: data.energyKcal.present
          ? data.energyKcal.value
          : this.energyKcal,
      proteinG: data.proteinG.present ? data.proteinG.value : this.proteinG,
      carbsG: data.carbsG.present ? data.carbsG.value : this.carbsG,
      fatG: data.fatG.present ? data.fatG.value : this.fatG,
      fiberG: data.fiberG.present ? data.fiberG.value : this.fiberG,
      sugarG: data.sugarG.present ? data.sugarG.value : this.sugarG,
      sodiumMg: data.sodiumMg.present ? data.sodiumMg.value : this.sodiumMg,
      amount: data.amount.present ? data.amount.value : this.amount,
      amountUnit: data.amountUnit.present
          ? data.amountUnit.value
          : this.amountUnit,
      isEstimate: data.isEstimate.present
          ? data.isEstimate.value
          : this.isEstimate,
      source: data.source.present ? data.source.value : this.source,
      sourceCheckedAt: data.sourceCheckedAt.present
          ? data.sourceCheckedAt.value
          : this.sourceCheckedAt,
      status: data.status.present ? data.status.value : this.status,
      eatenAt: data.eatenAt.present ? data.eatenAt.value : this.eatenAt,
      timeZoneName: data.timeZoneName.present
          ? data.timeZoneName.value
          : this.timeZoneName,
      note: data.note.present ? data.note.value : this.note,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MealEntry(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('day: $day, ')
          ..write('slotId: $slotId, ')
          ..write('foodId: $foodId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('servingAmount: $servingAmount, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('amount: $amount, ')
          ..write('amountUnit: $amountUnit, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('source: $source, ')
          ..write('sourceCheckedAt: $sourceCheckedAt, ')
          ..write('status: $status, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('timeZoneName: $timeZoneName, ')
          ..write('note: $note')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    createdAt,
    updatedAt,
    day,
    slotId,
    foodId,
    name,
    brand,
    servingAmount,
    servingUnit,
    energyKcal,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    sugarG,
    sodiumMg,
    amount,
    amountUnit,
    isEstimate,
    source,
    sourceCheckedAt,
    status,
    eatenAt,
    timeZoneName,
    note,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MealEntry &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.day == this.day &&
          other.slotId == this.slotId &&
          other.foodId == this.foodId &&
          other.name == this.name &&
          other.brand == this.brand &&
          other.servingAmount == this.servingAmount &&
          other.servingUnit == this.servingUnit &&
          other.energyKcal == this.energyKcal &&
          other.proteinG == this.proteinG &&
          other.carbsG == this.carbsG &&
          other.fatG == this.fatG &&
          other.fiberG == this.fiberG &&
          other.sugarG == this.sugarG &&
          other.sodiumMg == this.sodiumMg &&
          other.amount == this.amount &&
          other.amountUnit == this.amountUnit &&
          other.isEstimate == this.isEstimate &&
          other.source == this.source &&
          other.sourceCheckedAt == this.sourceCheckedAt &&
          other.status == this.status &&
          other.eatenAt == this.eatenAt &&
          other.timeZoneName == this.timeZoneName &&
          other.note == this.note);
}

class MealEntriesCompanion extends UpdateCompanion<MealEntry> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> day;
  final Value<String> slotId;
  final Value<String?> foodId;
  final Value<String> name;
  final Value<String?> brand;
  final Value<double?> servingAmount;
  final Value<String?> servingUnit;
  final Value<double?> energyKcal;
  final Value<double?> proteinG;
  final Value<double?> carbsG;
  final Value<double?> fatG;
  final Value<double?> fiberG;
  final Value<double?> sugarG;
  final Value<double?> sodiumMg;
  final Value<double?> amount;
  final Value<String?> amountUnit;
  final Value<bool> isEstimate;
  final Value<String> source;
  final Value<DateTime?> sourceCheckedAt;
  final Value<MealStatus> status;
  final Value<DateTime?> eatenAt;
  final Value<String> timeZoneName;
  final Value<String?> note;
  final Value<int> rowid;
  const MealEntriesCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.day = const Value.absent(),
    this.slotId = const Value.absent(),
    this.foodId = const Value.absent(),
    this.name = const Value.absent(),
    this.brand = const Value.absent(),
    this.servingAmount = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.amount = const Value.absent(),
    this.amountUnit = const Value.absent(),
    this.isEstimate = const Value.absent(),
    this.source = const Value.absent(),
    this.sourceCheckedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.eatenAt = const Value.absent(),
    this.timeZoneName = const Value.absent(),
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MealEntriesCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String day,
    required String slotId,
    this.foodId = const Value.absent(),
    required String name,
    this.brand = const Value.absent(),
    this.servingAmount = const Value.absent(),
    this.servingUnit = const Value.absent(),
    this.energyKcal = const Value.absent(),
    this.proteinG = const Value.absent(),
    this.carbsG = const Value.absent(),
    this.fatG = const Value.absent(),
    this.fiberG = const Value.absent(),
    this.sugarG = const Value.absent(),
    this.sodiumMg = const Value.absent(),
    this.amount = const Value.absent(),
    this.amountUnit = const Value.absent(),
    this.isEstimate = const Value.absent(),
    required String source,
    this.sourceCheckedAt = const Value.absent(),
    required MealStatus status,
    this.eatenAt = const Value.absent(),
    required String timeZoneName,
    this.note = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       day = Value(day),
       slotId = Value(slotId),
       name = Value(name),
       source = Value(source),
       status = Value(status),
       timeZoneName = Value(timeZoneName);
  static Insertable<MealEntry> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? day,
    Expression<String>? slotId,
    Expression<String>? foodId,
    Expression<String>? name,
    Expression<String>? brand,
    Expression<double>? servingAmount,
    Expression<String>? servingUnit,
    Expression<double>? energyKcal,
    Expression<double>? proteinG,
    Expression<double>? carbsG,
    Expression<double>? fatG,
    Expression<double>? fiberG,
    Expression<double>? sugarG,
    Expression<double>? sodiumMg,
    Expression<double>? amount,
    Expression<String>? amountUnit,
    Expression<bool>? isEstimate,
    Expression<String>? source,
    Expression<DateTime>? sourceCheckedAt,
    Expression<String>? status,
    Expression<DateTime>? eatenAt,
    Expression<String>? timeZoneName,
    Expression<String>? note,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (day != null) 'day': day,
      if (slotId != null) 'slot_id': slotId,
      if (foodId != null) 'food_id': foodId,
      if (name != null) 'name': name,
      if (brand != null) 'brand': brand,
      if (servingAmount != null) 'serving_amount': servingAmount,
      if (servingUnit != null) 'serving_unit': servingUnit,
      if (energyKcal != null) 'energy_kcal': energyKcal,
      if (proteinG != null) 'protein_g': proteinG,
      if (carbsG != null) 'carbs_g': carbsG,
      if (fatG != null) 'fat_g': fatG,
      if (fiberG != null) 'fiber_g': fiberG,
      if (sugarG != null) 'sugar_g': sugarG,
      if (sodiumMg != null) 'sodium_mg': sodiumMg,
      if (amount != null) 'amount': amount,
      if (amountUnit != null) 'amount_unit': amountUnit,
      if (isEstimate != null) 'is_estimate': isEstimate,
      if (source != null) 'source': source,
      if (sourceCheckedAt != null) 'source_checked_at': sourceCheckedAt,
      if (status != null) 'status': status,
      if (eatenAt != null) 'eaten_at': eatenAt,
      if (timeZoneName != null) 'time_zone_name': timeZoneName,
      if (note != null) 'note': note,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MealEntriesCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? day,
    Value<String>? slotId,
    Value<String?>? foodId,
    Value<String>? name,
    Value<String?>? brand,
    Value<double?>? servingAmount,
    Value<String?>? servingUnit,
    Value<double?>? energyKcal,
    Value<double?>? proteinG,
    Value<double?>? carbsG,
    Value<double?>? fatG,
    Value<double?>? fiberG,
    Value<double?>? sugarG,
    Value<double?>? sodiumMg,
    Value<double?>? amount,
    Value<String?>? amountUnit,
    Value<bool>? isEstimate,
    Value<String>? source,
    Value<DateTime?>? sourceCheckedAt,
    Value<MealStatus>? status,
    Value<DateTime?>? eatenAt,
    Value<String>? timeZoneName,
    Value<String?>? note,
    Value<int>? rowid,
  }) {
    return MealEntriesCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      day: day ?? this.day,
      slotId: slotId ?? this.slotId,
      foodId: foodId ?? this.foodId,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      servingAmount: servingAmount ?? this.servingAmount,
      servingUnit: servingUnit ?? this.servingUnit,
      energyKcal: energyKcal ?? this.energyKcal,
      proteinG: proteinG ?? this.proteinG,
      carbsG: carbsG ?? this.carbsG,
      fatG: fatG ?? this.fatG,
      fiberG: fiberG ?? this.fiberG,
      sugarG: sugarG ?? this.sugarG,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      amount: amount ?? this.amount,
      amountUnit: amountUnit ?? this.amountUnit,
      isEstimate: isEstimate ?? this.isEstimate,
      source: source ?? this.source,
      sourceCheckedAt: sourceCheckedAt ?? this.sourceCheckedAt,
      status: status ?? this.status,
      eatenAt: eatenAt ?? this.eatenAt,
      timeZoneName: timeZoneName ?? this.timeZoneName,
      note: note ?? this.note,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (slotId.present) {
      map['slot_id'] = Variable<String>(slotId.value);
    }
    if (foodId.present) {
      map['food_id'] = Variable<String>(foodId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (brand.present) {
      map['brand'] = Variable<String>(brand.value);
    }
    if (servingAmount.present) {
      map['serving_amount'] = Variable<double>(servingAmount.value);
    }
    if (servingUnit.present) {
      map['serving_unit'] = Variable<String>(servingUnit.value);
    }
    if (energyKcal.present) {
      map['energy_kcal'] = Variable<double>(energyKcal.value);
    }
    if (proteinG.present) {
      map['protein_g'] = Variable<double>(proteinG.value);
    }
    if (carbsG.present) {
      map['carbs_g'] = Variable<double>(carbsG.value);
    }
    if (fatG.present) {
      map['fat_g'] = Variable<double>(fatG.value);
    }
    if (fiberG.present) {
      map['fiber_g'] = Variable<double>(fiberG.value);
    }
    if (sugarG.present) {
      map['sugar_g'] = Variable<double>(sugarG.value);
    }
    if (sodiumMg.present) {
      map['sodium_mg'] = Variable<double>(sodiumMg.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (amountUnit.present) {
      map['amount_unit'] = Variable<String>(amountUnit.value);
    }
    if (isEstimate.present) {
      map['is_estimate'] = Variable<bool>(isEstimate.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (sourceCheckedAt.present) {
      map['source_checked_at'] = Variable<DateTime>(sourceCheckedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $MealEntriesTable.$converterstatus.toSql(status.value),
      );
    }
    if (eatenAt.present) {
      map['eaten_at'] = Variable<DateTime>(eatenAt.value);
    }
    if (timeZoneName.present) {
      map['time_zone_name'] = Variable<String>(timeZoneName.value);
    }
    if (note.present) {
      map['note'] = Variable<String>(note.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MealEntriesCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('day: $day, ')
          ..write('slotId: $slotId, ')
          ..write('foodId: $foodId, ')
          ..write('name: $name, ')
          ..write('brand: $brand, ')
          ..write('servingAmount: $servingAmount, ')
          ..write('servingUnit: $servingUnit, ')
          ..write('energyKcal: $energyKcal, ')
          ..write('proteinG: $proteinG, ')
          ..write('carbsG: $carbsG, ')
          ..write('fatG: $fatG, ')
          ..write('fiberG: $fiberG, ')
          ..write('sugarG: $sugarG, ')
          ..write('sodiumMg: $sodiumMg, ')
          ..write('amount: $amount, ')
          ..write('amountUnit: $amountUnit, ')
          ..write('isEstimate: $isEstimate, ')
          ..write('source: $source, ')
          ..write('sourceCheckedAt: $sourceCheckedAt, ')
          ..write('status: $status, ')
          ..write('eatenAt: $eatenAt, ')
          ..write('timeZoneName: $timeZoneName, ')
          ..write('note: $note, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProgramsTable extends Programs with TableInfo<$ProgramsTable, Program> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProgramsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 120,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalMeta = const VerificationMeta('goal');
  @override
  late final GeneratedColumn<String> goal = GeneratedColumn<String>(
    'goal',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _levelMeta = const VerificationMeta('level');
  @override
  late final GeneratedColumn<String> level = GeneratedColumn<String>(
    'level',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _equipmentMeta = const VerificationMeta(
    'equipment',
  );
  @override
  late final GeneratedColumn<String> equipment = GeneratedColumn<String>(
    'equipment',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _daysPerWeekMeta = const VerificationMeta(
    'daysPerWeek',
  );
  @override
  late final GeneratedColumn<int> daysPerWeek = GeneratedColumn<int>(
    'days_per_week',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _nextDayMeta = const VerificationMeta(
    'nextDay',
  );
  @override
  late final GeneratedColumn<int> nextDay = GeneratedColumn<int>(
    'next_day',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _planMeta = const VerificationMeta('plan');
  @override
  late final GeneratedColumn<String> plan = GeneratedColumn<String>(
    'plan',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    name,
    goal,
    level,
    equipment,
    daysPerWeek,
    active,
    nextDay,
    plan,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'programs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Program> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('goal')) {
      context.handle(
        _goalMeta,
        goal.isAcceptableOrUnknown(data['goal']!, _goalMeta),
      );
    } else if (isInserting) {
      context.missing(_goalMeta);
    }
    if (data.containsKey('level')) {
      context.handle(
        _levelMeta,
        level.isAcceptableOrUnknown(data['level']!, _levelMeta),
      );
    } else if (isInserting) {
      context.missing(_levelMeta);
    }
    if (data.containsKey('equipment')) {
      context.handle(
        _equipmentMeta,
        equipment.isAcceptableOrUnknown(data['equipment']!, _equipmentMeta),
      );
    } else if (isInserting) {
      context.missing(_equipmentMeta);
    }
    if (data.containsKey('days_per_week')) {
      context.handle(
        _daysPerWeekMeta,
        daysPerWeek.isAcceptableOrUnknown(
          data['days_per_week']!,
          _daysPerWeekMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_daysPerWeekMeta);
    }
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    }
    if (data.containsKey('next_day')) {
      context.handle(
        _nextDayMeta,
        nextDay.isAcceptableOrUnknown(data['next_day']!, _nextDayMeta),
      );
    }
    if (data.containsKey('plan')) {
      context.handle(
        _planMeta,
        plan.isAcceptableOrUnknown(data['plan']!, _planMeta),
      );
    } else if (isInserting) {
      context.missing(_planMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Program map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Program(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      goal: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal'],
      )!,
      level: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}level'],
      )!,
      equipment: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}equipment'],
      )!,
      daysPerWeek: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}days_per_week'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      nextDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_day'],
      )!,
      plan: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan'],
      )!,
    );
  }

  @override
  $ProgramsTable createAlias(String alias) {
    return $ProgramsTable(attachedDatabase, alias);
  }
}

class Program extends DataClass implements Insertable<Program> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String name;
  final String goal;
  final String level;
  final String equipment;
  final int daysPerWeek;
  final bool active;

  /// Index of the next day to train in [plan].
  final int nextDay;
  final String plan;
  const Program({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.name,
    required this.goal,
    required this.level,
    required this.equipment,
    required this.daysPerWeek,
    required this.active,
    required this.nextDay,
    required this.plan,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['name'] = Variable<String>(name);
    map['goal'] = Variable<String>(goal);
    map['level'] = Variable<String>(level);
    map['equipment'] = Variable<String>(equipment);
    map['days_per_week'] = Variable<int>(daysPerWeek);
    map['active'] = Variable<bool>(active);
    map['next_day'] = Variable<int>(nextDay);
    map['plan'] = Variable<String>(plan);
    return map;
  }

  ProgramsCompanion toCompanion(bool nullToAbsent) {
    return ProgramsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      name: Value(name),
      goal: Value(goal),
      level: Value(level),
      equipment: Value(equipment),
      daysPerWeek: Value(daysPerWeek),
      active: Value(active),
      nextDay: Value(nextDay),
      plan: Value(plan),
    );
  }

  factory Program.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Program(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      name: serializer.fromJson<String>(json['name']),
      goal: serializer.fromJson<String>(json['goal']),
      level: serializer.fromJson<String>(json['level']),
      equipment: serializer.fromJson<String>(json['equipment']),
      daysPerWeek: serializer.fromJson<int>(json['daysPerWeek']),
      active: serializer.fromJson<bool>(json['active']),
      nextDay: serializer.fromJson<int>(json['nextDay']),
      plan: serializer.fromJson<String>(json['plan']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'name': serializer.toJson<String>(name),
      'goal': serializer.toJson<String>(goal),
      'level': serializer.toJson<String>(level),
      'equipment': serializer.toJson<String>(equipment),
      'daysPerWeek': serializer.toJson<int>(daysPerWeek),
      'active': serializer.toJson<bool>(active),
      'nextDay': serializer.toJson<int>(nextDay),
      'plan': serializer.toJson<String>(plan),
    };
  }

  Program copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? name,
    String? goal,
    String? level,
    String? equipment,
    int? daysPerWeek,
    bool? active,
    int? nextDay,
    String? plan,
  }) => Program(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    name: name ?? this.name,
    goal: goal ?? this.goal,
    level: level ?? this.level,
    equipment: equipment ?? this.equipment,
    daysPerWeek: daysPerWeek ?? this.daysPerWeek,
    active: active ?? this.active,
    nextDay: nextDay ?? this.nextDay,
    plan: plan ?? this.plan,
  );
  Program copyWithCompanion(ProgramsCompanion data) {
    return Program(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      name: data.name.present ? data.name.value : this.name,
      goal: data.goal.present ? data.goal.value : this.goal,
      level: data.level.present ? data.level.value : this.level,
      equipment: data.equipment.present ? data.equipment.value : this.equipment,
      daysPerWeek: data.daysPerWeek.present
          ? data.daysPerWeek.value
          : this.daysPerWeek,
      active: data.active.present ? data.active.value : this.active,
      nextDay: data.nextDay.present ? data.nextDay.value : this.nextDay,
      plan: data.plan.present ? data.plan.value : this.plan,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Program(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('goal: $goal, ')
          ..write('level: $level, ')
          ..write('equipment: $equipment, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('active: $active, ')
          ..write('nextDay: $nextDay, ')
          ..write('plan: $plan')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    name,
    goal,
    level,
    equipment,
    daysPerWeek,
    active,
    nextDay,
    plan,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Program &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.name == this.name &&
          other.goal == this.goal &&
          other.level == this.level &&
          other.equipment == this.equipment &&
          other.daysPerWeek == this.daysPerWeek &&
          other.active == this.active &&
          other.nextDay == this.nextDay &&
          other.plan == this.plan);
}

class ProgramsCompanion extends UpdateCompanion<Program> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> name;
  final Value<String> goal;
  final Value<String> level;
  final Value<String> equipment;
  final Value<int> daysPerWeek;
  final Value<bool> active;
  final Value<int> nextDay;
  final Value<String> plan;
  final Value<int> rowid;
  const ProgramsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.name = const Value.absent(),
    this.goal = const Value.absent(),
    this.level = const Value.absent(),
    this.equipment = const Value.absent(),
    this.daysPerWeek = const Value.absent(),
    this.active = const Value.absent(),
    this.nextDay = const Value.absent(),
    this.plan = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProgramsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String name,
    required String goal,
    required String level,
    required String equipment,
    required int daysPerWeek,
    this.active = const Value.absent(),
    this.nextDay = const Value.absent(),
    required String plan,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       name = Value(name),
       goal = Value(goal),
       level = Value(level),
       equipment = Value(equipment),
       daysPerWeek = Value(daysPerWeek),
       plan = Value(plan);
  static Insertable<Program> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? name,
    Expression<String>? goal,
    Expression<String>? level,
    Expression<String>? equipment,
    Expression<int>? daysPerWeek,
    Expression<bool>? active,
    Expression<int>? nextDay,
    Expression<String>? plan,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (name != null) 'name': name,
      if (goal != null) 'goal': goal,
      if (level != null) 'level': level,
      if (equipment != null) 'equipment': equipment,
      if (daysPerWeek != null) 'days_per_week': daysPerWeek,
      if (active != null) 'active': active,
      if (nextDay != null) 'next_day': nextDay,
      if (plan != null) 'plan': plan,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProgramsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? name,
    Value<String>? goal,
    Value<String>? level,
    Value<String>? equipment,
    Value<int>? daysPerWeek,
    Value<bool>? active,
    Value<int>? nextDay,
    Value<String>? plan,
    Value<int>? rowid,
  }) {
    return ProgramsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      name: name ?? this.name,
      goal: goal ?? this.goal,
      level: level ?? this.level,
      equipment: equipment ?? this.equipment,
      daysPerWeek: daysPerWeek ?? this.daysPerWeek,
      active: active ?? this.active,
      nextDay: nextDay ?? this.nextDay,
      plan: plan ?? this.plan,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (goal.present) {
      map['goal'] = Variable<String>(goal.value);
    }
    if (level.present) {
      map['level'] = Variable<String>(level.value);
    }
    if (equipment.present) {
      map['equipment'] = Variable<String>(equipment.value);
    }
    if (daysPerWeek.present) {
      map['days_per_week'] = Variable<int>(daysPerWeek.value);
    }
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (nextDay.present) {
      map['next_day'] = Variable<int>(nextDay.value);
    }
    if (plan.present) {
      map['plan'] = Variable<String>(plan.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProgramsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('name: $name, ')
          ..write('goal: $goal, ')
          ..write('level: $level, ')
          ..write('equipment: $equipment, ')
          ..write('daysPerWeek: $daysPerWeek, ')
          ..write('active: $active, ')
          ..write('nextDay: $nextDay, ')
          ..write('plan: $plan, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BodyWeightsTable extends BodyWeights
    with TableInfo<$BodyWeightsTable, BodyWeight> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BodyWeightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayMeta = const VerificationMeta('day');
  @override
  late final GeneratedColumn<String> day = GeneratedColumn<String>(
    'day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<double> value = GeneratedColumn<double>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitMeta = const VerificationMeta('unit');
  @override
  late final GeneratedColumn<String> unit = GeneratedColumn<String>(
    'unit',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _measuredAtMeta = const VerificationMeta(
    'measuredAt',
  );
  @override
  late final GeneratedColumn<DateTime> measuredAt = GeneratedColumn<DateTime>(
    'measured_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    day,
    value,
    unit,
    measuredAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'body_weights';
  @override
  VerificationContext validateIntegrity(
    Insertable<BodyWeight> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('unit')) {
      context.handle(
        _unitMeta,
        unit.isAcceptableOrUnknown(data['unit']!, _unitMeta),
      );
    } else if (isInserting) {
      context.missing(_unitMeta);
    }
    if (data.containsKey('measured_at')) {
      context.handle(
        _measuredAtMeta,
        measuredAt.isAcceptableOrUnknown(data['measured_at']!, _measuredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_measuredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BodyWeight map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BodyWeight(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}value'],
      )!,
      unit: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}unit'],
      )!,
      measuredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}measured_at'],
      )!,
    );
  }

  @override
  $BodyWeightsTable createAlias(String alias) {
    return $BodyWeightsTable(attachedDatabase, alias);
  }
}

class BodyWeight extends DataClass implements Insertable<BodyWeight> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String day;
  final double value;
  final String unit;
  final DateTime measuredAt;
  const BodyWeight({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.day,
    required this.value,
    required this.unit,
    required this.measuredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    map['day'] = Variable<String>(day);
    map['value'] = Variable<double>(value);
    map['unit'] = Variable<String>(unit);
    map['measured_at'] = Variable<DateTime>(measuredAt);
    return map;
  }

  BodyWeightsCompanion toCompanion(bool nullToAbsent) {
    return BodyWeightsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      day: Value(day),
      value: Value(value),
      unit: Value(unit),
      measuredAt: Value(measuredAt),
    );
  }

  factory BodyWeight.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BodyWeight(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      day: serializer.fromJson<String>(json['day']),
      value: serializer.fromJson<double>(json['value']),
      unit: serializer.fromJson<String>(json['unit']),
      measuredAt: serializer.fromJson<DateTime>(json['measuredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'day': serializer.toJson<String>(day),
      'value': serializer.toJson<double>(value),
      'unit': serializer.toJson<String>(unit),
      'measuredAt': serializer.toJson<DateTime>(measuredAt),
    };
  }

  BodyWeight copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? day,
    double? value,
    String? unit,
    DateTime? measuredAt,
  }) => BodyWeight(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    day: day ?? this.day,
    value: value ?? this.value,
    unit: unit ?? this.unit,
    measuredAt: measuredAt ?? this.measuredAt,
  );
  BodyWeight copyWithCompanion(BodyWeightsCompanion data) {
    return BodyWeight(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      day: data.day.present ? data.day.value : this.day,
      value: data.value.present ? data.value.value : this.value,
      unit: data.unit.present ? data.unit.value : this.unit,
      measuredAt: data.measuredAt.present
          ? data.measuredAt.value
          : this.measuredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BodyWeight(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('day: $day, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('measuredAt: $measuredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, createdAt, updatedAt, day, value, unit, measuredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BodyWeight &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.day == this.day &&
          other.value == this.value &&
          other.unit == this.unit &&
          other.measuredAt == this.measuredAt);
}

class BodyWeightsCompanion extends UpdateCompanion<BodyWeight> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<String> day;
  final Value<double> value;
  final Value<String> unit;
  final Value<DateTime> measuredAt;
  final Value<int> rowid;
  const BodyWeightsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.day = const Value.absent(),
    this.value = const Value.absent(),
    this.unit = const Value.absent(),
    this.measuredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BodyWeightsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required String day,
    required double value,
    required String unit,
    required DateTime measuredAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       day = Value(day),
       value = Value(value),
       unit = Value(unit),
       measuredAt = Value(measuredAt);
  static Insertable<BodyWeight> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? day,
    Expression<double>? value,
    Expression<String>? unit,
    Expression<DateTime>? measuredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (day != null) 'day': day,
      if (value != null) 'value': value,
      if (unit != null) 'unit': unit,
      if (measuredAt != null) 'measured_at': measuredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BodyWeightsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<String>? day,
    Value<double>? value,
    Value<String>? unit,
    Value<DateTime>? measuredAt,
    Value<int>? rowid,
  }) {
    return BodyWeightsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      day: day ?? this.day,
      value: value ?? this.value,
      unit: unit ?? this.unit,
      measuredAt: measuredAt ?? this.measuredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (value.present) {
      map['value'] = Variable<double>(value.value);
    }
    if (unit.present) {
      map['unit'] = Variable<String>(unit.value);
    }
    if (measuredAt.present) {
      map['measured_at'] = Variable<DateTime>(measuredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BodyWeightsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('day: $day, ')
          ..write('value: $value, ')
          ..write('unit: $unit, ')
          ..write('measuredAt: $measuredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTable extends Settings with TableInfo<$SettingsTable, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTable(this.attachedDatabase, [this._alias]);
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
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
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
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
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
  $SettingsTable createAlias(String alias) {
    return $SettingsTable(attachedDatabase, alias);
  }
}

class Setting extends DataClass implements Insertable<Setting> {
  final String key;
  final String value;
  const Setting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(key: Value(key), value: Value(value));
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
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

  Setting copyWith({String? key, String? value}) =>
      Setting(key: key ?? this.key, value: value ?? this.value);
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
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
      (other is Setting && other.key == this.key && other.value == this.value);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const SettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<Setting> custom({
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

  SettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return SettingsCompanion(
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
    return (StringBuffer('SettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AiProposalsTable extends AiProposals
    with TableInfo<$AiProposalsTable, AiProposal> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AiProposalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProposalKind, String> kind =
      GeneratedColumn<String>(
        'kind',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ProposalKind>($AiProposalsTable.$converterkind);
  static const VerificationMeta _clientMeta = const VerificationMeta('client');
  @override
  late final GeneratedColumn<String> client = GeneratedColumn<String>(
    'client',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _viaMeta = const VerificationMeta('via');
  @override
  late final GeneratedColumn<String> via = GeneratedColumn<String>(
    'via',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _summaryMeta = const VerificationMeta(
    'summary',
  );
  @override
  late final GeneratedColumn<String> summary = GeneratedColumn<String>(
    'summary',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<ProposalStatus, String> status =
      GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<ProposalStatus>($AiProposalsTable.$converterstatus);
  static const VerificationMeta _decidedAtMeta = const VerificationMeta(
    'decidedAt',
  );
  @override
  late final GeneratedColumn<DateTime> decidedAt = GeneratedColumn<DateTime>(
    'decided_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    createdAt,
    updatedAt,
    kind,
    client,
    via,
    summary,
    payload,
    status,
    decidedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'ai_proposals';
  @override
  VerificationContext validateIntegrity(
    Insertable<AiProposal> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    if (data.containsKey('client')) {
      context.handle(
        _clientMeta,
        client.isAcceptableOrUnknown(data['client']!, _clientMeta),
      );
    } else if (isInserting) {
      context.missing(_clientMeta);
    }
    if (data.containsKey('via')) {
      context.handle(
        _viaMeta,
        via.isAcceptableOrUnknown(data['via']!, _viaMeta),
      );
    } else if (isInserting) {
      context.missing(_viaMeta);
    }
    if (data.containsKey('summary')) {
      context.handle(
        _summaryMeta,
        summary.isAcceptableOrUnknown(data['summary']!, _summaryMeta),
      );
    } else if (isInserting) {
      context.missing(_summaryMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('decided_at')) {
      context.handle(
        _decidedAtMeta,
        decidedAt.isAcceptableOrUnknown(data['decided_at']!, _decidedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AiProposal map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AiProposal(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
      kind: $AiProposalsTable.$converterkind.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}kind'],
        )!,
      ),
      client: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}client'],
      )!,
      via: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}via'],
      )!,
      summary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}summary'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      status: $AiProposalsTable.$converterstatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.string,
          data['${effectivePrefix}status'],
        )!,
      ),
      decidedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}decided_at'],
      ),
    );
  }

  @override
  $AiProposalsTable createAlias(String alias) {
    return $AiProposalsTable(attachedDatabase, alias);
  }

  static JsonTypeConverter2<ProposalKind, String, String> $converterkind =
      const EnumNameConverter<ProposalKind>(ProposalKind.values);
  static JsonTypeConverter2<ProposalStatus, String, String> $converterstatus =
      const EnumNameConverter<ProposalStatus>(ProposalStatus.values);
}

class AiProposal extends DataClass implements Insertable<AiProposal> {
  final String id;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProposalKind kind;

  /// Name the AI client gave, for example "Claude". Shown, never trusted.
  final String client;

  /// How the request arrived: 'wifi' or 'online'.
  final String via;
  final String summary;

  /// The validated request as JSON. Its shape depends on [kind].
  final String payload;
  final ProposalStatus status;
  final DateTime? decidedAt;
  const AiProposal({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    required this.kind,
    required this.client,
    required this.via,
    required this.summary,
    required this.payload,
    required this.status,
    this.decidedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    {
      map['kind'] = Variable<String>(
        $AiProposalsTable.$converterkind.toSql(kind),
      );
    }
    map['client'] = Variable<String>(client);
    map['via'] = Variable<String>(via);
    map['summary'] = Variable<String>(summary);
    map['payload'] = Variable<String>(payload);
    {
      map['status'] = Variable<String>(
        $AiProposalsTable.$converterstatus.toSql(status),
      );
    }
    if (!nullToAbsent || decidedAt != null) {
      map['decided_at'] = Variable<DateTime>(decidedAt);
    }
    return map;
  }

  AiProposalsCompanion toCompanion(bool nullToAbsent) {
    return AiProposalsCompanion(
      id: Value(id),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      kind: Value(kind),
      client: Value(client),
      via: Value(via),
      summary: Value(summary),
      payload: Value(payload),
      status: Value(status),
      decidedAt: decidedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(decidedAt),
    );
  }

  factory AiProposal.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AiProposal(
      id: serializer.fromJson<String>(json['id']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      kind: $AiProposalsTable.$converterkind.fromJson(
        serializer.fromJson<String>(json['kind']),
      ),
      client: serializer.fromJson<String>(json['client']),
      via: serializer.fromJson<String>(json['via']),
      summary: serializer.fromJson<String>(json['summary']),
      payload: serializer.fromJson<String>(json['payload']),
      status: $AiProposalsTable.$converterstatus.fromJson(
        serializer.fromJson<String>(json['status']),
      ),
      decidedAt: serializer.fromJson<DateTime?>(json['decidedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'kind': serializer.toJson<String>(
        $AiProposalsTable.$converterkind.toJson(kind),
      ),
      'client': serializer.toJson<String>(client),
      'via': serializer.toJson<String>(via),
      'summary': serializer.toJson<String>(summary),
      'payload': serializer.toJson<String>(payload),
      'status': serializer.toJson<String>(
        $AiProposalsTable.$converterstatus.toJson(status),
      ),
      'decidedAt': serializer.toJson<DateTime?>(decidedAt),
    };
  }

  AiProposal copyWith({
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProposalKind? kind,
    String? client,
    String? via,
    String? summary,
    String? payload,
    ProposalStatus? status,
    Value<DateTime?> decidedAt = const Value.absent(),
  }) => AiProposal(
    id: id ?? this.id,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    kind: kind ?? this.kind,
    client: client ?? this.client,
    via: via ?? this.via,
    summary: summary ?? this.summary,
    payload: payload ?? this.payload,
    status: status ?? this.status,
    decidedAt: decidedAt.present ? decidedAt.value : this.decidedAt,
  );
  AiProposal copyWithCompanion(AiProposalsCompanion data) {
    return AiProposal(
      id: data.id.present ? data.id.value : this.id,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      kind: data.kind.present ? data.kind.value : this.kind,
      client: data.client.present ? data.client.value : this.client,
      via: data.via.present ? data.via.value : this.via,
      summary: data.summary.present ? data.summary.value : this.summary,
      payload: data.payload.present ? data.payload.value : this.payload,
      status: data.status.present ? data.status.value : this.status,
      decidedAt: data.decidedAt.present ? data.decidedAt.value : this.decidedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AiProposal(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('kind: $kind, ')
          ..write('client: $client, ')
          ..write('via: $via, ')
          ..write('summary: $summary, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('decidedAt: $decidedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    createdAt,
    updatedAt,
    kind,
    client,
    via,
    summary,
    payload,
    status,
    decidedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AiProposal &&
          other.id == this.id &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.kind == this.kind &&
          other.client == this.client &&
          other.via == this.via &&
          other.summary == this.summary &&
          other.payload == this.payload &&
          other.status == this.status &&
          other.decidedAt == this.decidedAt);
}

class AiProposalsCompanion extends UpdateCompanion<AiProposal> {
  final Value<String> id;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<ProposalKind> kind;
  final Value<String> client;
  final Value<String> via;
  final Value<String> summary;
  final Value<String> payload;
  final Value<ProposalStatus> status;
  final Value<DateTime?> decidedAt;
  final Value<int> rowid;
  const AiProposalsCompanion({
    this.id = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.kind = const Value.absent(),
    this.client = const Value.absent(),
    this.via = const Value.absent(),
    this.summary = const Value.absent(),
    this.payload = const Value.absent(),
    this.status = const Value.absent(),
    this.decidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AiProposalsCompanion.insert({
    required String id,
    required DateTime createdAt,
    required DateTime updatedAt,
    required ProposalKind kind,
    required String client,
    required String via,
    required String summary,
    required String payload,
    required ProposalStatus status,
    this.decidedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt),
       kind = Value(kind),
       client = Value(client),
       via = Value(via),
       summary = Value(summary),
       payload = Value(payload),
       status = Value(status);
  static Insertable<AiProposal> custom({
    Expression<String>? id,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<String>? kind,
    Expression<String>? client,
    Expression<String>? via,
    Expression<String>? summary,
    Expression<String>? payload,
    Expression<String>? status,
    Expression<DateTime>? decidedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (kind != null) 'kind': kind,
      if (client != null) 'client': client,
      if (via != null) 'via': via,
      if (summary != null) 'summary': summary,
      if (payload != null) 'payload': payload,
      if (status != null) 'status': status,
      if (decidedAt != null) 'decided_at': decidedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AiProposalsCompanion copyWith({
    Value<String>? id,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<ProposalKind>? kind,
    Value<String>? client,
    Value<String>? via,
    Value<String>? summary,
    Value<String>? payload,
    Value<ProposalStatus>? status,
    Value<DateTime?>? decidedAt,
    Value<int>? rowid,
  }) {
    return AiProposalsCompanion(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      kind: kind ?? this.kind,
      client: client ?? this.client,
      via: via ?? this.via,
      summary: summary ?? this.summary,
      payload: payload ?? this.payload,
      status: status ?? this.status,
      decidedAt: decidedAt ?? this.decidedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(
        $AiProposalsTable.$converterkind.toSql(kind.value),
      );
    }
    if (client.present) {
      map['client'] = Variable<String>(client.value);
    }
    if (via.present) {
      map['via'] = Variable<String>(via.value);
    }
    if (summary.present) {
      map['summary'] = Variable<String>(summary.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(
        $AiProposalsTable.$converterstatus.toSql(status.value),
      );
    }
    if (decidedAt.present) {
      map['decided_at'] = Variable<DateTime>(decidedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AiProposalsCompanion(')
          ..write('id: $id, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('kind: $kind, ')
          ..write('client: $client, ')
          ..write('via: $via, ')
          ..write('summary: $summary, ')
          ..write('payload: $payload, ')
          ..write('status: $status, ')
          ..write('decidedAt: $decidedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $HealthWritesTable extends HealthWrites
    with TableInfo<$HealthWritesTable, HealthWrite> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HealthWritesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _recordIdMeta = const VerificationMeta(
    'recordId',
  );
  @override
  late final GeneratedColumn<String> recordId = GeneratedColumn<String>(
    'record_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _kindMeta = const VerificationMeta('kind');
  @override
  late final GeneratedColumn<String> kind = GeneratedColumn<String>(
    'kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _writtenAtMeta = const VerificationMeta(
    'writtenAt',
  );
  @override
  late final GeneratedColumn<DateTime> writtenAt = GeneratedColumn<DateTime>(
    'written_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [recordId, kind, writtenAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'health_writes';
  @override
  VerificationContext validateIntegrity(
    Insertable<HealthWrite> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('record_id')) {
      context.handle(
        _recordIdMeta,
        recordId.isAcceptableOrUnknown(data['record_id']!, _recordIdMeta),
      );
    } else if (isInserting) {
      context.missing(_recordIdMeta);
    }
    if (data.containsKey('kind')) {
      context.handle(
        _kindMeta,
        kind.isAcceptableOrUnknown(data['kind']!, _kindMeta),
      );
    } else if (isInserting) {
      context.missing(_kindMeta);
    }
    if (data.containsKey('written_at')) {
      context.handle(
        _writtenAtMeta,
        writtenAt.isAcceptableOrUnknown(data['written_at']!, _writtenAtMeta),
      );
    } else if (isInserting) {
      context.missing(_writtenAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {recordId, kind};
  @override
  HealthWrite map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return HealthWrite(
      recordId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}record_id'],
      )!,
      kind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}kind'],
      )!,
      writtenAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}written_at'],
      )!,
    );
  }

  @override
  $HealthWritesTable createAlias(String alias) {
    return $HealthWritesTable(attachedDatabase, alias);
  }
}

class HealthWrite extends DataClass implements Insertable<HealthWrite> {
  /// ID of the Reparc record, for example a workout session ID.
  final String recordId;

  /// 'workout' or 'meal'.
  final String kind;
  final DateTime writtenAt;
  const HealthWrite({
    required this.recordId,
    required this.kind,
    required this.writtenAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['record_id'] = Variable<String>(recordId);
    map['kind'] = Variable<String>(kind);
    map['written_at'] = Variable<DateTime>(writtenAt);
    return map;
  }

  HealthWritesCompanion toCompanion(bool nullToAbsent) {
    return HealthWritesCompanion(
      recordId: Value(recordId),
      kind: Value(kind),
      writtenAt: Value(writtenAt),
    );
  }

  factory HealthWrite.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return HealthWrite(
      recordId: serializer.fromJson<String>(json['recordId']),
      kind: serializer.fromJson<String>(json['kind']),
      writtenAt: serializer.fromJson<DateTime>(json['writtenAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'recordId': serializer.toJson<String>(recordId),
      'kind': serializer.toJson<String>(kind),
      'writtenAt': serializer.toJson<DateTime>(writtenAt),
    };
  }

  HealthWrite copyWith({String? recordId, String? kind, DateTime? writtenAt}) =>
      HealthWrite(
        recordId: recordId ?? this.recordId,
        kind: kind ?? this.kind,
        writtenAt: writtenAt ?? this.writtenAt,
      );
  HealthWrite copyWithCompanion(HealthWritesCompanion data) {
    return HealthWrite(
      recordId: data.recordId.present ? data.recordId.value : this.recordId,
      kind: data.kind.present ? data.kind.value : this.kind,
      writtenAt: data.writtenAt.present ? data.writtenAt.value : this.writtenAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('HealthWrite(')
          ..write('recordId: $recordId, ')
          ..write('kind: $kind, ')
          ..write('writtenAt: $writtenAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(recordId, kind, writtenAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is HealthWrite &&
          other.recordId == this.recordId &&
          other.kind == this.kind &&
          other.writtenAt == this.writtenAt);
}

class HealthWritesCompanion extends UpdateCompanion<HealthWrite> {
  final Value<String> recordId;
  final Value<String> kind;
  final Value<DateTime> writtenAt;
  final Value<int> rowid;
  const HealthWritesCompanion({
    this.recordId = const Value.absent(),
    this.kind = const Value.absent(),
    this.writtenAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  HealthWritesCompanion.insert({
    required String recordId,
    required String kind,
    required DateTime writtenAt,
    this.rowid = const Value.absent(),
  }) : recordId = Value(recordId),
       kind = Value(kind),
       writtenAt = Value(writtenAt);
  static Insertable<HealthWrite> custom({
    Expression<String>? recordId,
    Expression<String>? kind,
    Expression<DateTime>? writtenAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (recordId != null) 'record_id': recordId,
      if (kind != null) 'kind': kind,
      if (writtenAt != null) 'written_at': writtenAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  HealthWritesCompanion copyWith({
    Value<String>? recordId,
    Value<String>? kind,
    Value<DateTime>? writtenAt,
    Value<int>? rowid,
  }) {
    return HealthWritesCompanion(
      recordId: recordId ?? this.recordId,
      kind: kind ?? this.kind,
      writtenAt: writtenAt ?? this.writtenAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (recordId.present) {
      map['record_id'] = Variable<String>(recordId.value);
    }
    if (kind.present) {
      map['kind'] = Variable<String>(kind.value);
    }
    if (writtenAt.present) {
      map['written_at'] = Variable<DateTime>(writtenAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HealthWritesCompanion(')
          ..write('recordId: $recordId, ')
          ..write('kind: $kind, ')
          ..write('writtenAt: $writtenAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $ExercisesTable exercises = $ExercisesTable(this);
  late final $WorkoutTemplatesTable workoutTemplates = $WorkoutTemplatesTable(
    this,
  );
  late final $TemplateExercisesTable templateExercises =
      $TemplateExercisesTable(this);
  late final $WorkoutSessionsTable workoutSessions = $WorkoutSessionsTable(
    this,
  );
  late final $SessionExercisesTable sessionExercises = $SessionExercisesTable(
    this,
  );
  late final $SetEntriesTable setEntries = $SetEntriesTable(this);
  late final $FoodsTable foods = $FoodsTable(this);
  late final $MealSlotsTable mealSlots = $MealSlotsTable(this);
  late final $MealEntriesTable mealEntries = $MealEntriesTable(this);
  late final $ProgramsTable programs = $ProgramsTable(this);
  late final $BodyWeightsTable bodyWeights = $BodyWeightsTable(this);
  late final $SettingsTable settings = $SettingsTable(this);
  late final $AiProposalsTable aiProposals = $AiProposalsTable(this);
  late final $HealthWritesTable healthWrites = $HealthWritesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    exercises,
    workoutTemplates,
    templateExercises,
    workoutSessions,
    sessionExercises,
    setEntries,
    foods,
    mealSlots,
    mealEntries,
    programs,
    bodyWeights,
    settings,
    aiProposals,
    healthWrites,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_templates',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('template_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'workout_sessions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('session_exercises', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'session_exercises',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('set_entries', kind: UpdateKind.delete)],
    ),
  ]);
  @override
  DriftDatabaseOptions get options =>
      const DriftDatabaseOptions(storeDateTimeAsText: true);
}

typedef $$ExercisesTableCreateCompanionBuilder = ExercisesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String name,
  Value<String?> variation,
  Value<String?> equipment,
  Value<String?> targetMuscles,
  Value<String?> note,
  Value<String?> instructionSource,
  Value<String?> catalogId,
  Value<bool> archived,
  Value<int> rowid,
});
typedef $$ExercisesTableUpdateCompanionBuilder = ExercisesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String?> variation,
  Value<String?> equipment,
  Value<String?> targetMuscles,
  Value<String?> note,
  Value<String?> instructionSource,
  Value<String?> catalogId,
  Value<bool> archived,
  Value<int> rowid,
});

final class $$ExercisesTableReferences
    extends BaseReferences<_$AppDatabase, $ExercisesTable, Exercise> {
  $$ExercisesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
  _templateExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateExercises,
        aliasName: 'exercises__id__template_exercises__exercise_id',
      );

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$SessionExercisesTable, List<SessionExercise>>
  _sessionExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionExercises,
    aliasName: 'exercises__id__session_exercises__exercise_id',
  );

  $$SessionExercisesTableProcessedTableManager get sessionExercisesRefs {
    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.exerciseId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$ExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get variation => $composableBuilder(
    column: $table.variation,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetMuscles => $composableBuilder(
    column: $table.targetMuscles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get instructionSource => $composableBuilder(
    column: $table.instructionSource,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get catalogId => $composableBuilder(
    column: $table.catalogId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> templateExercisesRefs(
    Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f,
  ) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> sessionExercisesRefs(
    Expression<bool> Function($$SessionExercisesTableFilterComposer f) f,
  ) {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get variation => $composableBuilder(
    column: $table.variation,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetMuscles => $composableBuilder(
    column: $table.targetMuscles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get instructionSource => $composableBuilder(
    column: $table.instructionSource,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get catalogId => $composableBuilder(
    column: $table.catalogId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ExercisesTable> {
  $$ExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get variation =>
      $composableBuilder(column: $table.variation, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<String> get targetMuscles => $composableBuilder(
    column: $table.targetMuscles,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get instructionSource => $composableBuilder(
    column: $table.instructionSource,
    builder: (column) => column,
  );

  GeneratedColumn<String> get catalogId =>
      $composableBuilder(column: $table.catalogId, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.exerciseId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> sessionExercisesRefs<T extends Object>(
    Expression<T> Function($$SessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.exerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$ExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ExercisesTable,
          Exercise,
          $$ExercisesTableFilterComposer,
          $$ExercisesTableOrderingComposer,
          $$ExercisesTableAnnotationComposer,
          $$ExercisesTableCreateCompanionBuilder,
          $$ExercisesTableUpdateCompanionBuilder,
          (Exercise, $$ExercisesTableReferences),
          Exercise,
          PrefetchHooks Function({
            bool templateExercisesRefs,
            bool sessionExercisesRefs,
          })
        > {
  $$ExercisesTableTableManager(_$AppDatabase db, $ExercisesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> variation = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> targetMuscles = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> instructionSource = const Value.absent(),
                Value<String?> catalogId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                variation: variation,
                equipment: equipment,
                targetMuscles: targetMuscles,
                note: note,
                instructionSource: instructionSource,
                catalogId: catalogId,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String name,
                Value<String?> variation = const Value.absent(),
                Value<String?> equipment = const Value.absent(),
                Value<String?> targetMuscles = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> instructionSource = const Value.absent(),
                Value<String?> catalogId = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ExercisesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                variation: variation,
                equipment: equipment,
                targetMuscles: targetMuscles,
                note: note,
                instructionSource: instructionSource,
                catalogId: catalogId,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ExercisesTable, Exercise>(table),
                  $$ExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({templateExercisesRefs = false, sessionExercisesRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (templateExercisesRefs) db.templateExercises,
                    if (sessionExercisesRefs) db.sessionExercises,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (templateExercisesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          TemplateExercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._templateExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).templateExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (sessionExercisesRefs)
                        await $_getPrefetchedData<
                          Exercise,
                          $ExercisesTable,
                          SessionExercise
                        >(
                          currentTable: table,
                          referencedTable: $$ExercisesTableReferences
                              ._sessionExercisesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$ExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).sessionExercisesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.exerciseId == item.id,
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

typedef $$ExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ExercisesTable,
      Exercise,
      $$ExercisesTableFilterComposer,
      $$ExercisesTableOrderingComposer,
      $$ExercisesTableAnnotationComposer,
      $$ExercisesTableCreateCompanionBuilder,
      $$ExercisesTableUpdateCompanionBuilder,
      (Exercise, $$ExercisesTableReferences),
      Exercise,
      PrefetchHooks Function({
        bool templateExercisesRefs,
        bool sessionExercisesRefs,
      })
    >;
typedef $$WorkoutTemplatesTableCreateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String name,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$WorkoutTemplatesTableUpdateCompanionBuilder =
    WorkoutTemplatesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> name,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$WorkoutTemplatesTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutTemplatesTable, WorkoutTemplate> {
  $$WorkoutTemplatesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$TemplateExercisesTable, List<TemplateExercise>>
  _templateExercisesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.templateExercises,
        aliasName: 'workout_templates__id__template_exercises__template_id',
      );

  $$TemplateExercisesTableProcessedTableManager get templateExercisesRefs {
    final manager = $$TemplateExercisesTableTableManager(
      $_db,
      $_db.templateExercises,
    ).filter((f) => f.templateId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _templateExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutTemplatesTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> templateExercisesRefs(
    Expression<bool> Function($$TemplateExercisesTableFilterComposer f) f,
  ) {
    final $$TemplateExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.templateExercises,
      getReferencedColumn: (t) => t.templateId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TemplateExercisesTableFilterComposer(
            $db: $db,
            $table: $db.templateExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutTemplatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutTemplatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutTemplatesTable> {
  $$WorkoutTemplatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  Expression<T> templateExercisesRefs<T extends Object>(
    Expression<T> Function($$TemplateExercisesTableAnnotationComposer a) f,
  ) {
    final $$TemplateExercisesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.templateExercises,
          getReferencedColumn: (t) => t.templateId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$TemplateExercisesTableAnnotationComposer(
                $db: $db,
                $table: $db.templateExercises,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WorkoutTemplatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutTemplatesTable,
          WorkoutTemplate,
          $$WorkoutTemplatesTableFilterComposer,
          $$WorkoutTemplatesTableOrderingComposer,
          $$WorkoutTemplatesTableAnnotationComposer,
          $$WorkoutTemplatesTableCreateCompanionBuilder,
          $$WorkoutTemplatesTableUpdateCompanionBuilder,
          (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
          WorkoutTemplate,
          PrefetchHooks Function({bool templateExercisesRefs})
        > {
  $$WorkoutTemplatesTableTableManager(
    _$AppDatabase db,
    $WorkoutTemplatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutTemplatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutTemplatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutTemplatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutTemplatesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String name,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutTemplatesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutTemplatesTable, WorkoutTemplate>(table),
                  $$WorkoutTemplatesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (templateExercisesRefs) db.templateExercises,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (templateExercisesRefs)
                    await $_getPrefetchedData<
                      WorkoutTemplate,
                      $WorkoutTemplatesTable,
                      TemplateExercise
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutTemplatesTableReferences
                          ._templateExercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkoutTemplatesTableReferences(
                            db,
                            table,
                            p0,
                          ).templateExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.templateId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutTemplatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutTemplatesTable,
      WorkoutTemplate,
      $$WorkoutTemplatesTableFilterComposer,
      $$WorkoutTemplatesTableOrderingComposer,
      $$WorkoutTemplatesTableAnnotationComposer,
      $$WorkoutTemplatesTableCreateCompanionBuilder,
      $$WorkoutTemplatesTableUpdateCompanionBuilder,
      (WorkoutTemplate, $$WorkoutTemplatesTableReferences),
      WorkoutTemplate,
      PrefetchHooks Function({bool templateExercisesRefs})
    >;
typedef $$TemplateExercisesTableCreateCompanionBuilder =
    TemplateExercisesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String templateId,
      required String exerciseId,
      required int position,
      Value<int?> targetSets,
      Value<int?> targetReps,
      Value<int> rowid,
    });
typedef $$TemplateExercisesTableUpdateCompanionBuilder =
    TemplateExercisesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> templateId,
      Value<String> exerciseId,
      Value<int> position,
      Value<int?> targetSets,
      Value<int?> targetReps,
      Value<int> rowid,
    });

final class $$TemplateExercisesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise
        > {
  $$TemplateExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutTemplatesTable _templateIdTable(_$AppDatabase db) => db
      .workoutTemplates
      .createAlias('template_exercises__template_id__workout_templates__id');

  $$WorkoutTemplatesTableProcessedTableManager get templateId {
    final $_column = $_itemColumn<String>('template_id')!;

    final manager = $$WorkoutTemplatesTableTableManager(
      $_db,
      $_db.workoutTemplates,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_templateIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) => db.exercises
      .createAlias('template_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$TemplateExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutTemplatesTableFilterComposer get templateId {
    final $$WorkoutTemplatesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableFilterComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutTemplatesTableOrderingComposer get templateId {
    final $$WorkoutTemplatesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableOrderingComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $TemplateExercisesTable> {
  $$TemplateExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get targetSets => $composableBuilder(
    column: $table.targetSets,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetReps => $composableBuilder(
    column: $table.targetReps,
    builder: (column) => column,
  );

  $$WorkoutTemplatesTableAnnotationComposer get templateId {
    final $$WorkoutTemplatesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.templateId,
      referencedTable: $db.workoutTemplates,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutTemplatesTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutTemplates,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$TemplateExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TemplateExercisesTable,
          TemplateExercise,
          $$TemplateExercisesTableFilterComposer,
          $$TemplateExercisesTableOrderingComposer,
          $$TemplateExercisesTableAnnotationComposer,
          $$TemplateExercisesTableCreateCompanionBuilder,
          $$TemplateExercisesTableUpdateCompanionBuilder,
          (TemplateExercise, $$TemplateExercisesTableReferences),
          TemplateExercise,
          PrefetchHooks Function({bool templateId, bool exerciseId})
        > {
  $$TemplateExercisesTableTableManager(
    _$AppDatabase db,
    $TemplateExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TemplateExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TemplateExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TemplateExercisesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> templateId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int?> targetSets = const Value.absent(),
                Value<int?> targetReps = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateExercisesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                templateId: templateId,
                exerciseId: exerciseId,
                position: position,
                targetSets: targetSets,
                targetReps: targetReps,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String templateId,
                required String exerciseId,
                required int position,
                Value<int?> targetSets = const Value.absent(),
                Value<int?> targetReps = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TemplateExercisesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                templateId: templateId,
                exerciseId: exerciseId,
                position: position,
                targetSets: targetSets,
                targetReps: targetReps,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$TemplateExercisesTable, TemplateExercise>(table),
                  $$TemplateExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({templateId = false, exerciseId = false}) {
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
                    if (templateId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.templateId,
                        referencedTable: $$TemplateExercisesTableReferences
                            ._templateIdTable(db),
                        referencedColumn: $$TemplateExercisesTableReferences
                            ._templateIdTable(db)
                            .id,
                      ) as T;
                    }
                    if (exerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.exerciseId,
                        referencedTable: $$TemplateExercisesTableReferences
                            ._exerciseIdTable(db),
                        referencedColumn: $$TemplateExercisesTableReferences
                            ._exerciseIdTable(db)
                            .id,
                      ) as T;
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

typedef $$TemplateExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TemplateExercisesTable,
      TemplateExercise,
      $$TemplateExercisesTableFilterComposer,
      $$TemplateExercisesTableOrderingComposer,
      $$TemplateExercisesTableAnnotationComposer,
      $$TemplateExercisesTableCreateCompanionBuilder,
      $$TemplateExercisesTableUpdateCompanionBuilder,
      (TemplateExercise, $$TemplateExercisesTableReferences),
      TemplateExercise,
      PrefetchHooks Function({bool templateId, bool exerciseId})
    >;
typedef $$WorkoutSessionsTableCreateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<String?> templateId,
      required String name,
      required SessionStatus status,
      required DateTime startedAt,
      Value<DateTime?> endedAt,
      Value<int> pausedMs,
      Value<DateTime?> pausedAt,
      Value<DateTime?> restStartedAt,
      Value<int?> restTargetSec,
      required int utcOffsetMinutes,
      required String timeZoneName,
      Value<String?> note,
      Value<String?> programId,
      Value<int?> programDay,
      Value<int> rowid,
    });
typedef $$WorkoutSessionsTableUpdateCompanionBuilder =
    WorkoutSessionsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String?> templateId,
      Value<String> name,
      Value<SessionStatus> status,
      Value<DateTime> startedAt,
      Value<DateTime?> endedAt,
      Value<int> pausedMs,
      Value<DateTime?> pausedAt,
      Value<DateTime?> restStartedAt,
      Value<int?> restTargetSec,
      Value<int> utcOffsetMinutes,
      Value<String> timeZoneName,
      Value<String?> note,
      Value<String?> programId,
      Value<int?> programDay,
      Value<int> rowid,
    });

final class $$WorkoutSessionsTableReferences
    extends
        BaseReferences<_$AppDatabase, $WorkoutSessionsTable, WorkoutSession> {
  $$WorkoutSessionsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$SessionExercisesTable, List<SessionExercise>>
  _sessionExercisesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.sessionExercises,
    aliasName: 'workout_sessions__id__session_exercises__session_id',
  );

  $$SessionExercisesTableProcessedTableManager get sessionExercisesRefs {
    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.sessionId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _sessionExercisesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SessionStatus, SessionStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get pausedMs => $composableBuilder(
    column: $table.pausedMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get restStartedAt => $composableBuilder(
    column: $table.restStartedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restTargetSec => $composableBuilder(
    column: $table.restTargetSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get programDay => $composableBuilder(
    column: $table.programDay,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> sessionExercisesRefs(
    Expression<bool> Function($$SessionExercisesTableFilterComposer f) f,
  ) {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endedAt => $composableBuilder(
    column: $table.endedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get pausedMs => $composableBuilder(
    column: $table.pausedMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get pausedAt => $composableBuilder(
    column: $table.pausedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get restStartedAt => $composableBuilder(
    column: $table.restStartedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restTargetSec => $composableBuilder(
    column: $table.restTargetSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get programId => $composableBuilder(
    column: $table.programId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get programDay => $composableBuilder(
    column: $table.programDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SessionStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get pausedMs =>
      $composableBuilder(column: $table.pausedMs, builder: (column) => column);

  GeneratedColumn<DateTime> get pausedAt =>
      $composableBuilder(column: $table.pausedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get restStartedAt => $composableBuilder(
    column: $table.restStartedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restTargetSec => $composableBuilder(
    column: $table.restTargetSec,
    builder: (column) => column,
  );

  GeneratedColumn<int> get utcOffsetMinutes => $composableBuilder(
    column: $table.utcOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<String> get programId =>
      $composableBuilder(column: $table.programId, builder: (column) => column);

  GeneratedColumn<int> get programDay => $composableBuilder(
    column: $table.programDay,
    builder: (column) => column,
  );

  Expression<T> sessionExercisesRefs<T extends Object>(
    Expression<T> Function($$SessionExercisesTableAnnotationComposer a) f,
  ) {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.sessionId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$WorkoutSessionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WorkoutSessionsTable,
          WorkoutSession,
          $$WorkoutSessionsTableFilterComposer,
          $$WorkoutSessionsTableOrderingComposer,
          $$WorkoutSessionsTableAnnotationComposer,
          $$WorkoutSessionsTableCreateCompanionBuilder,
          $$WorkoutSessionsTableUpdateCompanionBuilder,
          (WorkoutSession, $$WorkoutSessionsTableReferences),
          WorkoutSession,
          PrefetchHooks Function({bool sessionExercisesRefs})
        > {
  $$WorkoutSessionsTableTableManager(
    _$AppDatabase db,
    $WorkoutSessionsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<SessionStatus> status = const Value.absent(),
                Value<DateTime> startedAt = const Value.absent(),
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> pausedMs = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<DateTime?> restStartedAt = const Value.absent(),
                Value<int?> restTargetSec = const Value.absent(),
                Value<int> utcOffsetMinutes = const Value.absent(),
                Value<String> timeZoneName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<String?> programId = const Value.absent(),
                Value<int?> programDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSessionsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                templateId: templateId,
                name: name,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                pausedMs: pausedMs,
                pausedAt: pausedAt,
                restStartedAt: restStartedAt,
                restTargetSec: restTargetSec,
                utcOffsetMinutes: utcOffsetMinutes,
                timeZoneName: timeZoneName,
                note: note,
                programId: programId,
                programDay: programDay,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<String?> templateId = const Value.absent(),
                required String name,
                required SessionStatus status,
                required DateTime startedAt,
                Value<DateTime?> endedAt = const Value.absent(),
                Value<int> pausedMs = const Value.absent(),
                Value<DateTime?> pausedAt = const Value.absent(),
                Value<DateTime?> restStartedAt = const Value.absent(),
                Value<int?> restTargetSec = const Value.absent(),
                required int utcOffsetMinutes,
                required String timeZoneName,
                Value<String?> note = const Value.absent(),
                Value<String?> programId = const Value.absent(),
                Value<int?> programDay = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WorkoutSessionsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                templateId: templateId,
                name: name,
                status: status,
                startedAt: startedAt,
                endedAt: endedAt,
                pausedMs: pausedMs,
                pausedAt: pausedAt,
                restStartedAt: restStartedAt,
                restTargetSec: restTargetSec,
                utcOffsetMinutes: utcOffsetMinutes,
                timeZoneName: timeZoneName,
                note: note,
                programId: programId,
                programDay: programDay,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$WorkoutSessionsTable, WorkoutSession>(table),
                  $$WorkoutSessionsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionExercisesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (sessionExercisesRefs) db.sessionExercises,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (sessionExercisesRefs)
                    await $_getPrefetchedData<
                      WorkoutSession,
                      $WorkoutSessionsTable,
                      SessionExercise
                    >(
                      currentTable: table,
                      referencedTable: $$WorkoutSessionsTableReferences
                          ._sessionExercisesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WorkoutSessionsTableReferences(
                            db,
                            table,
                            p0,
                          ).sessionExercisesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.sessionId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WorkoutSessionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WorkoutSessionsTable,
      WorkoutSession,
      $$WorkoutSessionsTableFilterComposer,
      $$WorkoutSessionsTableOrderingComposer,
      $$WorkoutSessionsTableAnnotationComposer,
      $$WorkoutSessionsTableCreateCompanionBuilder,
      $$WorkoutSessionsTableUpdateCompanionBuilder,
      (WorkoutSession, $$WorkoutSessionsTableReferences),
      WorkoutSession,
      PrefetchHooks Function({bool sessionExercisesRefs})
    >;
typedef $$SessionExercisesTableCreateCompanionBuilder =
    SessionExercisesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String sessionId,
      required String exerciseId,
      required int position,
      Value<String?> supersetGroup,
      Value<bool> skipped,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$SessionExercisesTableUpdateCompanionBuilder =
    SessionExercisesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> sessionId,
      Value<String> exerciseId,
      Value<int> position,
      Value<String?> supersetGroup,
      Value<bool> skipped,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$SessionExercisesTableReferences
    extends
        BaseReferences<_$AppDatabase, $SessionExercisesTable, SessionExercise> {
  $$SessionExercisesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WorkoutSessionsTable _sessionIdTable(_$AppDatabase db) => db
      .workoutSessions
      .createAlias('session_exercises__session_id__workout_sessions__id');

  $$WorkoutSessionsTableProcessedTableManager get sessionId {
    final $_column = $_itemColumn<String>('session_id')!;

    final manager = $$WorkoutSessionsTableTableManager(
      $_db,
      $_db.workoutSessions,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $ExercisesTable _exerciseIdTable(_$AppDatabase db) =>
      db.exercises.createAlias('session_exercises__exercise_id__exercises__id');

  $$ExercisesTableProcessedTableManager get exerciseId {
    final $_column = $_itemColumn<String>('exercise_id')!;

    final manager = $$ExercisesTableTableManager(
      $_db,
      $_db.exercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_exerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<$SetEntriesTable, List<SetEntry>>
  _setEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.setEntries,
    aliasName: 'session_exercises__id__set_entries__session_exercise_id',
  );

  $$SetEntriesTableProcessedTableManager get setEntriesRefs {
    final manager = $$SetEntriesTableTableManager($_db, $_db.setEntries).filter(
      (f) => f.sessionExerciseId.id.sqlEquals($_itemColumn<String>('id')!),
    );

    final cache = $_typedResult.readTableOrNull(_setEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SessionExercisesTableFilterComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$WorkoutSessionsTableFilterComposer get sessionId {
    final $$WorkoutSessionsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableFilterComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableFilterComposer get exerciseId {
    final $$ExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableFilterComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> setEntriesRefs(
    Expression<bool> Function($$SetEntriesTableFilterComposer f) f,
  ) {
    final $$SetEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setEntries,
      getReferencedColumn: (t) => t.sessionExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetEntriesTableFilterComposer(
            $db: $db,
            $table: $db.setEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionExercisesTableOrderingComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get skipped => $composableBuilder(
    column: $table.skipped,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$WorkoutSessionsTableOrderingComposer get sessionId {
    final $$WorkoutSessionsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableOrderingComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableOrderingComposer get exerciseId {
    final $$ExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SessionExercisesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SessionExercisesTable> {
  $$SessionExercisesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get supersetGroup => $composableBuilder(
    column: $table.supersetGroup,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get skipped =>
      $composableBuilder(column: $table.skipped, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$WorkoutSessionsTableAnnotationComposer get sessionId {
    final $$WorkoutSessionsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionId,
      referencedTable: $db.workoutSessions,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WorkoutSessionsTableAnnotationComposer(
            $db: $db,
            $table: $db.workoutSessions,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$ExercisesTableAnnotationComposer get exerciseId {
    final $$ExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.exerciseId,
      referencedTable: $db.exercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.exercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> setEntriesRefs<T extends Object>(
    Expression<T> Function($$SetEntriesTableAnnotationComposer a) f,
  ) {
    final $$SetEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setEntries,
      getReferencedColumn: (t) => t.sessionExerciseId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.setEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SessionExercisesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SessionExercisesTable,
          SessionExercise,
          $$SessionExercisesTableFilterComposer,
          $$SessionExercisesTableOrderingComposer,
          $$SessionExercisesTableAnnotationComposer,
          $$SessionExercisesTableCreateCompanionBuilder,
          $$SessionExercisesTableUpdateCompanionBuilder,
          (SessionExercise, $$SessionExercisesTableReferences),
          SessionExercise,
          PrefetchHooks Function({
            bool sessionId,
            bool exerciseId,
            bool setEntriesRefs,
          })
        > {
  $$SessionExercisesTableTableManager(
    _$AppDatabase db,
    $SessionExercisesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SessionExercisesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SessionExercisesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SessionExercisesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> sessionId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String?> supersetGroup = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionExercisesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sessionId: sessionId,
                exerciseId: exerciseId,
                position: position,
                supersetGroup: supersetGroup,
                skipped: skipped,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String sessionId,
                required String exerciseId,
                required int position,
                Value<String?> supersetGroup = const Value.absent(),
                Value<bool> skipped = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SessionExercisesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sessionId: sessionId,
                exerciseId: exerciseId,
                position: position,
                supersetGroup: supersetGroup,
                skipped: skipped,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SessionExercisesTable, SessionExercise>(table),
                  $$SessionExercisesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                sessionId = false,
                exerciseId = false,
                setEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [if (setEntriesRefs) db.setEntries],
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
                        if (sessionId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.sessionId,
                            referencedTable: $$SessionExercisesTableReferences
                                ._sessionIdTable(db),
                            referencedColumn: $$SessionExercisesTableReferences
                                ._sessionIdTable(db)
                                .id,
                          ) as T;
                        }
                        if (exerciseId) {
                          state = state.withJoin(
                            currentTable: table,
                            currentColumn: table.exerciseId,
                            referencedTable: $$SessionExercisesTableReferences
                                ._exerciseIdTable(db),
                            referencedColumn: $$SessionExercisesTableReferences
                                ._exerciseIdTable(db)
                                .id,
                          ) as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (setEntriesRefs)
                        await $_getPrefetchedData<
                          SessionExercise,
                          $SessionExercisesTable,
                          SetEntry
                        >(
                          currentTable: table,
                          referencedTable: $$SessionExercisesTableReferences
                              ._setEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$SessionExercisesTableReferences(
                                db,
                                table,
                                p0,
                              ).setEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.sessionExerciseId == item.id,
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

typedef $$SessionExercisesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SessionExercisesTable,
      SessionExercise,
      $$SessionExercisesTableFilterComposer,
      $$SessionExercisesTableOrderingComposer,
      $$SessionExercisesTableAnnotationComposer,
      $$SessionExercisesTableCreateCompanionBuilder,
      $$SessionExercisesTableUpdateCompanionBuilder,
      (SessionExercise, $$SessionExercisesTableReferences),
      SessionExercise,
      PrefetchHooks Function({
        bool sessionId,
        bool exerciseId,
        bool setEntriesRefs,
      })
    >;
typedef $$SetEntriesTableCreateCompanionBuilder = SetEntriesCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String sessionExerciseId,
  required int position,
  required SetType setType,
  Value<int?> reps,
  Value<double?> load,
  Value<String?> loadUnit,
  Value<int?> durationSec,
  Value<double?> distance,
  Value<String?> distanceUnit,
  Value<int?> restSec,
  Value<double?> effort,
  Value<String?> note,
  Value<bool> completed,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});
typedef $$SetEntriesTableUpdateCompanionBuilder = SetEntriesCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> sessionExerciseId,
  Value<int> position,
  Value<SetType> setType,
  Value<int?> reps,
  Value<double?> load,
  Value<String?> loadUnit,
  Value<int?> durationSec,
  Value<double?> distance,
  Value<String?> distanceUnit,
  Value<int?> restSec,
  Value<double?> effort,
  Value<String?> note,
  Value<bool> completed,
  Value<DateTime?> completedAt,
  Value<int> rowid,
});

final class $$SetEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $SetEntriesTable, SetEntry> {
  $$SetEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SessionExercisesTable _sessionExerciseIdTable(_$AppDatabase db) => db
      .sessionExercises
      .createAlias('set_entries__session_exercise_id__session_exercises__id');

  $$SessionExercisesTableProcessedTableManager get sessionExerciseId {
    final $_column = $_itemColumn<String>('session_exercise_id')!;

    final manager = $$SessionExercisesTableTableManager(
      $_db,
      $_db.sessionExercises,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_sessionExerciseIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<SetType, SetType, String> get setType =>
      $composableBuilder(
        column: $table.setType,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get load => $composableBuilder(
    column: $table.load,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get loadUnit => $composableBuilder(
    column: $table.loadUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get restSec => $composableBuilder(
    column: $table.restSec,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get effort => $composableBuilder(
    column: $table.effort,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$SessionExercisesTableFilterComposer get sessionExerciseId {
    final $$SessionExercisesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableFilterComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get setType => $composableBuilder(
    column: $table.setType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get load => $composableBuilder(
    column: $table.load,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get loadUnit => $composableBuilder(
    column: $table.loadUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get distance => $composableBuilder(
    column: $table.distance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get restSec => $composableBuilder(
    column: $table.restSec,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get effort => $composableBuilder(
    column: $table.effort,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get completed => $composableBuilder(
    column: $table.completed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$SessionExercisesTableOrderingComposer get sessionExerciseId {
    final $$SessionExercisesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableOrderingComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetEntriesTable> {
  $$SetEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<SetType, String> get setType =>
      $composableBuilder(column: $table.setType, builder: (column) => column);

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<double> get load =>
      $composableBuilder(column: $table.load, builder: (column) => column);

  GeneratedColumn<String> get loadUnit =>
      $composableBuilder(column: $table.loadUnit, builder: (column) => column);

  GeneratedColumn<int> get durationSec => $composableBuilder(
    column: $table.durationSec,
    builder: (column) => column,
  );

  GeneratedColumn<double> get distance =>
      $composableBuilder(column: $table.distance, builder: (column) => column);

  GeneratedColumn<String> get distanceUnit => $composableBuilder(
    column: $table.distanceUnit,
    builder: (column) => column,
  );

  GeneratedColumn<int> get restSec =>
      $composableBuilder(column: $table.restSec, builder: (column) => column);

  GeneratedColumn<double> get effort =>
      $composableBuilder(column: $table.effort, builder: (column) => column);

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  GeneratedColumn<bool> get completed =>
      $composableBuilder(column: $table.completed, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  $$SessionExercisesTableAnnotationComposer get sessionExerciseId {
    final $$SessionExercisesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.sessionExerciseId,
      referencedTable: $db.sessionExercises,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SessionExercisesTableAnnotationComposer(
            $db: $db,
            $table: $db.sessionExercises,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetEntriesTable,
          SetEntry,
          $$SetEntriesTableFilterComposer,
          $$SetEntriesTableOrderingComposer,
          $$SetEntriesTableAnnotationComposer,
          $$SetEntriesTableCreateCompanionBuilder,
          $$SetEntriesTableUpdateCompanionBuilder,
          (SetEntry, $$SetEntriesTableReferences),
          SetEntry,
          PrefetchHooks Function({bool sessionExerciseId})
        > {
  $$SetEntriesTableTableManager(_$AppDatabase db, $SetEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> sessionExerciseId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<SetType> setType = const Value.absent(),
                Value<int?> reps = const Value.absent(),
                Value<double?> load = const Value.absent(),
                Value<String?> loadUnit = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<String?> distanceUnit = const Value.absent(),
                Value<int?> restSec = const Value.absent(),
                Value<double?> effort = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetEntriesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sessionExerciseId: sessionExerciseId,
                position: position,
                setType: setType,
                reps: reps,
                load: load,
                loadUnit: loadUnit,
                durationSec: durationSec,
                distance: distance,
                distanceUnit: distanceUnit,
                restSec: restSec,
                effort: effort,
                note: note,
                completed: completed,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String sessionExerciseId,
                required int position,
                required SetType setType,
                Value<int?> reps = const Value.absent(),
                Value<double?> load = const Value.absent(),
                Value<String?> loadUnit = const Value.absent(),
                Value<int?> durationSec = const Value.absent(),
                Value<double?> distance = const Value.absent(),
                Value<String?> distanceUnit = const Value.absent(),
                Value<int?> restSec = const Value.absent(),
                Value<double?> effort = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<bool> completed = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetEntriesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                sessionExerciseId: sessionExerciseId,
                position: position,
                setType: setType,
                reps: reps,
                load: load,
                loadUnit: loadUnit,
                durationSec: durationSec,
                distance: distance,
                distanceUnit: distanceUnit,
                restSec: restSec,
                effort: effort,
                note: note,
                completed: completed,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SetEntriesTable, SetEntry>(table),
                  $$SetEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({sessionExerciseId = false}) {
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
                    if (sessionExerciseId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.sessionExerciseId,
                        referencedTable: $$SetEntriesTableReferences
                            ._sessionExerciseIdTable(db),
                        referencedColumn: $$SetEntriesTableReferences
                            ._sessionExerciseIdTable(db)
                            .id,
                      ) as T;
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

typedef $$SetEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetEntriesTable,
      SetEntry,
      $$SetEntriesTableFilterComposer,
      $$SetEntriesTableOrderingComposer,
      $$SetEntriesTableAnnotationComposer,
      $$SetEntriesTableCreateCompanionBuilder,
      $$SetEntriesTableUpdateCompanionBuilder,
      (SetEntry, $$SetEntriesTableReferences),
      SetEntry,
      PrefetchHooks Function({bool sessionExerciseId})
    >;
typedef $$FoodsTableCreateCompanionBuilder = FoodsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String name,
  Value<String?> brand,
  Value<double?> servingAmount,
  Value<String?> servingUnit,
  Value<double?> energyKcal,
  Value<double?> proteinG,
  Value<double?> carbsG,
  Value<double?> fatG,
  Value<double?> fiberG,
  Value<double?> sugarG,
  Value<double?> sodiumMg,
  Value<bool> isEstimate,
  required String source,
  Value<DateTime?> sourceCheckedAt,
  Value<String?> note,
  Value<int> rowid,
});
typedef $$FoodsTableUpdateCompanionBuilder = FoodsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String?> brand,
  Value<double?> servingAmount,
  Value<String?> servingUnit,
  Value<double?> energyKcal,
  Value<double?> proteinG,
  Value<double?> carbsG,
  Value<double?> fatG,
  Value<double?> fiberG,
  Value<double?> sugarG,
  Value<double?> sodiumMg,
  Value<bool> isEstimate,
  Value<String> source,
  Value<DateTime?> sourceCheckedAt,
  Value<String?> note,
  Value<int> rowid,
});

class $$FoodsTableFilterComposer extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingAmount => $composableBuilder(
    column: $table.servingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceCheckedAt => $composableBuilder(
    column: $table.sourceCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FoodsTableOrderingComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingAmount => $composableBuilder(
    column: $table.servingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceCheckedAt => $composableBuilder(
    column: $table.sourceCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FoodsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FoodsTable> {
  $$FoodsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get servingAmount => $composableBuilder(
    column: $table.servingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get sourceCheckedAt => $composableBuilder(
    column: $table.sourceCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);
}

class $$FoodsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FoodsTable,
          Food,
          $$FoodsTableFilterComposer,
          $$FoodsTableOrderingComposer,
          $$FoodsTableAnnotationComposer,
          $$FoodsTableCreateCompanionBuilder,
          $$FoodsTableUpdateCompanionBuilder,
          (Food, BaseReferences<_$AppDatabase, $FoodsTable, Food>),
          Food,
          PrefetchHooks Function()
        > {
  $$FoodsTableTableManager(_$AppDatabase db, $FoodsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FoodsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FoodsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FoodsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<double?> servingAmount = const Value.absent(),
                Value<String?> servingUnit = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbsG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> sugarG = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> sourceCheckedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                brand: brand,
                servingAmount: servingAmount,
                servingUnit: servingUnit,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                fiberG: fiberG,
                sugarG: sugarG,
                sodiumMg: sodiumMg,
                isEstimate: isEstimate,
                source: source,
                sourceCheckedAt: sourceCheckedAt,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<double?> servingAmount = const Value.absent(),
                Value<String?> servingUnit = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbsG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> sugarG = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                required String source,
                Value<DateTime?> sourceCheckedAt = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FoodsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                brand: brand,
                servingAmount: servingAmount,
                servingUnit: servingUnit,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                fiberG: fiberG,
                sugarG: sugarG,
                sodiumMg: sodiumMg,
                isEstimate: isEstimate,
                source: source,
                sourceCheckedAt: sourceCheckedAt,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FoodsTable, Food>(table),
                  BaseReferences<_$AppDatabase, $FoodsTable, Food>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FoodsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FoodsTable,
      Food,
      $$FoodsTableFilterComposer,
      $$FoodsTableOrderingComposer,
      $$FoodsTableAnnotationComposer,
      $$FoodsTableCreateCompanionBuilder,
      $$FoodsTableUpdateCompanionBuilder,
      (Food, BaseReferences<_$AppDatabase, $FoodsTable, Food>),
      Food,
      PrefetchHooks Function()
    >;
typedef $$MealSlotsTableCreateCompanionBuilder = MealSlotsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String name,
  required int position,
  Value<int?> usualMinute,
  Value<String?> kind,
  Value<bool> archived,
  Value<int> rowid,
});
typedef $$MealSlotsTableUpdateCompanionBuilder = MealSlotsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<int> position,
  Value<int?> usualMinute,
  Value<String?> kind,
  Value<bool> archived,
  Value<int> rowid,
});

final class $$MealSlotsTableReferences
    extends BaseReferences<_$AppDatabase, $MealSlotsTable, MealSlot> {
  $$MealSlotsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MealEntriesTable, List<MealEntry>>
  _mealEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.mealEntries,
    aliasName: 'meal_slots__id__meal_entries__slot_id',
  );

  $$MealEntriesTableProcessedTableManager get mealEntriesRefs {
    final manager = $$MealEntriesTableTableManager(
      $_db,
      $_db.mealEntries,
    ).filter((f) => f.slotId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_mealEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MealSlotsTableFilterComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usualMinute => $composableBuilder(
    column: $table.usualMinute,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> mealEntriesRefs(
    Expression<bool> Function($$MealEntriesTableFilterComposer f) f,
  ) {
    final $$MealEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealEntries,
      getReferencedColumn: (t) => t.slotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealEntriesTableFilterComposer(
            $db: $db,
            $table: $db.mealEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealSlotsTableOrderingComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usualMinute => $composableBuilder(
    column: $table.usualMinute,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get archived => $composableBuilder(
    column: $table.archived,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MealSlotsTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealSlotsTable> {
  $$MealSlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<int> get usualMinute => $composableBuilder(
    column: $table.usualMinute,
    builder: (column) => column,
  );

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<bool> get archived =>
      $composableBuilder(column: $table.archived, builder: (column) => column);

  Expression<T> mealEntriesRefs<T extends Object>(
    Expression<T> Function($$MealEntriesTableAnnotationComposer a) f,
  ) {
    final $$MealEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.mealEntries,
      getReferencedColumn: (t) => t.slotId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.mealEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MealSlotsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealSlotsTable,
          MealSlot,
          $$MealSlotsTableFilterComposer,
          $$MealSlotsTableOrderingComposer,
          $$MealSlotsTableAnnotationComposer,
          $$MealSlotsTableCreateCompanionBuilder,
          $$MealSlotsTableUpdateCompanionBuilder,
          (MealSlot, $$MealSlotsTableReferences),
          MealSlot,
          PrefetchHooks Function({bool mealEntriesRefs})
        > {
  $$MealSlotsTableTableManager(_$AppDatabase db, $MealSlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealSlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealSlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealSlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int?> usualMinute = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealSlotsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                position: position,
                usualMinute: usualMinute,
                kind: kind,
                archived: archived,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String name,
                required int position,
                Value<int?> usualMinute = const Value.absent(),
                Value<String?> kind = const Value.absent(),
                Value<bool> archived = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealSlotsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                position: position,
                usualMinute: usualMinute,
                kind: kind,
                archived: archived,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealSlotsTable, MealSlot>(table),
                  $$MealSlotsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({mealEntriesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (mealEntriesRefs) db.mealEntries],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (mealEntriesRefs)
                    await $_getPrefetchedData<
                      MealSlot,
                      $MealSlotsTable,
                      MealEntry
                    >(
                      currentTable: table,
                      referencedTable: $$MealSlotsTableReferences
                          ._mealEntriesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$MealSlotsTableReferences(
                            db,
                            table,
                            p0,
                          ).mealEntriesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.slotId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$MealSlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealSlotsTable,
      MealSlot,
      $$MealSlotsTableFilterComposer,
      $$MealSlotsTableOrderingComposer,
      $$MealSlotsTableAnnotationComposer,
      $$MealSlotsTableCreateCompanionBuilder,
      $$MealSlotsTableUpdateCompanionBuilder,
      (MealSlot, $$MealSlotsTableReferences),
      MealSlot,
      PrefetchHooks Function({bool mealEntriesRefs})
    >;
typedef $$MealEntriesTableCreateCompanionBuilder =
    MealEntriesCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String day,
      required String slotId,
      Value<String?> foodId,
      required String name,
      Value<String?> brand,
      Value<double?> servingAmount,
      Value<String?> servingUnit,
      Value<double?> energyKcal,
      Value<double?> proteinG,
      Value<double?> carbsG,
      Value<double?> fatG,
      Value<double?> fiberG,
      Value<double?> sugarG,
      Value<double?> sodiumMg,
      Value<double?> amount,
      Value<String?> amountUnit,
      Value<bool> isEstimate,
      required String source,
      Value<DateTime?> sourceCheckedAt,
      required MealStatus status,
      Value<DateTime?> eatenAt,
      required String timeZoneName,
      Value<String?> note,
      Value<int> rowid,
    });
typedef $$MealEntriesTableUpdateCompanionBuilder =
    MealEntriesCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> day,
      Value<String> slotId,
      Value<String?> foodId,
      Value<String> name,
      Value<String?> brand,
      Value<double?> servingAmount,
      Value<String?> servingUnit,
      Value<double?> energyKcal,
      Value<double?> proteinG,
      Value<double?> carbsG,
      Value<double?> fatG,
      Value<double?> fiberG,
      Value<double?> sugarG,
      Value<double?> sodiumMg,
      Value<double?> amount,
      Value<String?> amountUnit,
      Value<bool> isEstimate,
      Value<String> source,
      Value<DateTime?> sourceCheckedAt,
      Value<MealStatus> status,
      Value<DateTime?> eatenAt,
      Value<String> timeZoneName,
      Value<String?> note,
      Value<int> rowid,
    });

final class $$MealEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $MealEntriesTable, MealEntry> {
  $$MealEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MealSlotsTable _slotIdTable(_$AppDatabase db) =>
      db.mealSlots.createAlias('meal_entries__slot_id__meal_slots__id');

  $$MealSlotsTableProcessedTableManager get slotId {
    final $_column = $_itemColumn<String>('slot_id')!;

    final manager = $$MealSlotsTableTableManager(
      $_db,
      $_db.mealSlots,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_slotIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MealEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get servingAmount => $composableBuilder(
    column: $table.servingAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get amountUnit => $composableBuilder(
    column: $table.amountUnit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get sourceCheckedAt => $composableBuilder(
    column: $table.sourceCheckedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<MealStatus, MealStatus, String> get status =>
      $composableBuilder(
        column: $table.status,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnFilters(column),
  );

  $$MealSlotsTableFilterComposer get slotId {
    final $$MealSlotsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.mealSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealSlotsTableFilterComposer(
            $db: $db,
            $table: $db.mealSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get foodId => $composableBuilder(
    column: $table.foodId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get brand => $composableBuilder(
    column: $table.brand,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get servingAmount => $composableBuilder(
    column: $table.servingAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get proteinG => $composableBuilder(
    column: $table.proteinG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get carbsG => $composableBuilder(
    column: $table.carbsG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fatG => $composableBuilder(
    column: $table.fatG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get fiberG => $composableBuilder(
    column: $table.fiberG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sugarG => $composableBuilder(
    column: $table.sugarG,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get sodiumMg => $composableBuilder(
    column: $table.sodiumMg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get amountUnit => $composableBuilder(
    column: $table.amountUnit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get sourceCheckedAt => $composableBuilder(
    column: $table.sourceCheckedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get eatenAt => $composableBuilder(
    column: $table.eatenAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get note => $composableBuilder(
    column: $table.note,
    builder: (column) => ColumnOrderings(column),
  );

  $$MealSlotsTableOrderingComposer get slotId {
    final $$MealSlotsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.mealSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealSlotsTableOrderingComposer(
            $db: $db,
            $table: $db.mealSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MealEntriesTable> {
  $$MealEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<String> get foodId =>
      $composableBuilder(column: $table.foodId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get brand =>
      $composableBuilder(column: $table.brand, builder: (column) => column);

  GeneratedColumn<double> get servingAmount => $composableBuilder(
    column: $table.servingAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get servingUnit => $composableBuilder(
    column: $table.servingUnit,
    builder: (column) => column,
  );

  GeneratedColumn<double> get energyKcal => $composableBuilder(
    column: $table.energyKcal,
    builder: (column) => column,
  );

  GeneratedColumn<double> get proteinG =>
      $composableBuilder(column: $table.proteinG, builder: (column) => column);

  GeneratedColumn<double> get carbsG =>
      $composableBuilder(column: $table.carbsG, builder: (column) => column);

  GeneratedColumn<double> get fatG =>
      $composableBuilder(column: $table.fatG, builder: (column) => column);

  GeneratedColumn<double> get fiberG =>
      $composableBuilder(column: $table.fiberG, builder: (column) => column);

  GeneratedColumn<double> get sugarG =>
      $composableBuilder(column: $table.sugarG, builder: (column) => column);

  GeneratedColumn<double> get sodiumMg =>
      $composableBuilder(column: $table.sodiumMg, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  GeneratedColumn<String> get amountUnit => $composableBuilder(
    column: $table.amountUnit,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isEstimate => $composableBuilder(
    column: $table.isEstimate,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get sourceCheckedAt => $composableBuilder(
    column: $table.sourceCheckedAt,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<MealStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get eatenAt =>
      $composableBuilder(column: $table.eatenAt, builder: (column) => column);

  GeneratedColumn<String> get timeZoneName => $composableBuilder(
    column: $table.timeZoneName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get note =>
      $composableBuilder(column: $table.note, builder: (column) => column);

  $$MealSlotsTableAnnotationComposer get slotId {
    final $$MealSlotsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.slotId,
      referencedTable: $db.mealSlots,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MealSlotsTableAnnotationComposer(
            $db: $db,
            $table: $db.mealSlots,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MealEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MealEntriesTable,
          MealEntry,
          $$MealEntriesTableFilterComposer,
          $$MealEntriesTableOrderingComposer,
          $$MealEntriesTableAnnotationComposer,
          $$MealEntriesTableCreateCompanionBuilder,
          $$MealEntriesTableUpdateCompanionBuilder,
          (MealEntry, $$MealEntriesTableReferences),
          MealEntry,
          PrefetchHooks Function({bool slotId})
        > {
  $$MealEntriesTableTableManager(_$AppDatabase db, $MealEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MealEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MealEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MealEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<String> slotId = const Value.absent(),
                Value<String?> foodId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> brand = const Value.absent(),
                Value<double?> servingAmount = const Value.absent(),
                Value<String?> servingUnit = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbsG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> sugarG = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<String?> amountUnit = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime?> sourceCheckedAt = const Value.absent(),
                Value<MealStatus> status = const Value.absent(),
                Value<DateTime?> eatenAt = const Value.absent(),
                Value<String> timeZoneName = const Value.absent(),
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealEntriesCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                day: day,
                slotId: slotId,
                foodId: foodId,
                name: name,
                brand: brand,
                servingAmount: servingAmount,
                servingUnit: servingUnit,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                fiberG: fiberG,
                sugarG: sugarG,
                sodiumMg: sodiumMg,
                amount: amount,
                amountUnit: amountUnit,
                isEstimate: isEstimate,
                source: source,
                sourceCheckedAt: sourceCheckedAt,
                status: status,
                eatenAt: eatenAt,
                timeZoneName: timeZoneName,
                note: note,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String day,
                required String slotId,
                Value<String?> foodId = const Value.absent(),
                required String name,
                Value<String?> brand = const Value.absent(),
                Value<double?> servingAmount = const Value.absent(),
                Value<String?> servingUnit = const Value.absent(),
                Value<double?> energyKcal = const Value.absent(),
                Value<double?> proteinG = const Value.absent(),
                Value<double?> carbsG = const Value.absent(),
                Value<double?> fatG = const Value.absent(),
                Value<double?> fiberG = const Value.absent(),
                Value<double?> sugarG = const Value.absent(),
                Value<double?> sodiumMg = const Value.absent(),
                Value<double?> amount = const Value.absent(),
                Value<String?> amountUnit = const Value.absent(),
                Value<bool> isEstimate = const Value.absent(),
                required String source,
                Value<DateTime?> sourceCheckedAt = const Value.absent(),
                required MealStatus status,
                Value<DateTime?> eatenAt = const Value.absent(),
                required String timeZoneName,
                Value<String?> note = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MealEntriesCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                day: day,
                slotId: slotId,
                foodId: foodId,
                name: name,
                brand: brand,
                servingAmount: servingAmount,
                servingUnit: servingUnit,
                energyKcal: energyKcal,
                proteinG: proteinG,
                carbsG: carbsG,
                fatG: fatG,
                fiberG: fiberG,
                sugarG: sugarG,
                sodiumMg: sodiumMg,
                amount: amount,
                amountUnit: amountUnit,
                isEstimate: isEstimate,
                source: source,
                sourceCheckedAt: sourceCheckedAt,
                status: status,
                eatenAt: eatenAt,
                timeZoneName: timeZoneName,
                note: note,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$MealEntriesTable, MealEntry>(table),
                  $$MealEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({slotId = false}) {
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
                    if (slotId) {
                      state = state.withJoin(
                        currentTable: table,
                        currentColumn: table.slotId,
                        referencedTable: $$MealEntriesTableReferences
                            ._slotIdTable(db),
                        referencedColumn: $$MealEntriesTableReferences
                            ._slotIdTable(db)
                            .id,
                      ) as T;
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

typedef $$MealEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MealEntriesTable,
      MealEntry,
      $$MealEntriesTableFilterComposer,
      $$MealEntriesTableOrderingComposer,
      $$MealEntriesTableAnnotationComposer,
      $$MealEntriesTableCreateCompanionBuilder,
      $$MealEntriesTableUpdateCompanionBuilder,
      (MealEntry, $$MealEntriesTableReferences),
      MealEntry,
      PrefetchHooks Function({bool slotId})
    >;
typedef $$ProgramsTableCreateCompanionBuilder = ProgramsCompanion Function({
  required String id,
  required DateTime createdAt,
  required DateTime updatedAt,
  required String name,
  required String goal,
  required String level,
  required String equipment,
  required int daysPerWeek,
  Value<bool> active,
  Value<int> nextDay,
  required String plan,
  Value<int> rowid,
});
typedef $$ProgramsTableUpdateCompanionBuilder = ProgramsCompanion Function({
  Value<String> id,
  Value<DateTime> createdAt,
  Value<DateTime> updatedAt,
  Value<String> name,
  Value<String> goal,
  Value<String> level,
  Value<String> equipment,
  Value<int> daysPerWeek,
  Value<bool> active,
  Value<int> nextDay,
  Value<String> plan,
  Value<int> rowid,
});

class $$ProgramsTableFilterComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get nextDay => $composableBuilder(
    column: $table.nextDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProgramsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goal => $composableBuilder(
    column: $table.goal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get level => $composableBuilder(
    column: $table.level,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get equipment => $composableBuilder(
    column: $table.equipment,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get nextDay => $composableBuilder(
    column: $table.nextDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get plan => $composableBuilder(
    column: $table.plan,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProgramsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProgramsTable> {
  $$ProgramsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get goal =>
      $composableBuilder(column: $table.goal, builder: (column) => column);

  GeneratedColumn<String> get level =>
      $composableBuilder(column: $table.level, builder: (column) => column);

  GeneratedColumn<String> get equipment =>
      $composableBuilder(column: $table.equipment, builder: (column) => column);

  GeneratedColumn<int> get daysPerWeek => $composableBuilder(
    column: $table.daysPerWeek,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<int> get nextDay =>
      $composableBuilder(column: $table.nextDay, builder: (column) => column);

  GeneratedColumn<String> get plan =>
      $composableBuilder(column: $table.plan, builder: (column) => column);
}

class $$ProgramsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProgramsTable,
          Program,
          $$ProgramsTableFilterComposer,
          $$ProgramsTableOrderingComposer,
          $$ProgramsTableAnnotationComposer,
          $$ProgramsTableCreateCompanionBuilder,
          $$ProgramsTableUpdateCompanionBuilder,
          (Program, BaseReferences<_$AppDatabase, $ProgramsTable, Program>),
          Program,
          PrefetchHooks Function()
        > {
  $$ProgramsTableTableManager(_$AppDatabase db, $ProgramsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProgramsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProgramsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProgramsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> goal = const Value.absent(),
                Value<String> level = const Value.absent(),
                Value<String> equipment = const Value.absent(),
                Value<int> daysPerWeek = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<int> nextDay = const Value.absent(),
                Value<String> plan = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                goal: goal,
                level: level,
                equipment: equipment,
                daysPerWeek: daysPerWeek,
                active: active,
                nextDay: nextDay,
                plan: plan,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String name,
                required String goal,
                required String level,
                required String equipment,
                required int daysPerWeek,
                Value<bool> active = const Value.absent(),
                Value<int> nextDay = const Value.absent(),
                required String plan,
                Value<int> rowid = const Value.absent(),
              }) => ProgramsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                name: name,
                goal: goal,
                level: level,
                equipment: equipment,
                daysPerWeek: daysPerWeek,
                active: active,
                nextDay: nextDay,
                plan: plan,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ProgramsTable, Program>(table),
                  BaseReferences<_$AppDatabase, $ProgramsTable, Program>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProgramsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProgramsTable,
      Program,
      $$ProgramsTableFilterComposer,
      $$ProgramsTableOrderingComposer,
      $$ProgramsTableAnnotationComposer,
      $$ProgramsTableCreateCompanionBuilder,
      $$ProgramsTableUpdateCompanionBuilder,
      (Program, BaseReferences<_$AppDatabase, $ProgramsTable, Program>),
      Program,
      PrefetchHooks Function()
    >;
typedef $$BodyWeightsTableCreateCompanionBuilder =
    BodyWeightsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      required String day,
      required double value,
      required String unit,
      required DateTime measuredAt,
      Value<int> rowid,
    });
typedef $$BodyWeightsTableUpdateCompanionBuilder =
    BodyWeightsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<String> day,
      Value<double> value,
      Value<String> unit,
      Value<DateTime> measuredAt,
      Value<int> rowid,
    });

class $$BodyWeightsTableFilterComposer
    extends Composer<_$AppDatabase, $BodyWeightsTable> {
  $$BodyWeightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BodyWeightsTableOrderingComposer
    extends Composer<_$AppDatabase, $BodyWeightsTable> {
  $$BodyWeightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get unit => $composableBuilder(
    column: $table.unit,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BodyWeightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BodyWeightsTable> {
  $$BodyWeightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<double> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<String> get unit =>
      $composableBuilder(column: $table.unit, builder: (column) => column);

  GeneratedColumn<DateTime> get measuredAt => $composableBuilder(
    column: $table.measuredAt,
    builder: (column) => column,
  );
}

class $$BodyWeightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BodyWeightsTable,
          BodyWeight,
          $$BodyWeightsTableFilterComposer,
          $$BodyWeightsTableOrderingComposer,
          $$BodyWeightsTableAnnotationComposer,
          $$BodyWeightsTableCreateCompanionBuilder,
          $$BodyWeightsTableUpdateCompanionBuilder,
          (
            BodyWeight,
            BaseReferences<_$AppDatabase, $BodyWeightsTable, BodyWeight>,
          ),
          BodyWeight,
          PrefetchHooks Function()
        > {
  $$BodyWeightsTableTableManager(_$AppDatabase db, $BodyWeightsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BodyWeightsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BodyWeightsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BodyWeightsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<double> value = const Value.absent(),
                Value<String> unit = const Value.absent(),
                Value<DateTime> measuredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BodyWeightsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                day: day,
                value: value,
                unit: unit,
                measuredAt: measuredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required String day,
                required double value,
                required String unit,
                required DateTime measuredAt,
                Value<int> rowid = const Value.absent(),
              }) => BodyWeightsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                day: day,
                value: value,
                unit: unit,
                measuredAt: measuredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$BodyWeightsTable, BodyWeight>(table),
                  BaseReferences<_$AppDatabase, $BodyWeightsTable, BodyWeight>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BodyWeightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BodyWeightsTable,
      BodyWeight,
      $$BodyWeightsTableFilterComposer,
      $$BodyWeightsTableOrderingComposer,
      $$BodyWeightsTableAnnotationComposer,
      $$BodyWeightsTableCreateCompanionBuilder,
      $$BodyWeightsTableUpdateCompanionBuilder,
      (
        BodyWeight,
        BaseReferences<_$AppDatabase, $BodyWeightsTable, BodyWeight>,
      ),
      BodyWeight,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableCreateCompanionBuilder = SettingsCompanion Function({
  required String key,
  required String value,
  Value<int> rowid,
});
typedef $$SettingsTableUpdateCompanionBuilder = SettingsCompanion Function({
  Value<String> key,
  Value<String> value,
  Value<int> rowid,
});

class $$SettingsTableFilterComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableFilterComposer({
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

class $$SettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableOrderingComposer({
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

class $$SettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SettingsTable> {
  $$SettingsTableAnnotationComposer({
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

class $$SettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SettingsTable,
          Setting,
          $$SettingsTableFilterComposer,
          $$SettingsTableOrderingComposer,
          $$SettingsTableAnnotationComposer,
          $$SettingsTableCreateCompanionBuilder,
          $$SettingsTableUpdateCompanionBuilder,
          (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
          Setting,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableManager(_$AppDatabase db, $SettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> key = const Value.absent(),
            Value<String> value = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback: ({
            required String key,
            required String value,
            Value<int> rowid = const Value.absent(),
          }) => SettingsCompanion.insert(key: key, value: value, rowid: rowid),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTable, Setting>(table),
                  BaseReferences<_$AppDatabase, $SettingsTable, Setting>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SettingsTable,
      Setting,
      $$SettingsTableFilterComposer,
      $$SettingsTableOrderingComposer,
      $$SettingsTableAnnotationComposer,
      $$SettingsTableCreateCompanionBuilder,
      $$SettingsTableUpdateCompanionBuilder,
      (Setting, BaseReferences<_$AppDatabase, $SettingsTable, Setting>),
      Setting,
      PrefetchHooks Function()
    >;
typedef $$AiProposalsTableCreateCompanionBuilder =
    AiProposalsCompanion Function({
      required String id,
      required DateTime createdAt,
      required DateTime updatedAt,
      required ProposalKind kind,
      required String client,
      required String via,
      required String summary,
      required String payload,
      required ProposalStatus status,
      Value<DateTime?> decidedAt,
      Value<int> rowid,
    });
typedef $$AiProposalsTableUpdateCompanionBuilder =
    AiProposalsCompanion Function({
      Value<String> id,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<ProposalKind> kind,
      Value<String> client,
      Value<String> via,
      Value<String> summary,
      Value<String> payload,
      Value<ProposalStatus> status,
      Value<DateTime?> decidedAt,
      Value<int> rowid,
    });

class $$AiProposalsTableFilterComposer
    extends Composer<_$AppDatabase, $AiProposalsTable> {
  $$AiProposalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProposalKind, ProposalKind, String> get kind =>
      $composableBuilder(
        column: $table.kind,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get client => $composableBuilder(
    column: $table.client,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get via => $composableBuilder(
    column: $table.via,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<ProposalStatus, ProposalStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AiProposalsTableOrderingComposer
    extends Composer<_$AppDatabase, $AiProposalsTable> {
  $$AiProposalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get client => $composableBuilder(
    column: $table.client,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get via => $composableBuilder(
    column: $table.via,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get summary => $composableBuilder(
    column: $table.summary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get decidedAt => $composableBuilder(
    column: $table.decidedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AiProposalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AiProposalsTable> {
  $$AiProposalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProposalKind, String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<String> get client =>
      $composableBuilder(column: $table.client, builder: (column) => column);

  GeneratedColumn<String> get via =>
      $composableBuilder(column: $table.via, builder: (column) => column);

  GeneratedColumn<String> get summary =>
      $composableBuilder(column: $table.summary, builder: (column) => column);

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumnWithTypeConverter<ProposalStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<DateTime> get decidedAt =>
      $composableBuilder(column: $table.decidedAt, builder: (column) => column);
}

class $$AiProposalsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AiProposalsTable,
          AiProposal,
          $$AiProposalsTableFilterComposer,
          $$AiProposalsTableOrderingComposer,
          $$AiProposalsTableAnnotationComposer,
          $$AiProposalsTableCreateCompanionBuilder,
          $$AiProposalsTableUpdateCompanionBuilder,
          (
            AiProposal,
            BaseReferences<_$AppDatabase, $AiProposalsTable, AiProposal>,
          ),
          AiProposal,
          PrefetchHooks Function()
        > {
  $$AiProposalsTableTableManager(_$AppDatabase db, $AiProposalsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AiProposalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AiProposalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AiProposalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<ProposalKind> kind = const Value.absent(),
                Value<String> client = const Value.absent(),
                Value<String> via = const Value.absent(),
                Value<String> summary = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<ProposalStatus> status = const Value.absent(),
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiProposalsCompanion(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                kind: kind,
                client: client,
                via: via,
                summary: summary,
                payload: payload,
                status: status,
                decidedAt: decidedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required DateTime createdAt,
                required DateTime updatedAt,
                required ProposalKind kind,
                required String client,
                required String via,
                required String summary,
                required String payload,
                required ProposalStatus status,
                Value<DateTime?> decidedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AiProposalsCompanion.insert(
                id: id,
                createdAt: createdAt,
                updatedAt: updatedAt,
                kind: kind,
                client: client,
                via: via,
                summary: summary,
                payload: payload,
                status: status,
                decidedAt: decidedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AiProposalsTable, AiProposal>(table),
                  BaseReferences<_$AppDatabase, $AiProposalsTable, AiProposal>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AiProposalsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AiProposalsTable,
      AiProposal,
      $$AiProposalsTableFilterComposer,
      $$AiProposalsTableOrderingComposer,
      $$AiProposalsTableAnnotationComposer,
      $$AiProposalsTableCreateCompanionBuilder,
      $$AiProposalsTableUpdateCompanionBuilder,
      (
        AiProposal,
        BaseReferences<_$AppDatabase, $AiProposalsTable, AiProposal>,
      ),
      AiProposal,
      PrefetchHooks Function()
    >;
typedef $$HealthWritesTableCreateCompanionBuilder =
    HealthWritesCompanion Function({
      required String recordId,
      required String kind,
      required DateTime writtenAt,
      Value<int> rowid,
    });
typedef $$HealthWritesTableUpdateCompanionBuilder =
    HealthWritesCompanion Function({
      Value<String> recordId,
      Value<String> kind,
      Value<DateTime> writtenAt,
      Value<int> rowid,
    });

class $$HealthWritesTableFilterComposer
    extends Composer<_$AppDatabase, $HealthWritesTable> {
  $$HealthWritesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get writtenAt => $composableBuilder(
    column: $table.writtenAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HealthWritesTableOrderingComposer
    extends Composer<_$AppDatabase, $HealthWritesTable> {
  $$HealthWritesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get recordId => $composableBuilder(
    column: $table.recordId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get kind => $composableBuilder(
    column: $table.kind,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get writtenAt => $composableBuilder(
    column: $table.writtenAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HealthWritesTableAnnotationComposer
    extends Composer<_$AppDatabase, $HealthWritesTable> {
  $$HealthWritesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get recordId =>
      $composableBuilder(column: $table.recordId, builder: (column) => column);

  GeneratedColumn<String> get kind =>
      $composableBuilder(column: $table.kind, builder: (column) => column);

  GeneratedColumn<DateTime> get writtenAt =>
      $composableBuilder(column: $table.writtenAt, builder: (column) => column);
}

class $$HealthWritesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $HealthWritesTable,
          HealthWrite,
          $$HealthWritesTableFilterComposer,
          $$HealthWritesTableOrderingComposer,
          $$HealthWritesTableAnnotationComposer,
          $$HealthWritesTableCreateCompanionBuilder,
          $$HealthWritesTableUpdateCompanionBuilder,
          (
            HealthWrite,
            BaseReferences<_$AppDatabase, $HealthWritesTable, HealthWrite>,
          ),
          HealthWrite,
          PrefetchHooks Function()
        > {
  $$HealthWritesTableTableManager(_$AppDatabase db, $HealthWritesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HealthWritesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HealthWritesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HealthWritesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> recordId = const Value.absent(),
                Value<String> kind = const Value.absent(),
                Value<DateTime> writtenAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => HealthWritesCompanion(
                recordId: recordId,
                kind: kind,
                writtenAt: writtenAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String recordId,
                required String kind,
                required DateTime writtenAt,
                Value<int> rowid = const Value.absent(),
              }) => HealthWritesCompanion.insert(
                recordId: recordId,
                kind: kind,
                writtenAt: writtenAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HealthWritesTable, HealthWrite>(table),
                  BaseReferences<
                    _$AppDatabase,
                    $HealthWritesTable,
                    HealthWrite
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$HealthWritesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $HealthWritesTable,
      HealthWrite,
      $$HealthWritesTableFilterComposer,
      $$HealthWritesTableOrderingComposer,
      $$HealthWritesTableAnnotationComposer,
      $$HealthWritesTableCreateCompanionBuilder,
      $$HealthWritesTableUpdateCompanionBuilder,
      (
        HealthWrite,
        BaseReferences<_$AppDatabase, $HealthWritesTable, HealthWrite>,
      ),
      HealthWrite,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$ExercisesTableTableManager get exercises =>
      $$ExercisesTableTableManager(_db, _db.exercises);
  $$WorkoutTemplatesTableTableManager get workoutTemplates =>
      $$WorkoutTemplatesTableTableManager(_db, _db.workoutTemplates);
  $$TemplateExercisesTableTableManager get templateExercises =>
      $$TemplateExercisesTableTableManager(_db, _db.templateExercises);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$SessionExercisesTableTableManager get sessionExercises =>
      $$SessionExercisesTableTableManager(_db, _db.sessionExercises);
  $$SetEntriesTableTableManager get setEntries =>
      $$SetEntriesTableTableManager(_db, _db.setEntries);
  $$FoodsTableTableManager get foods =>
      $$FoodsTableTableManager(_db, _db.foods);
  $$MealSlotsTableTableManager get mealSlots =>
      $$MealSlotsTableTableManager(_db, _db.mealSlots);
  $$MealEntriesTableTableManager get mealEntries =>
      $$MealEntriesTableTableManager(_db, _db.mealEntries);
  $$ProgramsTableTableManager get programs =>
      $$ProgramsTableTableManager(_db, _db.programs);
  $$BodyWeightsTableTableManager get bodyWeights =>
      $$BodyWeightsTableTableManager(_db, _db.bodyWeights);
  $$SettingsTableTableManager get settings =>
      $$SettingsTableTableManager(_db, _db.settings);
  $$AiProposalsTableTableManager get aiProposals =>
      $$AiProposalsTableTableManager(_db, _db.aiProposals);
  $$HealthWritesTableTableManager get healthWrites =>
      $$HealthWritesTableTableManager(_db, _db.healthWrites);
}
