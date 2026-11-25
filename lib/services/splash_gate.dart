import 'dart:async';

import 'package:flutter/services.dart';

/// Tells the logo intro when Android's own splash has gone (so the intro is
/// not played underneath it) and what shape the phone gives app icons
/// (Pixel: circle, Samsung: rounded square), so the intro can start from it.
abstract class SplashGate {
  /// Completes when the system splash is gone, or after a short timeout.
  Future<void> splashGone();

  /// Distance from the centre to the icon edge at 72 even angles (starting
  /// at 3 o'clock, clockwise), as a fraction of half the icon size; null
  /// when unknown.
  Future<List<double>?> iconShape();
}

/// Talks to MainActivity over the `stick/splash` channel.
class AndroidSplashGate implements SplashGate {
  AndroidSplashGate() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'splashGone' && !_gone.isCompleted) _gone.complete();
    });
  }

  static const _channel = MethodChannel('stick/splash');
  static const _timeout = Duration(milliseconds: 1500);
  final _gone = Completer<void>();

  @override
  Future<void> splashGone() async {
    try {
      if (await _channel.invokeMethod<bool>('isGone') ?? true) return;
    } catch (_) {
      return; // no native side (tests, other platforms): don't wait
    }
    await _gone.future.timeout(_timeout, onTimeout: () {});
  }

  @override
  Future<List<double>?> iconShape() async {
    try {
      final radii = await _channel.invokeListMethod<double>('iconShape');
      return (radii == null || radii.length != 72) ? null : radii;
    } catch (_) {
      return null;
    }
  }
}
