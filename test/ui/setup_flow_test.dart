import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/app.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/onboarding.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/setup/setup_flow.dart';

class _Sink implements ReminderSink {
  _Sink({this.throws = false});
  final bool throws;
  int asked = 0;

  @override
  Future<void> reschedule(Snapshot? s, DateTime now) async {}

  @override
  Future<bool> requestPermission() async {
    asked++;
    if (throws) throw StateError('no permission plugin');
    return false;
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  late StickController c;
  late _Sink sink;
  late int finished;
  late int recorded;

  Future<void> pump(
    WidgetTester t, {
    bool sinkThrows = false,
    bool canRecord = false,
    Size size = const Size(400, 860),
    double textScale = 1,
  }) async {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    sink = _Sink(throws: sinkThrows);
    c = StickController(
      repo: StickRepository(db),
      clock: () => DateTime(2026, 11, 20, 12),
      reminders: sink,
    );
    finished = 0;
    recorded = 0;
    t.view.physicalSize = size;
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.runAsync(c.open);
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context)
                  .copyWith(textScaler: TextScaler.linear(textScale)),
              child: SetupFlow(
                onRecordFirstClip: canRecord ? () async => recorded++ : null,
                onFinished: () => finished++,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> settle(WidgetTester t) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 60)),
    );
    await t.pumpAndSettle();
  }

  /// Scrolls to [text] (big fonts push it below the fold), then taps it.
  Future<void> tap(WidgetTester t, String text) async {
    final f = find.text(text).last;
    await t.ensureVisible(f);
    await t.pumpAndSettle();
    await t.tap(f);
    await t.pumpAndSettle();
  }

  /// Welcome → quiz (answered or skipped) → Walk template.
  Future<void> toWhy(WidgetTester t, {bool skipQuiz = false}) async {
    await tap(t, 'Start');
    if (skipQuiz) {
      await tap(t, 'Skip');
      await tap(t, 'Skip');
    } else {
      await tap(t, 'Day 3');
      await tap(t, 'Continue');
      await tap(t, 'Too tired');
      await tap(t, 'Continue');
    }
    await tap(t, 'Walk');
    await tap(t, 'Continue'); // the edit sheet
  }

  testWidgets('the full flow creates the habit with the quiz answers', (
    t,
  ) async {
    await pump(t);
    expect(find.text('Built for the day you quit.'), findsOneWidget);
    await toWhy(t);
    await tap(t, 'Feel healthier');
    await tap(t, 'Continue');
    await tap(t, 'Morning');
    await tap(t, 'Continue');
    await settle(t);
    expect(
      find.text('You said day 3 gets you. Stick will be ready.'),
      findsOneWidget,
    );
    await tap(t, 'Got it');
    expect(find.text('On bad days, just put on your shoes'), findsOneWidget);
    await tap(t, 'I promise');
    await settle(t);

    final h = c.snapshot!.habit;
    expect(h.name, 'Walk');
    expect(h.tiny, 'Put on your shoes');
    expect(h.why, 'Feel healthier');
    expect(h.reminderMinutes, 7 * 60);
    expect(h.emoji, '🚶');
    expect(h.templateId, 'walk');
    expect(h.quizQuitDay, QuitDayAnswer.day3);
    expect(h.quizReason, QuitReason.tired);
    expect(sink.asked, 1);
    expect(finished, 1);
  });

  testWidgets('the wall and the promise use the quiz day', (t) async {
    await pump(t, canRecord: true);
    await tap(t, 'Start');
    await tap(t, 'Day 2');
    await tap(t, 'Continue');
    await tap(t, 'Skip');
    await tap(t, 'Walk');
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await settle(t);
    expect(find.textContaining('Day 2 is the'), findsOneWidget);
    await tap(t, 'Got it');
    expect(
      find.text('Say it out loud. Future you will hear it on day 2.'),
      findsOneWidget,
    );
    await tap(t, 'Skip recording');
    await settle(t);
    expect(c.snapshot!.current.quitTarget, 2);
  });

  testWidgets('quiz Continue waits for an answer', (t) async {
    await pump(t);
    await tap(t, 'Start');
    FilledButton cont() =>
        t.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));
    expect(cont().onPressed, isNull);
    await tap(t, 'Day 2');
    expect(cont().onPressed, isNotNull);
  });

  testWidgets('nothing is saved before the promise', (t) async {
    await pump(t);
    await toWhy(t);
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await settle(t);
    expect(find.text('Got it'), findsOneWidget);
    expect(c.needsSetup, isTrue);
  });

  testWidgets('back keeps what was typed and picked', (t) async {
    await pump(t);
    await toWhy(t);
    await t.enterText(find.byType(TextField), 'Head clear');
    await tap(t, 'Continue');
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('Head clear'), findsOneWidget);
    await t.tap(find.byTooltip('Back'));
    await t.pumpAndSettle();
    expect(find.text('Continue with 🚶 Walk'), findsOneWidget);
  });

  testWidgets('the system back button goes to the previous step', (t) async {
    await pump(t);
    await toWhy(t);
    await t.binding.handlePopRoute();
    await t.pumpAndSettle();
    expect(find.text('Pick your habit'), findsOneWidget);
  });

  testWidgets('skipping the quiz leaves the answers empty', (t) async {
    await pump(t);
    await toWhy(t, skipQuiz: true);
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await settle(t);
    expect(
      find.text('The first days are the hardest. Stick will be ready.'),
      findsOneWidget,
    );
    await tap(t, 'Got it');
    await tap(t, 'I promise');
    await settle(t);
    expect(c.snapshot!.habit.quizQuitDay, isNull);
    expect(c.snapshot!.habit.quizReason, isNull);
    expect(c.snapshot!.habit.reminderMinutes, 19 * 60);
  });

  testWidgets('a double tap does not reach the next step', (t) async {
    await pump(t);
    await toWhy(t);
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await settle(t);
    final at = t.getCenter(find.text('Got it'));
    await t.tapAt(at);
    await t.pump(const Duration(milliseconds: 60));
    await t.tapAt(at); // lands where "I promise" will be
    await settle(t);
    expect(find.text('Walk every day'), findsOneWidget);
    expect(c.needsSetup, isTrue);
  });

  testWidgets('a permission error does not block setup', (t) async {
    await pump(t, sinkThrows: true);
    await toWhy(t);
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await settle(t);
    await tap(t, 'Got it');
    await tap(t, 'I promise');
    await settle(t);
    expect(c.needsSetup, isFalse);
    expect(finished, 1);
  });

  testWidgets('record path: record once, then finish', (t) async {
    await pump(t, canRecord: true);
    await toWhy(t);
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await settle(t);
    await tap(t, 'Got it');
    expect(find.text('Skip recording'), findsOneWidget);
    await tap(t, 'I promise. Record it');
    await settle(t);
    expect(c.needsSetup, isFalse);
    expect(recorded, 1);
    expect(finished, 1);
  });

  testWidgets('skip recording still creates the habit', (t) async {
    await pump(t, canRecord: true);
    await toWhy(t);
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await settle(t);
    await tap(t, 'Got it');
    await tap(t, 'Skip recording');
    await settle(t);
    expect(c.needsSetup, isFalse);
    expect((recorded, finished), (0, 1));
  });

  testWidgets('2x text on a small phone does not overflow', (t) async {
    await pump(t, size: const Size(360, 640), textScale: 2);
    await tap(t, 'Start');
    expect(t.takeException(), isNull);
    expect(find.text('Continue').hitTestable(), findsOneWidget);
    await tap(t, 'Day 3');
    await tap(t, 'Continue');
    await tap(t, 'Too tired');
    await tap(t, 'Continue');
    await tap(t, 'Walk');
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await tap(t, 'Continue');
    await settle(t);
    await tap(t, 'Got it');
    expect(t.takeException(), isNull);
    expect(find.text('I promise').hitTestable(), findsOneWidget);
  });

  group('inside StickApp', () {
    Future<void> pumpApp(
      WidgetTester t, {
      String manufacturer = 'Google',
    }) async {
      db = db_.StickDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      sink = _Sink();
      c = StickController(
        repo: StickRepository(db),
        clock: () => DateTime(2026, 11, 20, 12),
        reminders: sink,
      );
      t.view.physicalSize = const Size(400, 860);
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.runAsync(c.open);
      await t.pumpWidget(
        StickScope(
          controller: c,
          child: StickApp(manufacturer: () async => manufacturer),
        ),
      );
    }

    Future<void> finish(WidgetTester t) async {
      await toWhy(t);
      await tap(t, 'Continue');
      await tap(t, 'Continue');
      await settle(t);
      await tap(t, 'Got it');
      await tap(t, 'I promise');
      await settle(t);
      await settle(t);
    }

    testWidgets('finishing lands on Home at day 1', (t) async {
      await pumpApp(t);
      await finish(t);
      expect(find.text('Day 1'), findsOneWidget);
    });

    for (final brand in ['Xiaomi', 'Google']) {
      testWidgets('battery tip after setup only on listed brands ($brand)', (
        t,
      ) async {
        await pumpApp(t, manufacturer: brand);
        await finish(t);
        expect(
          find.text('Keep reminders working'),
          brand == 'Xiaomi' ? findsOneWidget : findsNothing,
        );
      });
    }

    testWidgets('the why step survives the keyboard and a big font', (t) async {
      await pumpApp(t);
      await toWhy(t);
      t.view.viewInsets = const FakeViewPadding(bottom: 400);
      addTearDown(t.view.resetViewInsets);
      await t.pump();
      expect(t.takeException(), isNull);
      expect(find.text('Why are you starting?'), findsOneWidget);
    });
  });
}
