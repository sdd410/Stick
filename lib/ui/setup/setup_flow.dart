import 'package:flutter/cupertino.dart' show CupertinoDatePicker;
import 'package:flutter/cupertino.dart' as cupertino;
import 'package:flutter/material.dart';

import '../../controller/stick_scope.dart';
import '../../domain/onboarding.dart';
import '../../theme.dart';
import 'habit_picker.dart';
import 'setup_widgets.dart';

/// The onboarding screens, in order.
enum _Step { welcome, quitDay, reason, habit, why, reminder, wall, promise }

const _quitDayChoices = [
  (QuitDayAnswer.day1, '😮‍💨', 'Day 1. I barely start'),
  (QuitDayAnswer.day2, '😩', 'Day 2'),
  (QuitDayAnswer.day3, '🫠', 'Day 3'),
  (QuitDayAnswer.weekOrTwo, '📅', 'After a week or two'),
  (QuitDayAnswer.notSure, '🤷', 'Not sure'),
];

const _reasonChoices = [
  (QuitReason.tired, '😴', 'Too tired'),
  (QuitReason.busy, '⏰', 'Too busy'),
  (QuitReason.bored, '🥱', 'Got bored'),
  (QuitReason.missedOne, '💔', 'Missed one day and gave up'),
  (QuitReason.notSure, '🤷', 'Not sure'),
];

const _whyExamples = [
  ('💪', 'Feel healthier'),
  ('🏆', 'Prove I can stick to something'),
  ('🧘', 'Less stress'),
];

const _timeChips = [
  ('Morning', 7 * 60),
  ('Lunch', 13 * 60),
  ('Evening', 19 * 60),
];

class SetupFlow extends StatefulWidget {
  const SetupFlow({super.key, this.onRecordFirstClip, this.onFinished});

  /// Opens the record screen; null hides the first-message offer.
  final Future<void> Function()? onRecordFirstClip;

  /// Called once setup is over (after the promise, and the recording if any).
  final VoidCallback? onFinished;

  @override
  State<SetupFlow> createState() => _SetupFlowState();
}

class _SetupFlowState extends State<SetupFlow> {
  _Step _step = _Step.welcome;

  // The draft: kept across back/forward, saved only at the promise.
  QuitDayAnswer? _quitDay;
  QuitReason? _reason;
  PickedHabit? _habit;
  final _why = TextEditingController();
  int _minutes = 19 * 60;

  /// Bumped when a chip sets the time, so the wheel jumps to it.
  int _wheelVersion = 0;
  bool _busy = false;

  @override
  void dispose() {
    _why.dispose();
    super.dispose();
  }

  double get _progress => _step.index / (_Step.values.length - 1);

  void _go(_Step s) => setState(() => _step = s);
  void _next() => _go(_Step.values[_step.index + 1]);
  void _back() {
    if (_busy || _step == _Step.welcome) return;
    _go(_Step.values[_step.index - 1]);
  }

  Future<void> _afterReminder() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await StickScope.of(context).requestNotificationPermission();
    } catch (_) {
      // A failed or denied prompt must never block setup.
    } finally {
      if (mounted) setState(() => _busy = false);
    }
    if (mounted) _next();
  }

  Future<void> _promise({required bool record}) async {
    final habit = _habit;
    if (_busy || habit == null) return;
    final controller = StickScope.of(context);
    setState(() => _busy = true);
    try {
      await controller.createHabit(
        name: habit.name,
        tiny: habit.tiny,
        why: _why.text,
        reminderMinutes: _minutes,
        emoji: habit.emoji,
        templateId: habit.templateId,
        quizQuitDay: _quitDay,
        quizReason: _reason,
      );
      if (record) await widget.onRecordFirstClip?.call();
      widget.onFinished?.call();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: _step == _Step.welcome && !_busy,
    onPopInvokedWithResult: (didPop, _) {
      if (!didPop) _back();
    },
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      // No taps until a step has fully faded in: the big buttons share one
      // spot, so a double tap would otherwise hit the next step's button.
      transitionBuilder: (child, animation) => AnimatedBuilder(
        animation: animation,
        builder: (_, child) => IgnorePointer(
          ignoring: animation.status != AnimationStatus.completed,
          child: child,
        ),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: KeyedSubtree(key: ValueKey(_step), child: _buildStep(context)),
    ),
  );

  Widget _buildStep(BuildContext context) => switch (_step) {
    _Step.welcome => _welcome(context),
    _Step.quitDay => _choice(
      title: 'When do you usually quit?',
      highlight: 'quit',
      choices: _quitDayChoices,
      selected: _quitDay,
      onSelect: (a) => setState(() => _quitDay = a),
      onSkip: () {
        setState(() => _quitDay = null);
        _next();
      },
    ),
    _Step.reason => _choice(
      title: 'Why do you usually stop?',
      highlight: 'stop',
      choices: _reasonChoices,
      selected: _reason,
      onSelect: (r) => setState(() => _reason = r),
      onSkip: () {
        setState(() => _reason = null);
        _next();
      },
    ),
    _Step.habit => HabitPicker(
      progress: _progress,
      onBack: _back,
      initial: _habit,
      onPicked: (h) {
        setState(() => _habit = h);
        _next();
      },
    ),
    _Step.why => _whyStep(),
    _Step.reminder => _reminderStep(context),
    _Step.wall => _wallStep(context),
    _Step.promise => _promiseStep(context),
  };

  Widget _welcome(BuildContext context) => StepScaffold(
    title: 'Built for the day you quit.',
    highlight: 'quit',
    progress: 0,
    buttonLabel: 'Start',
    onButton: _next,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 96,
          height: 96,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: StickColors.lime,
            borderRadius: BorderRadius.circular(22),
          ),
          child: const ExcludeSemantics(
            child: Text(
              'S.',
              style: TextStyle(
                fontFamily: 'ArchivoBlack',
                fontSize: 52,
                color: StickColors.bg,
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),
        const Text(
          'Most habit apps want a perfect streak. '
          'Stick plans for the day you want to stop.',
          style: TextStyle(fontSize: 17, height: 1.4),
        ),
      ],
    ),
  );

  Widget _choice<T>({
    required String title,
    required String highlight,
    required List<(T, String, String)> choices,
    required T? selected,
    required ValueChanged<T> onSelect,
    required VoidCallback onSkip,
  }) => StepScaffold(
    title: title,
    highlight: highlight,
    progress: _progress,
    onBack: _back,
    onSkip: onSkip,
    buttonLabel: 'Continue',
    onButton: selected == null ? null : _next,
    body: Column(
      children: [
        for (final (value, emoji, label) in choices)
          ChoiceCard(
            emoji: emoji,
            label: label,
            selected: value == selected,
            onTap: () => onSelect(value),
          ),
      ],
    ),
  );

  Widget _whyStep() => StepScaffold(
    title: 'Why are you starting?',
    highlight: 'starting',
    progress: _progress,
    onBack: _back,
    buttonLabel: 'Continue',
    onButton: _next,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _why,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Your reason (optional)'),
        ),
        const SizedBox(height: 16),
        // One per row, like the quiz answers; tapping fills the reason.
        for (final (emoji, label) in _whyExamples)
          ChoiceCard(
            emoji: emoji,
            label: label,
            selected: _why.text.trim() == label,
            onTap: () => setState(() => _why.text = label),
          ),
      ],
    ),
  );

  String get _timeLabel {
    final h = (_minutes ~/ 60).toString().padLeft(2, '0');
    final m = (_minutes % 60).toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _reminderStep(BuildContext context) => StepScaffold(
    title: 'When should Stick remind you?',
    highlight: 'remind',
    progress: _progress,
    onBack: _back,
    buttonLabel: 'Continue',
    onButton: _busy ? null : _afterReminder,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          _timeLabel,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displaySmall
              ?.copyWith(color: StickColors.lime),
        ),
        const SizedBox(height: 12),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final (label, minutes) in _timeChips)
              ChoiceChip(
                label: Text(label),
                selected: _minutes == minutes,
                showCheckmark: false,
                selectedColor: StickColors.lime,
                labelStyle: TextStyle(
                  color: _minutes == minutes ? StickColors.bg : null,
                ),
                onSelected: (_) => setState(() {
                  _minutes = minutes;
                  _wheelVersion++;
                }),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: cupertino.CupertinoTheme(
            data: const cupertino.CupertinoThemeData(
              brightness: Brightness.dark,
            ),
            child: CupertinoDatePicker(
              key: ValueKey(_wheelVersion),
              mode: cupertino.CupertinoDatePickerMode.time,
              use24hFormat: MediaQuery.alwaysUse24HourFormatOf(context),
              initialDateTime: DateTime(
                2026,
                1,
                1,
                _minutes ~/ 60,
                _minutes % 60,
              ),
              onDateTimeChanged: (d) =>
                  setState(() => _minutes = d.hour * 60 + d.minute),
            ),
          ),
        ),
      ],
    ),
  );

  Widget _wallStep(BuildContext context) => StepScaffold(
    title: wallTitle(_quitDay),
    highlight: 'wall',
    progress: _progress,
    onBack: _back,
    buttonLabel: 'Got it',
    onButton: _next,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WallChart(quitDay: firstQuitTarget(_quitDay)),
        const SizedBox(height: 16),
        Text(
          wallLine(_quitDay),
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            fontVariations: [FontVariation('wght', 700)],
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Stick is built for that dip: on your quit day it shows a rescue '
          'screen, a tinier version and your own message.',
          style: TextStyle(color: StickColors.muted, height: 1.45),
        ),
      ],
    ),
  );

  Widget _promiseStep(BuildContext context) {
    final habit = _habit;
    final canRecord = widget.onRecordFirstClip != null;
    final lines = habit == null
        ? const <String>[]
        : promiseLines(name: habit.name, tiny: habit.tiny, quitDay: _quitDay);
    return StepScaffold(
      title: 'I promise I will',
      highlight: 'I will',
      progress: _progress,
      onBack: _back,
      buttonLabel: canRecord ? 'I promise. Record it' : 'I promise',
      onButton: _busy ? null : () => _promise(record: canRecord),
      below: canRecord
          ? TextButton(
              onPressed: _busy ? null : () => _promise(record: false),
              style: TextButton.styleFrom(foregroundColor: StickColors.muted),
              child: const Text('Skip recording'),
            )
          : null,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final l in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CircleAvatar(
                    radius: 12,
                    backgroundColor: StickColors.lime,
                    child: Icon(Icons.check, size: 15, color: StickColors.bg),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l,
                      style: const TextStyle(
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        fontVariations: [FontVariation('wght', 600)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (canRecord) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: StickColors.lime, width: 3),
                ),
                child: const Icon(
                  Icons.mic_rounded,
                  size: 48,
                  color: StickColors.lime,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Say it out loud. Future you will hear it on day '
              '${firstQuitTarget(_quitDay)}.',
              textAlign: TextAlign.center,
              style: TextStyle(color: StickColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
