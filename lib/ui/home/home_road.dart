import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../../theme.dart';

/// Style B: a vertical road of day markers, the road ahead on top. Only the
/// number area; the shared parts (counter, buttons, banners) live in
/// HomeScreen.
class HomeRoad extends StatefulWidget {
  const HomeRoad({super.key, required this.state});

  final HomeState state;

  @override
  State<HomeRoad> createState() => _HomeRoadState();
}

class _HomeRoadState extends State<HomeRoad> {
  static const double _viewport = 260;
  static const double _rowHeight = 44;
  static const double _todayHeight = 72;

  final _scroll = ScrollController();

  int get _lastDay =>
      math.max(widget.state.quitTarget + 1, widget.state.dayNumber + 2);

  @override
  void initState() {
    super.initState();
    _centerToday();
  }

  @override
  void didUpdateWidget(HomeRoad old) {
    super.didUpdateWidget(old);
    if (old.state.dayNumber != widget.state.dayNumber ||
        old.state.quitTarget != widget.state.quitTarget) {
      _centerToday(glide: true);
    }
  }

  // Days are listed highest first, so today sits `above` rows from the top.
  // A new day (after a check-in) glides one step; the first build jumps.
  void _centerToday({bool glide = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final above = (_lastDay - widget.state.dayNumber) * _rowHeight;
      final target = (above - (_viewport - _todayHeight) / 2).clamp(
        0.0,
        _scroll.position.maxScrollExtent,
      );
      if (glide && !MediaQuery.disableAnimationsOf(context)) {
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scroll.jumpTo(target);
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  String? _quitLabel() {
    final s = widget.state;
    if (s.attemptNumber > 1 && s.lastQuitDay != null) {
      return 'Day ${s.quitTarget}: last time you stopped';
    }
    return 'Most people quit here';
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.state;
    return SizedBox(
      height: _viewport,
      child: ListView.builder(
        controller: _scroll,
        itemCount: _lastDay,
        itemBuilder: (context, i) {
          final d = _lastDay - i;
          return _Marker(
            day: d,
            today: d == s.dayNumber,
            past: d < s.dayNumber,
            paused: s.paused,
            quit: d == s.quitTarget,
            quitLabel: d == s.quitTarget ? _quitLabel() : null,
            height: d == s.dayNumber ? _todayHeight : _rowHeight,
          );
        },
      ),
    );
  }
}

class _Marker extends StatelessWidget {
  const _Marker({
    required this.day,
    required this.today,
    required this.past,
    required this.paused,
    required this.quit,
    required this.quitLabel,
    required this.height,
  });

  final int day;
  final bool today;
  final bool past;
  final bool paused;
  final bool quit;
  final String? quitLabel;
  final double height;

  @override
  Widget build(BuildContext context) {
    final todayColor = paused ? StickColors.muted : StickColors.lime;
    final Widget dot;
    if (today) {
      dot = Container(
        width: 56,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(shape: BoxShape.circle, color: todayColor),
        child: Text(
          '$day',
          style: const TextStyle(
            fontFamily: 'ArchivoBlack',
            fontSize: 26,
            height: 1,
            color: StickColors.bg,
          ),
        ),
      );
    } else if (past) {
      dot = Container(
        width: 16,
        height: 16,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: StickColors.lime,
        ),
      );
    } else {
      dot = Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: StickColors.muted, width: 2),
        ),
      );
    }

    final String label;
    if (today && paused) {
      label = 'Day $day · paused';
    } else if (quitLabel != null) {
      label = quitLabel!;
    } else if (today) {
      label = 'Today';
    } else {
      label = 'Day $day';
    }
    final highlight = today || quit;

    return SizedBox(
      height: height,
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(width: 2, color: const Color(0xFF2A2A36)),
                dot,
              ],
            ),
          ),
          if (quit) ...[
            const Icon(Icons.flag, size: 20, color: StickColors.lime),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: highlight ? 16 : 14,
                fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
                fontVariations: [FontVariation('wght', highlight ? 700 : 500)],
                color: highlight
                    ? (today && paused ? StickColors.muted : Colors.white)
                    : StickColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
