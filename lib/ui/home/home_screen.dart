import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controller/stick_controller.dart';
import '../../controller/stick_scope.dart';
import '../../domain/habit_engine.dart';
import '../../data/repository.dart' show Snapshot;
import '../../domain/models.dart' hide Clip;
import '../../domain/onboarding.dart';
import '../../domain/week_strip.dart';
import '../../theme.dart';
import '../celebration/day4_screen.dart';
import 'home_big_number.dart';
import 'home_road.dart';
import 'slide_to_check_in.dart';
import 'week_strip_view.dart';

/// Length of the check-in moment (roll, pop, sparks).
const _momentLength = Duration(milliseconds: 900);

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenProgress,
    this.onAddMessage,
    this.onPlayReplay,
    this.onSeeAll,
    this.onOpenSettings,
    this.onOpenTimer,
  });

  /// Null until the matching screen exists; the control is then hidden.
  final VoidCallback? onOpenProgress;
  final VoidCallback? onAddMessage;
  final VoidCallback? onPlayReplay;
  final VoidCallback? onSeeAll;
  final VoidCallback? onOpenSettings;

  /// Opens the 2-minute tiny-version timer.
  final VoidCallback? onOpenTimer;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  // Blocks a second check-in while the first is still running.
  bool _busy = false;
  // The weekly replay opens at most once per screen.
  bool _weeklyHandled = false;
  // Day 4 screen is open or about to be; blocks a second push.
  bool _day4Open = false;

  /// Drives the sparks and the timing of the day-4 haptics.
  late final AnimationController _moment = AnimationController(
    vsync: this,
    duration: _momentLength,
  );
  bool _secondHeavyDue = false;

  /// The day-4 screen opens when the moment finishes.
  bool _day4Pending = false;

  @override
  void initState() {
    super.initState();
    _moment
      ..addListener(() {
        final ms = _moment.value * _momentLength.inMilliseconds;
        if (_secondHeavyDue && (ms >= 120 || _moment.isCompleted)) {
          _secondHeavyDue = false;
          HapticFeedback.heavyImpact();
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _day4Pending) {
          _day4Pending = false;
          _openDay4();
        }
      });
  }

  @override
  void dispose() {
    _moment.dispose();
    super.dispose();
  }

  void _maybeOpenWeeklyReplay(
    StickController c,
    HomeState home,
    bool hasClips,
  ) {
    if (_weeklyHandled ||
        !home.weeklyReplayDue ||
        !hasClips ||
        widget.onPlayReplay == null) {
      return;
    }
    _weeklyHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      widget.onPlayReplay!();
      c.markWeeklyReplaySeen();
    });
  }

  Future<void> _checkIn(StickController c) async {
    await c.checkIn();
    if (!mounted) return;
    final day4 = c.home?.showDay4 == true && !_day4Open;
    HapticFeedback.lightImpact();
    if (day4) {
      HapticFeedback.heavyImpact();
      _secondHeavyDue = true;
      _day4Pending = true;
    }
    _moment.duration = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _momentLength;
    // Not awaited: the status listener opens the day-4 screen at the end.
    _moment.forward(from: 0);
  }

  Future<void> _openDay4() async {
    final c = StickScope.of(context);
    if (!mounted || _day4Open || c.home?.showDay4 != true) return;
    _day4Open = true;
    try {
      await Navigator.of(context)
          .push<void>(MaterialPageRoute(builder: (_) => const Day4Screen()));
    } finally {
      _day4Open = false;
    }
  }

  Future<void> _guarded(Future<void> Function() op) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await op();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = StickScope.of(context);
    final home = c.home;
    final snap = c.snapshot;
    if (home == null || snap == null) return const Scaffold();

    final inRescue = home.rescue != RescueReason.none;
    final hasClips = snap.clips.isNotEmpty;
    final showReplay = hasClips && widget.onPlayReplay != null;
    final textTheme = Theme.of(context).textTheme;
    final noMotion = MediaQuery.disableAnimationsOf(context);
    _maybeOpenWeeklyReplay(c, home, hasClips);

    final showRescue = inRescue && !home.paused;
    final showBanner = home.clipPrompt && !home.paused && !inRescue;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _topRow(home),
                    const SizedBox(height: 16),
                    WeekStripView(
                      days: weekStrip(
                        c.today,
                        snap.allCheckIns.map((x) => x.day),
                      ),
                    ),
                    if (showBanner)
                      InkWell(
                        onTap: widget.onAddMessage,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(top: 16),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: StickColors.lime),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Text(
                            'Record one for future you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontVariations: [FontVariation('wght', 600)],
                            ),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (home.rescue == RescueReason.quitDay &&
                                home.lastQuitDay != null &&
                                home.attemptNumber > 1) ...[
                              const SizedBox(height: 16),
                              Text(
                                'Last time you stopped on Day '
                                '${home.lastQuitDay}. '
                                'Today is Day ${home.dayNumber}.',
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium,
                              ),
                            ],
                            const SizedBox(height: 16),
                            _card(
                              context,
                              snap: snap,
                              home: home,
                              showRescue: showRescue,
                              showReplay: showReplay,
                              noMotion: noMotion,
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    if (hasClips && widget.onSeeAll != null)
                      TextButton(
                        onPressed: widget.onSeeAll,
                        child: const Text('See all'),
                      ),
                    if (widget.onAddMessage != null)
                      TextButton(
                        onPressed: widget.onAddMessage,
                        child: const Text('Add a message'),
                      ),
                    const SizedBox(height: 8),
                    _checkInControl(c, home, snap.flags.checkInMode),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topRow(HomeState home) {
    final tappable = widget.onOpenProgress != null;
    final counter = Text(
      'Attempt ${home.attemptNumber} · Day ${home.dayNumber}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        color: tappable ? null : StickColors.muted,
        fontWeight: FontWeight.w600,
        fontVariations: const [FontVariation('wght', 600)],
      ),
    );
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: !tappable
                ? counter
                : ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 48),
                    child: Material(
                      type: MaterialType.transparency,
                      shape: StadiumBorder(
                        side: BorderSide(
                          color: StickColors.muted.withValues(alpha: 0.5),
                        ),
                      ),
                      child: InkWell(
                        customBorder: const StadiumBorder(),
                        onTap: widget.onOpenProgress,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.bar_chart_rounded,
                                size: 16,
                                color: StickColors.lime,
                              ),
                              const SizedBox(width: 6),
                              Flexible(child: counter),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: StickColors.muted,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        if (widget.onOpenSettings != null)
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            color: StickColors.muted,
            tooltip: 'Settings',
            onPressed: widget.onOpenSettings,
          ),
      ],
    );
  }

  Widget _card(
    BuildContext context, {
    required Snapshot snap,
    required HomeState home,
    required bool showRescue,
    required bool showReplay,
    required bool noMotion,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final hint = reasonHint(snap.habit.quizReason);
    final numberKey = ValueKey('${home.dayNumber}-${home.paused}');
    final Widget number = snap.flags.homeStyle == HomeStyle.road
        ? HomeRoad(state: home)
        : AnimatedSwitcher(
            duration: noMotion
                ? Duration.zero
                : const Duration(milliseconds: 400),
            transitionBuilder: (child, animation) {
              // The new number rolls up from below; the old one leaves up.
              final incoming = child.key == numberKey;
              final offset = Tween<Offset>(
                begin: Offset(0, incoming ? 0.6 : -0.6),
                end: Offset.zero,
              ).animate(animation);
              return ClipRect(
                child: SlideTransition(
                  position: offset,
                  child: FadeTransition(opacity: animation, child: child),
                ),
              );
            },
            child: FittedBox(
              key: numberKey,
              fit: BoxFit.scaleDown,
              child: HomeBigNumber(state: home),
            ),
          );
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ExcludeSemantics(
                child: Text(
                  snap.habit.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  snap.habit.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.headlineSmall?.copyWith(fontSize: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              number,
              AnimatedBuilder(
                animation: _moment,
                builder: (context, _) =>
                    _moment.isAnimating && !noMotion && _moment.value < 0.6
                    ? Positioned.fill(
                        child: IgnorePointer(
                          child: CustomPaint(
                            key: const Key('check-in-sparks'),
                            painter: _Sparks(_moment.value / 0.6),
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
          if (showRescue) ...[
            const SizedBox(height: 20),
            Text(
              'Just do this. Get to day ${home.dayNumber + 1}.',
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 8),
            Text(
              tinyLine(snap.habit),
              textAlign: TextAlign.center,
              style: textTheme.bodyLarge,
            ),
            if (hint != null) ...[
              const SizedBox(height: 8),
              Text(
                hint,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: StickColors.muted),
              ),
            ],
            if (!showReplay && snap.habit.why.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                snap.habit.why,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: StickColors.muted),
              ),
            ],
            if (widget.onOpenTimer != null || showReplay) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (widget.onOpenTimer != null)
                    ActionChip(
                      label: const Text('⏱ 2-min timer'),
                      backgroundColor: StickColors.lime,
                      labelStyle: const TextStyle(
                        color: StickColors.bg,
                        fontWeight: FontWeight.w700,
                        fontVariations: [FontVariation('wght', 700)],
                      ),
                      onPressed: widget.onOpenTimer,
                    ),
                  if (showReplay)
                    ActionChip(
                      label: const Text('▶ Your message'),
                      onPressed: widget.onPlayReplay,
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _checkInControl(StickController c, HomeState home, CheckInMode mode) {
    const big = TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      fontVariations: [FontVariation('wght', 600)],
    );
    if (home.paused) {
      return FilledButton(
        onPressed: _busy ? null : () => _guarded(c.pickBackUp),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(60),
          textStyle: big,
        ),
        child: const Text('Pick it back up'),
      );
    }
    final done = home.checkedInToday;
    if (mode == CheckInMode.slide) {
      return SlideToCheckIn(
        label: done ? 'Done for today ✓' : 'Slide when done',
        onDone: done || _busy ? null : () => _guarded(() => _checkIn(c)),
        onLongPress: done ? null : widget.onOpenTimer,
      );
    }
    return FilledButton(
      onPressed: done || _busy ? null : () => _guarded(() => _checkIn(c)),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(60),
        textStyle: big,
      ),
      child: Text(done ? 'Done for today ✓' : 'Done today'),
    );
  }
}

/// Six small lime sparks drifting up from the number and fading.
class _Sparks extends CustomPainter {
  _Sparks(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final paint = Paint()
      ..color = StickColors.lime.withValues(alpha: (1 - t).clamp(0, 1));
    for (var i = 0; i < 6; i++) {
      final a = -math.pi / 2 + (i - 2.5) * 0.35;
      final d = 30 + 70 * t;
      canvas.drawCircle(
        c + Offset(math.cos(a) * d, math.sin(a) * d),
        4 * (1 - t) + 1,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _Sparks old) => old.t != t;
}
