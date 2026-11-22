import 'package:flutter/material.dart';

import '../../controller/stick_controller.dart';
import '../../controller/stick_scope.dart';
import '../../domain/habit_engine.dart';
import '../../domain/models.dart';
import '../../theme.dart';
import '../celebration/day4_screen.dart';
import 'home_big_number.dart';
import 'home_road.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenProgress,
    this.onAddMessage,
    this.onPlayReplay,
    this.onSeeAll,
    this.onOpenSettings,
  });

  /// Null until the matching screen exists; the control is then hidden.
  final VoidCallback? onOpenProgress;
  final VoidCallback? onAddMessage;
  final VoidCallback? onPlayReplay;
  final VoidCallback? onSeeAll;
  final VoidCallback? onOpenSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Blocks a second tap while the first check-in is still running.
  bool _busy = false;
  // The weekly replay opens at most once per screen.
  bool _weeklyHandled = false;

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

  // Day 4 screen is open or about to be; blocks a second push.
  bool _day4Open = false;

  Future<void> _checkIn(StickController c) async {
    await c.checkIn();
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
    _maybeOpenWeeklyReplay(c, home, hasClips);

    final tappable = widget.onOpenProgress != null;
    final counter = Text(
      'Attempt ${home.attemptNumber} · Day ${home.dayNumber}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        fontSize: 14,
        color: tappable ? null : StickColors.muted,
        fontWeight: FontWeight.w600,
        fontVariations: [FontVariation('wght', 600)],
      ),
    );

    final number = snap.flags.homeStyle == HomeStyle.road
        ? HomeRoad(state: home)
        : HomeBigNumber(state: home);

    final String buttonLabel;
    final VoidCallback? onButton;
    if (home.paused) {
      buttonLabel = 'Pick it back up';
      onButton = _busy ? null : () => _guarded(c.pickBackUp);
    } else if (home.checkedInToday) {
      buttonLabel = 'Done for today';
      onButton = null;
    } else {
      buttonLabel = 'Done today';
      onButton = _busy ? null : () => _guarded(() => _checkIn(c));
    }

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
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: !tappable
                                ? counter
                                : ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      minHeight: 48,
                                    ),
                                    child: Material(
                                      type: MaterialType.transparency,
                                      shape: StadiumBorder(
                                        side: BorderSide(
                                          color: StickColors.muted.withValues(
                                            alpha: 0.5,
                                          ),
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
                    ),
                    if (showBanner)
                      InkWell(
                        onTap: widget.onAddMessage,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          margin: const EdgeInsets.only(top: 8),
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
                          children: [
                            if (home.rescue == RescueReason.quitDay &&
                                home.lastQuitDay != null &&
                                home.attemptNumber > 1) ...[
                              Text(
                                'Last time you stopped on Day '
                                '${home.lastQuitDay}. '
                                'Today is Day ${home.dayNumber}.',
                                textAlign: TextAlign.center,
                                style: textTheme.titleMedium,
                              ),
                              const SizedBox(height: 24),
                            ],
                            Text(
                              snap.habit.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 16),
                            number,
                            if (showRescue) ...[
                              const SizedBox(height: 24),
                              Text(
                                'Just do this. Get to day '
                                '${home.dayNumber + 1}.',
                                textAlign: TextAlign.center,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: 22,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                tinyLine(snap.habit),
                                textAlign: TextAlign.center,
                                style: textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 20),
                              if (showReplay)
                                OutlinedButton(
                                  onPressed: widget.onPlayReplay,
                                  child: const Text(
                                    '▶ You have something to say',
                                  ),
                                )
                              else if (snap.habit.why.isNotEmpty)
                                Text(
                                  snap.habit.why,
                                  textAlign: TextAlign.center,
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: StickColors.muted,
                                  ),
                                ),
                            ],
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
                    FilledButton(
                      onPressed: onButton,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(60),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          fontVariations: [FontVariation('wght', 600)],
                        ),
                      ),
                      child: Text(buttonLabel),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
