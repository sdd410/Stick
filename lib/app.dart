import 'package:flutter/material.dart';

import 'theme.dart';

class StickApp extends StatelessWidget {
  const StickApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stick',
      debugShowCheckedModeBanner: false,
      theme: stickTheme(),
      home: const Scaffold(body: Center(child: Text('Stick'))),
    );
  }
}
