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

  setUp(() {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('navguard');
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester t) async {
    final c = StickController(
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
  }

  testWidgets('double tap on the counter shows one Progress screen', (t) async {
    await pump(t);
    final counter = t.widget<InkWell>(
      find.ancestor(
        of: find.text('Attempt 1 · Day 1'),
        matching: find.byType(InkWell),
      ),
    );
    counter.onTap!();
    counter.onTap!();
    await t.pumpAndSettle();
    expect(find.byType(ProgressScreen, skipOffstage: false), findsOneWidget);
  });

  Future<void> messagesTab(WidgetTester t) async {
    await t.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Messages'),
      ),
    );
    await t.pumpAndSettle();
  }

  testWidgets('the record button works again after the screen is closed', (
    t,
  ) async {
    await pump(t);
    await messagesTab(t);
    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();
    expect(find.byType(RecordScreen), findsOneWidget);
    await t.pageBack();
    await t.pumpAndSettle();
    await t.tap(find.byType(FloatingActionButton));
    await t.pumpAndSettle();
    expect(find.byType(RecordScreen), findsOneWidget);
  });
}
