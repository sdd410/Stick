import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/progress/progress_screen.dart';

class FakeController extends StickController {
  FakeController(db_.StickDatabase db, this._home, this._snap)
    : super(
        repo: StickRepository(db),
        clock: DateTime.now,
        reminders: NoopReminderSink(),
      );
  final HomeState _home;
  final Snapshot _snap;
  @override
  HomeState? get home => _home;
  @override
  Snapshot? get snapshot => _snap;
  @override
  bool get loaded => true;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  setUp(() => db = db_.StickDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  final clip = Clip(
    id: 1,
    type: ClipType.voice,
    path: 'a.m4a',
    recordedAt: DateTime(2026, 11, 2),
    dayNumber: 1,
    durationMs: 5000,
    attempt: 1,
  );

  Future<void> pump(
    WidgetTester t, {
    List<Clip> clips = const [],
    VoidCallback? onOpenReplay,
    int day = 2,
    int target = 6,
    String name = 'Walk',
    bool star = true,
    bool currentCheckIn = true,
  }) async {
    final ended = Attempt(
      number: 1,
      startDay: '2026-11-01',
      quitTarget: star ? 3 : 9,
      firstMissDay: 6,
      finalDay: 5,
      endedDay: '2026-11-10',
    );
    final current = Attempt(
      number: 2,
      startDay: '2026-11-10',
      quitTarget: target,
    );
    final snap = Snapshot(
      habit: Habit(
        name: name,
        tiny: null,
        why: 'x',
        reminderMinutes: 1140,
        createdAt: DateTime(2026, 11, 1),
      ),
      current: current,
      ended: [ended],
      allCheckIns: [
        for (var i = 1; i <= 5; i++)
          CheckIn(day: '2026-11-0$i', attempt: 1, tiny: i == 2),
        if (currentCheckIn)
          const CheckIn(day: '2026-11-10', attempt: 2, tiny: false),
      ],
      clips: clips,
      flags: const Flags(
        day4Celebrated: false,
        lastWeeklyReplayDayNumber: null,
        homeStyle: HomeStyle.bigNumber,
      ),
    );
    final h = HomeState(
      attemptNumber: 2,
      dayNumber: day,
      checkedInToday: true,
      paused: false,
      rescue: RescueReason.none,
      quitTarget: target,
      lastQuitDay: 6,
      showDay4: false,
      weeklyReplayDue: false,
      clipPrompt: false,
      firstMissToRecord: null,
    );
    final c = FakeController(db, h, snap);
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(ctx).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProgressScreen(onOpenReplay: onOpenReplay),
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
    await t.pumpAndSettle();
  }

  testWidgets('shows the numbers from stored data', (t) async {
    await pump(t);
    expect(find.text('6'), findsOneWidget); // days showed up
    expect(find.text('Days you showed up'), findsOneWidget);
    expect(find.text('Walk'), findsOneWidget);
    expect(find.text('Progress'), findsNothing);
    expect(find.text('Your attempts'), findsOneWidget);
    expect(find.text('Attempt 1'), findsOneWidget);
    expect(find.text('Attempt 2 · now'), findsOneWidget);
    expect(find.text('5 days'), findsOneWidget);
    expect(find.text('1 day'), findsOneWidget);
    expect(find.textContaining('★'), findsAtLeastNWidgets(1));
    expect(find.text('★ = got past your quit day'), findsOneWidget);
    expect(find.text('Beat your quit day'), findsNothing);
    expect(find.text('Tiny days'), findsOneWidget);
  });

  testWidgets('button says Back to Day N once past the quit day', (t) async {
    await pump(t, day: 4, target: 3);
    expect(find.text('Back to Day 4'), findsOneWidget);
    expect(find.textContaining('Get past'), findsNothing);
    await t.ensureVisible(find.text('Back to Day 4'));
    await t.tap(find.text('Back to Day 4'));
    await t.pumpAndSettle();
    expect(find.byType(ProgressScreen), findsNothing);
  });

  testWidgets('button keeps Get past on the quit day', (t) async {
    await pump(t, day: 3, target: 3);
    expect(find.text('Get past Day 3 this time'), findsOneWidget);
  });

  testWidgets('no legend without a star', (t) async {
    await pump(t, star: false);
    expect(find.textContaining('★ ='), findsNothing);
  });

  testWidgets('long name does not overflow', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      t.view.reset();
      t.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await pump(t, name: 'Read twenty pages of a book every single night');
    expect(t.takeException(), isNull);
  });

  testWidgets('next step button label', (t) async {
    await pump(t);
    expect(find.text('Get past Day 6 this time'), findsOneWidget);
  });

  testWidgets('next step pops back to home', (t) async {
    await pump(t);
    await t.ensureVisible(find.text('Get past Day 6 this time'));
    await t.tap(find.text('Get past Day 6 this time'));
    await t.pumpAndSettle();
    expect(find.byType(ProgressScreen), findsNothing);
  });

  testWidgets('messages block only with clips, and opens replay', (t) async {
    await pump(t);
    expect(find.textContaining('Messages to future you'), findsNothing);
  });

  testWidgets('messages block opens replay', (t) async {
    var opened = 0;
    await pump(t, clips: [clip], onOpenReplay: () => opened++);
    await t.ensureVisible(find.textContaining('Messages to future you'));
    await t.tap(find.textContaining('Messages to future you'));
    expect(opened, 1);
  });

  testWidgets('no missed-day text anywhere', (t) async {
    await pump(t, clips: [clip], onOpenReplay: () {});
    expect(find.textContaining('miss'), findsNothing);
    expect(find.textContaining('Miss'), findsNothing);
  });

  testWidgets('title stays on one line inside the toolbar', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      t.view.reset();
      t.platformDispatcher.clearTextScaleFactorTestValue();
    });
    const name = 'Read twenty pages of a book every single night';
    await pump(t, name: name);
    final title = t.renderObject<RenderParagraph>(
      find.descendant(of: find.byType(AppBar), matching: find.text(name)),
    );
    expect(title.size.height, lessThanOrEqualTo(56));
  });

  testWidgets('0-day current attempt shows 0 days and does not throw', (
    t,
  ) async {
    await pump(t, currentCheckIn: false);
    expect(find.text('0 days'), findsOneWidget);
    expect(t.takeException(), isNull);
  });
}
