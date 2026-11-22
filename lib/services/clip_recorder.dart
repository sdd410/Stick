import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import '../domain/models.dart';

const maxClip = Duration(seconds: 15);

/// Shorter recordings are discarded.
const minClip = Duration(milliseconds: 800);

enum PermissionResult { granted, denied, permanentlyDenied }

class RecordedClip {
  const RecordedClip({required this.path, required this.durationMs});
  final String path;
  final int durationMs;
}

/// Everything the record screen needs from the platform, so tests can fake it.
abstract class ClipRecorder {
  Future<PermissionResult> ensurePermission(ClipType t);

  /// Gets the camera ready so [buildPreview] can show it (video only).
  Future<void> prepare(ClipType t);

  Future<void> start(ClipType t, String path);

  /// Stops and returns the clip, or null (file deleted) when it is shorter
  /// than [minClip] or the recording failed.
  Future<RecordedClip?> stop();

  /// Ticks while recording.
  Stream<Duration> get elapsed;

  /// Voice level, 0..1, while recording.
  Stream<double> get level;

  Widget buildPreview(BuildContext context);

  /// Frees the camera and microphone.
  Future<void> release();
}

class DeviceClipRecorder implements ClipRecorder {
  AudioRecorder? _audio;
  CameraController? _camera;
  ClipType? _type;
  String? _path;
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  StreamSubscription<Amplitude>? _ampSub;
  final _elapsed = StreamController<Duration>.broadcast();
  final _level = StreamController<double>.broadcast();

  @override
  Stream<Duration> get elapsed => _elapsed.stream;

  @override
  Stream<double> get level => _level.stream;

  @override
  Future<PermissionResult> ensurePermission(ClipType t) async {
    final needed = [
      Permission.microphone,
      if (t == ClipType.video) Permission.camera,
    ];
    final results = await needed.request();
    final all = results.values;
    if (all.every((s) => s.isGranted)) return PermissionResult.granted;
    if (all.any((s) => s.isPermanentlyDenied)) {
      return PermissionResult.permanentlyDenied;
    }
    return PermissionResult.denied;
  }

  @override
  Future<void> prepare(ClipType t) async {
    if (t != ClipType.video) return;
    final cameras = await availableCameras();
    if (cameras.isEmpty) throw StateError('No camera');
    final cam = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      cam,
      ResolutionPreset.high,
      enableAudio: true,
    );
    _camera = controller;
    await controller.initialize();
  }

  @override
  Widget buildPreview(BuildContext context) {
    final c = _camera;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    return CameraPreview(c);
  }

  @override
  Future<void> start(ClipType t, String path) async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    _type = t;
    _path = path;
    if (t == ClipType.voice) {
      final audio = _audio ??= AudioRecorder();
      await audio.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );
      _ampSub = audio
          .onAmplitudeChanged(const Duration(milliseconds: 100))
          .listen((a) {
            // dBFS -50..0 mapped to 0..1.
            _level.add(((a.current + 50) / 50).clamp(0.0, 1.0));
          });
    } else {
      final cam = _camera;
      if (cam == null || !cam.value.isInitialized) {
        throw StateError('Camera not ready');
      }
      await cam.startVideoRecording();
    }
    _stopwatch
      ..reset()
      ..start();
    _ticker = Timer.periodic(
      const Duration(milliseconds: 100),
      (_) => _elapsed.add(_stopwatch.elapsed),
    );
  }

  @override
  Future<RecordedClip?> stop() async {
    final type = _type;
    final path = _path;
    if (type == null || path == null) return null;
    _type = null;
    _path = null;
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    _stopwatch.stop();
    final ms = _stopwatch.elapsedMilliseconds;
    try {
      if (type == ClipType.voice) {
        await _audio?.stop();
      } else {
        final cam = _camera;
        if (cam == null) return null;
        final xfile = await cam.stopVideoRecording();
        await xfile.saveTo(path);
        try {
          await File(xfile.path).delete();
        } catch (_) {}
      }
    } catch (e, st) {
      // Interrupted (call, camera taken away): never keep a half-written file.
      debugPrint('stop failed: $e\n$st');
      await _discard(path);
      return null;
    }
    final file = File(path);
    if (ms < minClip.inMilliseconds ||
        !file.existsSync() ||
        file.lengthSync() == 0) {
      await _discard(path);
      return null;
    }
    return RecordedClip(path: path, durationMs: ms);
  }

  Future<void> _discard(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }

  @override
  Future<void> release() async {
    _ticker?.cancel();
    _ticker = null;
    await _ampSub?.cancel();
    _ampSub = null;
    final audio = _audio;
    _audio = null;
    final cam = _camera;
    _camera = null;
    try {
      await audio?.dispose();
    } catch (_) {}
    try {
      await cam?.dispose();
    } catch (_) {}
  }
}
