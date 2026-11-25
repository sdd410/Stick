import 'package:flutter/material.dart';

import '../../theme.dart';

/// Card fill used across onboarding.
const Color _card = Color(0xFF16161F);

/// One onboarding screen: back arrow, progress bar, optional Skip, a big
/// title, a scrolling body and one big button pinned at the bottom.
class StepScaffold extends StatelessWidget {
  const StepScaffold({
    super.key,
    required this.title,
    this.highlight,
    required this.progress,
    required this.body,
    required this.buttonLabel,
    required this.onButton,
    this.onBack,
    this.onSkip,
    this.below,
    this.floating,
  });

  final String title;

  /// A substring of [title] drawn in lime.
  final String? highlight;

  /// 0..1 for the progress bar.
  final double progress;
  final Widget body;

  /// Null hides the bottom button (the step picks some other way).
  final String? buttonLabel;

  /// Null disables the bottom button.
  final VoidCallback? onButton;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;

  /// Shown under the button, e.g. "Skip recording".
  final Widget? below;

  /// Floats over the bottom of the body, e.g. "My own habit".
  final Widget? floating;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 48,
              child: Row(
                children: [
                  if (onBack != null)
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, size: 18),
                      tooltip: 'Back',
                      color: StickColors.muted,
                      onPressed: onBack,
                    )
                  else
                    const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: progress.clamp(0, 1).toDouble(),
                        minHeight: 6,
                        color: StickColors.lime,
                        backgroundColor: const Color(0xFF262633),
                      ),
                    ),
                  ),
                  if (onSkip != null)
                    TextButton(
                      onPressed: onSkip,
                      style: TextButton.styleFrom(
                        foregroundColor: StickColors.muted,
                      ),
                      child: const Text('Skip'),
                    )
                  else
                    const SizedBox(width: 16),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        8,
                        16,
                        8,
                        floating == null ? 16 : 88,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _Title(title: title, highlight: highlight),
                          const SizedBox(height: 20),
                          body,
                        ],
                      ),
                    ),
                  ),
                  if (floating != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 12,
                      child: Center(child: floating),
                    ),
                ],
              ),
            ),
            if (buttonLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton(
                  onPressed: onButton,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                    shape: const StadiumBorder(),
                    disabledBackgroundColor: const Color(0xFF2A2A36),
                    disabledForegroundColor: const Color(0xFF666670),
                    textStyle: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      fontVariations: [FontVariation('wght', 700)],
                    ),
                  ),
                  child: Text(buttonLabel!),
                ),
              ),
            ?below,
          ],
        ),
      ),
    ),
  );
}

class _Title extends StatelessWidget {
  const _Title({required this.title, this.highlight});

  final String title;
  final String? highlight;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.headlineSmall
        ?.copyWith(fontSize: 27, height: 1.15);
    final h = highlight;
    final i = h == null ? -1 : title.indexOf(h);
    if (h == null || i < 0) return Text(title, style: style);
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          TextSpan(text: title.substring(0, i)),
          TextSpan(
            text: h,
            style: const TextStyle(color: StickColors.lime),
          ),
          TextSpan(text: title.substring(i + h.length)),
        ],
      ),
    );
  }
}

/// A big tappable answer with an emoji; lime border and check when picked.
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.emoji,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? const Color(0xFF1B2210) : _card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: selected ? StickColors.lime : Colors.transparent,
            width: 2,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Text(emoji, style: const TextStyle(fontSize: 22)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontVariations: [FontVariation('wght', 600)],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: selected ? StickColors.lime : null,
                    border: Border.all(
                      color: selected
                          ? StickColors.lime
                          : const Color(0xFF3A3A48),
                      width: 2,
                    ),
                  ),
                  child: selected
                      ? const Icon(Icons.check, size: 15, color: StickColors.bg)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// The "Day 3 is the wall" drawing: motivation drops to day 3, then rises.
class WallChart extends StatelessWidget {
  const WallChart({super.key});

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Motivation drops until day 3, then gets easier',
    child: const AspectRatio(
      aspectRatio: 316 / 250,
      child: CustomPaint(painter: _WallPainter()),
    ),
  );
}

class _WallPainter extends CustomPainter {
  const _WallPainter();

  static const _red = Color(0xFFFF5A5A);

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in a 316x250 box, scaled to fit.
    final sx = size.width / 316, sy = size.height / 250;
    Offset p(double x, double y) => Offset(x * sx, y * sy);

    canvas.drawLine(
      p(20, 220),
      p(306, 220),
      Paint()
        ..color = const Color(0xFF2C2C3A)
        ..strokeWidth = 2,
    );
    final curve = Path()
      ..moveTo(p(20, 60).dx, p(20, 60).dy)
      ..cubicTo(60 * sx, 70 * sy, 90 * sx, 120 * sy, 110 * sx, 175 * sy)
      ..cubicTo(120 * sx, 200 * sy, 135 * sx, 205 * sy, 150 * sx, 185 * sy)
      ..cubicTo(190 * sx, 130 * sy, 240 * sx, 80 * sy, 300 * sx, 40 * sy);
    canvas.drawPath(
      curve,
      Paint()
        ..color = StickColors.lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(p(124, 198), 9 * sx, Paint()..color = _red);
    canvas.drawCircle(p(168, 160), 9 * sx, Paint()..color = StickColors.lime);

    void label(String text, Offset at, Color color, {bool center = false}) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: TextStyle(
            color: color,
            fontSize: 13 * sx,
            fontWeight: FontWeight.w700,
            fontVariations: const [FontVariation('wght', 700)],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, center ? at - Offset(tp.width / 2, 0) : at);
    }

    label('motivation', p(20, 26), StickColors.muted);
    label('Day 3', p(124, 226), const Color(0xFFFF8A8A), center: true);
    label('Day 4 → easier', p(182, 166), StickColors.lime);
  }

  @override
  bool shouldRepaint(covariant _WallPainter oldDelegate) => false;
}
