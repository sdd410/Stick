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
Future<void> openReplayFromNotification(ClipFiles files) async {
  final ctx = navigatorKey.currentContext;
  if (ctx == null || !ctx.mounted) return;
  await openReplay(ctx, files: files);
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

  bool get _canRecord => widget.recorder != null && widget.files != null;

  Future<void> _openRecord() => Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) =>
          RecordScreen(recorder: widget.recorder!, files: widget.files!),
    ),
  );

  void _openClipList() {
    final files = widget.files!;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ClipListScreen(
          onPlay: (clip) => openReplay(ctx, files: files, clips: [clip]),
        ),
      ),
    );
  }

  void _openSettings() {
    final files = widget.files;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => SettingsScreen(
          readManufacturer: widget.manufacturer,
          openSystemSettings: widget.openSystemSettings,
          onManageClips: files == null ? null : _openClipList,
          onPlayReplay: files == null
              ? null
              : (headline) => openReplay(ctx, files: files, headline: headline),
        ),
      ),
    );
  }

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

  void _openProgress() {
    final files = widget.files;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (ctx) => ProgressScreen(
          onOpenReplay: files == null
              ? null
              : () => openReplay(ctx, files: files),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = StickScope.of(context);
    if (!c.loaded) return const Scaffold();
    if (c.needsSetup) _inSetup = true;
    if (_inSetup) {
      return SetupFlow(
        onRecordFirstClip: _canRecord ? _openRecord : null,
        onFinished: () {
          setState(() => _inSetup = false);
          _maybeShowBatteryTip();
        },
      );
    }
    return HomeScreen(
      onOpenProgress: _openProgress,
      onOpenSettings: _openSettings,
      onAddMessage: _canRecord ? _openRecord : null,
      onPlayReplay: widget.files == null
          ? null
          : () => openReplay(context, files: widget.files!),
      onSeeAll: widget.files == null ? null : _openClipList,
    );
  }
}
