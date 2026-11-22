import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/services/clip_files.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/settings/settings_screen.dart';

/// Deletes synchronously: real file IO never completes inside the widget
/// test's fake-async zone.
class SyncDeleteFiles extends ClipFiles {
  SyncDeleteFiles(super.root);
  @override
  Future<void> delete(String path) async {
    final f = File(path);
    if (f.existsSync()) f.deleteSync();
  }
}

class CountingSink implements ReminderSink {
  int reschedules = 0;
  @override
  Future<void> reschedule(Snapshot? s, DateTime now) async => reschedules++;
  @override
  Future<bool> requestPermission() async => true;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  late Directory tmp;
  late CountingSink sink;
  late StickController c;
  late List<String> log;
  late File clipFile;

  setUp(() {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('settings');
    sink = CountingSink();
    log = [];
    c = StickController(
      repo: StickRepository(db),
      clock: () => DateTime(2026, 11, 20, 12),
      reminders: sink,
      clipFiles: SyncDeleteFiles(tmp),
    );
  });
  tearDown(() {
    db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> seed(WidgetTester t, {bool withClip = false}) =>
      t.runAsync(() async {
        await c.createHabit(
          name: 'Walk',
          tiny: 'Shoes on',
          why: 'Head',
          reminderMinutes: 1140,
        );
        if (withClip) {
          clipFile = File('${tmp.path}/a.m4a')..writeAsStringSync('x');
          await c.addClip(ClipType.voice, clipFile.path, 3000);
        }
      });

  Future<void> pump(WidgetTester t, {String manufacturer = 'Google'}) async {
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push<void>(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(
                      readManufacturer: () async => manufacturer,
                      openSystemSettings: () async {
                        log.add('open settings');
                        return true;
                      },
                      onManageClips: () => log.add('manage clips'),
                      onPlayReplay: (headline) async =>
                          log.add('replay $headline'),
                    ),
                  ),
                ),
                child: const Text('go'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('go'));
    await t.pumpAndSettle();
  }

  Future<void> settle(WidgetTester t) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 300)),
    );
    await t.pumpAndSettle();
  }

  testWidgets('changing reminder time reschedules', (t) async {
    await seed(t);
    await pump(t);
    final before = sink.reschedules;
    await t.tap(find.text('Reminder time'));
    await t.pumpAndSettle();
    await t.tap(find.text('OK'));
    await settle(t);
    expect(sink.reschedules, before + 1);
  });

  testWidgets('edit habit needs a name and saves tiny and why', (t) async {
    await seed(t);
    await pump(t);
    await t.tap(find.text('Edit habit'));
    await t.pumpAndSettle();
    final fields = find.byType(TextField);
    await t.enterText(fields.at(0), '  ');
    await t.pump();
    expect(
      t
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'Save'))
          .onPressed,
      isNull,
    );
    await t.enterText(fields.at(0), 'Run');
    await t.enterText(fields.at(1), '');
    await t.enterText(fields.at(2), 'Energy');
    await t.pump();
    await t.tap(find.text('Save'));
    await settle(t);
    final h = c.snapshot!.habit;
    expect(h.name, 'Run');
    expect(h.tiny, isNull);
    expect(h.why, 'Energy');
    expect(h.reminderMinutes, 1140);
  });

  testWidgets('home style switches', (t) async {
    await seed(t);
    await pump(t);
    await t.tap(find.text('Road'));
    await settle(t);
    expect(c.snapshot!.flags.homeStyle, HomeStyle.road);
  });

  testWidgets('battery tip card only on listed brands', (t) async {
    await seed(t);
    await pump(t, manufacturer: 'Google');
    expect(find.text('Open settings'), findsNothing);
  });

  testWidgets('battery tip card shows with Open settings on Xiaomi', (t) async {
    await seed(t);
    await pump(t, manufacturer: 'Xiaomi');
    await settle(t);
    await t.scrollUntilVisible(find.text('Open settings'), 200);
    await t.tap(find.text('Open settings'));
    await t.pump();
    expect(log, ['open settings']);
  });

  testWidgets('manage clips opens the clip list callback', (t) async {
    await seed(t);
    await pump(t);
    await t.tap(find.text('Manage clips'));
    await t.pump();
    expect(log, ['manage clips']);
  });

  testWidgets('reset asks to confirm then increases attempt number', (t) async {
    await seed(t);
    await pump(t);
    await t.scrollUntilVisible(find.text('Reset'), 200);
    await t.tap(find.text('Reset'));
    await t.pumpAndSettle();
    expect(
      find.text('Start a new attempt. Your days stay counted.'),
      findsOneWidget,
    );
    await t.tap(find.text('Cancel'));
    await t.pumpAndSettle();
    expect(c.home!.attemptNumber, 1);

    await t.tap(find.text('Reset'));
    await t.pumpAndSettle();
    await t.tap(find.text('Start new attempt'));
    await settle(t);
    expect(c.home!.attemptNumber, 2);
  });

  testWidgets('fresh start shows replay first when clips exist', (t) async {
    await seed(t, withClip: true);
    await pump(t);
    await t.scrollUntilVisible(find.text('Fresh start'), 200);
    await t.tap(find.text('Fresh start'));
    await t.pumpAndSettle();
    expect(log, ['replay Day 1 you said this. Still switching?']);
    expect(find.text('Keep my clips?'), findsNothing);
    expect(find.text('Yes, start fresh'), findsOneWidget);
    await t.tap(find.text('Yes, start fresh'));
    await t.pumpAndSettle();
    expect(find.text('Keep my clips?'), findsOneWidget);
  });

  testWidgets('fresh start default deletes clips and returns to setup', (
    t,
  ) async {
    await seed(t, withClip: true);
    await pump(t);
    await t.scrollUntilVisible(find.text('Fresh start'), 200);
    await t.tap(find.text('Fresh start'));
    await t.pumpAndSettle();
    await t.tap(find.text('Yes, start fresh'));
    await t.pumpAndSettle();
    await t.tap(find.text('No'));
    await settle(t);
    expect(c.needsSetup, isTrue);
    expect(clipFile.existsSync(), isFalse);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('fresh start can keep clips', (t) async {
    await seed(t, withClip: true);
    await pump(t);
    await t.scrollUntilVisible(find.text('Fresh start'), 200);
    await t.tap(find.text('Fresh start'));
    await t.pumpAndSettle();
    await t.tap(find.text('Yes, start fresh'));
    await t.pumpAndSettle();
    await t.tap(find.text('Yes, keep'));
    await settle(t);
    expect(c.needsSetup, isTrue);
    expect(clipFile.existsSync(), isTrue);
  });

  testWidgets('fresh start without clips skips the replay', (t) async {
    await seed(t);
    await pump(t);
    await t.scrollUntilVisible(find.text('Fresh start'), 200);
    await t.tap(find.text('Fresh start'));
    await t.pumpAndSettle();
    expect(log, isEmpty);
    expect(find.text('Yes, start fresh'), findsOneWidget);
  });
}
