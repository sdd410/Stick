import 'package:drift/drift.dart';

import '../domain/day_clock.dart';
import '../domain/habit_engine.dart';
import '../domain/models.dart';
import 'database.dart' as db;

class Snapshot {
  const Snapshot({
    required this.habit,
    required this.current,
    required this.ended,
    required this.allCheckIns,
    required this.clips,
    required this.flags,
  });

  final Habit habit;
  final Attempt current;
  final List<Attempt> ended;

  /// Check-ins of every attempt (Progress totals).
  final List<CheckIn> allCheckIns;
  final List<Clip> clips;
  final Flags flags;

  /// Only the current attempt's check-ins: what the engine should be given.
  List<CheckIn> get currentCheckIns =>
      allCheckIns.where((c) => c.attempt == current.number).toList();

  Snapshot withClips(List<Clip> clips) => Snapshot(
    habit: habit,
    current: current,
    ended: ended,
    allCheckIns: allCheckIns,
    clips: clips,
    flags: flags,
  );

  @override
  bool operator ==(Object other) =>
      other is Snapshot &&
      other.habit == habit &&
      other.current == current &&
      _listEq(other.ended, ended) &&
      _listEq(other.allCheckIns, allCheckIns) &&
      _listEq(other.clips, clips) &&
      other.flags == flags;

  @override
  int get hashCode => Object.hash(
    habit,
    current,
    Object.hashAll(ended),
    Object.hashAll(allCheckIns),
    Object.hashAll(clips),
    flags,
  );
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}

const _defaultFlags = Flags(
  day4Celebrated: false,
  lastWeeklyReplayDayNumber: null,
  homeStyle: HomeStyle.bigNumber,
);

class StickRepository {
  StickRepository(this._db);

  final db.StickDatabase _db;

  Habit _habit(db.Habit r) => Habit(
    name: r.name,
    tiny: r.tiny,
    why: r.why,
    reminderMinutes: r.reminderMinutes,
    createdAt: r.createdAt,
    emoji: r.emoji,
    templateId: r.templateId,
    quizQuitDay: r.quizQuitDay,
    quizReason: r.quizReason,
  );

  Attempt _attempt(db.Attempt r) => Attempt(
    number: r.number,
    startDay: r.startDay,
    quitTarget: r.quitTarget,
    firstMissDay: r.firstMissDay,
    resumedDay: r.resumedDay,
    finalDay: r.finalDay,
    endedDay: r.endedDay,
  );

  Clip _clip(db.Clip r) => Clip(
    id: r.id,
    type: r.type,
    path: r.path,
    recordedAt: r.recordedAt,
    dayNumber: r.dayNumber,
    durationMs: r.durationMs,
    attempt: r.attempt,
  );

  /// Every clip row, even when no habit exists (clips can outlive a fresh
  /// start). Paths are as stored.
  Future<List<Clip>> allClips() async {
    final rows = await (_db.select(
      _db.clips,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    return rows.map(_clip).toList();
  }

  Future<Snapshot?> load() async {
    final habitRow = await _db.select(_db.habits).getSingleOrNull();
    if (habitRow == null) return null;
    final attempts = await (_db.select(
      _db.attempts,
    )..orderBy([(t) => OrderingTerm.asc(t.number)])).get();
    if (attempts.isEmpty) return null;
    final checkIns = await (_db.select(
      _db.checkIns,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final clipRows = await (_db.select(
      _db.clips,
    )..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
    final flagRow = await _db.select(_db.flags).getSingleOrNull();

    final all = attempts.map(_attempt).toList();
    final current = all.firstWhere(
      (a) => a.endedDay == null,
      orElse: () => all.last,
    );
    return Snapshot(
      habit: _habit(habitRow),
      current: current,
      ended: all.where((a) => a.number != current.number).toList(),
      allCheckIns: [
        for (final c in checkIns)
          CheckIn(day: c.day, attempt: c.attempt, tiny: c.tiny),
      ],
      clips: clipRows.map(_clip).toList(),
      flags: flagRow == null
          ? _defaultFlags
          : Flags(
              day4Celebrated: flagRow.day4Celebrated,
              lastWeeklyReplayDayNumber: flagRow.lastWeeklyReplayDayNumber,
              homeStyle: flagRow.homeStyle,
              checkInMode: flagRow.checkInMode,
              tipsSeen: flagRow.tipsSeen,
            ),
    );
  }

  db.HabitsCompanion _habitCompanion(Habit h) => db.HabitsCompanion(
    id: const Value(1),
    name: Value(h.name),
    tiny: Value(h.tiny),
    why: Value(h.why),
    reminderMinutes: Value(h.reminderMinutes),
    createdAt: Value(h.createdAt),
    emoji: Value(h.emoji),
    templateId: Value(h.templateId),
    quizQuitDay: Value(h.quizQuitDay),
    quizReason: Value(h.quizReason),
  );

  Future<void> createHabit(Habit h, DayKey today) => _db.transaction(() async {
    await _db.into(_db.habits).insertOnConflictUpdate(_habitCompanion(h));
    await _db.delete(_db.attempts).go();
    await _db.delete(_db.checkIns).go();
    await _db
        .into(_db.attempts)
        .insert(
          db.AttemptsCompanion.insert(
            number: const Value(1),
            startDay: today,
            quitTarget: 3,
          ),
        );
    await _db
        .into(_db.flags)
        .insertOnConflictUpdate(_flagsCompanion(_defaultFlags));
  });

  Future<void> updateHabit(Habit h) async {
    await _db.into(_db.habits).insertOnConflictUpdate(_habitCompanion(h));
  }

  Future<Attempt?> _currentAttempt() async {
    final rows =
        await (_db.select(_db.attempts)
              ..where((t) => t.endedDay.isNull())
              ..orderBy([(t) => OrderingTerm.desc(t.number)])
              ..limit(1))
            .get();
    return rows.isEmpty ? null : _attempt(rows.first);
  }

  Future<bool> checkIn(DayKey today, {required bool tiny}) async {
    final cur = await _currentAttempt();
    if (cur == null) return false;
    return _db.transaction(() async {
      final before = await _db.checkIns.count().getSingle();
      await _db
          .into(_db.checkIns)
          .insert(
            db.CheckInsCompanion.insert(
              day: today,
              attempt: cur.number,
              tiny: tiny,
            ),
            mode: InsertMode.insertOrIgnore,
          );
      // insertOrIgnore returns a stale rowid when ignored, so compare counts.
      final after = await _db.checkIns.count().getSingle();
      return after > before;
    });
  }

  Future<void> pickBackUp(DayKey today) async {
    final cur = await _currentAttempt();
    if (cur == null) return;
    await (_db.update(_db.attempts)..where((t) => t.number.equals(cur.number)))
        .write(db.AttemptsCompanion(resumedDay: Value(today)));
  }

  /// Writes only while the current attempt has no first miss yet.
  Future<void> recordFirstMiss(int dayNumber) async {
    final cur = await _currentAttempt();
    if (cur == null || cur.firstMissDay != null) return;
    await (_db.update(_db.attempts)..where((t) => t.number.equals(cur.number)))
        .write(db.AttemptsCompanion(firstMissDay: Value(dayNumber)));
  }

  Future<void> resetAttempt(DayKey today) => _db.transaction(() async {
    final cur = await _currentAttempt();
    if (cur == null) return;
    final mine = await (_db.select(
      _db.checkIns,
    )..where((t) => t.attempt.equals(cur.number))).get();
    final finalDay = finalDayOf([
      for (final c in mine)
        CheckIn(day: c.day, attempt: c.attempt, tiny: c.tiny),
    ]);
    await (_db.update(
      _db.attempts,
    )..where((t) => t.number.equals(cur.number))).write(
      db.AttemptsCompanion(finalDay: Value(finalDay), endedDay: Value(today)),
    );
    final endedRows = await (_db.select(
      _db.attempts,
    )..where((t) => t.endedDay.isNotNull())).get();
    final target = quitTargetFor(endedRows.map(_attempt).toList());
    await _db
        .into(_db.attempts)
        .insert(
          db.AttemptsCompanion.insert(
            number: Value(cur.number + 1),
            startDay: today,
            quitTarget: target,
          ),
        );
    // The weekly replay is per attempt: day 7 of the new attempt is due again.
    await (_db.update(_db.flags)..where((t) => t.id.equals(1))).write(
      const db.FlagsCompanion(lastWeeklyReplayDayNumber: Value(null)),
    );
  });

  /// Wipes habit, attempts, check-ins and flags. Clip rows are deleted unless
  /// [keepClips]. Returns the deleted clips' file paths so the caller can
  /// remove the files.
  Future<List<String>> freshStart({required bool keepClips}) =>
      _db.transaction(() async {
        var paths = <String>[];
        if (!keepClips) {
          final rows = await _db.select(_db.clips).get();
          paths = rows.map((r) => r.path).toList();
          await _db.delete(_db.clips).go();
        }
        // Kept clips belong to no attempt of the new habit.
        await _db
            .update(_db.clips)
            .write(const db.ClipsCompanion(attempt: Value(0)));
        await _db.delete(_db.checkIns).go();
        await _db.delete(_db.attempts).go();
        await _db.delete(_db.habits).go();
        await _db.delete(_db.flags).go();
        return paths;
      });

  Future<Clip> addClip(
    ClipType t,
    String path,
    int dayNumber,
    int durationMs,
    DateTime at, {
    required int attempt,
  }) async {
    final id = await _db
        .into(_db.clips)
        .insert(
          db.ClipsCompanion.insert(
            type: t,
            path: path,
            recordedAt: at,
            dayNumber: dayNumber,
            durationMs: durationMs,
            attempt: attempt,
          ),
        );
    return Clip(
      id: id,
      type: t,
      path: path,
      recordedAt: at,
      dayNumber: dayNumber,
      durationMs: durationMs,
      attempt: attempt,
    );
  }

  Future<void> deleteClip(int id) async {
    await (_db.delete(_db.clips)..where((t) => t.id.equals(id))).go();
  }

  db.FlagsCompanion _flagsCompanion(Flags f) => db.FlagsCompanion(
    id: const Value(1),
    day4Celebrated: Value(f.day4Celebrated),
    lastWeeklyReplayDayNumber: Value(f.lastWeeklyReplayDayNumber),
    homeStyle: Value(f.homeStyle),
    checkInMode: Value(f.checkInMode),
    tipsSeen: Value(f.tipsSeen),
  );

  Future<void> setFlags(Flags f) async {
    await _db.into(_db.flags).insertOnConflictUpdate(_flagsCompanion(f));
  }
}
