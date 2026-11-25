import 'package:flutter/material.dart';

import 'app.dart';
import 'controller/stick_controller.dart';
import 'controller/stick_scope.dart';
import 'services/clip_files.dart';
import 'services/clip_recorder.dart';
import 'services/splash_gate.dart';
import 'ui/replay/clip_player.dart';

/// Hosts the app: re-opens (reload + reschedule) whenever it returns to the
/// foreground, and acts on the reminder that launched it.
class StickLifecycle extends StatefulWidget {
  const StickLifecycle({
    super.key,
    required this.controller,
    required this.files,
    required this.recorder,
    required this.launchPayload,
    this.playerFactory = videoPlayerClipPlayer,
    this.ready,
    this.splash,
  });

  /// See [StickApp.splash].
  final SplashGate? splash;

  /// Completes once the first load is done (main loads behind the intro
  /// instead of before the first frame). Null means already loaded.
  final Future<void>? ready;

  final StickController controller;
  final ClipFiles files;
  final ClipRecorder recorder;

  /// Payload of the notification that launched the app, or null.
  final Future<String?> Function() launchPayload;
  final ClipPlayerFactory playerFactory;

  @override
  State<StickLifecycle> createState() => _StickLifecycleState();
}

class _StickLifecycleState extends State<StickLifecycle>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Launched by tapping a reminder: act once the navigator exists.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await widget.ready;
        if (await widget.launchPayload() == 'replay') {
          await openReplayFromNotification(
            widget.files,
            playerFactory: widget.playerFactory,
          );
        }
      } catch (e) {
        debugPrint('launch from notification failed: $e');
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.open().catchError(
        (Object e) => debugPrint('open on resume failed: $e'),
      );
    }
  }

  @override
  Widget build(BuildContext context) => StickScope(
    controller: widget.controller,
    child: StickApp(
      recorder: widget.recorder,
      files: widget.files,
      showIntro: true,
      splash: widget.splash,
    ),
  );
}
