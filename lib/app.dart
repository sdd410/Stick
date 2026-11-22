import 'package:flutter/material.dart';

import 'controller/stick_scope.dart';
import 'services/clip_files.dart';
import 'services/clip_recorder.dart';
import 'theme.dart';
import 'ui/home/home_screen.dart';
import 'ui/record/record_screen.dart';
import 'ui/setup/setup_flow.dart';

class StickApp extends StatelessWidget {
  const StickApp({super.key, this.recorder, this.files});

  /// Null hides recording (tests that do not care about it).
  final ClipRecorder? recorder;
  final ClipFiles? files;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stick',
      debugShowCheckedModeBanner: false,
      theme: stickTheme(),
      home: _Root(recorder: recorder, files: files),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root({this.recorder, this.files});

  final ClipRecorder? recorder;
  final ClipFiles? files;

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

  @override
  Widget build(BuildContext context) {
    final c = StickScope.of(context);
    if (!c.loaded) return const Scaffold();
    if (c.needsSetup) _inSetup = true;
    if (_inSetup) {
      return SetupFlow(
        onRecordFirstClip: _canRecord ? _openRecord : null,
        onFinished: () => setState(() => _inSetup = false),
      );
    }
    return HomeScreen(onAddMessage: _canRecord ? _openRecord : null);
  }
}
