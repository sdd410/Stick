import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../theme.dart';

/// Style A: the big "Day N" number. Only the number area; the shared parts
/// (counter, buttons, banners) live in HomeScreen.
class HomeBigNumber extends StatelessWidget {
  const HomeBigNumber({super.key, required this.state, this.compact = false});

  final HomeState state;

  /// Smaller on rescue days, so the rescue lines fit above the slide.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final paused = state.paused;
    final style = TextStyle(
      fontFamily: 'ArchivoBlack',
      fontSize: paused ? 56 : (compact ? 56 : 120),
      height: 1,
      color: paused ? StickColors.muted : StickColors.lime,
    );
    return Text(
      paused ? 'Day ${state.dayNumber} · paused' : 'Day ${state.dayNumber}',
      textAlign: TextAlign.center,
      style: style,
    );
  }
}
