import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'app.dart' show openReplayFromNotification;
import 'lifecycle.dart';
import 'controller/stick_controller.dart';
import 'data/database.dart';
import 'data/repository.dart';
import 'services/clip_files.dart';
import 'services/clip_recorder.dart';
import 'services/notification_service.dart';
import 'services/splash_gate.dart';

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
  // Listen for "splash gone" before the first frame can trigger it.
  final splash = AndroidSplashGate();
  final files = ClipFiles(await getApplicationDocumentsDirectory());
  final notifications = NotificationService();
  final controller = StickController(
    repo: StickRepository(StickDatabase()),
    clock: DateTime.now,
    reminders: notifications,
    clipFiles: files,
  );
  // Show the first frame right away and load behind the logo intro, so the
  // system splash does not wait for the database and the reminders.
  final ready = () async {
    try {
      await notifications.init((payload) {
        if (payload == 'replay') openReplayFromNotification(files);
      });
    } catch (e) {
      // Reminders are best effort; the app still works without them.
      debugPrint('notification init failed: $e');
    }
    try {
      await controller.open();
    } catch (e) {
      // The app shows a retry screen (controller.loadError).
      debugPrint('initial open failed: $e');
    }
  }();
  runApp(
    StickLifecycle(
      controller: controller,
      files: files,
      recorder: DeviceClipRecorder(),
      launchPayload: notifications.launchPayload,
      ready: ready,
      splash: splash,
    ),
  );
}
