import 'package:flutter/material.dart';

import '../../theme.dart';

const _length = Duration(milliseconds: 800);

/// Cold-start logo: the lime S tile pops, the dot drops in with a bounce,
/// "STICK" slides in, then it fades out and calls [onDone] once. A tap
/// skips it; with animations off it ends at once.
class LogoIntro extends StatefulWidget {
  const LogoIntro({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  State<LogoIntro> createState() => _LogoIntroState();
}

class _LogoIntroState extends State<LogoIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: _length)
        ..addStatusListener((s) {
          if (s == AnimationStatus.completed) _finish();
        });
  bool _finished = false;

  // Phases, as fractions of 800 ms.
  static const _dotFrom = 250 / 800, _dotTo = 550 / 800;
  static const _wordFrom = 450 / 800, _wordTo = 750 / 800;
  static const _fadeFrom = 700 / 800;

  late final Animation<double> _tile =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.05), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 1.05, end: 1.0), weight: 40),
      ]).animate(
        CurvedAnimation(
          parent: _c,
          curve: const Interval(0, 300 / 800, curve: Curves.easeOut),
        ),
      );
  late final Animation<double> _dot = CurvedAnimation(
    parent: _c,
    curve: const Interval(_dotFrom, _dotTo, curve: Curves.bounceOut),
  );
  late final Animation<double> _word = CurvedAnimation(
    parent: _c,
    curve: const Interval(_wordFrom, _wordTo, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(_fadeFrom, 1),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _finished || _c.isCompleted) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _c.forward();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _c.stop();
    widget.onDone();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: _finish,
    child: ColoredBox(
      color: StickColors.bg,
      child: Semantics(
        label: 'Stick',
        child: AnimatedBuilder(
          animation: _c,
          builder: (context, _) => Opacity(
            opacity: 1 - _fade.value,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: FittedBox(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.scale(scale: _tile.value, child: _tileView()),
                      if (_c.value >= _wordFrom) ...[
                        const SizedBox(width: 18),
                        Opacity(
                          opacity: _word.value,
                          child: Transform.translate(
                            offset: Offset(40 * (1 - _word.value), 0),
                            child: const Text(
                              'STICK',
                              style: TextStyle(
                                fontFamily: 'ArchivoBlack',
                                fontSize: 52,
                                color: StickColors.lime,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  Widget _tileView() => Container(
    width: 140,
    height: 140,
    decoration: BoxDecoration(
      color: StickColors.lime,
      borderRadius: BorderRadius.circular(32),
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 22,
          top: 4,
          child: Text(
            'S',
            style: TextStyle(
              fontFamily: 'ArchivoBlack',
              fontSize: 104,
              height: 1.15,
              color: StickColors.bg,
            ),
          ),
        ),
        if (_c.value >= _dotFrom)
          Positioned(
            right: 20,
            // Drops from above the tile to its resting spot.
            bottom: 30 + 90 * (1 - _dot.value),
            child: Container(
              key: const Key('intro-dot'),
              width: 22,
              height: 22,
              decoration: const BoxDecoration(
                color: StickColors.bg,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    ),
  );
}
