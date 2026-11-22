import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'controller/stick_controller.dart';
import 'controller/stick_scope.dart';
import 'data/database.dart';
import 'data/repository.dart';

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
  final controller = StickController(
    repo: StickRepository(StickDatabase()),
    clock: DateTime.now,
    reminders: NoopReminderSink(),
  );
  await controller.open();
  runApp(_Lifecycle(controller: controller));
}

/// Re-opens (reload + reschedule) whenever the app returns to the foreground.
class _Lifecycle extends StatefulWidget {
  const _Lifecycle({required this.controller});
  final StickController controller;

  @override
  State<_Lifecycle> createState() => _LifecycleState();
}

class _LifecycleState extends State<_Lifecycle> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) widget.controller.open();
  }

  @override
  Widget build(BuildContext context) =>
      StickScope(controller: widget.controller, child: const StickApp());
}
