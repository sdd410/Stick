import 'package:flutter/material.dart';

import '../../controller/stick_scope.dart';
import '../../domain/habit_engine.dart';
import '../../domain/models.dart';
import '../../theme.dart';
import 'home_big_number.dart';
import 'home_road.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    this.onOpenProgress,
    this.onAddMessage,
    this.onPlayReplay,
    this.onOpenSettings,
  });

  /// Null until the matching screen exists; the control is then hidden.
  final VoidCallback? onOpenProgress;
  final VoidCallback? onAddMessage;
  final VoidCallback? onPlayReplay;
  final VoidCallback? onOpenSettings;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Blocks a second tap while the first check-in is still running.
  bool _busy = false;

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

    final counter = Text(
      'Attempt ${home.attemptNumber} · Day ${home.dayNumber}',
      style: const TextStyle(
        fontSize: 14,
        color: StickColors.muted,
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
      onButton = _busy ? null : () => _guarded(c.checkIn);
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
                        widget.onOpenProgress == null
                            ? counter
                            : InkWell(
                                onTap: widget.onOpenProgress,
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    minHeight: 48,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: 1,
                                    child: counter,
                                  ),
                                ),
                              ),
                        const Spacer(),
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
                            if (showRescue &&
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
                              else
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
