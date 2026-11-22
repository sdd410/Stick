import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/home/home_screen.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  late DateTime now;
  late StickController c;
  setUp(() {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    now = DateTime(2026, 11, 20, 12);
    c = StickController(
      repo: StickRepository(db),
      clock: () => now,
      reminders: NoopReminderSink(),
    );
  });
  Future<void> seed() async {
    await c.createHabit(
      name: 'Walk',
      tiny: null,
      why: 'x',
      reminderMinutes: 1140,
    );
    for (var d = 21; d <= 22; d++) {
      await c.checkIn();
      now = DateTime(2026, 11, d, 12);
      await c.open();
    }
    await c.checkIn(); // day 3 done
    now = DateTime(2026, 11, 23, 12);
    await c.open(); // day 4
  }

  tearDown(() => db.close());

  testWidgets('day 4 screen shows once', (t) async {
    await t.runAsync(seed);
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(theme: stickTheme(), home: const HomeScreen()),
      ),
    );
    expect(c.home!.dayNumber, 4);
    expect(c.home!.showDay4, isTrue);
    expect(find.text('Day 4. You made it past the drop-off.'), findsNothing);

    await t.runAsync(() async {
      await t.tap(find.text('Done today'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
    expect(find.text('Day 4. You made it past the drop-off.'), findsOneWidget);

    await t.runAsync(() async {
      await t.tap(find.text('Keep going'));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await t.pumpAndSettle();
    expect(find.text('Day 4. You made it past the drop-off.'), findsNothing);
    expect(c.home!.showDay4, isFalse);
    expect(c.snapshot!.flags.day4Celebrated, isTrue);
  });
}
