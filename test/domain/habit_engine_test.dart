import 'package:flutter_test/flutter_test.dart';
import 'package:stick/domain/day_clock.dart';
import 'package:stick/domain/habit_engine.dart';
import 'package:stick/domain/models.dart';

const today = '2026-11-20';
String d(int offset) => addDays(today, offset);

final habit = Habit(
  name: 'Run',
  tiny: null,
  why: 'health',
  reminderMinutes: 480,
  createdAt: DateTime(2026, 11, 1),
);

Attempt attempt({
  int number = 1,
  String? startDay,
  int quitTarget = 3,
  int? firstMissDay,
  String? resumedDay,
  int? finalDay,
  String? endedDay,
}) => Attempt(
  number: number,
  startDay: startDay ?? d(-10),
  quitTarget: quitTarget,
  firstMissDay: firstMissDay,
  resumedDay: resumedDay,
  finalDay: finalDay,
  endedDay: endedDay,
);

List<CheckIn> checks(List<int> offsets) => [
  for (final o in offsets) CheckIn(day: d(o), attempt: 1, tiny: false),
];

Clip clip(int dayNumber) => Clip(
  id: dayNumber,
  type: ClipType.voice,
  path: 'clips/$dayNumber.m4a',
  recordedAt: DateTime(2026, 11, 1),
  dayNumber: dayNumber,
  durationMs: 5000,
  attempt: 1,
);

const noFlags = Flags(
  day4Celebrated: false,
  lastWeeklyReplayDayNumber: null,
  homeStyle: HomeStyle.bigNumber,
);

HomeState compute({
  Attempt? a,
  Attempt? previous,
  List<CheckIn> checkIns = const [],
  List<Clip> clips = const [],
  Flags flags = noFlags,
}) => computeHomeState(
  habit: habit,
  attempt: a ?? attempt(startDay: today),
  previous: previous,
  checkIns: checkIns,
  clips: clips,
  flags: flags,
  today: today,
);

void main() {
  test('new attempt is day 1, not paused, no rescue', () {
    final s = compute();
    expect(s.dayNumber, 1);
    expect(s.attemptNumber, 1);
    expect(s.checkedInToday, false);
    expect(s.paused, false);
    expect(s.rescue, RescueReason.none);
    expect(s.firstMissToRecord, isNull);
  });

  test('setup day without check-in is not a miss', () {
    final s = compute(a: attempt(startDay: d(-1)));
    expect(s.paused, false);
  });

  test('two check-ins makes day 3 and rescue quitDay on attempt 1', () {
    final s = compute(
      a: attempt(startDay: d(-2)),
      checkIns: checks([-2, -1]),
    );
    expect(s.dayNumber, 3);
    expect(s.quitTarget, 3);
    expect(s.paused, false);
    expect(s.rescue, RescueReason.quitDay);
  });

  test('checked in today clears rescue', () {
    final s = compute(
      a: attempt(startDay: d(-2)),
      checkIns: checks([-2, -1, 0]),
    );
    expect(s.checkedInToday, true);
    expect(s.dayNumber, 4);
    expect(s.rescue, RescueReason.none);
  });

  test('missed yesterday pauses and keeps day number', () {
    final s = compute(
      a: attempt(startDay: d(-3)),
      checkIns: checks([-3, -2]),
    );
    expect(s.dayNumber, 3);
    expect(s.paused, true);
    expect(s.rescue, RescueReason.paused);
    expect(s.firstMissToRecord, 3);
  });

  test('long gap records first miss once', () {
    final cis = checks([-12, -11, -10]);
    final s = compute(
      a: attempt(startDay: d(-12)),
      checkIns: cis,
    );
    expect(s.paused, true);
    expect(s.firstMissToRecord, s.dayNumber);
    expect(s.firstMissToRecord, 4);

    final again = compute(
      a: attempt(startDay: d(-12), firstMissDay: 4),
      checkIns: cis,
    );
    expect(again.paused, true);
    expect(again.firstMissToRecord, isNull);
  });

  test('pick it back up today gives afterMiss rescue', () {
    final s = compute(
      a: attempt(startDay: d(-6), resumedDay: today, firstMissDay: 3),
      checkIns: checks([-6, -5]),
    );
    expect(s.paused, false);
    expect(s.rescue, RescueReason.afterMiss);
  });

  test('resumed then missed again pauses again without new first miss', () {
    final s = compute(
      a: attempt(startDay: d(-9), resumedDay: d(-5), firstMissDay: 3),
      checkIns: checks([-9, -8, -4]),
    );
    expect(s.paused, true);
    expect(s.rescue, RescueReason.paused);
    expect(s.firstMissToRecord, isNull);
  });

  test('quitTargetFor uses most recent attempt with a miss', () {
    expect(
      quitTargetFor([
        attempt(number: 1, firstMissDay: 3),
        attempt(number: 2, firstMissDay: 5),
      ]),
      5,
    );
    expect(
      quitTargetFor([attempt(number: 1, firstMissDay: 5), attempt(number: 2)]),
      5,
    );
    expect(quitTargetFor([]), 3);
  });

  test('learned quit day triggers rescue', () {
    final prev = attempt(number: 1, firstMissDay: 5, endedDay: d(-20));
    final s = compute(
      a: attempt(number: 2, startDay: d(-4), quitTarget: 5),
      previous: prev,
      checkIns: checks([-4, -3, -2, -1]),
    );
    expect(s.dayNumber, 5);
    expect(s.quitTarget, 5);
    expect(s.rescue, RescueReason.quitDay);
    expect(s.lastQuitDay, 5);
  });

  test('day 4 celebration once', () {
    final a = attempt(startDay: d(-4));
    final cis = checks([-4, -3]);
    expect(compute(a: a, checkIns: cis).showDay4, false);
    final four = checks([-4, -3, -2]);
    expect(compute(a: a, checkIns: four).showDay4, true);
    expect(
      compute(
        a: a,
        checkIns: four,
        flags: noFlags.copyWith(day4Celebrated: true),
      ).showDay4,
      false,
    );
  });

  test('weekly replay on day 7 only once and only with clips', () {
    final a = attempt(startDay: d(-6));
    final six = checks([-6, -5, -4, -3, -2, -1]);
    expect(
      compute(a: a, checkIns: six, clips: [clip(1)]).weeklyReplayDue,
      true,
    );
    expect(compute(a: a, checkIns: six).weeklyReplayDue, false);
    expect(
      compute(
        a: a,
        checkIns: six,
        clips: [clip(1)],
        flags: noFlags.copyWith(lastWeeklyReplayDayNumber: 7),
      ).weeklyReplayDue,
      false,
    );
    final five = checks([-5, -4, -3, -2, -1]);
    expect(
      compute(
        a: attempt(startDay: d(-5)),
        checkIns: five,
        clips: [clip(1)],
      ).weeklyReplayDue,
      false,
    );
  });

  test('clip prompt on 7 14 21 unless a clip exists for that day', () {
    final a = attempt(startDay: d(-6));
    final six = checks([-6, -5, -4, -3, -2, -1]);
    expect(compute(a: a, checkIns: six).clipPrompt, true);
    expect(compute(a: a, checkIns: six, clips: [clip(7)]).clipPrompt, false);
    expect(compute(a: a, checkIns: six, clips: [clip(3)]).clipPrompt, true);
    final fiveC = checks([-5, -4, -3, -2, -1]);
    expect(
      compute(
        a: attempt(startDay: d(-5)),
        checkIns: fiveC,
      ).clipPrompt,
      false,
    );
  });

  test('clip prompt ignores clips from an earlier attempt', () {
    final a = attempt(startDay: d(-6)).copyWith(number: 2);
    final six = checks([-6, -5, -4, -3, -2, -1]);
    // clip(7) belongs to attempt 1: attempt 2 still gets its own prompt.
    expect(compute(a: a, checkIns: six, clips: [clip(7)]).clipPrompt, true);
    expect(
      compute(
        a: a,
        checkIns: six,
        clips: [clip(7).copyWith(attempt: 2)],
      ).clipPrompt,
      false,
    );
  });

  test('tinyLine fallback', () {
    expect(tinyLine(habit), 'Just show up for 2 minutes.');
    expect(
      tinyLine(habit.copyWith(tiny: 'put on shoes')),
      'Just do this: put on shoes.',
    );
  });

  test('finalDayOf is check-ins plus one', () {
    expect(finalDayOf(checks([-2, -1])), 3);
    expect(finalDayOf([]), 1);
  });
}
