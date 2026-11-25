import 'dart:async';

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
import 'package:stick/services/splash_gate.dart';
import 'package:stick/ui/intro/logo_intro.dart';

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late int done;

  Widget intro({bool noMotion = false, bool waiting = false}) => MaterialApp(
    theme: stickTheme(),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: noMotion),
        child: LogoIntro(waiting: waiting, onDone: () => done++),
      ),
    ),
  );

  Future<void> pumpIntro(
    WidgetTester t, {
    bool noMotion = false,
    bool waiting = false,
  }) async {
    done = 0;
    await t.pumpWidget(intro(noMotion: noMotion, waiting: waiting));
  }

  double tileRadius(WidgetTester t) {
    final box = t.widget<Container>(find.byKey(const Key('intro-tile')));
    final r = (box.decoration! as BoxDecoration).borderRadius! as BorderRadius;
    return r.topLeft.x;
  }

  testWidgets('starts as the splash circle with S., morphs into the tile', (
    t,
  ) async {
    await pumpIntro(t);
    expect(find.byKey(const Key('intro-s')), findsOneWidget);
    expect(find.byKey(const Key('intro-dot')), findsOneWidget);
    expect(tileRadius(t), 80); // a circle, like Android's splash
    await t.pump(const Duration(milliseconds: 150));
    expect(tileRadius(t), 80); // holds the splash frame while it fades
    await t.pump(const Duration(milliseconds: 450));
    expect(tileRadius(t), lessThan(45)); // rounded square
  });

  testWidgets('sits on a page, so its text gets no warning underline', (
    t,
  ) async {
    await pumpIntro(t);
    await t.pump(const Duration(milliseconds: 800));
    expect(
      find.ancestor(of: find.text('STICK'), matching: find.byType(Material)),
      findsWidgets,
    );
    expect(
      find.descendant(
        of: find.byType(LogoIntro),
        matching: find.byType(Material),
      ),
      findsOneWidget,
    );
  });

  testWidgets('STICK slides in, then it is done once', (t) async {
    await pumpIntro(t);
    expect(find.text('STICK'), findsNothing);
    await t.pump(const Duration(milliseconds: 800));
    expect(find.text('STICK'), findsOneWidget);
    await t.pump(const Duration(milliseconds: 250));
    expect(done, 0);
    await t.pump(const Duration(milliseconds: 350));
    expect(done, 1);
    await t.pump(const Duration(seconds: 1));
    expect(done, 1);
  });

  testWidgets('while still loading it holds, then finishes', (t) async {
    await pumpIntro(t, waiting: true);
    await t.pump(const Duration(seconds: 3));
    expect(done, 0);
    expect(find.text('STICK'), findsOneWidget);
    await t.pumpWidget(intro());
    await t.pump(const Duration(milliseconds: 400));
    expect(done, 1);
  });

  testWidgets('a tap skips it', (t) async {
    await pumpIntro(t);
    await t.pump(const Duration(milliseconds: 100));
    await t.tap(find.byType(LogoIntro));
    await t.pump(const Duration(seconds: 2));
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
    await t.pump(const Duration(milliseconds: 1400));
    await t.pumpAndSettle();
    expect(find.byType(LogoIntro), findsNothing);
    expect(find.text('Built for the day you quit.'), findsOneWidget);
  });

  testWidgets('waits for the system splash to go before it starts', (t) async {
    done = 0;
    final gate = _FakeGate();
    await t.pumpWidget(
      MaterialApp(
        theme: stickTheme(),
        home: LogoIntro(splash: gate, onDone: () => done++),
      ),
    );
    await t.pump(const Duration(seconds: 1));
    expect(find.text('STICK'), findsNothing); // still the splash frame
    expect(tileRadius(t), 80);
    gate.gone.complete();
    await t.pump(); // the signal is handled
    await t.pump(); // the animation's first frame marks its start
    await t.pump(const Duration(milliseconds: 900));
    expect(find.text('STICK'), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    expect(done, 1);
  });

  testWidgets('starts anyway if the splash never reports', (t) async {
    done = 0;
    await t.pumpWidget(
      MaterialApp(
        theme: stickTheme(),
        home: LogoIntro(splash: _FakeGate(), onDone: () => done++),
      ),
    );
    await t.pump(const Duration(milliseconds: 1600)); // gate timeout
    await t.pump(const Duration(milliseconds: 900));
    expect(find.text('STICK'), findsOneWidget);
  });

  testWidgets("starts from the phone's own icon shape, then morphs", (t) async {
    done = 0;
    final gate = _FakeGate(shape: List.filled(72, 0.9));
    await t.pumpWidget(
      MaterialApp(
        theme: stickTheme(),
        home: LogoIntro(splash: gate, onDone: () => done++),
      ),
    );
    await t.pump();
    IntroShapeClipper clipper() =>
        t.widget<ClipPath>(find.byKey(const Key('intro-shape'))).clipper!
            as IntroShapeClipper;
    expect(clipper().radii, List.filled(72, 0.9));
    expect(clipper().morph, 0);
    gate.gone.complete();
    await t.pump(); // the signal is handled
    await t.pump(); // the animation's first frame marks its start
    await t.pump(const Duration(milliseconds: 600));
    expect(clipper().morph, 1);
  });
}

class _FakeGate implements SplashGate {
  _FakeGate({this.shape});
  final List<double>? shape;
  final gone = Completer<void>();

  @override
  Future<void> splashGone() =>
      gone.future.timeout(const Duration(milliseconds: 1500), onTimeout: () {});

  @override
  Future<List<double>?> iconShape() async => shape;
}
