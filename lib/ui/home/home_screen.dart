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
import 'tip_bubble.dart';
import 'week_strip_view.dart';

/// Length of the check-in moment: lime floods the card, the day flips,
/// the lime drains away (option 2, "Lime flood").
const _momentLength = Duration(milliseconds: 1100);

// Phases of the moment, as fractions.
const _floodFull = 0.32; // lime covers the card
const _flipOut = 0.42; // old day turned away
const _flipIn = 0.55; // new day turned in
const _drainFrom = 0.64; // lime starts to drain

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenProgress,
    this.onAddMessage,
    this.onPlayReplay,
    this.onOpenTimer,
  });

  /// Null until the matching screen exists; the control is then hidden.
  final VoidCallback? onOpenProgress;

  /// The "Record one for future you." banner on day 7, 14 and 21.
  final VoidCallback? onAddMessage;
  final VoidCallback? onPlayReplay;

  /// Opens the 2-minute tiny-version timer. Home passes its own check-in,
  /// so finishing the timer plays the check-in moment and opens Day 4.
  final void Function(Future<void> Function() checkIn)? onOpenTimer;

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

  /// Drives the flood and the timing of its haptics.
  late final AnimationController _moment = AnimationController(
    vsync: this,
    duration: _momentLength,
  );
  bool _secondHeavyDue = false;
  bool _fullTapDue = false;
  bool _day4Taps = false;

  /// The days shown inside the flood: before and after the check-in.
  int _fromDay = 0;
  int _toDay = 0;

  /// Which one-time tip shows (0 = slide, 1 = Messages, 2 = none).
  int _tip = 0;

  /// The day-4 screen opens when the moment finishes.
  bool _day4Pending = false;

  @override
  void initState() {
    super.initState();
    _moment
      ..addListener(() {
        final v = _moment.value;
        // A soft tap when the lime is full; on day 4 two strong taps there.
        if (_fullTapDue && (v >= _floodFull || _moment.isCompleted)) {
          _fullTapDue = false;
          HapticFeedback.lightImpact();
          if (_day4Taps) {
            HapticFeedback.heavyImpact();
            _secondHeavyDue = true;
          }
        }
        final secondAt = _floodFull + 120 / _momentLength.inMilliseconds;
        if (_secondHeavyDue && (v >= secondAt || _moment.isCompleted)) {
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
    final from = c.home?.dayNumber ?? 0;
    await c.checkIn();
    if (!mounted) return;
    final day4 = c.home?.showDay4 == true && !_day4Open;
    _fromDay = from;
    _toDay = c.home?.dayNumber ?? from + 1;
    _fullTapDue = true;
    _day4Taps = day4;
    _day4Pending = day4;
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

  /// Opens the timer with Home's check-in; a no-op if already done today.
  VoidCallback? _timerOpener(StickController c) {
    final open = widget.onOpenTimer;
    if (open == null) return null;
    return () => open(() async {
      if (c.home?.checkedInToday ?? true) return;
      await _guarded(() => _checkIn(c));
    });
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
    final showTips = !snap.flags.tipsSeen && !home.paused && _tip < 2;

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Everything but the check-in scrolls; the check-in is pinned
                // so it never falls below the fold on a busy rescue day.
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
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
                                      border: Border.all(
                                        color: StickColors.lime,
                                      ),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Text(
                                      'Record one for future you.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        fontVariations: [
                                          FontVariation('wght', 600),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              Expanded(
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
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
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: _checkInControl(c, home, snap.flags.checkInMode),
                ),
              ],
            ),
            if (showTips)
              Positioned(
                left: 24,
                right: 24,
                bottom: _tip == 0 ? 24 + 64 + 8 : 4,
                child: _tip == 0
                    ? TipBubble(
                        text: snap.flags.checkInMode == CheckInMode.slide
                            ? "Slide the lime circle right when you've done it."
                            : "Tap Done today when you've done it.",
                        arrowAt: snap.flags.checkInMode == CheckInMode.slide
                            ? 0.1
                            : 0.5,
                        onOk: () => setState(() => _tip = 1),
                      )
                    : TipBubble(
                        text: 'Your messages to future you live here.',
                        arrowAt: 0.62,
                        onOk: () {
                          setState(() => _tip = 2);
                          c.markTipsSeen();
                        },
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
    // Until the lime covers the card, the card keeps showing the old day;
    // the flip happens inside the flood.
    final Widget number = AnimatedBuilder(
      animation: _moment,
      builder: (context, _) {
        final early =
            _moment.isAnimating && !noMotion && _moment.value < _floodFull;
        final shown = early
            ? home.copyWith(dayNumber: _fromDay, checkedInToday: false)
            : home;
        return snap.flags.homeStyle == HomeStyle.road
            ? HomeRoad(state: shown)
            : FittedBox(
                fit: BoxFit.scaleDown,
                child: HomeBigNumber(state: shown),
              );
      },
    );
    final card = Container(
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
          number,
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
                  if (_timerOpener(StickScope.of(context)) case final open?)
                    ActionChip(
                      label: const Text('⏱ 2-min timer'),
                      backgroundColor: StickColors.lime,
                      labelStyle: const TextStyle(
                        color: StickColors.bg,
                        fontWeight: FontWeight.w700,
                        fontVariations: [FontVariation('wght', 700)],
                      ),
                      onPressed: open,
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
    return Stack(
      children: [
        card,
        Positioned.fill(
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: _moment,
              builder: (context, _) => _moment.isAnimating && !noMotion
                  ? _Flood(t: _moment.value, from: _fromDay, to: _toDay)
                  : const SizedBox.shrink(),
            ),
          ),
        ),
      ],
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
        onLongPress: done ? null : _timerOpener(c),
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

/// Lime pours up from the slide bar over the card, the day flips from
/// [from] to [to] inside it, then the lime drains back down.
class _Flood extends StatelessWidget {
  const _Flood({required this.t, required this.from, required this.to});

  final double t;
  final int from;
  final int to;

  @override
  Widget build(BuildContext context) {
    final double cover;
    if (t < _floodFull) {
      cover = Curves.easeIn.transform(t / _floodFull);
    } else if (t < _drainFrom) {
      cover = 1;
    } else {
      cover = 1 - Curves.easeOut.transform((t - _drainFrom) / (1 - _drainFrom));
    }
    // Flip: the old day turns away, then the new one turns in.
    final double angle;
    final int shown;
    if (t < _floodFull) {
      angle = 0;
      shown = from;
    } else if (t < _flipOut) {
      angle = (t - _floodFull) / (_flipOut - _floodFull) * math.pi / 2;
      shown = from;
    } else if (t < _flipIn) {
      angle = -(1 - (t - _flipOut) / (_flipIn - _flipOut)) * math.pi / 2;
      shown = to;
    } else {
      angle = 0;
      shown = to;
    }
    return ClipRRect(
      key: const Key('check-in-flood'),
      borderRadius: BorderRadius.circular(24),
      child: ClipPath(
        clipper: _RisingCircle(cover),
        child: ColoredBox(
          color: StickColors.lime,
          child: Center(
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.002)
                ..rotateX(angle),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  'Day $shown',
                  style: const TextStyle(
                    fontFamily: 'ArchivoBlack',
                    fontSize: 96,
                    color: StickColors.bg,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A circle growing from just below the card's bottom centre.
class _RisingCircle extends CustomClipper<Path> {
  _RisingCircle(this.cover);

  final double cover;

  @override
  Path getClip(Size size) {
    final centre = Offset(size.width / 2, size.height * 1.3);
    final full = (Offset.zero - centre).distance;
    return Path()
      ..addOval(Rect.fromCircle(center: centre, radius: full * cover));
  }

  @override
  bool shouldReclip(covariant _RisingCircle old) => old.cover != cover;
}
