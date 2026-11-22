import 'package:flutter_test/flutter_test.dart';
import 'package:stick/data/repository.dart';
import 'package:stick/domain/day_clock.dart';
import 'package:stick/domain/habit_engine.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/domain/reminder_planner.dart';

const today = '2026-11-20';
String d(int offset) => addDays(today, offset);

// Reminder at 19:00.
Habit habit({String? tiny, int minutes = 1140}) => Habit(
  name: 'Run',
  tiny: tiny,
  why: 'health',
  reminderMinutes: minutes,
  createdAt: DateTime(2026, 11, 1),
);

Clip clip() => Clip(
  id: 1,
  type: ClipType.voice,
  path: 'clips/1.m4a',
  recordedAt: DateTime(2026, 11, 1),
  dayNumber: 1,
  durationMs: 5000,
);

const flags = Flags(
  day4Celebrated: false,
  lastWeeklyReplayDayNumber: null,
  homeStyle: HomeStyle.bigNumber,
);

Snapshot snap({
  Habit? h,
  int checkedOffsets = 0,
  List<int> checkInOffsets = const [],
  List<Attempt> ended = const [],
  List<Clip> clips = const [],
  Attempt? current,
}) => Snapshot(
  habit: h ?? habit(),
  current:
      current ??
      Attempt(number: 1, startDay: d(-10), quitTarget: quitTargetFor(ended)),
  ended: ended,
  allCheckIns: [
    for (final o in checkInOffsets)
      CheckIn(day: d(o), attempt: (current?.number ?? 1), tiny: false),
  ],
  clips: clips,
  flags: flags,
);

// 2026-11-20 10:00 local, so 19:00 is still ahead.
final morning = DateTime(2026, 11, 20, 10);
final night = DateTime(2026, 11, 20, 21);

void main() {
  test('seven reminders when not yet checked in and time ahead', () {
    final p = planReminders(snap(checkInOffsets: [-3, -2, -1]), morning);
    expect(p.length, 7);
    expect(p.first.at, DateTime(2026, 11, 20, 19));
    expect(p.last.at, DateTime(2026, 11, 26, 19));
    expect(p.first.title, 'Day 4 of Run');
    expect(p.first.body, 'Show up today. Just show up for 2 minutes.');
  });

  test('skips today after check-in', () {
    final p = planReminders(snap(checkInOffsets: [-3, -2, -1, 0]), morning);
    expect(p.length, 6);
    expect(p.first.at, DateTime(2026, 11, 21, 19));
    expect(p.first.id, 101);
    expect(p.first.title, 'Day 5 of Run');
  });

  test('skips today when the time has passed', () {
    final p = planReminders(snap(checkInOffsets: [-3, -2, -1]), night);
    expect(p.first.at, DateTime(2026, 11, 21, 19));
    expect(p.length, 6);
  });

  test('day 3 uses spec wording', () {
    final p = planReminders(snap(checkInOffsets: [-2, -1]), morning);
    expect(p.first.title, 'Day 3. This is where most people quit. Not you.');
    expect(p.first.body, 'Just show up for 2 minutes.');
  });

  test('learned quit day wording', () {
    final ended = [
      Attempt(
        number: 1,
        startDay: d(-30),
        quitTarget: 3,
        firstMissDay: 5,
        finalDay: 5,
        endedDay: d(-12),
      ),
    ];
    final current = Attempt(number: 2, startDay: d(-5), quitTarget: 5);
    final p = planReminders(
      snap(
        ended: ended,
        current: current,
        checkInOffsets: [-4, -3, -2, -1],
        h: habit(tiny: 'put on shoes'),
      ),
      morning,
    );
    expect(p.first.title, 'Day 5. Last time you stopped here.');
    expect(p.first.body, 'Not this time. Just do this: put on shoes.');
  });

  test('future days after no check-in are paused with replay payload when '
      'clips exist', () {
    final p = planReminders(
      snap(checkInOffsets: [-3, -2, -1], clips: [clip()]),
      morning,
    );
    expect(p.first.payload, isNull); // today still normal (day 4)
    for (final r in p.skip(1)) {
      expect(r.title, 'You left yourself a message');
      expect(r.body, 'Day 4 · paused. Tap to hear it.');
      expect(r.payload, 'replay');
    }
  });

  test('after check-in tomorrow is normal and later days are paused', () {
    final p = planReminders(
      snap(checkInOffsets: [-3, -2, -1, 0], clips: [clip()]),
      morning,
    );
    expect(p[0].title, 'Day 5 of Run');
    expect(p[0].payload, isNull);
    expect(p[1].title, 'You left yourself a message');
  });

  test('paused without clips has no payload', () {
    final p = planReminders(snap(checkInOffsets: [-3, -2, -1]), night);
    // today skipped; tomorrow (day 21) is anchored on 19th: 2 days -> paused.
    expect(p.first.title, 'Day 4 · paused');
    expect(p.first.body, 'Pick it back up. Just show up for 2 minutes.');
    expect(p.first.payload, isNull);
  });

  test('ids are stable 100 to 106', () {
    final p = planReminders(snap(checkInOffsets: [-1]), morning);
    expect(p.map((r) => r.id), [100, 101, 102, 103, 104, 105, 106]);
    // Same ids regardless of skipped day.
    final q = planReminders(snap(checkInOffsets: [-1]), night);
    expect(q.map((r) => r.id), [101, 102, 103, 104, 105, 106]);
  });

  test('reminder before 3 am belongs to the previous day key', () {
    // 00:30 reminder for day key 20 fires on calendar date 21 at 00:30.
    final p = planReminders(
      snap(h: habit(minutes: 30), checkInOffsets: [-1]),
      morning,
    );
    expect(p.first.at, DateTime(2026, 11, 21, 0, 30));
    expect(p.first.id, 100);
  });

  test('before 3 am now still counts as the previous day', () {
    // 01:00 on the 21st is still day key 20; its 00:30 reminder has passed.
    final p = planReminders(
      snap(h: habit(minutes: 30), checkInOffsets: [-1]),
      DateTime(2026, 11, 21, 1),
    );
    expect(p.first.id, 101);
    expect(p.first.at, DateTime(2026, 11, 22, 0, 30));
  });
}
