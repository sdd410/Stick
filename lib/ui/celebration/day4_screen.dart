import 'package:flutter/material.dart';

import '../../controller/stick_scope.dart';
import '../../theme.dart';

/// One-time celebration after the check-in that reaches Day 4. Leaving it
/// any way (button or back) marks it seen, so it never shows twice.
class Day4Screen extends StatelessWidget {
  const Day4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = StickScope.of(context);
    final theme = Theme.of(context);
    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) c.markDay4Seen();
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'Day 4. You made it past the drop-off.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: StickColors.lime,
                  ),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(60),
                  ),
                  child: const Text('Keep going'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
