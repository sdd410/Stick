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
import 'package:stick/services/clip_recorder.dart';
import 'package:stick/theme.dart';
import 'package:stick/ui/record/record_screen.dart';

class FakeRecorder implements ClipRecorder {
  PermissionResult permission = PermissionResult.granted;
  RecordedClip? result;
  int durationMs = 5000;
  int stops = 0;
  int starts = 0;
  int releases = 0;
  String? startedPath;
  final _elapsed = StreamController<Duration>.broadcast();
  final _level = StreamController<double>.broadcast();

  void emit(Duration d) => _elapsed.add(d);

  @override
  Future<PermissionResult> ensurePermission(ClipType t) async => permission;
  @override
  Future<void> prepare(ClipType t) async {}
  @override
  Future<void> start(ClipType t, String path) async {
    starts++;
    await Future<void>.delayed(Duration.zero);
    startedPath = path;
    File(path).writeAsBytesSync([1, 2, 3]);
    result = RecordedClip(path: path, durationMs: durationMs);
  }

  @override
  Future<RecordedClip?> stop() async {
    stops++;
    return result;
  }

  @override
  Stream<Duration> get elapsed => _elapsed.stream;
  @override
  Stream<double> get level => _level.stream;
  @override
  Widget buildPreview(BuildContext context) => const Text('preview');
  @override
  Future<void> release() async => releases++;
}

class FakeSink implements ReminderSink {
  @override
  Future<void> reschedule(Snapshot s, DateTime now) async {}
  @override
  Future<bool> requestPermission() async => true;
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late db_.StickDatabase db;
  late Directory tmp;
  late ClipFiles files;
  late FakeRecorder rec;
  late StickController c;
  var settingsOpened = 0;
  bool? popped;

  setUp(() {
    db = db_.StickDatabase.forTesting(NativeDatabase.memory());
    tmp = Directory.systemTemp.createTempSync('recscreen');
    files = ClipFiles(tmp);
    rec = FakeRecorder();
    settingsOpened = 0;
    popped = null;
    c = StickController(
      repo: StickRepository(db),
      clock: () => DateTime(2026, 11, 20, 12),
      reminders: FakeSink(),
      clipFiles: files,
    );
  });
  tearDown(() async {
    await db.close();
    tmp.deleteSync(recursive: true);
  });

  Future<void> pump(WidgetTester t) async {
    await t.runAsync(() async {
      await c.createHabit(name: 'Walk', why: 'x', reminderMinutes: 1140);
    });
    await t.pumpWidget(
      StickScope(
        controller: c,
        child: MaterialApp(
          theme: stickTheme(),
          home: Builder(
            builder: (ctx) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  popped = await Navigator.of(ctx).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => RecordScreen(
                        recorder: rec,
                        files: files,
                        openSettings: () async {
                          settingsOpened++;
                          return true;
                        },
                      ),
                    ),
                  );
                },
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

  Future<void> choose(WidgetTester t, String label) async {
    await t.tap(find.text(label));
    await t.pump();
    await t.pump();
  }

  /// File deletes are real IO, which FakeAsync cannot advance.
  Future<void> settle(WidgetTester t) async {
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 30)),
    );
    await t.pump();
  }

  Future<void> tapRecord(WidgetTester t) async {
    await t.tap(find.byKey(const Key('record-button')));
    await t.pump();
    await t.pump(const Duration(milliseconds: 1));
    await t.pump();
  }

  List<File> clipFilesOnDisk() {
    final d = Directory('${tmp.path}/clips');
    return d.existsSync() ? d.listSync().whereType<File>().toList() : [];
  }

  testWidgets('denied permission shows Open settings and does not crash', (
    t,
  ) async {
    rec.permission = PermissionResult.permanentlyDenied;
    await pump(t);
    await choose(t, 'Voice');
    expect(
      find.text(
        'Stick needs the microphone to record. Nothing leaves your phone.',
      ),
      findsOneWidget,
    );
    await t.tap(find.text('Open settings'));
    await t.pump();
    expect(settingsOpened, 1);
    expect(find.byKey(const Key('record-button')), findsNothing);
  });

  testWidgets('video asks for camera wording when denied', (t) async {
    rec.permission = PermissionResult.denied;
    await pump(t);
    await choose(t, 'Video');
    expect(
      find.text(
        'Stick needs the camera and microphone to record. '
        'Nothing leaves your phone.',
      ),
      findsOneWidget,
    );
    expect(find.text('Open settings'), findsOneWidget);
  });

  testWidgets('auto stops at 15 seconds', (t) async {
    await pump(t);
    await choose(t, 'Voice');
    await tapRecord(t);
    expect(rec.stops, 0);
    rec.emit(const Duration(seconds: 14));
    await t.pump();
    expect(rec.stops, 0);
    rec.emit(maxClip);
    await t.pump();
    await t.pump();
    expect(rec.stops, 1);
    expect(find.text('Keep'), findsOneWidget);
    expect(find.text('Redo'), findsOneWidget);
  });

  testWidgets('too short recording is discarded', (t) async {
    await pump(t);
    await choose(t, 'Voice');
    await tapRecord(t);
    rec.result = null; // the recorder discarded it
    await t.tap(find.byKey(const Key('record-button')));
    await t.pump();
    await t.pump();
    expect(find.text('Keep'), findsNothing);
    expect(c.snapshot!.clips, isEmpty);
    expect(find.byKey(const Key('record-button')), findsOneWidget);
  });

  testWidgets('a clip under the minimum is deleted even if recorder kept it', (
    t,
  ) async {
    rec.durationMs = 300;
    await pump(t);
    await choose(t, 'Voice');
    await tapRecord(t);
    await t.tap(find.byKey(const Key('record-button')));
    await settle(t);
    expect(find.text('Keep'), findsNothing);
    expect(clipFilesOnDisk(), isEmpty);
    expect(c.snapshot!.clips, isEmpty);
  });

  testWidgets('background during recording keeps partial clip', (t) async {
    await pump(t);
    await choose(t, 'Voice');
    await tapRecord(t);
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await t.pump();
    await t.pump();
    expect(rec.stops, 1);
    // Frames are off while paused; the user sees the result on return.
    t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await t.pump();
    expect(find.text('Keep'), findsOneWidget);
    await t.tap(find.text('Keep'));
    await settle(t);
    await t.pumpAndSettle();
    expect(c.snapshot!.clips, hasLength(1));
    expect(c.snapshot!.clips.single.durationMs, 5000);
    expect(c.snapshot!.clips.single.type, ClipType.voice);
    expect(popped, isTrue);
    expect(rec.releases, 1);
  });

  testWidgets('Redo deletes the file and returns to the record button', (
    t,
  ) async {
    await pump(t);
    await choose(t, 'Video');
    await tapRecord(t);
    await t.tap(find.byKey(const Key('record-button')));
    await t.pump();
    await t.pump();
    expect(clipFilesOnDisk(), hasLength(1));
    await t.tap(find.text('Redo'));
    await settle(t);
    expect(clipFilesOnDisk(), isEmpty);
    expect(find.byKey(const Key('record-button')), findsOneWidget);
    expect(c.snapshot!.clips, isEmpty);
  });

  testWidgets('leaving without keeping deletes the pending file', (t) async {
    await pump(t);
    await choose(t, 'Voice');
    await tapRecord(t);
    await t.tap(find.byKey(const Key('record-button')));
    await t.pump();
    await t.pump();
    expect(clipFilesOnDisk(), hasLength(1));
    await t.pageBack();
    await t.pumpAndSettle();
    await t.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
    expect(clipFilesOnDisk(), isEmpty);
    expect(c.snapshot!.clips, isEmpty);
  });

  testWidgets('double tap on record starts only one recording', (t) async {
    await pump(t);
    await choose(t, 'Voice');
    await t.tap(find.byKey(const Key('record-button')));
    await t.tap(find.byKey(const Key('record-button')));
    await t.pump(const Duration(milliseconds: 1));
    await t.pump();
    expect(rec.starts, 1);
  });

  testWidgets('double tap on Keep saves one clip', (t) async {
    await pump(t);
    await choose(t, 'Voice');
    await tapRecord(t);
    await t.tap(find.byKey(const Key('record-button')));
    await t.pump();
    await t.pump();
    await t.tap(find.text('Keep'));
    await t.tap(find.text('Keep'), warnIfMissed: false);
    await settle(t);
    await t.pumpAndSettle();
    expect(c.snapshot!.clips, hasLength(1));
  });
}
