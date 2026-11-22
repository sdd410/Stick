import 'dart:async';

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
import 'package:stick/ui/home/home_screen.dart';

class FakeController extends StickController {
  FakeController(db_.StickDatabase db, this._home, this._snap)
    : super(
        repo: StickRepository(db),
        clock: DateTime.now,
        reminders: NoopReminderSink(),
      );

  final HomeState _home;
  final Snapshot _snap;
  int checkIns = 0;
  int pickUps = 0;
  Completer<void>? gate;

  @override
  HomeState? get home => _home;
  @override
  Snapshot? get snapshot => _snap;
  @override
  bool get loaded => true;

  @override
  Future<void> checkIn() async {
    checkIns++;
    await gate?.future;
  }

  @override
  Future<void> pickBackUp() async => pickUps++;
}

HomeState state({
  int attempt = 1,
  int day = 3,
  bool done = false,
  bool paused = false,
  RescueReason rescue = RescueReason.none,
  int? lastQuitDay,
  bool clipPrompt = false,
}) => HomeState(
  attemptNumber: attempt,
  dayNumber: day,
  checkedInToday: done,
  paused: paused,
  rescue: rescue,
  quitTarget: 5,
  lastQuitDay: lastQuitDay,
  showDay4: false,
  weeklyReplayDue: false,
  clipPrompt: clipPrompt,
  firstMissToRecord: null,
);

Snapshot snap({
  List<Clip> clips = const [],
  String? tiny,
  String why = 'Be healthier',
  String name = 'Walk',
  HomeStyle homeStyle = HomeStyle.bigNumber,
}) => Snapshot(
  habit: Habit(
    name: name,
    tiny: tiny,
    why: why,
    reminderMinutes: 1140,
    createdAt: DateTime(2026, 11, 1),
  ),
  current: Attempt(number: 1, startDay: '2026-11-01', quitTarget: 5),
  ended: const [],
  allCheckIns: const [],
  clips: clips,
  flags: Flags(
    day4Celebrated: false,
    lastWeeklyReplayDayNumber: null,
    homeStyle: homeStyle,
  ),
);

final clip = Clip(
  id: 1,
  type: ClipType.voice,
  path: 'a.m4a',
  recordedAt: DateTime(2026, 11, 2),
  dayNumber: 1,
  durationMs: 5000,
  attempt: 1,
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  setUp(() => db = db_.StickDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  Future<FakeController> pump(
    WidgetTester t,
    HomeState s, {
    Snapshot? sn,
    VoidCallback? onOpenProgress,
    VoidCallback? onAddMessage,
    VoidCallback? onPlayReplay,
    VoidCallback? onOpenSettings,
  }) async {
    final c = FakeController(db, s, sn ?? snap());
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: HomeScreen(
            onOpenProgress: onOpenProgress,
            onAddMessage: onAddMessage,
            onPlayReplay: onPlayReplay,
            onOpenSettings: onOpenSettings,
          ),
        ),
      ),
    );
    return c;
  }

  testWidgets('normal day shows Done today', (t) async {
    await pump(t, state(day: 3));
    expect(find.text('Day 3'), findsWidgets);
    expect(find.text('Done today'), findsOneWidget);
  });

  testWidgets('after check-in shows Done for today, disabled', (t) async {
    final c = await pump(t, state(done: true));
    expect(find.text('Done for today'), findsOneWidget);
    await t.tap(find.text('Done for today'));
    await t.pump();
    expect(c.checkIns, 0);
  });

  testWidgets('tap Done today calls checkIn once even on double tap', (
    t,
  ) async {
    final c = await pump(t, state());
    c.gate = Completer<void>();
    await t.tap(find.text('Done today'));
    await t.pump();
    await t.tap(find.text('Done today'), warnIfMissed: false);
    await t.pump();
    expect(c.checkIns, 1);
    c.gate!.complete();
    await t.pump();
  });

  testWidgets('paused shows grey Day 3 · paused and Pick it back up', (
    t,
  ) async {
    final c = await pump(
      t,
      state(day: 3, paused: true, rescue: RescueReason.paused),
    );
    final text = t.widget<Text>(find.text('Day 3 · paused'));
    expect(text.style?.color, StickColors.muted);
    expect(find.text('Done today'), findsNothing);
    await t.tap(find.text('Pick it back up'));
    await t.pump();
    expect(c.pickUps, 1);
  });

  testWidgets('rescue shows tiny version and Get to day 4', (t) async {
    await pump(t, state(day: 3, rescue: RescueReason.quitDay));
    expect(find.text('Just do this. Get to day 4.'), findsOneWidget);
    expect(find.text('Just show up for 2 minutes.'), findsOneWidget);
  });

  testWidgets('rescue uses the custom tiny habit', (t) async {
    await pump(
      t,
      state(day: 3, rescue: RescueReason.afterMiss),
      sn: snap(tiny: 'Put on shoes'),
    );
    expect(find.text('Just do this: Put on shoes.'), findsOneWidget);
  });

  testWidgets('learned quit day shows Last time you stopped on Day 5. '
      'Today is Day 5.', (t) async {
    await pump(
      t,
      state(attempt: 2, day: 5, rescue: RescueReason.quitDay, lastQuitDay: 5),
    );
    expect(
      find.text('Last time you stopped on Day 5. Today is Day 5.'),
      findsOneWidget,
    );
    expect(find.text('Just do this. Get to day 6.'), findsOneWidget);
  });

  testWidgets('Last time line only appears on the quit day itself', (t) async {
    // Day after picking back up: afterMiss, not the quit day.
    await pump(
      t,
      state(attempt: 2, day: 4, rescue: RescueReason.afterMiss, lastQuitDay: 5),
    );
    expect(find.textContaining('Last time you stopped'), findsNothing);
    expect(find.text('Just do this. Get to day 5.'), findsOneWidget);
  });

  testWidgets('empty why and no clips hides the blank rescue line', (t) async {
    await pump(
      t,
      state(rescue: RescueReason.quitDay),
      sn: snap(why: ''),
      onPlayReplay: () {},
    );
    expect(find.text(''), findsNothing);
    expect(find.text('Just show up for 2 minutes.'), findsOneWidget);
  });

  testWidgets('rescue without clips shows why text', (t) async {
    await pump(t, state(rescue: RescueReason.quitDay), onPlayReplay: () {});
    expect(find.text('Be healthier'), findsOneWidget);
    expect(find.text('▶ You have something to say'), findsNothing);
  });

  testWidgets('rescue with clips shows replay button wired', (t) async {
    var played = 0;
    await pump(
      t,
      state(rescue: RescueReason.quitDay),
      sn: snap(clips: [clip]),
      onPlayReplay: () => played++,
    );
    expect(find.text('Be healthier'), findsNothing);
    await t.tap(find.text('▶ You have something to say'));
    expect(played, 1);
  });

  testWidgets('rescue with clips but no replay callback shows why', (t) async {
    await pump(
      t,
      state(rescue: RescueReason.quitDay),
      sn: snap(clips: [clip]),
    );
    expect(find.text('Be healthier'), findsOneWidget);
    expect(find.text('▶ You have something to say'), findsNothing);
  });

  testWidgets('counter shows Attempt 4 · Day 2 and opens progress', (t) async {
    var opened = 0;
    await pump(t, state(attempt: 4, day: 2), onOpenProgress: () => opened++);
    await t.tap(find.text('Attempt 4 · Day 2'));
    expect(opened, 1);
  });

  testWidgets('shows the habit name', (t) async {
    await pump(t, state());
    expect(find.text('Walk'), findsOneWidget);
    await pump(t, state(), sn: snap(homeStyle: HomeStyle.road));
    await t.pump();
    expect(find.text('Walk'), findsOneWidget);
  });

  testWidgets('counter shows a chevron when progress can open', (t) async {
    await pump(t, state(), onOpenProgress: () {});
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('no chevron without progress callback', (t) async {
    await pump(t, state());
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('long name does not overflow', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    t.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(() {
      t.view.reset();
      t.platformDispatcher.clearTextScaleFactorTestValue();
    });
    await pump(
      t,
      state(attempt: 2, day: 3, rescue: RescueReason.quitDay, lastQuitDay: 3),
      sn: snap(name: 'Read twenty pages of a book every single night'),
      onOpenProgress: () {},
      onOpenSettings: () {},
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('counter is not truncated at 360dp', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pump(
      t,
      state(attempt: 2, day: 3),
      onOpenProgress: () {},
      onOpenSettings: () {},
    );
    // The pill takes all the width the settings icon leaves (360 - 2*24
    // padding - 48 icon). Flexible + Spacer capped it at about half.
    final pill = t.getSize(
      find.ancestor(
        of: find.text('Attempt 2 · Day 3'),
        matching: find.byType(InkWell),
      ),
    );
    expect(pill.width, 264);
    expect(pill.height, greaterThanOrEqualTo(48));
  });

  testWidgets('clip prompt banner shows on 7/14/21 and opens recorder', (
    t,
  ) async {
    var added = 0;
    await pump(t, state(day: 7, clipPrompt: true), onAddMessage: () => added++);
    expect(find.text('Record one for future you.'), findsOneWidget);
    await t.tap(find.text('Add a message'));
    expect(added, 1);
  });

  testWidgets('clip prompt hidden while paused or in rescue', (t) async {
    await pump(
      t,
      state(clipPrompt: true, rescue: RescueReason.quitDay),
      onAddMessage: () {},
    );
    expect(find.text('Record one for future you.'), findsNothing);
    await pump(
      t,
      state(clipPrompt: true, paused: true, rescue: RescueReason.paused),
      onAddMessage: () {},
    );
    await t.pump();
    expect(find.text('Record one for future you.'), findsNothing);
  });

  testWidgets('buttons for unbuilt screens are hidden when callbacks null', (
    t,
  ) async {
    await pump(t, state());
    expect(find.text('Add a message'), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  testWidgets('settings icon calls onOpenSettings', (t) async {
    var n = 0;
    await pump(t, state(), onOpenSettings: () => n++);
    await t.tap(find.byIcon(Icons.settings_outlined));
    expect(n, 1);
  });
}
