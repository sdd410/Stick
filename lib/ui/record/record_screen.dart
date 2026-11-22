import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../controller/stick_scope.dart';
import '../../domain/models.dart';
import '../../services/clip_files.dart';
import '../../services/clip_recorder.dart';
import '../../theme.dart';
import 'voice_level_view.dart';

enum _Phase { choose, working, blocked, ready, recording, review }

/// Records one voice or video message. Pops `true` when a clip was kept.
class RecordScreen extends StatefulWidget {
  const RecordScreen({
    super.key,
    required this.recorder,
    required this.files,
    Future<bool> Function()? openSettings,
  }) : openSettings = openSettings ?? openAppSettings;

  final ClipRecorder recorder;
  final ClipFiles files;
  final Future<bool> Function() openSettings;

  @override
  State<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends State<RecordScreen>
    with WidgetsBindingObserver {
  _Phase _phase = _Phase.choose;
  ClipType _type = ClipType.voice;
  PermissionResult _permission = PermissionResult.denied;
  Duration _elapsed = Duration.zero;
  RecordedClip? _clip;
  String? _path;
  String? _notice;
  bool _stopping = false;
  bool _starting = false;
  bool _saving = false;
  // Only a return from system settings re-checks; the permission dialog also
  // pauses and resumes the activity and must not trigger a second prompt.
  bool _sentToSettings = false;
  StreamSubscription<Duration>? _sub;

  ClipRecorder get _rec => widget.recorder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _sub?.cancel();
    _cleanUp();
    super.dispose();
  }

  /// Leaving the screen: stop anything running, drop unkept files, free the
  /// camera and microphone.
  Future<void> _cleanUp() async {
    final wasRecording = _phase == _Phase.recording;
    final pending = _clip?.path ?? (wasRecording ? _path : null);
    try {
      if (wasRecording) await _rec.stop();
    } catch (_) {}
    if (pending != null) {
      try {
        await widget.files.delete(pending);
      } catch (_) {}
    }
    try {
      await _rec.release();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if ((state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive) &&
        _phase == _Phase.recording) {
      _stop();
    } else if (state == AppLifecycleState.resumed &&
        _phase == _Phase.blocked &&
        _sentToSettings) {
      // The user may have granted it in system settings.
      _sentToSettings = false;
      _recheckAfterSettings();
    }
  }

  /// Reads the permission state (never prompts) and carries on if it is now
  /// granted.
  Future<void> _recheckAfterSettings() async {
    final type = _type;
    try {
      final status = await _rec.permissionStatus(type);
      if (!mounted || _phase != _Phase.blocked) return;
      if (status == PermissionResult.granted) {
        await _choose(type);
      } else {
        setState(() => _permission = status);
      }
    } catch (e) {
      debugPrint('permission re-check failed: $e');
    }
  }

  Future<void> _choose(ClipType t) async {
    setState(() {
      _type = t;
      _phase = _Phase.working;
      _notice = null;
    });
    try {
      final result = await _rec.ensurePermission(t);
      if (!mounted) return;
      if (result != PermissionResult.granted) {
        setState(() {
          _permission = result;
          _phase = _Phase.blocked;
        });
        return;
      }
      await _rec.prepare(t);
      if (!mounted) return;
      setState(() => _phase = _Phase.ready);
    } catch (e) {
      debugPrint('prepare failed: $e');
      if (!mounted) return;
      setState(() {
        _phase = _Phase.choose;
        _notice =
            "Couldn't start the ${t == ClipType.voice ? 'microphone' : 'camera'}. Try again.";
      });
    }
  }

  Future<void> _start() async {
    if (_starting || _phase != _Phase.ready) return;
    _starting = true;
    try {
      await _startRecording();
    } finally {
      _starting = false;
    }
  }

  Future<void> _startRecording() async {
    final path = widget.files.newPath(_type, DateTime.now());
    _path = path;
    try {
      await _rec.start(_type, path);
    } catch (e) {
      debugPrint('start failed: $e');
      await widget.files.delete(path);
      if (!mounted) return;
      setState(() => _notice = "Couldn't start recording. Try again.");
      return;
    }
    if (!mounted) {
      return;
    }
    _stopping = false;
    _sub = _rec.elapsed.listen((d) {
      if (!mounted) return;
      setState(() => _elapsed = d);
      if (d >= maxClip) _stop();
    });
    setState(() {
      _elapsed = Duration.zero;
      _phase = _Phase.recording;
      _notice = null;
    });
  }

  Future<void> _stop() async {
    if (_stopping || _phase != _Phase.recording) return;
    _stopping = true;
    unawaited(_sub?.cancel());
    _sub = null;
    RecordedClip? clip;
    try {
      clip = await _rec.stop();
    } catch (e) {
      debugPrint('stop failed: $e');
    }
    // Never keep a clip shorter than the minimum, even if the recorder did.
    if (clip != null && clip.durationMs < minClip.inMilliseconds) {
      await widget.files.delete(clip.path);
      clip = null;
    }
    if (!mounted) return;
    if (clip == null) {
      final p = _path;
      if (p != null) await widget.files.delete(p);
      _path = null;
      if (!mounted) return;
      setState(() {
        _phase = _Phase.ready;
        _notice = 'Too short. Try again.';
      });
      return;
    }
    setState(() {
      _clip = clip;
      _phase = _Phase.review;
    });
  }

  Future<void> _redo() async {
    if (_saving) return;
    final clip = _clip;
    _clip = null;
    if (clip != null) await widget.files.delete(clip.path);
    if (!mounted) return;
    setState(() {
      _phase = _Phase.ready;
      _notice = null;
    });
  }

  Future<void> _keep() async {
    final clip = _clip;
    if (clip == null || _saving) return;
    setState(() => _saving = true);
    final controller = StickScope.of(context);
    final nav = Navigator.of(context);
    try {
      await controller.addClip(_type, clip.path, clip.durationMs);
    } catch (e) {
      debugPrint('addClip failed: $e');
      if (!mounted) return;
      setState(() {
        _saving = false;
        _notice = "Couldn't save that. Try again.";
      });
      return;
    }
    _clip = null; // kept: do not delete on leaving
    if (mounted) nav.pop(true);
  }

  String get _blockedText {
    final what = _type == ClipType.voice
        ? 'the microphone'
        : 'the camera and microphone';
    return 'Stick needs $what to record. Nothing leaves your phone.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Widget body;
    switch (_phase) {
      case _Phase.choose:
        body = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Record one for future you.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'Up to 15 seconds.',
              textAlign: TextAlign.center,
              style: TextStyle(color: StickColors.muted),
            ),
            if (_notice != null) ...[
              const SizedBox(height: 12),
              Text(_notice!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => _choose(ClipType.voice),
              style: _bigButton,
              child: const Text('Voice'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => _choose(ClipType.video),
              style: _bigButton,
              child: const Text('Video'),
            ),
          ],
        );
      case _Phase.working:
        body = const Center(child: CircularProgressIndicator());
      case _Phase.blocked:
        body = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _blockedText,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () async {
                _sentToSettings = true;
                try {
                  await widget.openSettings();
                } catch (e) {
                  debugPrint('openSettings failed: $e');
                }
              },
              style: _bigButton,
              child: const Text('Open settings'),
            ),
            if (_permission == PermissionResult.denied)
              TextButton(
                onPressed: () => _choose(_type),
                child: const Text('Try again'),
              ),
          ],
        );
      case _Phase.ready:
      case _Phase.recording:
        body = _recordBody(theme);
      case _Phase.review:
        body = Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${((_clip?.durationMs ?? 0) / 1000).toStringAsFixed(1)} s '
              '${_type == ClipType.voice ? 'voice' : 'video'} message',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            if (_notice != null) ...[
              const SizedBox(height: 12),
              Text(_notice!, textAlign: TextAlign.center),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _saving ? null : _keep,
              style: _bigButton,
              child: const Text('Keep'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _saving ? null : _redo,
              style: _bigButton,
              child: const Text('Redo'),
            ),
          ],
        );
    }
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: Padding(padding: const EdgeInsets.all(24), child: body),
      ),
    );
  }

  static final _bigButton = FilledButton.styleFrom(
    minimumSize: const Size.fromHeight(56),
  );

  Widget _recordBody(ThemeData theme) {
    final recording = _phase == _Phase.recording;
    final progress = (_elapsed.inMilliseconds / maxClip.inMilliseconds).clamp(
      0.0,
      1.0,
    );
    final left = (maxClip - _elapsed).inSeconds.clamp(0, 15);
    return Column(
      children: [
        Expanded(
          child: _type == ClipType.video
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Center(child: _rec.buildPreview(context)),
                )
              : Center(
                  child: VoiceLevelView(
                    key: ValueKey(_path),
                    level: _rec.level,
                  ),
                ),
        ),
        if (_notice != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_notice!),
          ),
        Text(
          recording ? '${left}s' : '15s max',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: 96,
          height: 96,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: recording ? progress : 0,
                  strokeWidth: 4,
                  backgroundColor: StickColors.muted.withValues(alpha: 0.4),
                ),
              ),
              GestureDetector(
                key: const Key('record-button'),
                onTap: recording ? _stop : _start,
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: StickColors.lime,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: recording
                      ? Container(
                          key: const Key('stop-square'),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: StickColors.bg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
