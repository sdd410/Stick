import 'package:flutter/material.dart';

import 'controller/stick_scope.dart';
import 'theme.dart';
import 'ui/home/home_screen.dart';
import 'ui/setup/setup_flow.dart';

class StickApp extends StatelessWidget {
  const StickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stick',
      debugShowCheckedModeBanner: false,
      theme: stickTheme(),
      home: const _Root(),
    );
  }
}

class _Root extends StatelessWidget {
  const _Root();

  @override
  Widget build(BuildContext context) {
    final c = StickScope.of(context);
    if (!c.loaded) return const Scaffold();
    if (c.needsSetup) return const SetupFlow();
    return const HomeScreen();
  }
}
