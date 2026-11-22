import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Live voice bars (newest on the right) under a mic whose ring follows the voice level.
class VoiceLevelView extends StatefulWidget {
  const VoiceLevelView({super.key, required this.level});

  final Stream<double> level;

  @override
  State<VoiceLevelView> createState() => _VoiceLevelViewState();
}

class _VoiceLevelViewState extends State<VoiceLevelView> {
  static const _count = 30;
  static const _minH = 4.0;
  static const _maxH = 56.0;

  final List<double> _levels = List<double>.filled(_count, 0, growable: true);
  StreamSubscription<double>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = _listen();
  }

  StreamSubscription<double> _listen() => widget.level.listen((v) {
    if (!mounted) return;
    setState(() {
      _levels
        ..removeAt(0)
        ..add(v.isNaN ? 0.0 : v.clamp(0.0, 1.0));
    });
  });

  @override
  void didUpdateWidget(VoiceLevelView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _sub?.cancel();
      _sub = _listen();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final lvl = _levels.last;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (!reduced)
                AnimatedOpacity(
                  opacity: 0.15 + 0.7 * lvl,
                  duration: const Duration(milliseconds: 100),
                  child: AnimatedScale(
                    scale: 0.72 + 0.28 * lvl,
                    duration: const Duration(milliseconds: 100),
                    child: Container(
                      key: const Key('voice-ring'),
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: StickColors.lime, width: 2),
                      ),
                    ),
                  ),
                ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: StickColors.lime.withValues(alpha: 0.25),
                ),
                child: const Icon(Icons.mic, size: 32, color: StickColors.lime),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: _maxH,
          child: RepaintBoundary(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < _count; i++) ...[
                  if (i > 0) const SizedBox(width: 3),
                  AnimatedContainer(
                    key: Key('voice-bar-$i'),
                    duration: reduced
                        ? Duration.zero
                        : const Duration(milliseconds: 90),
                    width: 4,
                    height: _minH + (_maxH - _minH) * _levels[i],
                    decoration: BoxDecoration(
                      color: StickColors.lime.withValues(
                        alpha: i < _count ~/ 3 ? 0.55 : 1,
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
