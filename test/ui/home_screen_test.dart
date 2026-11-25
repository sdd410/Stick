import 'dart:async';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/domain/day_clock.dart';
import 'package:stick/domain/onboarding.dart';
import 'package:stick/domain/week_strip.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/home/home_screen.dart';
import 'package:stick/ui/home/week_strip_view.dart';

import '../support/home_helpers.dart';

class FakeController extends StickController {
  FakeController(db_.StickDatabase db, this._home, this._snap)
    : super(
        repo: StickRepository(db),
        clock: DateTime.now,
        reminders: NoopReminderSink(),
      );

  HomeState _home;
  final Snapshot _snap;
  int checkIns = 0;

  /// When true, a check-in moves to the next day like the real controller.
  bool advance = false;
  bool day4Next = false;
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
    if (advance) {
      _home = _home.copyWith(
        dayNumber: _home.dayNumber + 1,
        checkedInToday: true,
        showDay4: day4Next,
      );
      notifyListeners();
    }
  }

  @override
  Future<void> pickBackUp() async => pickUps++;

  int tipsMarked = 0;
  @override
  Future<void> markTipsSeen() async => tipsMarked++;
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
  QuitReason? quizReason,
  String emoji = '⭐',
  CheckInMode checkInMode = CheckInMode.tap,
  List<CheckIn> checkIns = const [],
  bool tipsSeen = true,
}) => Snapshot(
  habit: Habit(
    name: name,
    tiny: tiny,
    why: why,
    reminderMinutes: 1140,
    createdAt: DateTime(2026, 11, 1),
    quizReason: quizReason,
    emoji: emoji,
  ),
  current: Attempt(number: 1, startDay: '2026-11-01', quitTarget: 5),
  ended: const [],
  allCheckIns: checkIns,
  clips: clips,
  flags: Flags(
    day4Celebrated: false,
    lastWeeklyReplayDayNumber: null,
    homeStyle: homeStyle,
    checkInMode: checkInMode,
    tipsSeen: tipsSeen,
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
    void Function(Future<void> Function())? onOpenTimer,
    bool noMotion = false,
    void Function(FakeController)? before,
  }) async {
    final c = FakeController(db, s, sn ?? snap());
    before?.call(c);
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(disableAnimations: noMotion),
            child: child!,
          ),
          home: HomeScreen(
            onOpenTimer: onOpenTimer,
            onOpenProgress: onOpenProgress,
            onAddMessage: onAddMessage,
            onPlayReplay: onPlayReplay,
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
    expect(find.text('Done for today ✓'), findsOneWidget);
    await t.tap(find.text('Done for today ✓'));
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

  testWidgets('rescue shows the hint for the quiz reason', (t) async {
    await pump(
      t,
      state(day: 3, rescue: RescueReason.quitDay),
      sn: snap(quizReason: QuitReason.tired),
    );
    expect(
      find.text('Too tired? The tiny version is enough today.'),
      findsOneWidget,
    );
    expect(find.text('Just do this. Get to day 4.'), findsOneWidget);
  });

  testWidgets('no quiz reason, no hint', (t) async {
    await pump(t, state(day: 3, rescue: RescueReason.quitDay));
    for (final r in QuitReason.values) {
      final hint = reasonHint(r);
      if (hint != null) expect(find.text(hint), findsNothing);
    }
  });

  testWidgets('the hint only shows on a rescue day', (t) async {
    await pump(t, state(day: 2), sn: snap(quizReason: QuitReason.busy));
    expect(find.text('Too busy? Two minutes still counts.'), findsNothing);
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
    expect(find.text('▶ Your message'), findsNothing);
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
    await t.tap(find.text('▶ Your message'));
    expect(played, 1);
  });

  testWidgets('rescue with clips but no replay callback shows why', (t) async {
    await pump(
      t,
      state(rescue: RescueReason.quitDay),
      sn: snap(clips: [clip]),
    );
    expect(find.text('Be healthier'), findsOneWidget);
    expect(find.text('▶ Your message'), findsNothing);
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
    );
    expect(t.takeException(), isNull);
  });

  testWidgets('counter pill gets all free width at 360dp', (t) async {
    t.view.physicalSize = const Size(360, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pump(t, state(attempt: 2, day: 3), onOpenProgress: () {});
    // The pill takes the full width (360 - 2*24 padding); settings moved
    // to the tab bar. The text is still ellipsized under the wide Ahem
    // test font; the width assertion relies on that wide font filling the
    // available width. It guards against the Flexible + Spacer regression
    // that capped the pill at about half the width.
    final pill = t.getSize(
      find.ancestor(
        of: find.text('Attempt 2 · Day 3'),
        matching: find.byType(InkWell),
      ),
    );
    expect(pill.width, greaterThan(264)); // was capped by the old gear
    expect(pill.width, lessThanOrEqualTo(312));
    expect(pill.height, greaterThanOrEqualTo(48));
  });

  testWidgets('clip prompt banner shows on 7/14/21 and opens recorder', (
    t,
  ) async {
    var added = 0;
    await pump(t, state(day: 7, clipPrompt: true), onAddMessage: () => added++);
    expect(find.text('Record one for future you.'), findsOneWidget);
    await t.tap(find.text('Record one for future you.'));
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

  testWidgets('Home has no gear or See all / Add a message buttons', (t) async {
    await pump(t, state(), onAddMessage: () {});
    expect(find.text('Add a message'), findsNothing);
    expect(find.text('See all'), findsNothing);
    expect(find.byIcon(Icons.settings_outlined), findsNothing);
  });

  group('slide mode', () {
    Snapshot slideSnap({List<CheckIn> checkIns = const []}) =>
        snap(checkInMode: CheckInMode.slide, emoji: '🚶', checkIns: checkIns);

    testWidgets('shows the knob, not the Done today button', (t) async {
      await pump(t, state(day: 2), sn: slideSnap());
      expect(find.byKey(const Key('slide-knob')), findsOneWidget);
      expect(find.text('Slide when done'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, 'Done today'), findsNothing);
    });

    testWidgets('the habit card shows emoji and name', (t) async {
      await pump(t, state(day: 2), sn: slideSnap());
      expect(find.text('🚶'), findsOneWidget);
      expect(find.text('Walk'), findsOneWidget);
    });

    testWidgets('the week strip marks this week\'s check-ins', (t) async {
      final c = await pump(t, state(day: 2), sn: slideSnap());
      final yesterday = addDays(c.today, -1);
      await t.pumpWidget(const SizedBox());
      await pump(
        t,
        state(day: 2),
        sn: slideSnap(
          checkIns: [CheckIn(day: yesterday, attempt: 1, tiny: false)],
        ),
      );
      final strip = t.widget<WeekStripView>(find.byType(WeekStripView));
      final today = strip.days.firstWhere((d) => d.day == c.today);
      expect(today.state, WeekDayState.today);
      if (strip.days.any((d) => d.day == yesterday)) {
        expect(
          strip.days.firstWhere((d) => d.day == yesterday).state,
          WeekDayState.done,
        );
      }
    });

    testWidgets('a slide rolls the number up after the animation', (t) async {
      final c = await pump(
        t,
        state(day: 2),
        sn: slideSnap(),
        before: (c) => c.advance = true,
      );
      await slideToCheckIn(t);
      await t.pump();
      await t.pump(const Duration(milliseconds: 150));
      expect(find.text('Day 2'), findsOneWidget); // rolling out
      expect(find.text('Day 3'), findsOneWidget); // rolling in
      expect(find.byKey(const Key('check-in-sparks')), findsOneWidget);
      await t.pumpAndSettle();
      expect(find.text('Day 2'), findsNothing);
      expect(find.text('Day 3'), findsOneWidget);
      expect(find.byKey(const Key('check-in-sparks')), findsNothing);
      expect(find.text('Done for today ✓'), findsOneWidget);
      expect(c.checkIns, 1);
    });

    testWidgets('reduced motion: number changes at once, no sparks', (t) async {
      await pump(
        t,
        state(day: 2),
        sn: slideSnap(),
        noMotion: true,
        before: (c) => c.advance = true,
      );
      await slideToCheckIn(t);
      await t.pump();
      await t.pump();
      expect(find.text('Day 2'), findsNothing);
      expect(find.text('Day 3'), findsOneWidget);
      expect(find.byKey(const Key('check-in-sparks')), findsNothing);
    });

    testWidgets('reaching day 4 plays two heavy taps before the screen', (
      t,
    ) async {
      final haptics = <String>[];
      t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments as String);
          }
          return null;
        },
      );
      addTearDown(
        () => t.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await pump(
        t,
        state(day: 3),
        sn: slideSnap(),
        before: (c) => c
          ..advance = true
          ..day4Next = true,
      );
      await slideToCheckIn(t);
      await t.pumpAndSettle();
      expect(
        haptics.where((h) => h == 'HapticFeedbackType.heavyImpact'),
        hasLength(2),
      );
      expect(haptics, contains('HapticFeedbackType.lightImpact'));
      expect(find.byType(HomeScreen), findsNothing); // Day 4 screen on top
    });

    testWidgets('rescue shows the timer chip, wired', (t) async {
      var timers = 0;
      await pump(
        t,
        state(day: 3, rescue: RescueReason.quitDay),
        sn: slideSnap(),
        onOpenTimer: (_) => timers++,
      );
      await t.tap(find.text('⏱ 2-min timer'));
      expect(timers, 1);
    });

    testWidgets('long-press on the slide opens the timer', (t) async {
      var timers = 0;
      await pump(
        t,
        state(day: 2),
        sn: slideSnap(),
        onOpenTimer: (_) => timers++,
      );
      await t.longPress(find.text('Slide when done'));
      expect(timers, 1);
    });

    testWidgets('paused shows Pick it back up, no knob', (t) async {
      await pump(t, state(day: 3, paused: true), sn: slideSnap());
      expect(find.text('Pick it back up'), findsOneWidget);
      expect(find.byKey(const Key('slide-knob')), findsNothing);
    });

    testWidgets('done today shows the settled bar', (t) async {
      await pump(t, state(day: 3, done: true), sn: slideSnap());
      expect(find.text('Done for today ✓'), findsOneWidget);
    });
  });

  testWidgets('on a small phone the slide is visible on a busy rescue day', (
    t,
  ) async {
    t.view.physicalSize = const Size(360, 560); // 640 minus the tab bar
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await pump(
      t,
      state(attempt: 2, day: 3, rescue: RescueReason.quitDay, lastQuitDay: 3),
      sn: Snapshot(
        habit: snap(quizReason: QuitReason.tired).habit,
        current: snap().current,
        ended: const [],
        allCheckIns: const [],
        clips: [clip],
        flags: snap(checkInMode: CheckInMode.slide).flags,
      ),
      onPlayReplay: () {},
      onOpenTimer: (_) {},
    );
    expect(t.takeException(), isNull);
    expect(find.byKey(const Key('slide-knob')).hitTestable(), findsOneWidget);
  });

  group('tips', () {
    const slideTip = "Slide the lime circle right when you've done it.";
    const messagesTip = 'Your messages to future you live here.';

    testWidgets('two tips, one after the other, then never again', (t) async {
      final c = await pump(
        t,
        state(day: 1),
        sn: snap(checkInMode: CheckInMode.slide, tipsSeen: false),
      );
      expect(find.text(slideTip), findsOneWidget);
      expect(find.text(messagesTip), findsNothing);
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();
      expect(find.text(slideTip), findsNothing);
      expect(find.text(messagesTip), findsOneWidget);
      await t.tap(find.text('OK'));
      await t.pumpAndSettle();
      expect(find.text(messagesTip), findsNothing);
      expect(c.tipsMarked, 1);
    });

    testWidgets('tap mode explains the button', (t) async {
      await pump(t, state(day: 1), sn: snap(tipsSeen: false));
      expect(find.text("Tap Done today when you've done it."), findsOneWidget);
    });

    testWidgets('no tips once seen or while paused', (t) async {
      await pump(t, state(day: 1), sn: snap(checkInMode: CheckInMode.slide));
      expect(find.text(slideTip), findsNothing);
      await pump(
        t,
        state(day: 3, paused: true),
        sn: snap(checkInMode: CheckInMode.slide, tipsSeen: false),
      );
      expect(find.text(slideTip), findsNothing);
    });

    testWidgets('the slide still works under the first tip', (t) async {
      final c = await pump(
        t,
        state(day: 1),
        sn: snap(checkInMode: CheckInMode.slide, tipsSeen: false),
      );
      await slideToCheckIn(t);
      await t.pumpAndSettle();
      expect(c.checkIns, 1);
    });
  });
}
