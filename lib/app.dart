import 'package:flutter/material.dart';

import 'controller/stick_scope.dart';
import 'domain/battery_tip.dart';
import 'services/clip_files.dart';
import 'services/device_info.dart';

import 'package:permission_handler/permission_handler.dart';

import 'services/clip_recorder.dart';
import 'domain/models.dart';
import 'domain/replay_rules.dart';
import 'theme.dart';
import 'ui/replay/clip_list_screen.dart';
import 'ui/replay/clip_player.dart';
import 'ui/replay/replay_screen.dart';
import 'ui/home/home_screen.dart';
import 'ui/progress/progress_screen.dart';
import 'ui/record/record_screen.dart';
import 'ui/settings/battery_tip_card.dart';
import 'ui/settings/settings_screen.dart';
import 'ui/setup/setup_flow.dart';
import 'ui/shell/home_shell.dart';
import 'ui/timer/tiny_timer_screen.dart';

/// Opens the story-style replay. Task 10 (notification) and Task 12 (fresh
/// start) call this. Pass [clips] to play specific ones instead of the pick.
Future<void> openReplay(
  BuildContext context, {
  required ClipFiles files,
  String? headline,
  List<Clip>? clips,
  ClipPlayerFactory playerFactory = videoPlayerClipPlayer,
}) async {
  final chosen =
      clips ??
      selectReplayClips(StickScope.of(context).snapshot?.clips ?? const []);
  if (chosen.isEmpty) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ReplayScreen(
        clips: chosen,
        files: files,
        headline: headline,
        playerFactory: playerFactory,
      ),
    ),
  );
}

/// Lets a notification tap open screens without a BuildContext.
final navigatorKey = GlobalKey<NavigatorState>();

/// Opens the replay from a tapped "paused" reminder. Does nothing if there is
/// no navigator yet or no clips.
Future<void> openReplayFromNotification(
  ClipFiles files, {
  ClipPlayerFactory playerFactory = videoPlayerClipPlayer,
}) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  await openReplay(ctx, files: files, playerFactory: playerFactory);
}

class StickApp extends StatelessWidget {
  const StickApp({
    super.key,
    this.recorder,
    this.files,
    this.manufacturer = readDeviceManufacturer,
    this.openSystemSettings = openAppSettings,
  });

  /// Injectable so tests never touch the platform channel.
  final Future<String> Function() manufacturer;
  final OpenSystemSettings openSystemSettings;

  /// Null hides recording (tests that do not care about it).
  final ClipRecorder? recorder;
  final ClipFiles? files;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Stick',
      debugShowCheckedModeBanner: false,
      theme: stickTheme(),
      home: _Root(
        recorder: recorder,
        files: files,
        manufacturer: manufacturer,
        openSystemSettings: openSystemSettings,
      ),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({
    this.recorder,
    this.files,
    required this.manufacturer,
    required this.openSystemSettings,
  });

  final ClipRecorder? recorder;
  final ClipFiles? files;
  final Future<String> Function() manufacturer;
  final OpenSystemSettings openSystemSettings;

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  // Setup stays on screen after the habit exists, for the optional first clip.
  bool _inSetup = false;

  /// The selected bottom tab (0 = Home).
  final _tab = ValueNotifier<int>(0);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  // Buttons whose pushed screen is still open; a second tap is ignored.
  final _open = <String>{};

  Future<void> _once(String key, Future<void> Function() push) async {
    if (!_open.add(key)) return;
    try {
      await push();
    } finally {
      _open.remove(key);
    }
  }

  bool get _canRecord => widget.recorder != null && widget.files != null;

  Future<void> _openRecord() => _once(
    'record',
    () => Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            RecordScreen(recorder: widget.recorder!, files: widget.files!),
      ),
    ),
  );

  /// The 2-minute tiny-version timer; finishing it checks the day in.
  Future<void> _openTimer() => _once('timer', () {
    final c = StickScope.of(context);
    final habit = c.snapshot?.habit;
    if (habit == null) return Future<void>.value();
    final t = habit.tiny?.trim();
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => TinyTimerScreen(
          emoji: habit.emoji,
          name: habit.name,
          tinyText: (t == null || t.isEmpty) ? 'Show up for 2 minutes' : t,
          onComplete: () async {
            if (c.home?.checkedInToday == false) await c.checkIn();
          },
        ),
      ),
    );
  });

  /// Once, right after setup, on phones that kill background reminders.
  Future<void> _maybeShowBatteryTip() async {
    String maker;
    try {
      maker = await widget.manufacturer();
    } catch (_) {
      return;
    }
    final tip = batteryTipFor(maker);
    final ctx = navigatorKey.currentContext;
    if (tip == null || ctx == null || !ctx.mounted) return;
    await showBatteryTipDialog(
      ctx,
      tip: tip,
      openSystemSettings: widget.openSystemSettings,
    );
  }

  void _retry() {
    StickScope.of(context)
        .open()
        .catchError((Object e) => debugPrint('retry open failed: $e'));
  }

  @override
  Widget build(BuildContext context) {
    final c = StickScope.of(context);
    if (!c.loaded) {
      if (c.loadError != null) return _LoadErrorScreen(onRetry: _retry);
      return const Scaffold();
    }
    if (c.needsSetup) _inSetup = true;
    if (_inSetup) {
      return SetupFlow(
        onRecordFirstClip: _canRecord ? _openRecord : null,
        onFinished: () {
          _tab.value = 0;
          setState(() => _inSetup = false);
          _maybeShowBatteryTip();
        },
      );
    }
    final files = widget.files;
    void replay() {
      if (files != null) openReplay(context, files: files);
    }

    return HomeShell(
      tab: _tab,
      home: HomeScreen(
        onOpenProgress: () => _tab.value = 1,
        onOpenTimer: _openTimer,
        onAddMessage: _canRecord ? _openRecord : null,
        onPlayReplay: files == null ? null : replay,
      ),
      progress: ProgressScreen(
        onOpenReplay: files == null ? null : replay,
        onBack: () => _tab.value = 0,
      ),
      messages: ClipListScreen(
        onPlay: (clip) {
          if (files != null) openReplay(context, files: files, clips: [clip]);
        },
        onPlayAll: files == null ? null : replay,
        onAddMessage: _canRecord ? _openRecord : null,
      ),
      settings: SettingsScreen(
        readManufacturer: widget.manufacturer,
        openSystemSettings: widget.openSystemSettings,
        onPlayReplay: files == null
            ? null
            : (headline) =>
                  openReplay(context, files: files, headline: headline),
      ),
    );
  }
}

/// Shown when the first load failed, so the launch is never a blank screen.
class _LoadErrorScreen extends StatelessWidget {
  const _LoadErrorScreen({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Something went wrong. Try again',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    ),
  );
}
