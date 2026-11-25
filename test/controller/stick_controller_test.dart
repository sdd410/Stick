import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/domain/onboarding.dart';
import 'package:stick/services/clip_files.dart';

class CountingSink implements ReminderSink {
  int reschedules = 0;
  Snapshot? last;
  bool permission = true;
  bool throws = false;

  @override
  Future<void> reschedule(Snapshot? s, DateTime now) async {
    reschedules++;
    last = s;
    if (throws) throw StateError('boom');
  }

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

  test('createHabit passes emoji and quiz answers through', () async {
    await c.open();
    await c.createHabit(
      name: 'Read',
      why: 'x',
      reminderMinutes: 1140,
      emoji: '📖',
      templateId: 'read',
      quizQuitDay: QuitDayAnswer.day2,
      quizReason: QuitReason.busy,
    );
    final h = c.snapshot!.habit;
    expect(h.emoji, '📖');
    expect(h.templateId, 'read');
    expect(h.quizQuitDay, QuitDayAnswer.day2);
    expect(h.quizReason, QuitReason.busy);
  });

  test('updateHabit keeps emoji and quiz answers', () async {
    await c.open();
    await c.createHabit(
      name: 'Read',
      why: 'x',
      reminderMinutes: 1140,
      emoji: '📖',
      quizReason: QuitReason.tired,
    );
    await c.updateHabit(name: 'Read more', why: 'y', reminderMinutes: 600);
    final h = c.snapshot!.habit;
    expect(h.name, 'Read more');
    expect(h.emoji, '📖');
    expect(h.quizReason, QuitReason.tired);
  });

  test('setCheckInMode and markTipsSeen update the flags', () async {
    await c.open();
    await setup();
    await c.setCheckInMode(CheckInMode.tap);
    await c.markTipsSeen();
    expect(c.snapshot!.flags.checkInMode, CheckInMode.tap);
    expect(c.snapshot!.flags.tipsSeen, isTrue);
  });

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
    // A later, longer gap must not overwrite the stored first miss.
    now = DateTime(2026, 12, 20, 12);
    await c.open();
    expect(c.home!.paused, isTrue);
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
    // Before setup the sink is told there is nothing to remind about.
    expect(sink.reschedules, 1);
    expect(sink.last, isNull);
    var n = 1;
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

  test('changing reminder time reschedules', () async {
    await setup();
    final before = sink.reschedules;
    await c.updateHabit(
      name: 'Walk',
      tiny: null,
      why: 'Head',
      reminderMinutes: 480,
    );
    expect(sink.reschedules, before + 1);
    expect(sink.last!.habit.reminderMinutes, 480);
    expect(c.snapshot!.habit.tiny, isNull);
    expect(c.snapshot!.habit.createdAt, DateTime(2026, 11, 20, 12));
  });

  test('freshStart returns to setup', () async {
    await setup();
    await c.freshStart(keepClips: false);
    expect(c.needsSetup, isTrue);
    expect(sink.last, isNull); // pending reminders get cancelled
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

  test('a throwing reminder sink does not block setup or open', () async {
    sink.throws = true;
    await c.open();
    expect(c.needsSetup, isTrue);
    await setup();
    expect(c.needsSetup, isFalse);
    expect(c.home!.dayNumber, 1);
    c = StickController(repo: repo, clock: () => now, reminders: sink);
    await c.open();
    expect(c.snapshot!.habit.name, 'Walk');
    expect(c.loaded, isTrue);
  });

  test('open during a checkIn leaves consistent state', () async {
    await setup();
    now = DateTime(2026, 11, 21, 12);
    await c.open();
    await Future.wait([c.checkIn(), c.open(), c.checkIn(), c.open()]);
    expect(c.snapshot!.currentCheckIns, hasLength(1));
    expect(c.home!.dayNumber, 2);
    expect(c.home!.checkedInToday, isTrue);
  });

  group('clips', () {
    late Directory tmp;
    late ClipFiles files;

    File makeFile(String name) {
      final f = File('${tmp.path}/$name')..writeAsBytesSync([1, 2, 3]);
      return f;
    }

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('ctrlclips');
      files = ClipFiles(tmp);
      c = StickController(
        repo: repo,
        clock: () => now,
        reminders: sink,
        clipFiles: files,
      );
    });
    tearDown(() => tmp.deleteSync(recursive: true));

    test('addClip stores the clip on the current day', () async {
      await setup();
      final f = makeFile('a.m4a');
      await c.addClip(ClipType.voice, f.path, 4000);
      final clip = c.snapshot!.clips.single;
      expect(clip.dayNumber, 1);
      expect(clip.durationMs, 4000);
      expect(clip.recordedAt, now);
    });

    test('clip rows store paths relative to the clip root', () async {
      await setup();
      final path = files.newPath(ClipType.voice, now);
      File(path).writeAsBytesSync([1]);
      await c.addClip(ClipType.voice, path, 4000);
      final stored = (await repo.allClips()).single;
      expect(stored.path, 'clips/${now.millisecondsSinceEpoch}.m4a');
      expect(stored.attempt, 1);
      // The app still sees the absolute path.
      expect(c.snapshot!.clips.single.path, path);
    });

    test('open drops clip rows whose file is missing', () async {
      await setup();
      final keep = files.newPath(ClipType.voice, now);
      final gone = files.newPath(
        ClipType.voice,
        now.add(const Duration(seconds: 1)),
      );
      File(keep).writeAsBytesSync([1]);
      File(gone).writeAsBytesSync([1]);
      await c.addClip(ClipType.voice, keep, 4000);
      await c.addClip(ClipType.voice, gone, 4000);
      File(gone).deleteSync();
      await c.open();
      expect(c.snapshot!.clips.map((x) => x.path), [keep]);
      expect(await repo.allClips(), hasLength(1));
    });

    test('first open deletes clip files that have no row', () async {
      await setup();
      final tracked = files.newPath(ClipType.voice, now);
      final orphan = files.newPath(
        ClipType.voice,
        now.add(const Duration(seconds: 1)),
      );
      File(tracked).writeAsBytesSync([1]);
      File(orphan).writeAsBytesSync([1]);
      await c.addClip(ClipType.voice, tracked, 4000);
      // A fresh controller is a cold start.
      final cold = StickController(
        repo: repo,
        clock: () => now,
        reminders: sink,
        clipFiles: files,
      );
      await cold.open();
      expect(File(orphan).existsSync(), isFalse);
      expect(File(tracked).existsSync(), isTrue);
      expect(cold.snapshot!.clips, hasLength(1));
    });

    test('later opens leave unsaved recordings alone', () async {
      await setup();
      await c.open(); // first open
      final pending = files.newPath(ClipType.voice, now);
      File(pending).writeAsBytesSync([1]); // still in the record screen
      await c.open(); // app resumed
      expect(File(pending).existsSync(), isTrue);
    });

    test('deleteClip removes the row and the file', () async {
      await setup();
      final f = makeFile('a.m4a');
      await c.addClip(ClipType.voice, f.path, 4000);
      await c.deleteClip(c.snapshot!.clips.single.id);
      expect(c.snapshot!.clips, isEmpty);
      expect(f.existsSync(), isFalse);
    });

    test('freshStart deletes clip files unless keepClips', () async {
      await setup();
      final f = makeFile('a.m4a');
      await c.addClip(ClipType.voice, f.path, 4000);
      await c.freshStart(keepClips: true);
      expect(f.existsSync(), isTrue);
      await setup();
      await c.freshStart(keepClips: false);
      // keepClips kept the row, so the second wipe deletes it and the file.
      expect(f.existsSync(), isFalse);
    });
  });
}
