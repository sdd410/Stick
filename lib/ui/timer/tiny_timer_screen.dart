import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';

/// "Just 2 minutes.": a countdown for the tiny version. Reaching zero, or
/// Done ✓, calls [onComplete] once (the app checks the day in) and closes.
class TinyTimerScreen extends StatefulWidget {
  const TinyTimerScreen({
    super.key,
    required this.emoji,
    required this.name,
    required this.tinyText,
    required this.onComplete,
    this.length = const Duration(minutes: 2),
  });

  final String emoji;
  final String name;
  final String tinyText;
  final Future<void> Function() onComplete;
  final Duration length;

  @override
  State<TinyTimerScreen> createState() => _TinyTimerScreenState();
}

class _TinyTimerScreenState extends State<TinyTimerScreen>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker = createTicker(_onTick);

  /// Time counted before the current run (pauses split runs).
  Duration _before = Duration.zero;
  Duration _run = Duration.zero;
  bool _paused = false;
  bool _done = false;

  Duration get _elapsed => _before + _run;
  Duration get _left {
    final l = widget.length - _elapsed;
    return l.isNegative ? Duration.zero : l;
  }

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    setState(() => _run = elapsed);
    if (_left == Duration.zero) _complete();
  }

  void _togglePause() {
    setState(() {
      if (_paused) {
        _paused = false;
        _run = Duration.zero;
        _ticker.start();
      } else {
        _paused = true;
        _ticker.stop();
        _before += _run;
        _run = Duration.zero;
      }
    });
  }

  Future<void> _complete() async {
    if (_done) return;
    _done = true;
    if (_ticker.isActive) _ticker.stop();
    HapticFeedback.mediumImpact();
    await widget.onComplete();
    if (mounted) Navigator.of(context).pop();
  }

  String get _label {
    final s = (_left.inMilliseconds / 1000).ceil();
    return '${s ~/ 60}:${(s % 60).toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final progress = _elapsed.inMilliseconds / widget.length.inMilliseconds;
    final title = Theme.of(context).textTheme.headlineSmall;
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.emoji} ${widget.name}'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text.rich(
                TextSpan(
                  style: title?.copyWith(fontSize: 30),
                  children: const [
                    TextSpan(text: 'Just '),
                    TextSpan(
                      text: '2 minutes',
                      style: TextStyle(color: StickColors.lime),
                    ),
                    TextSpan(text: '.'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: CustomPaint(
                        painter: _Ring(progress.clamp(0, 1).toDouble()),
                        child: Center(
                          child: FittedBox(
                            child: Text(
                              _label,
                              style: const TextStyle(
                                fontFamily: 'ArchivoBlack',
                                fontSize: 56,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Text(
                '${widget.tinyText}.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 17),
              ),
              const SizedBox(height: 6),
              const Text(
                'If you keep going, great. If not, it still counts.',
                textAlign: TextAlign.center,
                style: TextStyle(color: StickColors.muted),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _done ? null : _togglePause,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: const StadiumBorder(),
                      ),
                      child: Text(_paused ? 'Resume' : 'Pause'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _done ? null : _complete,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(56),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Done ✓'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Ring extends CustomPainter {
  _Ring(this.progress);

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.06;
    final r = rect.deflate(stroke / 2);
    canvas.drawArc(
      r,
      0,
      2 * math.pi,
      false,
      Paint()
        ..color = const Color(0xFF22222E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    // The lime arc is the time left, shrinking clockwise from the top.
    canvas.drawArc(
      r,
      -math.pi / 2 + 2 * math.pi * progress,
      2 * math.pi * (1 - progress),
      false,
      Paint()
        ..color = StickColors.lime
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = stroke,
    );
  }

  @override
  bool shouldRepaint(covariant _Ring old) => old.progress != progress;
}
