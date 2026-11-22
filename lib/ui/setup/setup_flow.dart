import 'package:flutter/material.dart';

import '../../controller/stick_scope.dart';
import '../../theme.dart';

class SetupFlow extends StatefulWidget {
  const SetupFlow({super.key, this.onRecordFirstClip, this.onFinished});

  /// Opens the record screen; null hides the optional first clip.
  final Future<void> Function()? onRecordFirstClip;

  /// Called once setup is over (after Start, or after the first-clip offer).
  final VoidCallback? onFinished;

  @override
  State<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends State<SetupFlow> {
  final _name = TextEditingController();
  final _tiny = TextEditingController();
  final _why = TextEditingController();
  int _step = 0;
  int _minutes = 19 * 60;
  bool _starting = false;

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

  bool get _canNext => _step != 0 || _name.text.trim().isNotEmpty;

  String get _timeLabel {
    final h = (_minutes ~/ 60).toString().padLeft(2, '0');
    final m = (_minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Future<void> _pickTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _minutes ~/ 60, minute: _minutes % 60),
    );
    if (t != null) setState(() => _minutes = t.hour * 60 + t.minute);
  }

  Future<void> _start() async {
    if (_starting) return;
    final controller = StickScope.of(context);
    setState(() => _starting = true);
    try {
      try {
        await controller.requestNotificationPermission();
      } catch (_) {
        // A failed or denied prompt must never block setup.
      }
      await controller.createHabit(
        name: _name.text,
        tiny: _tiny.text,
        why: _why.text,
        reminderMinutes: _minutes,
      );
      if (widget.onRecordFirstClip != null) {
        if (mounted) setState(() => _step = 3);
      } else {
        widget.onFinished?.call();
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  Future<void> _recordFirst() async {
    await widget.onRecordFirstClip?.call();
    widget.onFinished?.call();
  }

  /// System back: step 2 and 3 go to the previous step, the first-clip offer
  /// counts as Skip, and the first step leaves the app.
  void _onBack() {
    if (_starting) return;
    if (_step == 3) {
      widget.onFinished?.call();
    } else if (_step > 0) {
      setState(() => _step--);
    }
  }

  /// Fills the screen when short, scrolls when the keyboard or a big font
  /// leaves too little room.
  Widget _scrollable(Widget child) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
        child: IntrinsicHeight(child: child),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == 0 && !_starting,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _onBack();
    },
    child: _buildStep(context),
  );

  Widget _buildStep(BuildContext context) {
    final theme = Theme.of(context);
    if (_step == 3) {
      return Scaffold(
        body: SafeArea(
          child: _scrollable(
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Text(
                  'Record one for future you.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall,
                ),
                const SizedBox(height: 32),
                FilledButton(
                  onPressed: _recordFirst,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(56),
                  ),
                  child: const Text('Record a message for future you'),
                ),
                TextButton(
                  onPressed: widget.onFinished,
                  child: const Text('Skip'),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      );
    }
    final Widget body;
    switch (_step) {
      case 0:
        body = _field(
          'What habit are you starting?',
          _name,
          'e.g. Walk 20 minutes',
        );
      case 1:
        body = _field(
          'Make it tiny (optional)',
          _tiny,
          'Just show up for 2 minutes',
        );
      default:
        body = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Why are you starting?', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextField(
              controller: _why,
              decoration: const InputDecoration(hintText: 'Your reason'),
            ),
            const SizedBox(height: 24),
            Text('Remind me at', style: theme.textTheme.titleMedium),
            TextButton(
              onPressed: _pickTime,
              child: Text(_timeLabel, style: theme.textTheme.headlineMedium),
            ),
          ],
        );
    }
    final last = _step == 2;
    return Scaffold(
      body: SafeArea(
        child: _scrollable(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Step ${_step + 1} of 3',
                style: const TextStyle(color: StickColors.muted),
              ),
              const SizedBox(height: 24),
              body,
              const Spacer(),
              Row(
                children: [
                  if (_step > 0)
                    TextButton(
                      onPressed: _starting
                          ? null
                          : () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: !_canNext || _starting
                        ? null
                        : (last ? _start : () => setState(() => _step++)),
                    child: Text(last ? 'Start' : 'Next'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String title, TextEditingController c, String hint) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 16),
      TextField(
        controller: c,
        autofocus: true,
        decoration: InputDecoration(hintText: hint),
      ),
    ],
  );
}
