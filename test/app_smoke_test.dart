import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/app.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('StickApp shows setup on the dark background', (tester) async {
    final db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = StickController(
      repo: StickRepository(db),
      clock: DateTime.now,
      reminders: NoopReminderSink(),
    );
    await tester.runAsync(c.open);
    await tester.pumpWidget(StickScope(controller: c, child: const StickApp()));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final bg =
        scaffold.backgroundColor ??
        Theme.of(tester.element(find.byType(Scaffold))).scaffoldBackgroundColor;
    expect(bg, const Color(0xFF0B0B12));
    expect(find.text('Built for the day you quit.'), findsOneWidget);
  });

  testWidgets('a failed first load shows a retry screen, not a blank one', (
    tester,
  ) async {
    final db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final repo = _FlakyRepo(db);
    final c = StickController(
      repo: repo,
      clock: DateTime.now,
      reminders: NoopReminderSink(),
    );
    await tester.runAsync(() => c.open().catchError((Object _) {}));
    await tester.pumpWidget(StickScope(controller: c, child: const StickApp()));

    expect(c.loaded, isFalse);
    expect(find.text('Something went wrong. Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    await tester.pump();

    expect(c.loadError, isNull);
    expect(find.text('Something went wrong. Try again'), findsNothing);
    expect(find.text('Built for the day you quit.'), findsOneWidget);
  });
}

class _FlakyRepo extends StickRepository {
  _FlakyRepo(super.db);
  bool fail = true;

  @override
  Future<Snapshot?> load() async {
    if (fail) {
      fail = false;
      throw StateError('disk hiccup');
    }
    return super.load();
  }
}
