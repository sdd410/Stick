import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/app.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/timer/tiny_timer_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late int completed;

  Future<void> pumpTimer(WidgetTester t) async {
    completed = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: stickTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => TinyTimerScreen(
                      emoji: '🚶',
                      name: 'Walk',
                      tinyText: 'Put on your shoes',
                      onComplete: () async => completed++,
                    ),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    // Not pumpAndSettle: the running countdown never settles.
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  testWidgets('counts down from 2:00', (t) async {
    await pumpTimer(t);
    expect(find.text('2:00'), findsOneWidget);
    expect(find.text('Put on your shoes.'), findsOneWidget);
    await t.pump(const Duration(seconds: 30));
    expect(find.text('1:30'), findsOneWidget);
  });

  testWidgets('pause stops the clock, resume continues', (t) async {
    await pumpTimer(t);
    await t.pump(const Duration(seconds: 30));
    await t.tap(find.text('Pause'));
    await t.pump(const Duration(seconds: 30));
    expect(find.text('1:30'), findsOneWidget);
    await t.tap(find.text('Resume'));
    await t.pump(); // the restarted ticker's first frame marks its start
    await t.pump(const Duration(seconds: 30));
    expect(find.text('1:00'), findsOneWidget);
  });

  testWidgets('reaching zero completes once and closes', (t) async {
    await pumpTimer(t);
    await t.pump(const Duration(minutes: 2, seconds: 1));
    await t.pumpAndSettle();
    expect(completed, 1);
    expect(find.byType(TinyTimerScreen), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('Done ✓ early completes once, even on a double tap', (t) async {
    await pumpTimer(t);
    await t.pump(const Duration(seconds: 10));
    final done = t.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Done ✓'),
    );
    done.onPressed!();
    done.onPressed!();
    await t.pumpAndSettle();
    expect(completed, 1);
    expect(find.byType(TinyTimerScreen), findsNothing);
  });

  testWidgets('rescue chip → timer → Done checks the day in', (t) async {
    final db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    var now = DateTime(2026, 11, 20, 12);
    final c = StickController(
      repo: StickRepository(db),
      clock: () => now,
      reminders: NoopReminderSink(),
    );
    await t.runAsync(() async {
      await c.open();
      await c.createHabit(name: 'Walk', why: 'x', reminderMinutes: 1140);
      await c.checkIn();
      now = DateTime(2026, 11, 21, 12);
      await c.open();
      await c.checkIn();
      now = DateTime(2026, 11, 22, 12); // day 3: the rescue
      await c.open();
      await c.markTipsSeen();
    });
    await t.pumpWidget(StickScope(controller: c, child: const StickApp()));
    await t.pumpAndSettle();
    await t.tap(find.text('⏱ 2-min timer'));
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byType(TinyTimerScreen), findsOneWidget);
    await t.runAsync(() async {
      await t.tap(find.widgetWithText(FilledButton, 'Done ✓'));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await t.pumpAndSettle();
    expect(c.home!.checkedInToday, isTrue);
    expect(find.text('Done for today ✓'), findsOneWidget);
  });
}
