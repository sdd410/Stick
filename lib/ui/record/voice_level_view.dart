import 'dart:async';

import 'package:flutter/material.dart';

import '../../theme.dart';

/// Live voice bars (newest on the right) under a mic with a pulsing ring.
class VoiceLevelView extends StatefulWidget {
  const VoiceLevelView({super.key, required this.level});

  final Stream<double> level;

  @override
  State<VoiceLevelView> createState() => _VoiceLevelViewState();
}

class _VoiceLevelViewState extends State<VoiceLevelView>
    with SingleTickerProviderStateMixin {
  static const _count = 30;
  static const _minH = 4.0;
  static const _maxH = 56.0;

  final List<double> _levels = List<double>.filled(_count, 0, growable: true);
  StreamSubscription<double>? _sub;
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );
  bool _pulsing = false;

  @override
  void initState() {
    super.initState();
    _sub = widget.level.listen((v) {
      if (!mounted) return;
      setState(() {
        _levels
          ..removeAt(0)
          ..add(v.isNaN ? 0.0 : v.clamp(0.0, 1.0));
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced && _pulsing) {
      _pulse.stop();
      _pulsing = false;
    } else if (!reduced && !_pulsing) {
      _pulse.repeat();
      _pulsing = true;
    }
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
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (context, _) {
                    final t = _pulse.value;
                    return Opacity(
                      opacity: 1 - t,
                      child: Transform.scale(
                        scale: 72 / 110 + (1 - 72 / 110) * t,
                        child: Container(
                          key: const Key('voice-ring'),
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: StickColors.lime,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              for (var i = 0; i < _count; i++) ...[
                if (i > 0) const SizedBox(width: 3),
                Opacity(
                  opacity: i < _count ~/ 3 ? 0.55 : 1,
                  child: AnimatedContainer(
                    key: Key('voice-bar-$i'),
                    duration: const Duration(milliseconds: 90),
                    width: 4,
                    height: _minH + (_maxH - _minH) * _levels[i],
                    decoration: BoxDecoration(
                      color: StickColors.lime,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
