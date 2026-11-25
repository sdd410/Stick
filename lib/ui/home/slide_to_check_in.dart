import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme.dart';

const double _height = 64;
const double _pad = 6;
const double _knob = _height - 2 * _pad;

/// Fraction of the way at which the slide locks in.
const double _lockAt = 0.8;
const List<double> _ticks = [0.25, 0.5, 0.75];

/// The Home check-in: drag the lime knob to the right. Ticks on the way,
/// a firm tap when it locks, and [onDone] exactly once.
class SlideToCheckIn extends StatefulWidget {
  const SlideToCheckIn({
    super.key,
    required this.onDone,
    this.onLongPress,
    this.label = 'Slide when done',
  });

  /// Null disables the slide (already done, or busy).
  final VoidCallback? onDone;
  final VoidCallback? onLongPress;
  final String label;

  @override
  State<SlideToCheckIn> createState() => _SlideToCheckInState();
}

class _SlideToCheckInState extends State<SlideToCheckIn>
    with TickerProviderStateMixin {
  double _dx = 0;
  double _max = 1;
  bool _locked = false;
  final Set<double> _ticked = {};

  late final AnimationController _back = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 250),
  )..addListener(() => setState(() => _dx = _backFrom * (1 - _back.value)));
  double _backFrom = 0;

  late final AnimationController _glow = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
  );

  bool get _enabled => widget.onDone != null;

  bool get _noMotion => MediaQuery.disableAnimationsOf(context);

  @override
  void didUpdateWidget(SlideToCheckIn old) {
    super.didUpdateWidget(old);
    // A new day: the slide becomes usable again.
    if (old.onDone == null && widget.onDone != null) {
      _locked = false;
      _dx = 0;
      _ticked.clear();
    }
  }

  @override
  void dispose() {
    _back.dispose();
    _glow.dispose();
    super.dispose();
  }

  void _onUpdate(DragUpdateDetails d) {
    if (!_enabled || _locked) return;
    _back.stop();
    setState(() => _dx = (_dx + d.delta.dx).clamp(0, _max));
    final f = _dx / _max;
    for (final t in _ticks) {
      if (f >= t && _ticked.add(t)) HapticFeedback.selectionClick();
    }
    if (f >= _lockAt) _lock();
  }

  void _onEnd(DragEndDetails _) {
    if (_locked || _dx == 0) return;
    _ticked.clear();
    if (_noMotion) {
      setState(() => _dx = 0);
      return;
    }
    _backFrom = _dx;
    _back.forward(from: 0);
  }

  void _lock() {
    if (_locked || !_enabled) return;
    setState(() {
      _locked = true;
      _dx = _max;
    });
    HapticFeedback.mediumImpact();
    if (!_noMotion) _glow.forward(from: 0);
    widget.onDone!();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    enabled: _enabled && !_locked,
    label: _enabled ? 'Done today' : widget.label,
    onTap: _enabled && !_locked ? _lock : null,
    child: ExcludeSemantics(
      child: GestureDetector(
        onLongPress: widget.onLongPress,
        child: LayoutBuilder(
          builder: (context, c) {
            _max = (c.maxWidth - _knob - 2 * _pad).clamp(1, double.infinity);
            final f = _locked ? 1.0 : _dx / _max;
            final showCheck = _locked || !_enabled;
            return AnimatedBuilder(
              animation: _glow,
              builder: (context, child) => Container(
                height: _height,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B25),
                  borderRadius: BorderRadius.circular(_height / 2),
                  boxShadow: [
                    if (_glow.isAnimating)
                      BoxShadow(
                        color: StickColors.lime.withValues(
                          alpha: 0.45 * (1 - _glow.value),
                        ),
                        blurRadius: 24 * _glow.value + 4,
                        spreadRadius: 6 * _glow.value,
                      ),
                  ],
                ),
                child: child,
              ),
              child: Stack(
                children: [
                  // Lime fill behind the knob.
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: _dx + _knob + 2 * _pad,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: StickColors.lime.withValues(
                          alpha: _locked ? 0.35 : 0.25 * f,
                        ),
                        borderRadius: BorderRadius.circular(_height / 2),
                      ),
                    ),
                  ),
                  Center(
                    child: Opacity(
                      opacity: _enabled ? (1 - f * 1.4).clamp(0, 1) : 1,
                      child: Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          fontVariations: const [FontVariation('wght', 600)],
                          color: _enabled
                              ? StickColors.muted
                              : Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: _pad + _dx,
                    top: _pad,
                    child: GestureDetector(
                      key: const Key('slide-knob'),
                      onHorizontalDragUpdate: _onUpdate,
                      onHorizontalDragEnd: _onEnd,
                      child: Container(
                        width: _knob,
                        height: _knob,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _enabled || _locked
                              ? StickColors.lime
                              : const Color(0xFF2A2A36),
                        ),
                        child: Icon(
                          showCheck
                              ? Icons.check_rounded
                              : Icons.arrow_forward_rounded,
                          color: _enabled || _locked
                              ? StickColors.bg
                              : StickColors.muted,
                        ),
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
