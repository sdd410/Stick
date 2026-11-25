import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/week_strip.dart';
import '../../theme.dart';

/// Mon–Sun at the top of Home: lime check for a check-in, a dashed ring for
/// today. Missed days look like future days.
class WeekStripView extends StatelessWidget {
  const WeekStripView({super.key, required this.days});

  final List<WeekDay> days;

  @override
  Widget build(BuildContext context) {
    final done = days.where((d) => d.state != WeekDayState.other).length;
    return Semantics(
      label: 'This week: $done of 7 days',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [for (final d in days) _Day(day: d)],
        ),
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day});

  final WeekDay day;

  @override
  Widget build(BuildContext context) {
    final noMotion = MediaQuery.disableAnimationsOf(context);
    final filled =
        day.state == WeekDayState.done || day.state == WeekDayState.todayDone;
    final circle = Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? StickColors.lime : null,
        border: day.state == WeekDayState.other
            ? Border.all(color: const Color(0xFF2C2C3A), width: 2)
            : null,
      ),
      child: filled
          ? const Icon(Icons.check_rounded, size: 18, color: StickColors.bg)
          : null,
    );
    final Widget dot = switch (day.state) {
      WeekDayState.today => CustomPaint(
        painter: _DashedRing(),
        child: SizedBox(
          width: 34,
          height: 34,
          child: Center(
            child: Text(
              '${int.parse(day.day.substring(8))}',
              style: const TextStyle(
                color: StickColors.lime,
                fontWeight: FontWeight.w800,
                fontVariations: [FontVariation('wght', 800)],
              ),
            ),
          ),
        ),
      ),
      // Today just checked in: a small pop as it fills.
      WeekDayState.todayDone => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: noMotion ? Duration.zero : const Duration(milliseconds: 500),
        builder: (_, v, child) {
          final t = ((v - 0.2) / 0.8).clamp(0.0, 1.0);
          return Transform.scale(
            scale: 1 + 0.15 * math.sin(math.pi * t),
            child: child,
          );
        },
        child: circle,
      ),
      _ => circle,
    };
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          day.letter,
          style: const TextStyle(fontSize: 12, color: StickColors.muted),
        ),
        const SizedBox(height: 6),
        dot,
      ],
    );
  }
}

class _DashedRing extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = StickColors.lime
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final r = size.width / 2 - 1;
    const n = 12;
    for (var i = 0; i < n; i++) {
      final a = 2 * math.pi * i / n;
      canvas.drawArc(
        Rect.fromCircle(center: size.center(Offset.zero), radius: r),
        a,
        math.pi / n,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRing oldDelegate) => false;
}
