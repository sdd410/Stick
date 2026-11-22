import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';

final _habit = Habit(
  name: 'Walk',
  tiny: 'Shoes on',
  why: 'Head clear',
  reminderMinutes: 480,
  createdAt: DateTime(2026, 11, 20, 9),
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  late StickRepository repo;

  setUp(() {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    repo = StickRepository(db);
  });
  tearDown(() => db.close());

  test('load returns null before setup', () async {
    expect(await repo.load(), isNull);
  });

  test('createHabit makes attempt 1 with quitTarget 3', () async {
    await repo.createHabit(_habit, '2026-11-20');
    final s = (await repo.load())!;
    expect(s.habit, _habit);
    expect(s.current.number, 1);
    expect(s.current.quitTarget, 3);
    expect(s.current.startDay, '2026-11-20');
    expect(s.ended, isEmpty);
    expect(s.flags.homeStyle, HomeStyle.bigNumber);
    expect(s.flags.day4Celebrated, isFalse);
    expect(s.flags.lastWeeklyReplayDayNumber, isNull);
  });

  test('second check-in same day is ignored', () async {
    await repo.createHabit(_habit, '2026-11-20');
    expect(await repo.checkIn('2026-11-20', tiny: false), isTrue);
    expect(await repo.checkIn('2026-11-20', tiny: true), isFalse);
    final s = (await repo.load())!;
    expect(s.allCheckIns, hasLength(1));
    expect(s.allCheckIns.single.tiny, isFalse);
  });

  test('same day may be checked in again in a new attempt', () async {
    await repo.createHabit(_habit, '2026-11-20');
    await repo.checkIn('2026-11-20', tiny: false);
    await repo.resetAttempt('2026-11-20');
    expect(await repo.checkIn('2026-11-20', tiny: false), isTrue);
    final s = (await repo.load())!;
    expect(s.allCheckIns, hasLength(2));
    expect(s.currentCheckIns, hasLength(1));
    expect(s.currentCheckIns.single.attempt, 2);
  });

  test('recordFirstMiss writes once', () async {
    await repo.createHabit(_habit, '2026-11-20');
    await repo.recordFirstMiss(5);
    await repo.recordFirstMiss(9);
    expect((await repo.load())!.current.firstMissDay, 5);
  });

  test('pickBackUp sets resumedDay', () async {
    await repo.createHabit(_habit, '2026-11-20');
    await repo.pickBackUp('2026-11-25');
    expect((await repo.load())!.current.resumedDay, '2026-11-25');
  });

  test('resetAttempt stores finalDay and uses learned quit target', () async {
    await repo.createHabit(_habit, '2026-11-20');
    await repo.checkIn('2026-11-20', tiny: false);
    await repo.checkIn('2026-11-21', tiny: false);
    await repo.recordFirstMiss(5);
    await repo.resetAttempt('2026-11-27');
    final s = (await repo.load())!;
    expect(s.ended, hasLength(1));
    expect(s.ended.single.finalDay, 3); // 2 check-ins + 1
    expect(s.ended.single.endedDay, '2026-11-27');
    expect(s.current.number, 2);
    expect(s.current.quitTarget, 5);
    expect(s.current.startDay, '2026-11-27');
    expect(s.currentCheckIns, isEmpty);
    expect(s.allCheckIns, hasLength(2));
  });

  test('flags and clips round trip', () async {
    await repo.createHabit(_habit, '2026-11-20');
    const f = Flags(
      day4Celebrated: true,
      lastWeeklyReplayDayNumber: 7,
      homeStyle: HomeStyle.road,
    );
    await repo.setFlags(f);
    final at = DateTime(2026, 11, 21, 8);
    final c = await repo.addClip(ClipType.video, '/x/a.mp4', 2, 4000, at);
    var s = (await repo.load())!;
    expect(s.flags, f);
    expect(s.clips, [c]);
    await repo.deleteClip(c.id);
    s = (await repo.load())!;
    expect(s.clips, isEmpty);
  });

  test('freshStart keepClips false clears everything', () async {
    await repo.createHabit(_habit, '2026-11-20');
    await repo.checkIn('2026-11-20', tiny: false);
    await repo.setFlags(
      const Flags(
        day4Celebrated: true,
        lastWeeklyReplayDayNumber: 7,
        homeStyle: HomeStyle.road,
      ),
    );
    await repo.addClip(ClipType.voice, '/x/a.m4a', 1, 1000, DateTime(2026));
    final paths = await repo.freshStart(keepClips: false);
    expect(paths, ['/x/a.m4a']);
    expect(await repo.load(), isNull);
    expect(await db.select(db.clips).get(), isEmpty);
    expect(await db.select(db.checkIns).get(), isEmpty);
    expect(await db.select(db.attempts).get(), isEmpty);
    expect(await db.select(db.flags).get(), isEmpty);
  });

  test('freshStart keepClips true keeps clip rows', () async {
    await repo.createHabit(_habit, '2026-11-20');
    await repo.addClip(ClipType.voice, '/x/a.m4a', 1, 1000, DateTime(2026));
    final paths = await repo.freshStart(keepClips: true);
    expect(paths, isEmpty);
    expect(await repo.load(), isNull);
    expect(await db.select(db.clips).get(), hasLength(1));
    // New habit after fresh start works and resets flags.
    await repo.createHabit(_habit, '2026-12-01');
    final s = (await repo.load())!;
    expect(s.current.number, 1);
    expect(s.clips, hasLength(1));
    expect(s.flags.homeStyle, HomeStyle.bigNumber);
  });

  test('data survives reopening', () async {
    final dir = await Directory.systemTemp.createTemp('stick_db');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/stick.sqlite');
    final db1 = db_.StickDatabase.forTesting(NativeDatabase(file));
    final r1 = StickRepository(db1);
    await r1.createHabit(_habit, '2026-11-20');
    await r1.checkIn('2026-11-20', tiny: true);
    await r1.addClip(
      ClipType.voice,
      '/x/a.m4a',
      1,
      1000,
      DateTime(2026, 11, 20),
    );
    final before = await r1.load();
    await db1.close();

    final db2 = db_.StickDatabase.forTesting(NativeDatabase(file));
    addTearDown(db2.close);
    final after = await StickRepository(db2).load();
    expect(after, isNotNull);
    expect(after, before);
  });
}
