import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/home/home_big_number.dart';
import 'package:stick/ui/home/home_road.dart';
import 'package:stick/ui/home/home_screen.dart';

HomeState state({
  int attempt = 1,
  int day = 3,
  int quit = 5,
  bool paused = false,
  int? lastQuitDay,
}) => HomeState(
  attemptNumber: attempt,
  dayNumber: day,
  checkedInToday: false,
  paused: paused,
  rescue: RescueReason.none,
  quitTarget: quit,
  lastQuitDay: lastQuitDay,
  showDay4: false,
  weeklyReplayDue: false,
  clipPrompt: false,
  firstMissToRecord: null,
);

Widget road(HomeState s) => MaterialApp(
  theme: stickTheme(),
  home: Scaffold(
    body: Center(child: HomeRoad(state: s)),
  ),
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('road shows markers up to quit target plus one', (t) async {
    await t.pumpWidget(road(state(day: 3, quit: 5)));
    expect(find.text('Day 6'), findsOneWidget);
    expect(find.text('Day 7'), findsNothing);
    expect(find.text('Day 1'), findsOneWidget);
  });

  testWidgets('quit day flag shows Most people quit here on attempt 1', (
    t,
  ) async {
    await t.pumpWidget(road(state(day: 3, quit: 5)));
    expect(find.text('Most people quit here'), findsOneWidget);
    expect(find.byIcon(Icons.flag), findsOneWidget);
  });

  testWidgets('later attempt shows last time you stopped', (t) async {
    await t.pumpWidget(
      road(state(attempt: 2, day: 2, quit: 5, lastQuitDay: 5)),
    );
    expect(find.text('Day 5: last time you stopped'), findsOneWidget);
    expect(find.text('Most people quit here'), findsNothing);
  });

  testWidgets('paused makes today marker grey', (t) async {
    await t.pumpWidget(road(state(day: 3, paused: true)));
    final today = t.widget<Text>(find.text('3'));
    expect(today.style?.color, StickColors.bg);
    final circle = t.widget<Container>(
      find.ancestor(of: find.text('3'), matching: find.byType(Container)).first,
    );
    expect((circle.decoration as BoxDecoration).color, StickColors.muted);
  });

  testWidgets('long road at 360x640 does not overflow', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(road(state(day: 20, quit: 5)));
    await t.pump();
    expect(t.takeException(), isNull);
  });

  testWidgets('auto-scrolls so today is inside the road viewport', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await t.pumpWidget(road(state(day: 3, quit: 30)));
    await t.pump();
    await t.pump();
    expect(t.takeException(), isNull);
    final offset = t
        .state<ScrollableState>(find.byType(Scrollable))
        .position
        .pixels;
    expect(offset, greaterThan(0));
    final list = t.getRect(find.byType(ListView));
    final today = t.getRect(find.text('3'));
    expect(today.top, greaterThanOrEqualTo(list.top));
    expect(today.bottom, lessThanOrEqualTo(list.bottom));
  });

  testWidgets('paused on the quit day still says paused', (t) async {
    await t.pumpWidget(road(state(day: 5, quit: 5, paused: true)));
    expect(find.text('Day 5 · paused'), findsOneWidget);
    expect(find.byIcon(Icons.flag), findsOneWidget);
  });

  group('switch', () {
    late db_.StickDatabase db;
    setUp(() => db = db_.StickDatabase.forTesting(NativeDatabase.memory()));
    tearDown(() => db.close());

    testWidgets('switching style rebuilds home with HomeRoad', (t) async {
      final c = StickController(
        repo: StickRepository(db),
        clock: () => DateTime(2026, 11, 20, 12),
        reminders: NoopReminderSink(),
      );
      await t.runAsync(() async {
        await c.open();
        await c.createHabit(name: 'Walk', why: 'Health', reminderMinutes: 1140);
      });
      await t.pumpWidget(
        StickScope(
          controller: c,
          child: MaterialApp(theme: stickTheme(), home: const HomeScreen()),
        ),
      );
      expect(find.byType(HomeBigNumber), findsOneWidget);
      expect(find.byType(HomeRoad), findsNothing);
      await t.runAsync(() => c.setHomeStyle(HomeStyle.road));
      await t.pump();
      expect(find.byType(HomeRoad), findsOneWidget);
      expect(find.byType(HomeBigNumber), findsNothing);
    });
  });

  testWidgets('progress counter tap target is at least 48 tall', (t) async {
    final fakeDb = db_.StickDatabase.forTesting(NativeDatabase.memory());
    addTearDown(fakeDb.close);
    final c = _Fake(state(day: 3), fakeDb);
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: HomeScreen(onOpenProgress: () {}),
        ),
      ),
    );
    final h = t
        .getSize(
          find.ancestor(
            of: find.text('Attempt 1 · Day 3'),
            matching: find.byType(InkWell),
          ),
        )
        .height;
    expect(h, greaterThanOrEqualTo(48));
  });
}

class _Fake extends StickController {
  _Fake(this._h, db_.StickDatabase db)
    : super(
        repo: StickRepository(db),
        clock: DateTime.now,
        reminders: NoopReminderSink(),
      );
  final HomeState _h;
  @override
  HomeState? get home => _h;
  @override
  Snapshot? get snapshot => Snapshot(
    habit: Habit(
      name: 'Walk',
      tiny: null,
      why: 'x',
      reminderMinutes: 1,
      createdAt: DateTime(2026),
    ),
    current: Attempt(number: 1, startDay: '2026-11-01', quitTarget: 5),
    ended: const [],
    allCheckIns: const [],
    clips: const [],
    flags: const Flags(
      day4Celebrated: false,
      lastWeeklyReplayDayNumber: null,
      homeStyle: HomeStyle.bigNumber,
    ),
  );
  @override
  bool get loaded => true;
}
