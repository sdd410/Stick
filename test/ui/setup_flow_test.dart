import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/app.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';

class FakeSink implements ReminderSink {
  FakeSink(this.granted);
  final bool granted;
  int asked = 0;

  @override
  Future<void> reschedule(Snapshot s, DateTime now) async {}

  @override
  Future<bool> requestPermission() async {
    asked++;
    return granted;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;

  setUp(() => db = db_.StickDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<StickController> pump(WidgetTester t, FakeSink sink) async {
    final c = StickController(
      repo: StickRepository(db),
      clock: () => DateTime(2026, 11, 20, 12),
      reminders: sink,
    );
    await t.runAsync(c.open);
    await t.pumpWidget(StickScope(controller: c, child: const StickApp()));
    return c;
  }

  FilledButton button(WidgetTester t) =>
      t.widget<FilledButton>(find.byType(FilledButton));

  testWidgets('name is required', (t) async {
    await pump(t, FakeSink(true));
    expect(button(t).onPressed, isNull);
    await t.enterText(find.byType(TextField), 'Walk');
    await t.pump();
    expect(button(t).onPressed, isNotNull);
    await t.enterText(find.byType(TextField), '   ');
    await t.pump();
    expect(button(t).onPressed, isNull);
  });

  testWidgets('tiny is optional', (t) async {
    await pump(t, FakeSink(true));
    await t.enterText(find.byType(TextField), 'Walk');
    await t.pump();
    await t.tap(find.text('Next'));
    await t.pump();
    expect(find.text('Just show up for 2 minutes'), findsOneWidget);
    expect(button(t).onPressed, isNotNull);
    await t.tap(find.text('Next'));
    await t.pump();
    expect(find.text('Why are you starting?'), findsOneWidget);
    expect(find.text('19:00'), findsOneWidget);
  });

  for (final granted in [true, false]) {
    testWidgets('finishes setup, permission granted=$granted', (t) async {
      final sink = FakeSink(granted);
      final c = await pump(t, sink);
      await t.enterText(find.byType(TextField), 'Walk');
      await t.pump();
      await t.tap(find.text('Next'));
      await t.pump();
      await t.tap(find.text('Next'));
      await t.pump();
      await t.enterText(find.byType(TextField), 'Head clear');
      await t.pump();
      await t.runAsync(() async {
        await t.tap(find.text('Start'));
        // Let the permission ask and the database write finish.
        await Future<void>.delayed(const Duration(milliseconds: 300));
      });
      await t.pump();
      expect(sink.asked, 1);
      expect(c.snapshot!.habit.name, 'Walk');
      expect(c.snapshot!.habit.reminderMinutes, 1140);
      expect(find.text('Day 1'), findsOneWidget);
    });
  }
}
