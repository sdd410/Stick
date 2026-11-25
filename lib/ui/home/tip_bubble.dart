import 'package:flutter/material.dart';

import '../../theme.dart';

/// A one-time hint: white bubble, dark text, "OK", with a small arrow at
/// [arrowAt] (0 = left edge, 1 = right edge) pointing down at the control.
class TipBubble extends StatelessWidget {
  const TipBubble({
    super.key,
    required this.text,
    required this.onOk,
    this.arrowAt = 0.5,
  });

  final String text;
  final VoidCallback onOk;
  final double arrowAt;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.white,
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    text,
                    style: const TextStyle(
                      color: StickColors.bg,
                      fontSize: 14,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      fontVariations: [FontVariation('wght', 600)],
                    ),
                  ),
                ),
                TextButton(
                  onPressed: onOk,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4A6A00),
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment(arrowAt * 2 - 1, 0),
          child: CustomPaint(size: const Size(18, 9), painter: _Arrow()),
        ),
      ],
    ),
  );
}

class _Arrow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant _Arrow oldDelegate) => false;
}
