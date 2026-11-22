import 'package:flutter_test/flutter_test.dart';
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/domain/progress.dart';

const _flags = Flags(
  day4Celebrated: false,
  lastWeeklyReplayDayNumber: null,
  homeStyle: HomeStyle.bigNumber,
);

Snapshot snap({
  required List<Attempt> ended,
  required Attempt current,
  required List<CheckIn> checkIns,
  List<Clip> clips = const [],
}) => Snapshot(
  habit: Habit(
    name: 'Walk',
    tiny: null,
    why: 'x',
    reminderMinutes: 1140,
    createdAt: DateTime(2026, 11, 1),
  ),
  current: current,
  ended: ended,
  allCheckIns: checkIns,
  clips: clips,
  flags: _flags,
);

HomeState home(int attempt, int day, int target) => HomeState(
  attemptNumber: attempt,
  dayNumber: day,
  checkedInToday: false,
  paused: false,
  rescue: RescueReason.none,
  quitTarget: target,
  lastQuitDay: null,
  showDay4: false,
  weeklyReplayDue: false,
  clipPrompt: false,
  firstMissToRecord: null,
);

CheckIn ci(String day, int attempt, {bool tiny = false}) =>
    CheckIn(day: day, attempt: attempt, tiny: tiny);

void main() {
  final a1 = Attempt(
    number: 1,
    startDay: '2026-11-01',
    quitTarget: 3,
    firstMissDay: 6,
    finalDay: 5,
    endedDay: '2026-11-10',
  );
  final a2 = Attempt(number: 2, startDay: '2026-11-10', quitTarget: 6);
  final checkIns = [
    for (var i = 1; i <= 5; i++) ci('2026-11-0$i', 1),
    ci('2026-11-10', 2),
    ci('2026-11-11', 2, tiny: true),
  ];

  test('days showed up never drops after reset', () {
    final before = computeProgress(
      snap(
        ended: const [],
        current: a1.copyWith(finalDay: null, endedDay: null),
        checkIns: checkIns.sublist(0, 5),
      ),
      home(1, 6, 3),
    );
    final after = computeProgress(
      snap(ended: [a1], current: a2, checkIns: checkIns),
      home(2, 3, 6),
    );
    expect(before.daysShowedUp, 5);
    expect(after.daysShowedUp, greaterThanOrEqualTo(before.daysShowedUp));
    expect(after.daysShowedUp, 7);
  });

  test('days showed up counts a calendar day once across attempts', () {
    final p = computeProgress(
      snap(
        ended: [a1],
        current: a2,
        checkIns: [...checkIns, ci('2026-11-05', 2)],
      ),
      home(2, 4, 6),
    );
    expect(p.daysShowedUp, 7);
  });

  test('star when attempt passed its quit target', () {
    final p = computeProgress(
      snap(ended: [a1], current: a2, checkIns: checkIns),
      home(2, 3, 6),
    );
    expect(p.bars.map((b) => b.number), [1, 2]);
    expect(p.bars[0].length, 5);
    expect(p.bars[0].beatQuitDay, isTrue);
    expect(p.bars[1].length, 3);
    expect(p.bars[1].beatQuitDay, isFalse);
    expect(p.quitDaysBeaten, 1);
  });

  test('length equal to target is not a star', () {
    final p = computeProgress(
      snap(
        ended: [a1.copyWith(quitTarget: 5)],
        current: a2,
        checkIns: checkIns,
      ),
      home(2, 3, 6),
    );
    expect(p.bars[0].beatQuitDay, isFalse);
    expect(p.quitDaysBeaten, 0);
  });

  test('current bar marked now and can earn a star', () {
    final p = computeProgress(
      snap(ended: [a1], current: a2, checkIns: checkIns),
      home(2, 7, 6),
    );
    expect(p.bars[0].isCurrent, isFalse);
    expect(p.bars[1].isCurrent, isTrue);
    expect(p.bars[1].beatQuitDay, isTrue);
    expect(p.quitDaysBeaten, 2);
    expect(p.nextQuitTarget, 6);
  });

  test('tiny days counted', () {
    final p = computeProgress(
      snap(ended: [a1], current: a2, checkIns: checkIns),
      home(2, 3, 6),
    );
    expect(p.tinyDays, 1);
    expect(p.clipCount, 0);
  });
}
