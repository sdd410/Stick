// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $HabitsTable extends Habits with TableInfo<$HabitsTable, Habit> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $HabitsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  static const VerificationMeta _tinyMeta = const VerificationMeta('tiny');
  @override
  late final GeneratedColumn<String> tiny = GeneratedColumn<String>(
    'tiny',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _whyMeta = const VerificationMeta('why');
  @override
  late final GeneratedColumn<String> why = GeneratedColumn<String>(
    'why',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    tiny,
    why,
    reminderMinutes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'habits';
  @override
  VerificationContext validateIntegrity(
    Insertable<Habit> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('tiny')) {
      context.handle(
        _tinyMeta,
        tiny.isAcceptableOrUnknown(data['tiny']!, _tinyMeta),
      );
    }
    if (data.containsKey('why')) {
      context.handle(
        _whyMeta,
        why.isAcceptableOrUnknown(data['why']!, _whyMeta),
      );
    } else if (isInserting) {
      context.missing(_whyMeta);
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderMinutesMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Habit map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Habit(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      tiny: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tiny'],
      ),
      why: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}why'],
      )!,
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $HabitsTable createAlias(String alias) {
    return $HabitsTable(attachedDatabase, alias);
  }
}

class Habit extends DataClass implements Insertable<Habit> {
  final int id;
  final String name;
  final String? tiny;
  final String why;
  final int reminderMinutes;
  final DateTime createdAt;
  const Habit({
    required this.id,
    required this.name,
    this.tiny,
    required this.why,
    required this.reminderMinutes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || tiny != null) {
      map['tiny'] = Variable<String>(tiny);
    }
    map['why'] = Variable<String>(why);
    map['reminder_minutes'] = Variable<int>(reminderMinutes);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  HabitsCompanion toCompanion(bool nullToAbsent) {
    return HabitsCompanion(
      id: Value(id),
      name: Value(name),
      tiny: tiny == null && nullToAbsent ? const Value.absent() : Value(tiny),
      why: Value(why),
      reminderMinutes: Value(reminderMinutes),
      createdAt: Value(createdAt),
    );
  }

  factory Habit.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Habit(
      id: serializer.fromJson<int>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      tiny: serializer.fromJson<String?>(json['tiny']),
      why: serializer.fromJson<String>(json['why']),
      reminderMinutes: serializer.fromJson<int>(json['reminderMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'name': serializer.toJson<String>(name),
      'tiny': serializer.toJson<String?>(tiny),
      'why': serializer.toJson<String>(why),
      'reminderMinutes': serializer.toJson<int>(reminderMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Habit copyWith({
    int? id,
    String? name,
    Value<String?> tiny = const Value.absent(),
    String? why,
    int? reminderMinutes,
    DateTime? createdAt,
  }) => Habit(
    id: id ?? this.id,
    name: name ?? this.name,
    tiny: tiny.present ? tiny.value : this.tiny,
    why: why ?? this.why,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    createdAt: createdAt ?? this.createdAt,
  );
  Habit copyWithCompanion(HabitsCompanion data) {
    return Habit(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      tiny: data.tiny.present ? data.tiny.value : this.tiny,
      why: data.why.present ? data.why.value : this.why,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Habit(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tiny: $tiny, ')
          ..write('why: $why, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, tiny, why, reminderMinutes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Habit &&
          other.id == this.id &&
          other.name == this.name &&
          other.tiny == this.tiny &&
          other.why == this.why &&
          other.reminderMinutes == this.reminderMinutes &&
          other.createdAt == this.createdAt);
}

class HabitsCompanion extends UpdateCompanion<Habit> {
  final Value<int> id;
  final Value<String> name;
  final Value<String?> tiny;
  final Value<String> why;
  final Value<int> reminderMinutes;
  final Value<DateTime> createdAt;
  const HabitsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.tiny = const Value.absent(),
    this.why = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  HabitsCompanion.insert({
    this.id = const Value.absent(),
    required String name,
    this.tiny = const Value.absent(),
    required String why,
    required int reminderMinutes,
    required DateTime createdAt,
  }) : name = Value(name),
       why = Value(why),
       reminderMinutes = Value(reminderMinutes),
       createdAt = Value(createdAt);
  static Insertable<Habit> custom({
    Expression<int>? id,
    Expression<String>? name,
    Expression<String>? tiny,
    Expression<String>? why,
    Expression<int>? reminderMinutes,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (tiny != null) 'tiny': tiny,
      if (why != null) 'why': why,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  HabitsCompanion copyWith({
    Value<int>? id,
    Value<String>? name,
    Value<String?>? tiny,
    Value<String>? why,
    Value<int>? reminderMinutes,
    Value<DateTime>? createdAt,
  }) {
    return HabitsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      tiny: tiny ?? this.tiny,
      why: why ?? this.why,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (tiny.present) {
      map['tiny'] = Variable<String>(tiny.value);
    }
    if (why.present) {
      map['why'] = Variable<String>(why.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('HabitsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('tiny: $tiny, ')
          ..write('why: $why, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $AttemptsTable extends Attempts with TableInfo<$AttemptsTable, Attempt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AttemptsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _numberMeta = const VerificationMeta('number');
  @override
  late final GeneratedColumn<int> number = GeneratedColumn<int>(
    'number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _startDayMeta = const VerificationMeta(
    'startDay',
  );
  @override
  late final GeneratedColumn<String> startDay = GeneratedColumn<String>(
    'start_day',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quitTargetMeta = const VerificationMeta(
    'quitTarget',
  );
  @override
  late final GeneratedColumn<int> quitTarget = GeneratedColumn<int>(
    'quit_target',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _firstMissDayMeta = const VerificationMeta(
    'firstMissDay',
  );
  @override
  late final GeneratedColumn<int> firstMissDay = GeneratedColumn<int>(
    'first_miss_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _resumedDayMeta = const VerificationMeta(
    'resumedDay',
  );
  @override
  late final GeneratedColumn<String> resumedDay = GeneratedColumn<String>(
    'resumed_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _finalDayMeta = const VerificationMeta(
    'finalDay',
  );
  @override
  late final GeneratedColumn<int> finalDay = GeneratedColumn<int>(
    'final_day',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endedDayMeta = const VerificationMeta(
    'endedDay',
  );
  @override
  late final GeneratedColumn<String> endedDay = GeneratedColumn<String>(
    'ended_day',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    number,
    startDay,
    quitTarget,
    firstMissDay,
    resumedDay,
    finalDay,
    endedDay,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attempts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attempt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('number')) {
      context.handle(
        _numberMeta,
        number.isAcceptableOrUnknown(data['number']!, _numberMeta),
      );
    }
    if (data.containsKey('start_day')) {
      context.handle(
        _startDayMeta,
        startDay.isAcceptableOrUnknown(data['start_day']!, _startDayMeta),
      );
    } else if (isInserting) {
      context.missing(_startDayMeta);
    }
    if (data.containsKey('quit_target')) {
      context.handle(
        _quitTargetMeta,
        quitTarget.isAcceptableOrUnknown(data['quit_target']!, _quitTargetMeta),
      );
    } else if (isInserting) {
      context.missing(_quitTargetMeta);
    }
    if (data.containsKey('first_miss_day')) {
      context.handle(
        _firstMissDayMeta,
        firstMissDay.isAcceptableOrUnknown(
          data['first_miss_day']!,
          _firstMissDayMeta,
        ),
      );
    }
    if (data.containsKey('resumed_day')) {
      context.handle(
        _resumedDayMeta,
        resumedDay.isAcceptableOrUnknown(data['resumed_day']!, _resumedDayMeta),
      );
    }
    if (data.containsKey('final_day')) {
      context.handle(
        _finalDayMeta,
        finalDay.isAcceptableOrUnknown(data['final_day']!, _finalDayMeta),
      );
    }
    if (data.containsKey('ended_day')) {
      context.handle(
        _endedDayMeta,
        endedDay.isAcceptableOrUnknown(data['ended_day']!, _endedDayMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {number};
  @override
  Attempt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attempt(
      number: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}number'],
      )!,
      startDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_day'],
      )!,
      quitTarget: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quit_target'],
      )!,
      firstMissDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}first_miss_day'],
      ),
      resumedDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}resumed_day'],
      ),
      finalDay: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}final_day'],
      ),
      endedDay: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}ended_day'],
      ),
    );
  }

  @override
  $AttemptsTable createAlias(String alias) {
    return $AttemptsTable(attachedDatabase, alias);
  }
}

class Attempt extends DataClass implements Insertable<Attempt> {
  final int number;
  final String startDay;
  final int quitTarget;
  final int? firstMissDay;
  final String? resumedDay;
  final int? finalDay;
  final String? endedDay;
  const Attempt({
    required this.number,
    required this.startDay,
    required this.quitTarget,
    this.firstMissDay,
    this.resumedDay,
    this.finalDay,
    this.endedDay,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['number'] = Variable<int>(number);
    map['start_day'] = Variable<String>(startDay);
    map['quit_target'] = Variable<int>(quitTarget);
    if (!nullToAbsent || firstMissDay != null) {
      map['first_miss_day'] = Variable<int>(firstMissDay);
    }
    if (!nullToAbsent || resumedDay != null) {
      map['resumed_day'] = Variable<String>(resumedDay);
    }
    if (!nullToAbsent || finalDay != null) {
      map['final_day'] = Variable<int>(finalDay);
    }
    if (!nullToAbsent || endedDay != null) {
      map['ended_day'] = Variable<String>(endedDay);
    }
    return map;
  }

  AttemptsCompanion toCompanion(bool nullToAbsent) {
    return AttemptsCompanion(
      number: Value(number),
      startDay: Value(startDay),
      quitTarget: Value(quitTarget),
      firstMissDay: firstMissDay == null && nullToAbsent
          ? const Value.absent()
          : Value(firstMissDay),
      resumedDay: resumedDay == null && nullToAbsent
          ? const Value.absent()
          : Value(resumedDay),
      finalDay: finalDay == null && nullToAbsent
          ? const Value.absent()
          : Value(finalDay),
      endedDay: endedDay == null && nullToAbsent
          ? const Value.absent()
          : Value(endedDay),
    );
  }

  factory Attempt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attempt(
      number: serializer.fromJson<int>(json['number']),
      startDay: serializer.fromJson<String>(json['startDay']),
      quitTarget: serializer.fromJson<int>(json['quitTarget']),
      firstMissDay: serializer.fromJson<int?>(json['firstMissDay']),
      resumedDay: serializer.fromJson<String?>(json['resumedDay']),
      finalDay: serializer.fromJson<int?>(json['finalDay']),
      endedDay: serializer.fromJson<String?>(json['endedDay']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'number': serializer.toJson<int>(number),
      'startDay': serializer.toJson<String>(startDay),
      'quitTarget': serializer.toJson<int>(quitTarget),
      'firstMissDay': serializer.toJson<int?>(firstMissDay),
      'resumedDay': serializer.toJson<String?>(resumedDay),
      'finalDay': serializer.toJson<int?>(finalDay),
      'endedDay': serializer.toJson<String?>(endedDay),
    };
  }

  Attempt copyWith({
    int? number,
    String? startDay,
    int? quitTarget,
    Value<int?> firstMissDay = const Value.absent(),
    Value<String?> resumedDay = const Value.absent(),
    Value<int?> finalDay = const Value.absent(),
    Value<String?> endedDay = const Value.absent(),
  }) => Attempt(
    number: number ?? this.number,
    startDay: startDay ?? this.startDay,
    quitTarget: quitTarget ?? this.quitTarget,
    firstMissDay: firstMissDay.present ? firstMissDay.value : this.firstMissDay,
    resumedDay: resumedDay.present ? resumedDay.value : this.resumedDay,
    finalDay: finalDay.present ? finalDay.value : this.finalDay,
    endedDay: endedDay.present ? endedDay.value : this.endedDay,
  );
  Attempt copyWithCompanion(AttemptsCompanion data) {
    return Attempt(
      number: data.number.present ? data.number.value : this.number,
      startDay: data.startDay.present ? data.startDay.value : this.startDay,
      quitTarget: data.quitTarget.present
          ? data.quitTarget.value
          : this.quitTarget,
      firstMissDay: data.firstMissDay.present
          ? data.firstMissDay.value
          : this.firstMissDay,
      resumedDay: data.resumedDay.present
          ? data.resumedDay.value
          : this.resumedDay,
      finalDay: data.finalDay.present ? data.finalDay.value : this.finalDay,
      endedDay: data.endedDay.present ? data.endedDay.value : this.endedDay,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attempt(')
          ..write('number: $number, ')
          ..write('startDay: $startDay, ')
          ..write('quitTarget: $quitTarget, ')
          ..write('firstMissDay: $firstMissDay, ')
          ..write('resumedDay: $resumedDay, ')
          ..write('finalDay: $finalDay, ')
          ..write('endedDay: $endedDay')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    number,
    startDay,
    quitTarget,
    firstMissDay,
    resumedDay,
    finalDay,
    endedDay,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attempt &&
          other.number == this.number &&
          other.startDay == this.startDay &&
          other.quitTarget == this.quitTarget &&
          other.firstMissDay == this.firstMissDay &&
          other.resumedDay == this.resumedDay &&
          other.finalDay == this.finalDay &&
          other.endedDay == this.endedDay);
}

class AttemptsCompanion extends UpdateCompanion<Attempt> {
  final Value<int> number;
  final Value<String> startDay;
  final Value<int> quitTarget;
  final Value<int?> firstMissDay;
  final Value<String?> resumedDay;
  final Value<int?> finalDay;
  final Value<String?> endedDay;
  const AttemptsCompanion({
    this.number = const Value.absent(),
    this.startDay = const Value.absent(),
    this.quitTarget = const Value.absent(),
    this.firstMissDay = const Value.absent(),
    this.resumedDay = const Value.absent(),
    this.finalDay = const Value.absent(),
    this.endedDay = const Value.absent(),
  });
  AttemptsCompanion.insert({
    this.number = const Value.absent(),
    required String startDay,
    required int quitTarget,
    this.firstMissDay = const Value.absent(),
    this.resumedDay = const Value.absent(),
    this.finalDay = const Value.absent(),
    this.endedDay = const Value.absent(),
  }) : startDay = Value(startDay),
       quitTarget = Value(quitTarget);
  static Insertable<Attempt> custom({
    Expression<int>? number,
    Expression<String>? startDay,
    Expression<int>? quitTarget,
    Expression<int>? firstMissDay,
    Expression<String>? resumedDay,
    Expression<int>? finalDay,
    Expression<String>? endedDay,
  }) {
    return RawValuesInsertable({
      if (number != null) 'number': number,
      if (startDay != null) 'start_day': startDay,
      if (quitTarget != null) 'quit_target': quitTarget,
      if (firstMissDay != null) 'first_miss_day': firstMissDay,
      if (resumedDay != null) 'resumed_day': resumedDay,
      if (finalDay != null) 'final_day': finalDay,
      if (endedDay != null) 'ended_day': endedDay,
    });
  }

  AttemptsCompanion copyWith({
    Value<int>? number,
    Value<String>? startDay,
    Value<int>? quitTarget,
    Value<int?>? firstMissDay,
    Value<String?>? resumedDay,
    Value<int?>? finalDay,
    Value<String?>? endedDay,
  }) {
    return AttemptsCompanion(
      number: number ?? this.number,
      startDay: startDay ?? this.startDay,
      quitTarget: quitTarget ?? this.quitTarget,
      firstMissDay: firstMissDay ?? this.firstMissDay,
      resumedDay: resumedDay ?? this.resumedDay,
      finalDay: finalDay ?? this.finalDay,
      endedDay: endedDay ?? this.endedDay,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (number.present) {
      map['number'] = Variable<int>(number.value);
    }
    if (startDay.present) {
      map['start_day'] = Variable<String>(startDay.value);
    }
    if (quitTarget.present) {
      map['quit_target'] = Variable<int>(quitTarget.value);
    }
    if (firstMissDay.present) {
      map['first_miss_day'] = Variable<int>(firstMissDay.value);
    }
    if (resumedDay.present) {
      map['resumed_day'] = Variable<String>(resumedDay.value);
    }
    if (finalDay.present) {
      map['final_day'] = Variable<int>(finalDay.value);
    }
    if (endedDay.present) {
      map['ended_day'] = Variable<String>(endedDay.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttemptsCompanion(')
          ..write('number: $number, ')
          ..write('startDay: $startDay, ')
          ..write('quitTarget: $quitTarget, ')
          ..write('firstMissDay: $firstMissDay, ')
          ..write('resumedDay: $resumedDay, ')
          ..write('finalDay: $finalDay, ')
          ..write('endedDay: $endedDay')
          ..write(')'))
        .toString();
  }
}

class $CheckInsTable extends CheckIns with TableInfo<$CheckInsTable, CheckIn> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CheckInsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
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
  static const VerificationMeta _attemptMeta = const VerificationMeta(
    'attempt',
  );
  @override
  late final GeneratedColumn<int> attempt = GeneratedColumn<int>(
    'attempt',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tinyMeta = const VerificationMeta('tiny');
  @override
  late final GeneratedColumn<bool> tiny = GeneratedColumn<bool>(
    'tiny',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("tiny" IN (0, 1))',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, day, attempt, tiny];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'check_ins';
  @override
  VerificationContext validateIntegrity(
    Insertable<CheckIn> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day')) {
      context.handle(
        _dayMeta,
        day.isAcceptableOrUnknown(data['day']!, _dayMeta),
      );
    } else if (isInserting) {
      context.missing(_dayMeta);
    }
    if (data.containsKey('attempt')) {
      context.handle(
        _attemptMeta,
        attempt.isAcceptableOrUnknown(data['attempt']!, _attemptMeta),
      );
    } else if (isInserting) {
      context.missing(_attemptMeta);
    }
    if (data.containsKey('tiny')) {
      context.handle(
        _tinyMeta,
        tiny.isAcceptableOrUnknown(data['tiny']!, _tinyMeta),
      );
    } else if (isInserting) {
      context.missing(_tinyMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {day, attempt},
  ];
  @override
  CheckIn map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CheckIn(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}day'],
      )!,
      attempt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt'],
      )!,
      tiny: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}tiny'],
      )!,
    );
  }

  @override
  $CheckInsTable createAlias(String alias) {
    return $CheckInsTable(attachedDatabase, alias);
  }
}

class CheckIn extends DataClass implements Insertable<CheckIn> {
  final int id;
  final String day;
  final int attempt;
  final bool tiny;
  const CheckIn({
    required this.id,
    required this.day,
    required this.attempt,
    required this.tiny,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day'] = Variable<String>(day);
    map['attempt'] = Variable<int>(attempt);
    map['tiny'] = Variable<bool>(tiny);
    return map;
  }

  CheckInsCompanion toCompanion(bool nullToAbsent) {
    return CheckInsCompanion(
      id: Value(id),
      day: Value(day),
      attempt: Value(attempt),
      tiny: Value(tiny),
    );
  }

  factory CheckIn.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CheckIn(
      id: serializer.fromJson<int>(json['id']),
      day: serializer.fromJson<String>(json['day']),
      attempt: serializer.fromJson<int>(json['attempt']),
      tiny: serializer.fromJson<bool>(json['tiny']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day': serializer.toJson<String>(day),
      'attempt': serializer.toJson<int>(attempt),
      'tiny': serializer.toJson<bool>(tiny),
    };
  }

  CheckIn copyWith({int? id, String? day, int? attempt, bool? tiny}) => CheckIn(
    id: id ?? this.id,
    day: day ?? this.day,
    attempt: attempt ?? this.attempt,
    tiny: tiny ?? this.tiny,
  );
  CheckIn copyWithCompanion(CheckInsCompanion data) {
    return CheckIn(
      id: data.id.present ? data.id.value : this.id,
      day: data.day.present ? data.day.value : this.day,
      attempt: data.attempt.present ? data.attempt.value : this.attempt,
      tiny: data.tiny.present ? data.tiny.value : this.tiny,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CheckIn(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('attempt: $attempt, ')
          ..write('tiny: $tiny')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, day, attempt, tiny);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CheckIn &&
          other.id == this.id &&
          other.day == this.day &&
          other.attempt == this.attempt &&
          other.tiny == this.tiny);
}

class CheckInsCompanion extends UpdateCompanion<CheckIn> {
  final Value<int> id;
  final Value<String> day;
  final Value<int> attempt;
  final Value<bool> tiny;
  const CheckInsCompanion({
    this.id = const Value.absent(),
    this.day = const Value.absent(),
    this.attempt = const Value.absent(),
    this.tiny = const Value.absent(),
  });
  CheckInsCompanion.insert({
    this.id = const Value.absent(),
    required String day,
    required int attempt,
    required bool tiny,
  }) : day = Value(day),
       attempt = Value(attempt),
       tiny = Value(tiny);
  static Insertable<CheckIn> custom({
    Expression<int>? id,
    Expression<String>? day,
    Expression<int>? attempt,
    Expression<bool>? tiny,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day != null) 'day': day,
      if (attempt != null) 'attempt': attempt,
      if (tiny != null) 'tiny': tiny,
    });
  }

  CheckInsCompanion copyWith({
    Value<int>? id,
    Value<String>? day,
    Value<int>? attempt,
    Value<bool>? tiny,
  }) {
    return CheckInsCompanion(
      id: id ?? this.id,
      day: day ?? this.day,
      attempt: attempt ?? this.attempt,
      tiny: tiny ?? this.tiny,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day.present) {
      map['day'] = Variable<String>(day.value);
    }
    if (attempt.present) {
      map['attempt'] = Variable<int>(attempt.value);
    }
    if (tiny.present) {
      map['tiny'] = Variable<bool>(tiny.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CheckInsCompanion(')
          ..write('id: $id, ')
          ..write('day: $day, ')
          ..write('attempt: $attempt, ')
          ..write('tiny: $tiny')
          ..write(')'))
        .toString();
  }
}

class $ClipsTable extends Clips with TableInfo<$ClipsTable, Clip> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ClipsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<int> type = GeneratedColumn<int>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _pathMeta = const VerificationMeta('path');
  @override
  late final GeneratedColumn<String> path = GeneratedColumn<String>(
    'path',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dayNumberMeta = const VerificationMeta(
    'dayNumber',
  );
  @override
  late final GeneratedColumn<int> dayNumber = GeneratedColumn<int>(
    'day_number',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    type,
    path,
    recordedAt,
    dayNumber,
    durationMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'clips';
  @override
  VerificationContext validateIntegrity(
    Insertable<Clip> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('path')) {
      context.handle(
        _pathMeta,
        path.isAcceptableOrUnknown(data['path']!, _pathMeta),
      );
    } else if (isInserting) {
      context.missing(_pathMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('day_number')) {
      context.handle(
        _dayNumberMeta,
        dayNumber.isAcceptableOrUnknown(data['day_number']!, _dayNumberMeta),
      );
    } else if (isInserting) {
      context.missing(_dayNumberMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Clip map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Clip(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}type'],
      )!,
      path: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}path'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      dayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_number'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      )!,
    );
  }

  @override
  $ClipsTable createAlias(String alias) {
    return $ClipsTable(attachedDatabase, alias);
  }
}

class Clip extends DataClass implements Insertable<Clip> {
  final int id;
  final int type;
  final String path;
  final DateTime recordedAt;
  final int dayNumber;
  final int durationMs;
  const Clip({
    required this.id,
    required this.type,
    required this.path,
    required this.recordedAt,
    required this.dayNumber,
    required this.durationMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['type'] = Variable<int>(type);
    map['path'] = Variable<String>(path);
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['day_number'] = Variable<int>(dayNumber);
    map['duration_ms'] = Variable<int>(durationMs);
    return map;
  }

  ClipsCompanion toCompanion(bool nullToAbsent) {
    return ClipsCompanion(
      id: Value(id),
      type: Value(type),
      path: Value(path),
      recordedAt: Value(recordedAt),
      dayNumber: Value(dayNumber),
      durationMs: Value(durationMs),
    );
  }

  factory Clip.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Clip(
      id: serializer.fromJson<int>(json['id']),
      type: serializer.fromJson<int>(json['type']),
      path: serializer.fromJson<String>(json['path']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      dayNumber: serializer.fromJson<int>(json['dayNumber']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'type': serializer.toJson<int>(type),
      'path': serializer.toJson<String>(path),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'dayNumber': serializer.toJson<int>(dayNumber),
      'durationMs': serializer.toJson<int>(durationMs),
    };
  }

  Clip copyWith({
    int? id,
    int? type,
    String? path,
    DateTime? recordedAt,
    int? dayNumber,
    int? durationMs,
  }) => Clip(
    id: id ?? this.id,
    type: type ?? this.type,
    path: path ?? this.path,
    recordedAt: recordedAt ?? this.recordedAt,
    dayNumber: dayNumber ?? this.dayNumber,
    durationMs: durationMs ?? this.durationMs,
  );
  Clip copyWithCompanion(ClipsCompanion data) {
    return Clip(
      id: data.id.present ? data.id.value : this.id,
      type: data.type.present ? data.type.value : this.type,
      path: data.path.present ? data.path.value : this.path,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      dayNumber: data.dayNumber.present ? data.dayNumber.value : this.dayNumber,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Clip(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, type, path, recordedAt, dayNumber, durationMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Clip &&
          other.id == this.id &&
          other.type == this.type &&
          other.path == this.path &&
          other.recordedAt == this.recordedAt &&
          other.dayNumber == this.dayNumber &&
          other.durationMs == this.durationMs);
}

class ClipsCompanion extends UpdateCompanion<Clip> {
  final Value<int> id;
  final Value<int> type;
  final Value<String> path;
  final Value<DateTime> recordedAt;
  final Value<int> dayNumber;
  final Value<int> durationMs;
  const ClipsCompanion({
    this.id = const Value.absent(),
    this.type = const Value.absent(),
    this.path = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.dayNumber = const Value.absent(),
    this.durationMs = const Value.absent(),
  });
  ClipsCompanion.insert({
    this.id = const Value.absent(),
    required int type,
    required String path,
    required DateTime recordedAt,
    required int dayNumber,
    required int durationMs,
  }) : type = Value(type),
       path = Value(path),
       recordedAt = Value(recordedAt),
       dayNumber = Value(dayNumber),
       durationMs = Value(durationMs);
  static Insertable<Clip> custom({
    Expression<int>? id,
    Expression<int>? type,
    Expression<String>? path,
    Expression<DateTime>? recordedAt,
    Expression<int>? dayNumber,
    Expression<int>? durationMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (type != null) 'type': type,
      if (path != null) 'path': path,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (dayNumber != null) 'day_number': dayNumber,
      if (durationMs != null) 'duration_ms': durationMs,
    });
  }

  ClipsCompanion copyWith({
    Value<int>? id,
    Value<int>? type,
    Value<String>? path,
    Value<DateTime>? recordedAt,
    Value<int>? dayNumber,
    Value<int>? durationMs,
  }) {
    return ClipsCompanion(
      id: id ?? this.id,
      type: type ?? this.type,
      path: path ?? this.path,
      recordedAt: recordedAt ?? this.recordedAt,
      dayNumber: dayNumber ?? this.dayNumber,
      durationMs: durationMs ?? this.durationMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (type.present) {
      map['type'] = Variable<int>(type.value);
    }
    if (path.present) {
      map['path'] = Variable<String>(path.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (dayNumber.present) {
      map['day_number'] = Variable<int>(dayNumber.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ClipsCompanion(')
          ..write('id: $id, ')
          ..write('type: $type, ')
          ..write('path: $path, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('dayNumber: $dayNumber, ')
          ..write('durationMs: $durationMs')
          ..write(')'))
        .toString();
  }
}

class $FlagsTable extends Flags with TableInfo<$FlagsTable, Flag> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FlagsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _day4CelebratedMeta = const VerificationMeta(
    'day4Celebrated',
  );
  @override
  late final GeneratedColumn<bool> day4Celebrated = GeneratedColumn<bool>(
    'day4_celebrated',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("day4_celebrated" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _lastWeeklyReplayDayNumberMeta =
      const VerificationMeta('lastWeeklyReplayDayNumber');
  @override
  late final GeneratedColumn<int> lastWeeklyReplayDayNumber =
      GeneratedColumn<int>(
        'last_weekly_replay_day_number',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _homeStyleMeta = const VerificationMeta(
    'homeStyle',
  );
  @override
  late final GeneratedColumn<int> homeStyle = GeneratedColumn<int>(
    'home_style',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    day4Celebrated,
    lastWeeklyReplayDayNumber,
    homeStyle,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'flags';
  @override
  VerificationContext validateIntegrity(
    Insertable<Flag> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day4_celebrated')) {
      context.handle(
        _day4CelebratedMeta,
        day4Celebrated.isAcceptableOrUnknown(
          data['day4_celebrated']!,
          _day4CelebratedMeta,
        ),
      );
    }
    if (data.containsKey('last_weekly_replay_day_number')) {
      context.handle(
        _lastWeeklyReplayDayNumberMeta,
        lastWeeklyReplayDayNumber.isAcceptableOrUnknown(
          data['last_weekly_replay_day_number']!,
          _lastWeeklyReplayDayNumberMeta,
        ),
      );
    }
    if (data.containsKey('home_style')) {
      context.handle(
        _homeStyleMeta,
        homeStyle.isAcceptableOrUnknown(data['home_style']!, _homeStyleMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Flag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Flag(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      day4Celebrated: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}day4_celebrated'],
      )!,
      lastWeeklyReplayDayNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_weekly_replay_day_number'],
      ),
      homeStyle: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}home_style'],
      )!,
    );
  }

  @override
  $FlagsTable createAlias(String alias) {
    return $FlagsTable(attachedDatabase, alias);
  }
}

class Flag extends DataClass implements Insertable<Flag> {
  final int id;
  final bool day4Celebrated;
  final int? lastWeeklyReplayDayNumber;
  final int homeStyle;
  const Flag({
    required this.id,
    required this.day4Celebrated,
    this.lastWeeklyReplayDayNumber,
    required this.homeStyle,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day4_celebrated'] = Variable<bool>(day4Celebrated);
    if (!nullToAbsent || lastWeeklyReplayDayNumber != null) {
      map['last_weekly_replay_day_number'] = Variable<int>(
        lastWeeklyReplayDayNumber,
      );
    }
    map['home_style'] = Variable<int>(homeStyle);
    return map;
  }

  FlagsCompanion toCompanion(bool nullToAbsent) {
    return FlagsCompanion(
      id: Value(id),
      day4Celebrated: Value(day4Celebrated),
      lastWeeklyReplayDayNumber:
          lastWeeklyReplayDayNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(lastWeeklyReplayDayNumber),
      homeStyle: Value(homeStyle),
    );
  }

  factory Flag.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Flag(
      id: serializer.fromJson<int>(json['id']),
      day4Celebrated: serializer.fromJson<bool>(json['day4Celebrated']),
      lastWeeklyReplayDayNumber: serializer.fromJson<int?>(
        json['lastWeeklyReplayDayNumber'],
      ),
      homeStyle: serializer.fromJson<int>(json['homeStyle']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'day4Celebrated': serializer.toJson<bool>(day4Celebrated),
      'lastWeeklyReplayDayNumber': serializer.toJson<int?>(
        lastWeeklyReplayDayNumber,
      ),
      'homeStyle': serializer.toJson<int>(homeStyle),
    };
  }

  Flag copyWith({
    int? id,
    bool? day4Celebrated,
    Value<int?> lastWeeklyReplayDayNumber = const Value.absent(),
    int? homeStyle,
  }) => Flag(
    id: id ?? this.id,
    day4Celebrated: day4Celebrated ?? this.day4Celebrated,
    lastWeeklyReplayDayNumber: lastWeeklyReplayDayNumber.present
        ? lastWeeklyReplayDayNumber.value
        : this.lastWeeklyReplayDayNumber,
    homeStyle: homeStyle ?? this.homeStyle,
  );
  Flag copyWithCompanion(FlagsCompanion data) {
    return Flag(
      id: data.id.present ? data.id.value : this.id,
      day4Celebrated: data.day4Celebrated.present
          ? data.day4Celebrated.value
          : this.day4Celebrated,
      lastWeeklyReplayDayNumber: data.lastWeeklyReplayDayNumber.present
          ? data.lastWeeklyReplayDayNumber.value
          : this.lastWeeklyReplayDayNumber,
      homeStyle: data.homeStyle.present ? data.homeStyle.value : this.homeStyle,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Flag(')
          ..write('id: $id, ')
          ..write('day4Celebrated: $day4Celebrated, ')
          ..write('lastWeeklyReplayDayNumber: $lastWeeklyReplayDayNumber, ')
          ..write('homeStyle: $homeStyle')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, day4Celebrated, lastWeeklyReplayDayNumber, homeStyle);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Flag &&
          other.id == this.id &&
          other.day4Celebrated == this.day4Celebrated &&
          other.lastWeeklyReplayDayNumber == this.lastWeeklyReplayDayNumber &&
          other.homeStyle == this.homeStyle);
}

class FlagsCompanion extends UpdateCompanion<Flag> {
  final Value<int> id;
  final Value<bool> day4Celebrated;
  final Value<int?> lastWeeklyReplayDayNumber;
  final Value<int> homeStyle;
  const FlagsCompanion({
    this.id = const Value.absent(),
    this.day4Celebrated = const Value.absent(),
    this.lastWeeklyReplayDayNumber = const Value.absent(),
    this.homeStyle = const Value.absent(),
  });
  FlagsCompanion.insert({
    this.id = const Value.absent(),
    this.day4Celebrated = const Value.absent(),
    this.lastWeeklyReplayDayNumber = const Value.absent(),
    this.homeStyle = const Value.absent(),
  });
  static Insertable<Flag> custom({
    Expression<int>? id,
    Expression<bool>? day4Celebrated,
    Expression<int>? lastWeeklyReplayDayNumber,
    Expression<int>? homeStyle,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (day4Celebrated != null) 'day4_celebrated': day4Celebrated,
      if (lastWeeklyReplayDayNumber != null)
        'last_weekly_replay_day_number': lastWeeklyReplayDayNumber,
      if (homeStyle != null) 'home_style': homeStyle,
    });
  }

  FlagsCompanion copyWith({
    Value<int>? id,
    Value<bool>? day4Celebrated,
    Value<int?>? lastWeeklyReplayDayNumber,
    Value<int>? homeStyle,
  }) {
    return FlagsCompanion(
      id: id ?? this.id,
      day4Celebrated: day4Celebrated ?? this.day4Celebrated,
      lastWeeklyReplayDayNumber:
          lastWeeklyReplayDayNumber ?? this.lastWeeklyReplayDayNumber,
      homeStyle: homeStyle ?? this.homeStyle,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (day4Celebrated.present) {
      map['day4_celebrated'] = Variable<bool>(day4Celebrated.value);
    }
    if (lastWeeklyReplayDayNumber.present) {
      map['last_weekly_replay_day_number'] = Variable<int>(
        lastWeeklyReplayDayNumber.value,
      );
    }
    if (homeStyle.present) {
      map['home_style'] = Variable<int>(homeStyle.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FlagsCompanion(')
          ..write('id: $id, ')
          ..write('day4Celebrated: $day4Celebrated, ')
          ..write('lastWeeklyReplayDayNumber: $lastWeeklyReplayDayNumber, ')
          ..write('homeStyle: $homeStyle')
          ..write(')'))
        .toString();
  }
}

abstract class _$StickDatabase extends GeneratedDatabase {
  _$StickDatabase(QueryExecutor e) : super(e);
  $StickDatabaseManager get managers => $StickDatabaseManager(this);
  late final $HabitsTable habits = $HabitsTable(this);
  late final $AttemptsTable attempts = $AttemptsTable(this);
  late final $CheckInsTable checkIns = $CheckInsTable(this);
  late final $ClipsTable clips = $ClipsTable(this);
  late final $FlagsTable flags = $FlagsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    habits,
    attempts,
    checkIns,
    clips,
    flags,
  ];
}

typedef $$HabitsTableCreateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  required String name,
  Value<String?> tiny,
  required String why,
  required int reminderMinutes,
  required DateTime createdAt,
});
typedef $$HabitsTableUpdateCompanionBuilder = HabitsCompanion Function({
  Value<int> id,
  Value<String> name,
  Value<String?> tiny,
  Value<String> why,
  Value<int> reminderMinutes,
  Value<DateTime> createdAt,
});

class $$HabitsTableFilterComposer
    extends Composer<_$StickDatabase, $HabitsTable> {
  $$HabitsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tiny => $composableBuilder(
    column: $table.tiny,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$HabitsTableOrderingComposer
    extends Composer<_$StickDatabase, $HabitsTable> {
  $$HabitsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tiny => $composableBuilder(
    column: $table.tiny,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get why => $composableBuilder(
    column: $table.why,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$HabitsTableAnnotationComposer
    extends Composer<_$StickDatabase, $HabitsTable> {
  $$HabitsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get tiny =>
      $composableBuilder(column: $table.tiny, builder: (column) => column);

  GeneratedColumn<String> get why =>
      $composableBuilder(column: $table.why, builder: (column) => column);

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$HabitsTableTableManager
    extends
        RootTableManager<
          _$StickDatabase,
          $HabitsTable,
          Habit,
          $$HabitsTableFilterComposer,
          $$HabitsTableOrderingComposer,
          $$HabitsTableAnnotationComposer,
          $$HabitsTableCreateCompanionBuilder,
          $$HabitsTableUpdateCompanionBuilder,
          (Habit, BaseReferences<_$StickDatabase, $HabitsTable, Habit>),
          Habit,
          PrefetchHooks Function()
        > {
  $$HabitsTableTableManager(_$StickDatabase db, $HabitsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$HabitsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$HabitsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$HabitsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> tiny = const Value.absent(),
                Value<String> why = const Value.absent(),
                Value<int> reminderMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => HabitsCompanion(
                id: id,
                name: name,
                tiny: tiny,
                why: why,
                reminderMinutes: reminderMinutes,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String name,
                Value<String?> tiny = const Value.absent(),
                required String why,
                required int reminderMinutes,
                required DateTime createdAt,
              }) => HabitsCompanion.insert(
                id: id,
                name: name,
                tiny: tiny,
                why: why,
                reminderMinutes: reminderMinutes,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$HabitsTable, Habit>(table),
                  BaseReferences<_$StickDatabase, $HabitsTable, Habit>(
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

typedef $$HabitsTableProcessedTableManager =
    ProcessedTableManager<
      _$StickDatabase,
      $HabitsTable,
      Habit,
      $$HabitsTableFilterComposer,
      $$HabitsTableOrderingComposer,
      $$HabitsTableAnnotationComposer,
      $$HabitsTableCreateCompanionBuilder,
      $$HabitsTableUpdateCompanionBuilder,
      (Habit, BaseReferences<_$StickDatabase, $HabitsTable, Habit>),
      Habit,
      PrefetchHooks Function()
    >;
typedef $$AttemptsTableCreateCompanionBuilder = AttemptsCompanion Function({
  Value<int> number,
  required String startDay,
  required int quitTarget,
  Value<int?> firstMissDay,
  Value<String?> resumedDay,
  Value<int?> finalDay,
  Value<String?> endedDay,
});
typedef $$AttemptsTableUpdateCompanionBuilder = AttemptsCompanion Function({
  Value<int> number,
  Value<String> startDay,
  Value<int> quitTarget,
  Value<int?> firstMissDay,
  Value<String?> resumedDay,
  Value<int?> finalDay,
  Value<String?> endedDay,
});

class $$AttemptsTableFilterComposer
    extends Composer<_$StickDatabase, $AttemptsTable> {
  $$AttemptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quitTarget => $composableBuilder(
    column: $table.quitTarget,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get firstMissDay => $composableBuilder(
    column: $table.firstMissDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get resumedDay => $composableBuilder(
    column: $table.resumedDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get finalDay => $composableBuilder(
    column: $table.finalDay,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endedDay => $composableBuilder(
    column: $table.endedDay,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AttemptsTableOrderingComposer
    extends Composer<_$StickDatabase, $AttemptsTable> {
  $$AttemptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get number => $composableBuilder(
    column: $table.number,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDay => $composableBuilder(
    column: $table.startDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quitTarget => $composableBuilder(
    column: $table.quitTarget,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get firstMissDay => $composableBuilder(
    column: $table.firstMissDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get resumedDay => $composableBuilder(
    column: $table.resumedDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get finalDay => $composableBuilder(
    column: $table.finalDay,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endedDay => $composableBuilder(
    column: $table.endedDay,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AttemptsTableAnnotationComposer
    extends Composer<_$StickDatabase, $AttemptsTable> {
  $$AttemptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get number =>
      $composableBuilder(column: $table.number, builder: (column) => column);

  GeneratedColumn<String> get startDay =>
      $composableBuilder(column: $table.startDay, builder: (column) => column);

  GeneratedColumn<int> get quitTarget => $composableBuilder(
    column: $table.quitTarget,
    builder: (column) => column,
  );

  GeneratedColumn<int> get firstMissDay => $composableBuilder(
    column: $table.firstMissDay,
    builder: (column) => column,
  );

  GeneratedColumn<String> get resumedDay => $composableBuilder(
    column: $table.resumedDay,
    builder: (column) => column,
  );

  GeneratedColumn<int> get finalDay =>
      $composableBuilder(column: $table.finalDay, builder: (column) => column);

  GeneratedColumn<String> get endedDay =>
      $composableBuilder(column: $table.endedDay, builder: (column) => column);
}

class $$AttemptsTableTableManager
    extends
        RootTableManager<
          _$StickDatabase,
          $AttemptsTable,
          Attempt,
          $$AttemptsTableFilterComposer,
          $$AttemptsTableOrderingComposer,
          $$AttemptsTableAnnotationComposer,
          $$AttemptsTableCreateCompanionBuilder,
          $$AttemptsTableUpdateCompanionBuilder,
          (Attempt, BaseReferences<_$StickDatabase, $AttemptsTable, Attempt>),
          Attempt,
          PrefetchHooks Function()
        > {
  $$AttemptsTableTableManager(_$StickDatabase db, $AttemptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AttemptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AttemptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AttemptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                Value<String> startDay = const Value.absent(),
                Value<int> quitTarget = const Value.absent(),
                Value<int?> firstMissDay = const Value.absent(),
                Value<String?> resumedDay = const Value.absent(),
                Value<int?> finalDay = const Value.absent(),
                Value<String?> endedDay = const Value.absent(),
              }) => AttemptsCompanion(
                number: number,
                startDay: startDay,
                quitTarget: quitTarget,
                firstMissDay: firstMissDay,
                resumedDay: resumedDay,
                finalDay: finalDay,
                endedDay: endedDay,
              ),
          createCompanionCallback:
              ({
                Value<int> number = const Value.absent(),
                required String startDay,
                required int quitTarget,
                Value<int?> firstMissDay = const Value.absent(),
                Value<String?> resumedDay = const Value.absent(),
                Value<int?> finalDay = const Value.absent(),
                Value<String?> endedDay = const Value.absent(),
              }) => AttemptsCompanion.insert(
                number: number,
                startDay: startDay,
                quitTarget: quitTarget,
                firstMissDay: firstMissDay,
                resumedDay: resumedDay,
                finalDay: finalDay,
                endedDay: endedDay,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$AttemptsTable, Attempt>(table),
                  BaseReferences<_$StickDatabase, $AttemptsTable, Attempt>(
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

typedef $$AttemptsTableProcessedTableManager =
    ProcessedTableManager<
      _$StickDatabase,
      $AttemptsTable,
      Attempt,
      $$AttemptsTableFilterComposer,
      $$AttemptsTableOrderingComposer,
      $$AttemptsTableAnnotationComposer,
      $$AttemptsTableCreateCompanionBuilder,
      $$AttemptsTableUpdateCompanionBuilder,
      (Attempt, BaseReferences<_$StickDatabase, $AttemptsTable, Attempt>),
      Attempt,
      PrefetchHooks Function()
    >;
typedef $$CheckInsTableCreateCompanionBuilder = CheckInsCompanion Function({
  Value<int> id,
  required String day,
  required int attempt,
  required bool tiny,
});
typedef $$CheckInsTableUpdateCompanionBuilder = CheckInsCompanion Function({
  Value<int> id,
  Value<String> day,
  Value<int> attempt,
  Value<bool> tiny,
});

class $$CheckInsTableFilterComposer
    extends Composer<_$StickDatabase, $CheckInsTable> {
  $$CheckInsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get tiny => $composableBuilder(
    column: $table.tiny,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CheckInsTableOrderingComposer
    extends Composer<_$StickDatabase, $CheckInsTable> {
  $$CheckInsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get day => $composableBuilder(
    column: $table.day,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get attempt => $composableBuilder(
    column: $table.attempt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get tiny => $composableBuilder(
    column: $table.tiny,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CheckInsTableAnnotationComposer
    extends Composer<_$StickDatabase, $CheckInsTable> {
  $$CheckInsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get day =>
      $composableBuilder(column: $table.day, builder: (column) => column);

  GeneratedColumn<int> get attempt =>
      $composableBuilder(column: $table.attempt, builder: (column) => column);

  GeneratedColumn<bool> get tiny =>
      $composableBuilder(column: $table.tiny, builder: (column) => column);
}

class $$CheckInsTableTableManager
    extends
        RootTableManager<
          _$StickDatabase,
          $CheckInsTable,
          CheckIn,
          $$CheckInsTableFilterComposer,
          $$CheckInsTableOrderingComposer,
          $$CheckInsTableAnnotationComposer,
          $$CheckInsTableCreateCompanionBuilder,
          $$CheckInsTableUpdateCompanionBuilder,
          (CheckIn, BaseReferences<_$StickDatabase, $CheckInsTable, CheckIn>),
          CheckIn,
          PrefetchHooks Function()
        > {
  $$CheckInsTableTableManager(_$StickDatabase db, $CheckInsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CheckInsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CheckInsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CheckInsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> day = const Value.absent(),
                Value<int> attempt = const Value.absent(),
                Value<bool> tiny = const Value.absent(),
              }) => CheckInsCompanion(
                id: id,
                day: day,
                attempt: attempt,
                tiny: tiny,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String day,
                required int attempt,
                required bool tiny,
              }) => CheckInsCompanion.insert(
                id: id,
                day: day,
                attempt: attempt,
                tiny: tiny,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CheckInsTable, CheckIn>(table),
                  BaseReferences<_$StickDatabase, $CheckInsTable, CheckIn>(
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

typedef $$CheckInsTableProcessedTableManager =
    ProcessedTableManager<
      _$StickDatabase,
      $CheckInsTable,
      CheckIn,
      $$CheckInsTableFilterComposer,
      $$CheckInsTableOrderingComposer,
      $$CheckInsTableAnnotationComposer,
      $$CheckInsTableCreateCompanionBuilder,
      $$CheckInsTableUpdateCompanionBuilder,
      (CheckIn, BaseReferences<_$StickDatabase, $CheckInsTable, CheckIn>),
      CheckIn,
      PrefetchHooks Function()
    >;
typedef $$ClipsTableCreateCompanionBuilder = ClipsCompanion Function({
  Value<int> id,
  required int type,
  required String path,
  required DateTime recordedAt,
  required int dayNumber,
  required int durationMs,
});
typedef $$ClipsTableUpdateCompanionBuilder = ClipsCompanion Function({
  Value<int> id,
  Value<int> type,
  Value<String> path,
  Value<DateTime> recordedAt,
  Value<int> dayNumber,
  Value<int> durationMs,
});

class $$ClipsTableFilterComposer
    extends Composer<_$StickDatabase, $ClipsTable> {
  $$ClipsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ClipsTableOrderingComposer
    extends Composer<_$StickDatabase, $ClipsTable> {
  $$ClipsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get path => $composableBuilder(
    column: $table.path,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayNumber => $composableBuilder(
    column: $table.dayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ClipsTableAnnotationComposer
    extends Composer<_$StickDatabase, $ClipsTable> {
  $$ClipsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get path =>
      $composableBuilder(column: $table.path, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get dayNumber =>
      $composableBuilder(column: $table.dayNumber, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );
}

class $$ClipsTableTableManager
    extends
        RootTableManager<
          _$StickDatabase,
          $ClipsTable,
          Clip,
          $$ClipsTableFilterComposer,
          $$ClipsTableOrderingComposer,
          $$ClipsTableAnnotationComposer,
          $$ClipsTableCreateCompanionBuilder,
          $$ClipsTableUpdateCompanionBuilder,
          (Clip, BaseReferences<_$StickDatabase, $ClipsTable, Clip>),
          Clip,
          PrefetchHooks Function()
        > {
  $$ClipsTableTableManager(_$StickDatabase db, $ClipsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ClipsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ClipsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ClipsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> type = const Value.absent(),
                Value<String> path = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> dayNumber = const Value.absent(),
                Value<int> durationMs = const Value.absent(),
              }) => ClipsCompanion(
                id: id,
                type: type,
                path: path,
                recordedAt: recordedAt,
                dayNumber: dayNumber,
                durationMs: durationMs,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required int type,
                required String path,
                required DateTime recordedAt,
                required int dayNumber,
                required int durationMs,
              }) => ClipsCompanion.insert(
                id: id,
                type: type,
                path: path,
                recordedAt: recordedAt,
                dayNumber: dayNumber,
                durationMs: durationMs,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ClipsTable, Clip>(table),
                  BaseReferences<_$StickDatabase, $ClipsTable, Clip>(
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

typedef $$ClipsTableProcessedTableManager =
    ProcessedTableManager<
      _$StickDatabase,
      $ClipsTable,
      Clip,
      $$ClipsTableFilterComposer,
      $$ClipsTableOrderingComposer,
      $$ClipsTableAnnotationComposer,
      $$ClipsTableCreateCompanionBuilder,
      $$ClipsTableUpdateCompanionBuilder,
      (Clip, BaseReferences<_$StickDatabase, $ClipsTable, Clip>),
      Clip,
      PrefetchHooks Function()
    >;
typedef $$FlagsTableCreateCompanionBuilder = FlagsCompanion Function({
  Value<int> id,
  Value<bool> day4Celebrated,
  Value<int?> lastWeeklyReplayDayNumber,
  Value<int> homeStyle,
});
typedef $$FlagsTableUpdateCompanionBuilder = FlagsCompanion Function({
  Value<int> id,
  Value<bool> day4Celebrated,
  Value<int?> lastWeeklyReplayDayNumber,
  Value<int> homeStyle,
});

class $$FlagsTableFilterComposer
    extends Composer<_$StickDatabase, $FlagsTable> {
  $$FlagsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get day4Celebrated => $composableBuilder(
    column: $table.day4Celebrated,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lastWeeklyReplayDayNumber => $composableBuilder(
    column: $table.lastWeeklyReplayDayNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get homeStyle => $composableBuilder(
    column: $table.homeStyle,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FlagsTableOrderingComposer
    extends Composer<_$StickDatabase, $FlagsTable> {
  $$FlagsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get day4Celebrated => $composableBuilder(
    column: $table.day4Celebrated,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lastWeeklyReplayDayNumber => $composableBuilder(
    column: $table.lastWeeklyReplayDayNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get homeStyle => $composableBuilder(
    column: $table.homeStyle,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FlagsTableAnnotationComposer
    extends Composer<_$StickDatabase, $FlagsTable> {
  $$FlagsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<bool> get day4Celebrated => $composableBuilder(
    column: $table.day4Celebrated,
    builder: (column) => column,
  );

  GeneratedColumn<int> get lastWeeklyReplayDayNumber => $composableBuilder(
    column: $table.lastWeeklyReplayDayNumber,
    builder: (column) => column,
  );

  GeneratedColumn<int> get homeStyle =>
      $composableBuilder(column: $table.homeStyle, builder: (column) => column);
}

class $$FlagsTableTableManager
    extends
        RootTableManager<
          _$StickDatabase,
          $FlagsTable,
          Flag,
          $$FlagsTableFilterComposer,
          $$FlagsTableOrderingComposer,
          $$FlagsTableAnnotationComposer,
          $$FlagsTableCreateCompanionBuilder,
          $$FlagsTableUpdateCompanionBuilder,
          (Flag, BaseReferences<_$StickDatabase, $FlagsTable, Flag>),
          Flag,
          PrefetchHooks Function()
        > {
  $$FlagsTableTableManager(_$StickDatabase db, $FlagsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FlagsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FlagsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FlagsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> day4Celebrated = const Value.absent(),
                Value<int?> lastWeeklyReplayDayNumber = const Value.absent(),
                Value<int> homeStyle = const Value.absent(),
              }) => FlagsCompanion(
                id: id,
                day4Celebrated: day4Celebrated,
                lastWeeklyReplayDayNumber: lastWeeklyReplayDayNumber,
                homeStyle: homeStyle,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<bool> day4Celebrated = const Value.absent(),
                Value<int?> lastWeeklyReplayDayNumber = const Value.absent(),
                Value<int> homeStyle = const Value.absent(),
              }) => FlagsCompanion.insert(
                id: id,
                day4Celebrated: day4Celebrated,
                lastWeeklyReplayDayNumber: lastWeeklyReplayDayNumber,
                homeStyle: homeStyle,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$FlagsTable, Flag>(table),
                  BaseReferences<_$StickDatabase, $FlagsTable, Flag>(
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

typedef $$FlagsTableProcessedTableManager =
    ProcessedTableManager<
      _$StickDatabase,
      $FlagsTable,
      Flag,
      $$FlagsTableFilterComposer,
      $$FlagsTableOrderingComposer,
      $$FlagsTableAnnotationComposer,
      $$FlagsTableCreateCompanionBuilder,
      $$FlagsTableUpdateCompanionBuilder,
      (Flag, BaseReferences<_$StickDatabase, $FlagsTable, Flag>),
      Flag,
      PrefetchHooks Function()
    >;

class $StickDatabaseManager {
  final _$StickDatabase _db;
  $StickDatabaseManager(this._db);
  $$HabitsTableTableManager get habits =>
      $$HabitsTableTableManager(_db, _db.habits);
  $$AttemptsTableTableManager get attempts =>
      $$AttemptsTableTableManager(_db, _db.attempts);
  $$CheckInsTableTableManager get checkIns =>
      $$CheckInsTableTableManager(_db, _db.checkIns);
  $$ClipsTableTableManager get clips =>
      $$ClipsTableTableManager(_db, _db.clips);
  $$FlagsTableTableManager get flags =>
      $$FlagsTableTableManager(_db, _db.flags);
}
