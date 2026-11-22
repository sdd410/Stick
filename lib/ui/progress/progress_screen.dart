import 'package:flutter/material.dart';

import '../../controller/stick_scope.dart';
import '../../domain/progress.dart';
import '../../theme.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key, this.onOpenReplay});

  /// Opens the replay. The "Messages to future you" block shows only when
  /// there are clips and this is set.
  final VoidCallback? onOpenReplay;

  @override
  Widget build(BuildContext context) {
    final c = StickScope.of(context);
    final snap = c.snapshot;
    final home = c.home;
    if (snap == null || home == null) return const Scaffold();
    final p = computeProgress(snap, home);
    final textTheme = Theme.of(context).textTheme;
    final maxLen = p.bars.fold<int>(1, (m, b) => b.length > m ? b.length : m);

    Widget stat(String label, int value) => Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyLarge)),
        Text(
          '$value',
          style: textTheme.headlineSmall?.copyWith(color: StickColors.lime),
        ),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Progress')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          children: [
            Text(
              '${p.daysShowedUp}',
              textAlign: TextAlign.center,
              style: textTheme.displayLarge?.copyWith(
                color: StickColors.lime,
                fontSize: 96,
              ),
            ),
            Text(
              'Days you showed up',
              textAlign: TextAlign.center,
              style: textTheme.titleMedium,
            ),
            const SizedBox(height: 32),
            for (final b in p.bars)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    SizedBox(
                      width: 96,
                      child: Text(
                        'Day ${b.length}${b.beatQuitDay ? ' ★' : ''}',
                        style: textTheme.bodyMedium,
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (_, box) => Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            height: 16,
                            width: box.maxWidth * b.length / maxLen,
                            decoration: BoxDecoration(
                              color: b.isCurrent
                                  ? StickColors.lime
                                  : StickColors.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text(
                        b.isCurrent ? 'now' : '',
                        textAlign: TextAlign.end,
                        style: textTheme.bodySmall?.copyWith(
                          color: StickColors.lime,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
            stat('Beat your quit day', p.quitDaysBeaten),
            const SizedBox(height: 12),
            stat('Tiny days', p.tinyDays),
            Text(
              'They count.',
              style: textTheme.bodySmall?.copyWith(color: StickColors.muted),
            ),
            if (p.clipCount > 0 && onOpenReplay != null) ...[
              const SizedBox(height: 12),
              InkWell(
                onTap: onOpenReplay,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 48),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Messages to future you',
                          style: textTheme.bodyLarge,
                        ),
                      ),
                      Text(
                        '${p.clipCount}',
                        style: textTheme.headlineSmall?.copyWith(
                          color: StickColors.lime,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(60),
              ),
              child: Text('Get past Day ${p.nextQuitTarget} this time'),
            ),
          ],
        ),
      ),
    );
  }
}
