import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart';
import 'controller/stick_controller.dart';
import 'controller/stick_scope.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'services/clip_files.dart';
import 'services/clip_recorder.dart';
import 'services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarContrastEnforced: false,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final files = ClipFiles(await getApplicationDocumentsDirectory());
  final notifications = NotificationService();
  try {
    await notifications.init((payload) {
      if (payload == 'replay') openReplayFromNotification(files);
    });
  } catch (e) {
    // Reminders are best effort; the app still works without them.
    debugPrint('notification init failed: $e');
  }
  final controller = StickController(
    repo: StickRepository(StickDatabase()),
    clock: DateTime.now,
    reminders: notifications,
    clipFiles: files,
  );
  try {
    await controller.open();
  } catch (e) {
    // Show setup/home anyway rather than a blank launch.
    debugPrint('initial open failed: $e');
  }
  runApp(_Lifecycle(
      controller: controller,
      files: files,
      notifications: notifications,
    ));
}

/// Re-opens (reload + reschedule) whenever the app returns to the foreground.
class _Lifecycle extends StatefulWidget {
  const _Lifecycle({
    required this.controller,
    required this.files,
    required this.notifications,
  });
  final StickController controller;
  final ClipFiles files;
  final NotificationService notifications;

  @override
  State<_Lifecycle> createState() => _LifecycleState();
}

class _LifecycleState extends State<_Lifecycle> with WidgetsBindingObserver {
  final _recorder = DeviceClipRecorder();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Launched by tapping a reminder: act once the navigator exists.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        if (await widget.notifications.launchPayload() == 'replay') {
          await openReplayFromNotification(widget.files);
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
    child: StickApp(recorder: _recorder, files: widget.files),
  );
}
