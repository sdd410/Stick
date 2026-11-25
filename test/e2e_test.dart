import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/app.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/lifecycle.dart';
import 'package:stick/services/clip_files.dart';
import 'package:stick/services/clip_recorder.dart';
import 'package:stick/ui/replay/clip_player.dart';
import 'package:stick/ui/replay/replay_screen.dart';

import 'support/home_helpers.dart';

class _Sink implements ReminderSink {
  @override
  Future<void> reschedule(Snapshot? s, DateTime now) async {}
  @override
  Future<bool> requestPermission() async => true;
}

class _Player implements ClipPlayer {
  @override
  Future<void> load(Clip c) async {}
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Stream<void> get completed => const Stream.empty();
  @override
  Widget view() => const Text('playing');
  @override
  Future<void> dispose() async {}
}

class _Recorder implements ClipRecorder {
  @override
  Future<PermissionResult> ensurePermission(ClipType t) async =>
      PermissionResult.granted;
  @override
  Future<PermissionResult> permissionStatus(ClipType t) async =>
      PermissionResult.granted;
  @override
  Future<void> prepare(ClipType t) async {}
  @override
  Future<void> start(ClipType t, String path) async {}
  @override
  Future<RecordedClip?> stop() async => null;
  @override
  Stream<Duration> get elapsed => const Stream.empty();
  @override
  Stream<double> get level => const Stream.empty();
  @override
  Widget buildPreview(BuildContext context) => const SizedBox.shrink();
  @override
  Future<void> release() async {}
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  late Directory tmp;
  late DateTime now;
  late StickController c;

  setUp(() {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('e2e');
    now = DateTime(2026, 11, 20, 12);
    c = StickController(
      repo: StickRepository(db),
      clock: () => now,
      reminders: _Sink(),
      clipFiles: ClipFiles(tmp),
    );
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  /// Lets real async work (sqlite, file IO) finish, then settles animations.
  Future<void> settle(WidgetTester t) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await t.pumpAndSettle();
  }

  /// Moves the fake clock and re-opens, like returning to the app that day.
  Future<void> goTo(WidgetTester t, DateTime when) async {
    now = when;
    await t.runAsync(c.open);
    await t.pumpAndSettle();
  }

  Future<void> checkIn(WidgetTester t) async {
    await slideToCheckIn(t);
    await settle(t);
  }

  testWidgets('setup, a streak, a gap, a restart and the learned quit day', (
    t,
  ) async {
    await t.runAsync(c.open);
    await t.pumpWidget(StickScope(controller: c, child: const StickApp()));

    // Setup.
    expect(find.text('Built for the day you quit.'), findsOneWidget);
    Future<void> tapText(String text) async {
      await t.tap(find.text(text).last);
      await t.pumpAndSettle();
    }

    await tapText('Start');
    await tapText('Skip');
    await tapText('Skip');
    await tapText('Walk');
    await t.enterText(find.byKey(const Key('habit-tiny')), '');
    await tapText('Continue');
    await t.enterText(find.byType(TextField), 'Head clear');
    await tapText('Continue');
    await tapText('Continue');
    await settle(t);
    await tapText('Got it');
    await tapText('I promise');
    await settle(t);
    expect(find.text('Attempt 1 · Day 1'), findsOneWidget);

    // Three days in a row.
    await checkIn(t);
    expect(find.text('Done for today ✓'), findsOneWidget);
    await goTo(t, DateTime(2026, 11, 21, 12));
    await checkIn(t);
    await goTo(t, DateTime(2026, 11, 22, 12));
    expect(find.text('Attempt 1 · Day 3'), findsOneWidget);
    expect(find.text('Just do this. Get to day 4.'), findsOneWidget);
    await checkIn(t);

    // The Day 4 screen opens once.
    expect(find.text('Day 4. You made it past the drop-off.'), findsOneWidget);
    await t.tap(find.text('Keep going'));
    await t.pumpAndSettle();
    expect(find.text('Attempt 1 · Day 4'), findsOneWidget);

    // Skip two days: paused, and the day it stopped on is learned once.
    await goTo(t, DateTime(2026, 11, 24, 12));
    expect(find.text('Pick it back up'), findsOneWidget);
    expect(c.snapshot!.current.firstMissDay, 4);
    await goTo(t, DateTime(2026, 11, 24, 13));
    expect(c.snapshot!.current.firstMissDay, 4);

    // Pick it back up: rescue, no guilt screen.
    await t.tap(find.text('Pick it back up'));
    await settle(t);
    expect(find.text('Just do this. Get to day 5.'), findsOneWidget);

    // Reset from Settings starts attempt 2 with the learned quit day.
    await t.tap(find.byIcon(Icons.settings_outlined));
    await t.pumpAndSettle();
    await t.scrollUntilVisible(find.text('Reset'), 200);
    await t.tap(find.text('Reset'));
    await t.pumpAndSettle();
    await t.tap(find.text('Start new attempt'));
    await settle(t);
    await t.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Home'),
      ),
    );
    await t.pumpAndSettle();
    expect(c.home!.attemptNumber, 2);
    expect(c.home!.quitTarget, 4);
    expect(find.text('Attempt 2 · Day 1'), findsOneWidget);

    // Three good days, then the learned quit day shows the rescue.
    await checkIn(t);
    await goTo(t, DateTime(2026, 11, 25, 12));
    await checkIn(t);
    await goTo(t, DateTime(2026, 11, 26, 12));
    await checkIn(t);
    // Day 4 was celebrated in attempt 1, so no second celebration.
    expect(find.text('Day 4. You made it past the drop-off.'), findsNothing);
    await goTo(t, DateTime(2026, 11, 27, 12));
    expect(
      find.text('Last time you stopped on Day 4. Today is Day 4.'),
      findsOneWidget,
    );
    expect(find.text('Just do this. Get to day 5.'), findsOneWidget);
  });

  group('launched by a reminder tap', () {
    Future<void> boot(WidgetTester t, String? payload) async {
      await t.runAsync(() async {
        await c.open();
        await c.createHabit(name: 'Walk', why: 'x', reminderMinutes: 1140);
        final files = ClipFiles(tmp);
        final path = files.newPath(ClipType.voice, now);
        File(path).writeAsBytesSync([1, 2, 3]);
        await c.addClip(ClipType.voice, path, 3000);
      });
      await t.pumpWidget(
        StickLifecycle(
          controller: c,
          files: ClipFiles(tmp),
          recorder: _Recorder(),
          launchPayload: () async => payload,
          playerFactory: _Player.new,
        ),
      );
      await settle(t);
    }

    testWidgets('payload replay opens the replay on a cold start', (t) async {
      await boot(t, 'replay');
      expect(find.byType(ReplayScreen), findsOneWidget);
    });

    testWidgets('a replay launch waits until the app has loaded', (t) async {
      await t.runAsync(() async {
        await c.open();
        await c.createHabit(name: 'Walk', why: 'x', reminderMinutes: 1140);
        final files = ClipFiles(tmp);
        final path = files.newPath(ClipType.voice, now);
        File(path).writeAsBytesSync([1, 2, 3]);
        await c.addClip(ClipType.voice, path, 3000);
      });
      // A fresh controller that is still loading when the app starts.
      final fresh = StickController(
        repo: StickRepository(db),
        clock: () => now,
        reminders: _Sink(),
        clipFiles: ClipFiles(tmp),
      );
      final ready = Completer<void>();
      await t.pumpWidget(
        StickLifecycle(
          controller: fresh,
          files: ClipFiles(tmp),
          recorder: _Recorder(),
          launchPayload: () async => 'replay',
          playerFactory: _Player.new,
          ready: ready.future,
        ),
      );
      await settle(t);
      expect(find.byType(ReplayScreen), findsNothing);
      await t.runAsync(() async {
        await fresh.open();
        ready.complete();
      });
      await settle(t);
      await settle(t);
      expect(find.byType(ReplayScreen), findsOneWidget);
    });

    testWidgets('no payload stays on Home', (t) async {
      await boot(t, null);
      expect(find.byType(ReplayScreen), findsNothing);
      expect(find.text('Attempt 1 · Day 1'), findsOneWidget);
    });
  });
}
