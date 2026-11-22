import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';

class CountingSink implements ReminderSink {
  int reschedules = 0;
  bool permission = true;

  @override
  Future<void> reschedule(Snapshot s, DateTime now) async => reschedules++;

  @override
  Future<bool> requestPermission() async => permission;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  late StickRepository repo;
  late CountingSink sink;
  late DateTime now;
  late StickController c;

  setUp(() {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    repo = StickRepository(db);
    sink = CountingSink();
    now = DateTime(2026, 11, 20, 12);
    c = StickController(repo: repo, clock: () => now, reminders: sink);
  });
  tearDown(() => db.close());

  Future<void> setup() => c.createHabit(
    name: 'Walk',
    tiny: 'Shoes on',
    why: 'Head',
    reminderMinutes: 1140,
  );

  test('needs setup on an empty database', () async {
    expect(c.needsSetup, isFalse); // not loaded yet
    await c.open();
    expect(c.needsSetup, isTrue);
    expect(c.home, isNull);
  });

  test('open persists first miss once', () async {
    await setup();
    now = DateTime(2026, 11, 30, 12); // 10 days later, never checked in
    await c.open();
    expect(c.home!.paused, isTrue);
    expect(c.snapshot!.current.firstMissDay, 1);
    now = DateTime(2026, 12, 1, 12);
    await c.open();
    expect(c.snapshot!.current.firstMissDay, 1);
  });

  test('checkIn on a rescue day is tiny, otherwise normal', () async {
    await setup();
    await c.checkIn(); // day 1, no rescue
    expect(c.snapshot!.currentCheckIns.single.tiny, isFalse);
    now = DateTime(2026, 11, 21, 12);
    await c.open();
    await c.checkIn(); // day 2, still no rescue
    now = DateTime(2026, 11, 22, 12);
    await c.open();
    expect(c.home!.dayNumber, 3);
    expect(c.home!.rescue, RescueReason.quitDay);
    await c.checkIn();
    expect(c.snapshot!.currentCheckIns.last.tiny, isTrue);
    expect(c.home!.checkedInToday, isTrue);
  });

  test('every change reschedules reminders', () async {
    await c.open();
    expect(sink.reschedules, 0); // nothing to schedule before setup
    var n = 0;
    Future<void> expectBump(Future<void> Function() act) async {
      await act();
      expect(sink.reschedules, ++n);
    }

    await expectBump(setup);
    await expectBump(c.checkIn);
    await expectBump(() => c.setHomeStyle(HomeStyle.road));
    await expectBump(c.markDay4Seen);
    await expectBump(c.markWeeklyReplaySeen);
    await expectBump(c.resetAttempt);
    await expectBump(c.pickBackUp);
    await expectBump(c.open);
    expect(c.snapshot!.flags.homeStyle, HomeStyle.road);
  });

  test('freshStart returns to setup', () async {
    await setup();
    await c.freshStart(keepClips: false);
    expect(c.needsSetup, isTrue);
  });

  test('blank tiny is stored as null', () async {
    await c.createHabit(
      name: ' Walk ',
      tiny: '  ',
      why: 'x',
      reminderMinutes: 1140,
    );
    expect(c.snapshot!.habit.tiny, isNull);
    expect(c.snapshot!.habit.name, 'Walk');
  });
}
