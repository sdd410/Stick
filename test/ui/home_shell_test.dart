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
import 'package:stick/services/clip_files.dart';
import 'package:stick/services/clip_recorder.dart';
import 'package:stick/ui/progress/progress_screen.dart';
import 'package:stick/ui/record/record_screen.dart';

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
  late StickController c;

  setUp(() {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('shell');
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester t) async {
    c = StickController(
      repo: StickRepository(db),
      clock: () => DateTime(2026, 11, 20, 12),
      reminders: NoopReminderSink(),
    );
    await t.runAsync(() async {
      await c.createHabit(name: 'Walk', why: 'x', reminderMinutes: 1140);
      await c.open();
    });
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: StickApp(recorder: _Recorder(), files: ClipFiles(tmp)),
      ),
    );
    await t.pumpAndSettle();
  }

  Future<void> settle(WidgetTester t) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await t.pumpAndSettle();
  }

  Future<void> tab(WidgetTester t, String label) async {
    await t.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('four tabs, Home first, no gear or text buttons on Home', (
    t,
  ) async {
    await pump(t);
    for (final l in ['Home', 'Progress', 'Messages', 'Settings']) {
      expect(
        find.descendant(of: find.byType(NavigationBar), matching: find.text(l)),
        findsOneWidget,
      );
    }
    expect(find.text('Slide when done'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Add a message'), findsNothing);
    expect(find.widgetWithText(TextButton, 'See all'), findsNothing);
  });

  testWidgets('Messages tab lists messages and can add one', (t) async {
    await pump(t);
    await tab(t, 'Messages');
    expect(find.text('Your messages'), findsOneWidget);
    await t.tap(find.text('+ Add a message'));
    await t.pumpAndSettle();
    expect(find.byType(RecordScreen), findsOneWidget);
  });

  testWidgets('a double tap on + Add a message opens one record screen', (
    t,
  ) async {
    await pump(t);
    await tab(t, 'Messages');
    final add = t.widget<FloatingActionButton>(
      find.byType(FloatingActionButton),
    );
    add.onPressed!();
    add.onPressed!();
    await t.pumpAndSettle();
    expect(find.byType(RecordScreen, skipOffstage: false), findsOneWidget);
  });

  testWidgets('back on another tab returns to Home', (t) async {
    await pump(t);
    await tab(t, 'Messages');
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Slide when done'), findsOneWidget);
    expect(find.text('Your messages'), findsNothing);
  });

  testWidgets('the counter and Progress button switch tabs', (t) async {
    await pump(t);
    await t.tap(find.text('Attempt 1 · Day 1'));
    await t.pumpAndSettle();
    expect(find.byType(ProgressScreen), findsOneWidget);
    final back = find.descendant(
      of: find.byType(ProgressScreen),
      matching: find.byType(FilledButton),
    );
    await t.ensureVisible(back);
    await t.pumpAndSettle();
    await t.tap(back);
    await t.pumpAndSettle();
    expect(find.text('Slide when done'), findsOneWidget);
  });

  testWidgets('Settings can switch check-in to Tap', (t) async {
    await pump(t);
    await tab(t, 'Settings');
    await t.tap(find.text('Tap'));
    await settle(t);
    await tab(t, 'Home');
    expect(find.widgetWithText(FilledButton, 'Done today'), findsOneWidget);
    expect(find.byKey(const Key('slide-knob')), findsNothing);
  });

  testWidgets('fresh start from the Settings tab ends on setup', (t) async {
    await pump(t);
    await tab(t, 'Settings');
    await t.scrollUntilVisible(find.text('Fresh start'), 200);
    await t.tap(find.text('Fresh start'));
    await t.pumpAndSettle();
    await t.tap(find.text('Yes, start fresh'));
    await settle(t);
    await settle(t);
    expect(find.text('Built for the day you quit.'), findsOneWidget);
  });
}
