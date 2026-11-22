import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

/// Single row (id is always 1).
class Habits extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get tiny => text().nullable()();
  TextColumn get why => text()();
  IntColumn get reminderMinutes => integer()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Attempts extends Table {
  IntColumn get number => integer()();
  TextColumn get startDay => text()();
  IntColumn get quitTarget => integer()();
  IntColumn get firstMissDay => integer().nullable()();
  TextColumn get resumedDay => text().nullable()();
  IntColumn get finalDay => integer().nullable()();
  TextColumn get endedDay => text().nullable()();

  @override
  Set<Column> get primaryKey => {number};
}

class CheckIns extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get day => text()();
  IntColumn get attempt => integer()();
  BoolColumn get tiny => boolean()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {day, attempt},
  ];
}

class Clips extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get type => integer()(); // ClipType.index
  TextColumn get path => text()();
  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get dayNumber => integer()();
  IntColumn get durationMs => integer()();
}

/// Single row (id is always 1).
class Flags extends Table {
  IntColumn get id => integer()();
  BoolColumn get day4Celebrated =>
      boolean().withDefault(const Constant(false))();
  IntColumn get lastWeeklyReplayDayNumber => integer().nullable()();
  IntColumn get homeStyle => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Habits, Attempts, CheckIns, Clips, Flags])
class StickDatabase extends _$StickDatabase {
  StickDatabase() : super(_openProduction());

  StickDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openProduction() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(dir.path, 'stick.sqlite')),
    );
  });
}
