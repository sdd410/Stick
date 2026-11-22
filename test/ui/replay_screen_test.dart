import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stick/controller/stick_controller.dart';
import 'package:stick/controller/stick_scope.dart';
import 'package:stick/data/database.dart' as db_;
import 'package:stick/data/repository.dart';
import 'package:stick/domain/models.dart';
import 'package:stick/services/clip_files.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/home/home_screen.dart';
import 'package:stick/ui/replay/clip_player.dart';
import 'package:stick/ui/replay/clip_list_screen.dart';
import 'package:stick/ui/replay/replay_screen.dart';

class FakePlayer implements ClipPlayer {
  FakePlayer(this.log, this.broken);
  final List<String> log;
  final Set<int> broken;
  Clip? clip;
  bool disposed = false;
  final done = StreamController<void>.broadcast();

  @override
  Future<void> load(Clip c) async {
    if (broken.contains(c.id)) throw Exception('cannot open');
    clip = c;
    log.add('load ${c.id}');
  }

  @override
  Future<void> play() async => log.add('play ${clip!.id}');
  @override
  Future<void> pause() async => log.add('pause ${clip!.id}');
  @override
  Stream<void> get completed => done.stream;
  @override
  Widget view() => Text('playing ${clip!.id}');
  @override
  Future<void> dispose() async {
    disposed = true;
    log.add('dispose ${clip?.id}');
  }
}

class FakeFiles extends ClipFiles {
  FakeFiles(this.present) : super(Directory('unused'));
  final Set<String> present;
  @override
  Future<bool> exists(String path) async => present.contains(path);
}

Clip mk(int id) => Clip(
  id: id,
  type: ClipType.voice,
  path: '$id.m4a',
  recordedAt: DateTime(2026, 11, id),
  dayNumber: id,
  durationMs: 5000,
);

class WeeklyController extends StickController {
  WeeklyController(db_.StickDatabase db, this._home, this._snap)
    : super(
        repo: StickRepository(db),
        clock: DateTime.now,
        reminders: NoopReminderSink(),
      );
  final HomeState _home;
  final Snapshot _snap;
  int seen = 0;
  @override
  HomeState? get home => _home;
  @override
  Snapshot? get snapshot => _snap;
  @override
  bool get loaded => true;
  @override
  Future<void> markWeeklyReplaySeen() async => seen++;
  final deleted = <int>[];
  @override
  Future<void> deleteClip(int id) async => deleted.add(id);
}

HomeState home7({bool due = true}) => HomeState(
  attemptNumber: 1,
  dayNumber: 7,
  checkedInToday: false,
  paused: false,
  rescue: RescueReason.none,
  quitTarget: 5,
  lastQuitDay: null,
  showDay4: false,
  weeklyReplayDue: due,
  clipPrompt: false,
  firstMissToRecord: null,
);

Snapshot snapWith(List<Clip> clips) => Snapshot(
  habit: Habit(
    name: 'Walk',
    tiny: null,
    why: 'Be healthier',
    reminderMinutes: 1140,
    createdAt: DateTime(2026, 11, 1),
  ),
  current: Attempt(number: 1, startDay: '2026-11-01', quitTarget: 5),
  ended: const [],
  allCheckIns: const [],
  clips: clips,
  flags: const Flags(
    day4Celebrated: false,
    lastWeeklyReplayDayNumber: null,
    homeStyle: HomeStyle.bigNumber,
  ),
);

/// Navigation is async (dispose, load), so give the microtasks a few turns.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 5; i++) {
    await t.pump(const Duration(milliseconds: 50));
  }
  await t.pumpAndSettle();
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  setUp(() => db = db_.StickDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  late List<String> log;
  late List<FakePlayer> players;
  ClipPlayer factory({Set<int> broken = const {}}) {
    final p = FakePlayer(log, broken);
    players.add(p);
    return p;
  }

  setUp(() {
    log = [];
    players = [];
  });

  Future<void> pumpReplay(
    WidgetTester t,
    List<Clip> clips, {
    Set<String>? present,
    Set<int> broken = const {},
    String? headline,
  }) async {
    await t.pumpWidget(
      MaterialApp(
        theme: stickTheme(),
        home: Builder(
          builder: (ctx) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (_) => ReplayScreen(
                    clips: clips,
                    files: FakeFiles(
                      present ?? clips.map((c) => c.path).toSet(),
                    ),
                    headline: headline,
                    playerFactory: () => factory(broken: broken),
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await t.tap(find.text('open'));
    await settle(t);
  }

  testWidgets('does not play before tap', (t) async {
    await pumpReplay(t, [mk(1), mk(2)], headline: 'Day 1 you said this.');
    expect(find.text('▶ You have something to say'), findsOneWidget);
    expect(find.text('Day 1 you said this.'), findsOneWidget);
    expect(players, isEmpty);
    expect(log, isEmpty);
    await t.tap(find.text('▶ You have something to say'));
    await settle(t);
    expect(log, ['load 1', 'play 1']);
  });

  testWidgets('missing file is skipped', (t) async {
    await pumpReplay(t, [mk(1), mk(2), mk(3)], present: {'1.m4a', '3.m4a'});
    await t.tap(find.text('▶ You have something to say'));
    await settle(t);
    expect(find.text('playing 1'), findsOneWidget);
    await t.tapAt(const Offset(700, 300));
    await settle(t);
    expect(find.text('playing 3'), findsOneWidget);
    expect(log.where((l) => l == 'load 2'), isEmpty);
  });

  testWidgets('clip that fails to load is skipped, no crash', (t) async {
    await pumpReplay(t, [mk(1), mk(2), mk(3)], broken: {2});
    await t.tap(find.text('▶ You have something to say'));
    await settle(t);
    await t.tapAt(const Offset(700, 300));
    await settle(t);
    expect(find.text('playing 3'), findsOneWidget);
  });

  testWidgets('right tap next, left tap previous, end closes, no leaks', (
    t,
  ) async {
    await pumpReplay(t, [mk(1), mk(2)]);
    await t.tap(find.text('▶ You have something to say'));
    await settle(t);
    await t.tapAt(const Offset(700, 300));
    await settle(t);
    expect(find.text('playing 2'), findsOneWidget);
    await t.tapAt(const Offset(100, 300));
    await settle(t);
    expect(find.text('playing 1'), findsOneWidget);
    await t.tapAt(const Offset(700, 300));
    await settle(t);
    await t.tapAt(const Offset(700, 300));
    await settle(t);
    expect(find.text('open'), findsOneWidget);
    expect(players.every((p) => p.disposed), isTrue);
  });

  testWidgets('finishing a clip moves to the next', (t) async {
    await pumpReplay(t, [mk(1), mk(2)]);
    await t.tap(find.text('▶ You have something to say'));
    await settle(t);
    players.last.done.add(null);
    await settle(t);
    expect(find.text('playing 2'), findsOneWidget);
  });

  testWidgets('all files missing closes the screen', (t) async {
    await pumpReplay(t, [mk(1)], present: {});
    expect(find.text('open'), findsOneWidget);
    expect(players, isEmpty);
  });

  testWidgets('rapid taps leave only one live player', (t) async {
    await pumpReplay(t, [mk(1), mk(2), mk(3), mk(4)]);
    await t.tap(find.text('▶ You have something to say'));
    await settle(t);
    for (var i = 0; i < 2; i++) {
      await t.tapAt(const Offset(700, 300));
    }
    await settle(t);
    expect(players.where((p) => !p.disposed).length, 1);
  });

  testWidgets('weekly replay opens once on day 7', (t) async {
    final c = WeeklyController(db, home7(), snapWith([mk(1)]));
    var opened = 0;
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: HomeScreen(onPlayReplay: () => opened++),
        ),
      ),
    );
    await t.pump();
    await t.pump();
    expect(opened, 1);
    expect(c.seen, 1);
    c.notifyListeners();
    await t.pump();
    await t.pump();
    expect(opened, 1);
  });

  testWidgets('weekly replay does not open when not due', (t) async {
    final c = WeeklyController(db, home7(due: false), snapWith([mk(1)]));
    var opened = 0;
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: HomeScreen(onPlayReplay: () => opened++),
        ),
      ),
    );
    await t.pump();
    expect(opened, 0);
  });

  testWidgets('clip list: newest first, play, delete with confirm', (t) async {
    final c = WeeklyController(db, home7(), snapWith([mk(1), mk(3), mk(2)]));
    Clip? played;
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: ClipListScreen(onPlay: (x) => played = x),
        ),
      ),
    );
    final titles = t
        .widgetList<Text>(find.textContaining('Day '))
        .map((e) => e.data)
        .toList();
    expect(titles, ['Day 3', 'Day 2', 'Day 1']);
    await t.tap(find.text('Day 2'));
    expect(played?.id, 2);
    await t.tap(find.byIcon(Icons.delete_outline).first);
    await settle(t);
    expect(c.deleted, isEmpty);
    await t.tap(find.text('Delete'));
    await settle(t);
    expect(c.deleted, [3]);
  });
}
