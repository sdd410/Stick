import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../domain/models.dart';
import '../../theme.dart';

/// Playback behind an interface so widget tests avoid platform channels.
abstract class ClipPlayer {
  /// Throws when the file cannot be opened.
  Future<void> load(Clip clip);
  Future<void> play();
  Future<void> pause();

  /// Fires once when playback reaches the end.
  Stream<void> get completed;

  /// Full-screen content for the loaded clip.
  Widget view();
  Future<void> dispose();
}

typedef ClipPlayerFactory = ClipPlayer Function();

ClipPlayer videoPlayerClipPlayer() => VideoPlayerClipPlayer();

/// Plays .mp4 and .m4a through video_player. Voice shows a lime card.
class VideoPlayerClipPlayer implements ClipPlayer {
  VideoPlayerController? _controller;
  Clip? _clip;
  final _done = StreamController<void>.broadcast();
  bool _fired = false;
  bool _disposed = false;

  @override
  Stream<void> get completed => _done.stream;

  @override
  Future<void> load(Clip clip) async {
    final controller = VideoPlayerController.file(File(clip.path));
    _controller = controller;
    _clip = clip;
    await controller.initialize();
    if (_disposed) return;
    controller.addListener(() {
      final v = controller.value;
      if (!_fired &&
          v.isInitialized &&
          v.duration > Duration.zero &&
          v.position >= v.duration) {
        _fired = true;
        _done.add(null);
      }
    });
  }

  @override
  Future<void> play() async => _controller?.play();

  @override
  Future<void> pause() async => _controller?.pause();

  @override
  Widget view() {
    final controller = _controller!;
    final clip = _clip!;
    if (clip.type == ClipType.voice) {
      return Container(
        margin: const EdgeInsets.fromLTRB(24, 120, 24, 120),
        decoration: BoxDecoration(
          color: StickColors.lime,
          borderRadius: BorderRadius.circular(28),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.graphic_eq, size: 96, color: StickColors.bg),
            const SizedBox(height: 16),
            Text(
              'Day ${clip.dayNumber}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.w800,
                color: StickColors.bg,
              ),
            ),
          ],
        ),
      );
    }
    return Center(
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: VideoPlayer(controller),
      ),
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _controller?.dispose();
    await _done.close();
  }
}
