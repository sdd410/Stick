import 'package:flutter/material.dart';

import '../../theme.dart';

typedef OpenSystemSettings = Future<bool> Function();

/// Runs [open], never throwing: a missing settings screen must not crash.
Future<void> safeOpen(OpenSystemSettings open) async {
  try {
    await open();
  } catch (_) {}
}

class BatteryTipCard extends StatelessWidget {
  const BatteryTipCard({super.key, required this.tip, required this.onOpen});

  final String tip;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: StickColors.lime),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Keep reminders working',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(tip),
          const SizedBox(height: 8),
          TextButton(onPressed: onOpen, child: const Text('Open settings')),
        ],
      ),
    );
  }
}

/// Shown once right after setup on phones that kill background reminders.
Future<void> showBatteryTipDialog(
  BuildContext context, {
  required String tip,
  required OpenSystemSettings openSystemSettings,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Keep reminders working'),
      content: Text(tip),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () {
            safeOpen(openSystemSettings);
            Navigator.of(ctx).pop();
          },
          child: const Text('Open settings'),
        ),
      ],
    ),
  );
}
