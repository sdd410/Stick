import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';

const _length = Duration(milliseconds: 1100);
const double _ms = 1100;

// Phases (fractions of the whole).
const _morphTo = 350 / _ms;
const _dotFrom = 150 / _ms, _dotTo = 670 / _ms;
const _wordFrom = 360 / _ms, _wordTo = 720 / _ms;
const _holdAt = 900 / _ms; // last full frame before the fade

const double _splash = 160; // Android 12+ splash circle, in dp
const double _tileEnd = 120; // tile size next to the word
const double _gap = 16;
const _wordStyle = TextStyle(
  fontFamily: 'ArchivoBlack',
  fontSize: 44,
  color: StickColors.lime,
);

/// Option A, "Morph & drop": starts exactly like Android's splash (a lime
/// circle with "S."), the circle turns into the rounded tile, the dot hops
/// and bounces back into place, STICK slides in, then it fades out and calls
/// [onDone] once. While [waiting] (the app is still loading) it holds the
/// full logo instead of fading to a blank screen. A tap skips it; with
/// animations off it ends at once.
class LogoIntro extends StatefulWidget {
  const LogoIntro({super.key, required this.onDone, this.waiting = false});

  final VoidCallback onDone;
  final bool waiting;

  @override
  State<LogoIntro> createState() => _LogoIntroState();
}

class _LogoIntroState extends State<LogoIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: _length,
  );
  bool _finished = false;
  bool _landed = false;
  bool _skipped = false;

  late final Animation<double> _pop =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.08), weight: 55),
        TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 45),
      ]).animate(
        CurvedAnimation(
          parent: _c,
          curve: const Interval(0, _morphTo, curve: Curves.easeOut),
        ),
      );
  late final Animation<double> _morph = CurvedAnimation(
    parent: _c,
    curve: const Interval(0, _morphTo, curve: Curves.easeInOut),
  );
  // The dot hops up and bounces back down into place.
  late final Animation<double> _hop =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -46.0), weight: 35),
        TweenSequenceItem(
          tween: Tween(
            begin: -46.0,
            end: 0.0,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 35,
        ),
        TweenSequenceItem(tween: Tween(begin: 0.0, end: -9.0), weight: 15),
        TweenSequenceItem(tween: Tween(begin: -9.0, end: 0.0), weight: 15),
      ]).animate(
        CurvedAnimation(parent: _c, curve: const Interval(_dotFrom, _dotTo)),
      );
  late final Animation<double> _word = CurvedAnimation(
    parent: _c,
    curve: const Interval(_wordFrom, _wordTo, curve: Curves.easeOutCubic),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _c,
    curve: const Interval(_holdAt, 1),
  );

  @override
  void initState() {
    super.initState();
    _c
      ..addListener(_onTick)
      ..addStatusListener((s) {
        if (s != AnimationStatus.completed) return;
        if (widget.waiting) {
          // A long frame jumped past the hold: go back and wait there.
          _c.value = _holdAt;
        } else {
          _finish();
        }
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_c.isAnimating || _finished || _c.value > 0) return;
    if (MediaQuery.disableAnimationsOf(context)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _finish());
    } else {
      _c.forward();
    }
  }

  @override
  void didUpdateWidget(LogoIntro old) {
    super.didUpdateWidget(old);
    // Loading finished while holding: play the fade now.
    if (old.waiting && !widget.waiting && !_c.isAnimating && !_finished) {
      if (_skipped) {
        _finish();
      } else {
        _c.forward();
      }
    }
  }

  void _onTick() {
    if (!_landed && _c.value >= _dotFrom + (_dotTo - _dotFrom) * 0.7) {
      _landed = true;
      HapticFeedback.lightImpact();
    }
    // Stop first: setting the value notifies this listener again, and a
    // stopped controller does not re-enter here.
    if (widget.waiting && _c.isAnimating && _c.value >= _holdAt) {
      _c.stop();
      _c.value = _holdAt;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _skip() {
    if (widget.waiting) {
      // Still loading: jump to the full logo and wait there.
      _skipped = true;
      _c
        ..stop()
        ..value = _holdAt;
      return;
    }
    _finish();
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _c.stop();
    widget.onDone();
  }

  double _wordWidth() {
    final tp = TextPainter(
      text: const TextSpan(text: 'STICK', style: _wordStyle),
      textDirection: TextDirection.ltr,
      textScaler: TextScaler.noScaling,
    )..layout();
    return tp.width;
  }

  @override
  Widget build(BuildContext context) {
    final ww = _wordWidth();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _skip,
      child: ColoredBox(
        color: StickColors.bg,
        child: Semantics(
          label: 'Stick',
          child: AnimatedBuilder(
            animation: _c,
            builder: (context, _) {
              final w = _word.value;
              // Tile shrinks to make room for the word; the pair ends
              // centred on screen.
              final size = _splash + (_tileEnd - _splash) * w;
              final total = _tileEnd + _gap + ww;
              final tileX = (-total / 2 + _tileEnd / 2) * w;
              final wordX = tileX + size / 2 + _gap + ww / 2 + 30 * (1 - w);
              final radius = (_splash / 2) - (_splash / 2 - 36) * _morph.value;
              return Opacity(
                opacity: 1 - _fade.value,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Center(
                      child: Transform.translate(
                        offset: Offset(tileX, 0),
                        child: Transform.scale(
                          scale: _pop.value * (size / _splash),
                          child: _tile(radius),
                        ),
                      ),
                    ),
                    if (_c.value >= _wordFrom)
                      Center(
                        child: Transform.translate(
                          offset: Offset(wordX, 0),
                          child: Opacity(
                            opacity: w,
                            child: const Text('STICK', style: _wordStyle),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tile(double radius) => Container(
    key: const Key('intro-tile'),
    width: _splash,
    height: _splash,
    decoration: BoxDecoration(
      color: StickColors.lime,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        const Positioned(
          left: 34,
          top: 14,
          child: Text(
            'S',
            style: TextStyle(
              fontFamily: 'ArchivoBlack',
              fontSize: 112,
              height: 1.15,
              color: StickColors.bg,
            ),
          ),
        ),
        Positioned(
          right: 34,
          bottom: 40,
          child: Transform.translate(
            offset: Offset(0, _hop.value),
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
        ),
      ],
    ),
  );
}
