import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../controller/stick_controller.dart';
import '../../controller/stick_scope.dart';
import '../../domain/battery_tip.dart';
import '../../domain/models.dart';
import '../../services/device_info.dart';
import '../../theme.dart';
import 'battery_tip_card.dart';

const freshStartHeadline = 'Day 1 you said this. Still switching?';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.onManageClips,
    this.onPlayReplay,
    this.readManufacturer = readDeviceManufacturer,
    this.openSystemSettings = openAppSettings,
  });

  /// Null hides "Manage clips" (no clip storage).
  final VoidCallback? onManageClips;

  /// Plays the replay with a headline. Null skips it on fresh start.
  final Future<void> Function(String headline)? onPlayReplay;
  final Future<String> Function() readManufacturer;
  final OpenSystemSettings openSystemSettings;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _tip;
  // Blocks double taps on anything that changes data.
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.readManufacturer().then((m) {
      if (mounted) setState(() => _tip = batteryTipFor(m));
    }, onError: (_) {});
  }

  Future<void> _guarded(Future<void> Function() op) async {
    if (_busy) return;
    _busy = true;
    try {
      await op();
    } finally {
      _busy = false;
    }
  }

  Future<void> _editHabit(StickController c, Habit h) => _guarded(() async {
    final result = await showDialog<_HabitEdit>(
      context: context,
      builder: (_) => _EditHabitDialog(habit: h),
    );
    if (result == null) return;
    await c.updateHabit(
      name: result.name,
      tiny: result.tiny,
      why: result.why,
      reminderMinutes: h.reminderMinutes,
    );
  });

  Future<void> _pickTime(StickController c, Habit h) => _guarded(() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: h.reminderMinutes ~/ 60,
        minute: h.reminderMinutes % 60,
      ),
    );
    if (t == null) return;
    await c.updateHabit(
      name: h.name,
      tiny: h.tiny,
      why: h.why,
      reminderMinutes: t.hour * 60 + t.minute,
    );
  });

  Future<bool> _confirm(
    String title,
    String body,
    String yes, {
    String no = 'Cancel',
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(no),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(yes),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _reset(StickController c) => _guarded(() async {
    final ok = await _confirm(
      'Reset?',
      'Start a new attempt. Your days stay counted.',
      'Start new attempt',
    );
    if (ok) await c.resetAttempt();
  });

  Future<void> _freshStart(StickController c) => _guarded(() async {
    final nav = Navigator.of(context);
    final hasClips = c.snapshot?.clips.isNotEmpty ?? false;
    if (hasClips && widget.onPlayReplay != null) {
      await widget.onPlayReplay!(freshStartHeadline);
      if (!mounted) return;
    }
    final ok = await _confirm(
      'Fresh start?',
      'This clears your habit and your days. You will set up again.',
      'Yes, start fresh',
    );
    if (!ok || !mounted) return;
    var keep = false;
    if (hasClips) {
      // Default is No: the clips go with the old habit.
      keep =
          await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Keep my clips?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Yes, keep'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('No'),
                ),
              ],
            ),
          ) ??
          false;
      if (!mounted) return;
    }
    await c.freshStart(keepClips: keep);
    nav.popUntil((r) => r.isFirst);
  });

  @override
  Widget build(BuildContext context) {
    final c = StickScope.of(context);
    final snap = c.snapshot;
    if (snap == null) return const Scaffold();
    final h = snap.habit;
    final style = snap.flags.homeStyle;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: EdgeInsets.only(
          bottom: 24 + MediaQuery.paddingOf(context).bottom,
        ),
        children: [
          ListTile(
            title: const Text('Edit habit'),
            subtitle: Text(h.name),
            onTap: () => _editHabit(c, h),
          ),
          ListTile(
            title: const Text('Reminder time'),
            subtitle: Text(
              TimeOfDay(
                hour: h.reminderMinutes ~/ 60,
                minute: h.reminderMinutes % 60,
              ).format(context),
            ),
            onTap: () => _pickTime(c, h),
          ),
          if (widget.onManageClips != null)
            ListTile(
              title: const Text('Manage clips'),
              onTap: widget.onManageClips,
            ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Home style',
              style: TextStyle(color: StickColors.muted),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<HomeStyle>(
              segments: const [
                ButtonSegment(
                  value: HomeStyle.bigNumber,
                  label: Text('Big number'),
                ),
                ButtonSegment(value: HomeStyle.road, label: Text('Road')),
              ],
              selected: {style},
              onSelectionChanged: (s) => c.setHomeStyle(s.first),
            ),
          ),
          if (_tip != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: BatteryTipCard(
                tip: _tip!,
                onOpen: () => safeOpen(widget.openSystemSettings),
              ),
            ),
          const Divider(height: 32),
          ListTile(title: const Text('Reset'), onTap: () => _reset(c)),
          ListTile(
            title: const Text('Fresh start'),
            onTap: () => _freshStart(c),
          ),
        ],
      ),
    );
  }
}

class _HabitEdit {
  const _HabitEdit(this.name, this.tiny, this.why);
  final String name;
  final String? tiny;
  final String why;
}

class _EditHabitDialog extends StatefulWidget {
  const _EditHabitDialog({required this.habit});
  final Habit habit;

  @override
  State<_EditHabitDialog> createState() => _EditHabitDialogState();
}

class _EditHabitDialogState extends State<_EditHabitDialog> {
  late final _name = TextEditingController(text: widget.habit.name);
  late final _tiny = TextEditingController(text: widget.habit.tiny ?? '');
  late final _why = TextEditingController(text: widget.habit.why);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _tiny.dispose();
    _why.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit habit'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Habit'),
            ),
            TextField(
              controller: _tiny,
              decoration: const InputDecoration(
                labelText: 'Tiny version (optional)',
              ),
            ),
            TextField(
              controller: _why,
              decoration: const InputDecoration(
                labelText: 'Why are you starting?',
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _name.text.trim().isEmpty
              ? null
              : () =>
                    Navigator.of(context)
                        .pop(_HabitEdit(_name.text, _tiny.text, _why.text)),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
