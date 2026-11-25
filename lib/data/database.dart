import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/models.dart' show ClipType, HomeStyle;
import '../domain/onboarding.dart' show QuitDayAnswer, QuitReason, defaultEmoji;

part 'database.g.dart';

/// Single row (id is always 1).
class Habits extends Table {
  IntColumn get id => integer()();
  TextColumn get name => text()();
  TextColumn get tiny => text().nullable()();
  TextColumn get why => text()();
  IntColumn get reminderMinutes => integer()();
  DateTimeColumn get createdAt => dateTime()();

  // Schema 2 (1.1): onboarding.
  TextColumn get emoji => text().withDefault(const Constant(defaultEmoji))();
  TextColumn get templateId => text().nullable()();
  TextColumn get quizQuitDay => textEnum<QuitDayAnswer>().nullable()();
  TextColumn get quizReason => textEnum<QuitReason>().nullable()();

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
  // Stored by name, so reordering the enum can never relabel old rows.
  TextColumn get type => textEnum<ClipType>()();

  /// Relative to the clip root (`clips/<millis>.m4a`), so a moved app
  /// directory does not break rows.
  TextColumn get path => text()();

  /// The attempt this clip was recorded in (0 = kept across a fresh start).
  IntColumn get attempt => integer()();
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
  TextColumn get homeStyle =>
      textEnum<HomeStyle>().withDefault(const Constant('bigNumber'))();

  @override
  Set<Column> get primaryKey => {id};
}

@DriftDatabase(tables: [Habits, Attempts, CheckIns, Clips, Flags])
class StickDatabase extends _$StickDatabase {
  StickDatabase() : super(_openProduction());

  StickDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    // Schema 1 shipped in 1.0.0. One explicit step per version, and every
    // new version is dumped to drift_schemas/. An unknown version fails
    // loudly instead of drift's silent default.
    onUpgrade: (m, from, to) async {
      for (var v = from; v < to; v++) {
        switch (v) {
          case 1:
            await m.addColumn(habits, habits.emoji);
            await m.addColumn(habits, habits.templateId);
            await m.addColumn(habits, habits.quizQuitDay);
            await m.addColumn(habits, habits.quizReason);
          default:
            throw UnsupportedError(
              'No migration from schema version $v to ${v + 1}',
            );
        }
      }
    },
  );
}

QueryExecutor _openProduction() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    return NativeDatabase.createInBackground(
      File(p.join(dir.path, 'stick.sqlite')),
    );
  });
}
