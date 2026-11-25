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
import 'package:stick/ui/intro/logo_intro.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late int done;

  Future<void> pumpIntro(WidgetTester t, {bool noMotion = false}) async {
    done = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: stickTheme(),
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: noMotion),
            child: LogoIntro(onDone: () => done++),
          ),
        ),
      ),
    );
  }

  testWidgets('the dot and STICK arrive, then it is done once', (t) async {
    await pumpIntro(t);
    expect(find.text('S'), findsOneWidget);
    expect(find.text('STICK'), findsNothing);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const Key('intro-dot')), findsOneWidget);
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('STICK'), findsOneWidget);
    expect(done, 0);
    await t.pump(const Duration(milliseconds: 300));
    expect(done, 1);
    await t.pump(const Duration(seconds: 1));
    expect(done, 1);
  });

  testWidgets('a tap skips it', (t) async {
    await pumpIntro(t);
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byType(LogoIntro));
    await t.pump(const Duration(seconds: 1));
    expect(done, 1);
  });

  testWidgets('with animations off it is done at once', (t) async {
    await pumpIntro(t, noMotion: true);
    await t.pump();
    expect(done, 1);
  });

  testWidgets('StickApp(showIntro: true) plays it before setup', (t) async {
    final db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final c = StickController(
      repo: StickRepository(db),
      clock: DateTime.now,
      reminders: NoopReminderSink(),
    );
    await t.runAsync(c.open);
    await t.pumpWidget(
      StickScope(controller: c, child: const StickApp(showIntro: true)),
    );
    expect(find.byType(LogoIntro), findsOneWidget);
    expect(find.text('Built for the day you quit.'), findsNothing);
    await t.pump(const Duration(milliseconds: 900));
    await t.pumpAndSettle();
    expect(find.byType(LogoIntro), findsNothing);
    expect(find.text('Built for the day you quit.'), findsOneWidget);
  });
}
