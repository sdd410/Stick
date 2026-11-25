import 'package:flutter/material.dart';

import '../../domain/onboarding.dart';
import '../../theme.dart';
import 'setup_widgets.dart';

/// What the user chose on the habit step.
class PickedHabit {
  const PickedHabit({
    required this.emoji,
    required this.name,
    required this.tiny,
    required this.templateId,
  });

  final String emoji;
  final String name;
  final String? tiny;
  final String? templateId;
}

const _labels = {
  TemplateCategory.popular: 'Popular',
  TemplateCategory.body: 'Body',
  TemplateCategory.mind: 'Mind',
  TemplateCategory.work: 'Work',
};

/// "Pick your habit": templates by category, each opening an edit sheet,
/// plus "My own habit" for free text.
class HabitPicker extends StatefulWidget {
  const HabitPicker({
    super.key,
    required this.progress,
    required this.onBack,
    required this.onPicked,
    this.initial,
  });

  final double progress;
  final VoidCallback onBack;
  final ValueChanged<PickedHabit> onPicked;

  /// The earlier pick when the user came back to this step.
  final PickedHabit? initial;

  @override
  State<HabitPicker> createState() => _HabitPickerState();
}

class _HabitPickerState extends State<HabitPicker> {
  TemplateCategory _category = TemplateCategory.popular;

  Future<void> _edit({HabitTemplate? template}) async {
    final picked = await showModalBottomSheet<PickedHabit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF16161F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _EditSheet(template: template),
    );
    if (picked != null) widget.onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final initial = widget.initial;
    return StepScaffold(
      title: 'Pick your habit',
      highlight: 'habit',
      progress: widget.progress,
      onBack: widget.onBack,
      buttonLabel: initial == null
          ? null
          : 'Continue with ${initial.emoji} ${initial.name}',
      onButton: initial == null ? null : () => widget.onPicked(initial),
      floating: FilledButton(
        onPressed: () => _edit(),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 52),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 22),
        ),
        child: const Text('✎ My own habit'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in TemplateCategory.values)
                ChoiceChip(
                  label: Text(_labels[c]!),
                  selected: c == _category,
                  showCheckmark: false,
                  selectedColor: StickColors.lime,
                  labelStyle: TextStyle(
                    color: c == _category ? StickColors.bg : StickColors.muted,
                    fontWeight: FontWeight.w600,
                    fontVariations: const [FontVariation('wght', 600)],
                  ),
                  onSelected: (_) => setState(() => _category = c),
                ),
            ],
          ),
          const SizedBox(height: 8),
          for (final t in templatesFor(_category))
            _TemplateRow(
              template: t,
              onTap: () => _edit(template: t),
            ),
        ],
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  const _TemplateRow({required this.template, required this.onTap});

  final HabitTemplate template;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF262633))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(template.emoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    fontVariations: [FontVariation('wght', 700)],
                  ),
                ),
                Text(
                  'Tiny: ${template.tiny}',
                  style: const TextStyle(
                    fontSize: 13,
                    color: StickColors.muted,
                  ),
                ),
              ],
            ),
          ),
          const ExcludeSemantics(
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFF1F1F2A),
              child: Icon(Icons.add, size: 20, color: StickColors.lime),
            ),
          ),
        ],
      ),
    ),
  );
}

/// "Make it yours": name and tiny version, prefilled from a template.
class _EditSheet extends StatefulWidget {
  const _EditSheet({this.template});

  final HabitTemplate? template;

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  late final _name = TextEditingController(text: widget.template?.name ?? '');
  late final _tiny = TextEditingController(text: widget.template?.tiny ?? '');

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _tiny.dispose();
    super.dispose();
  }

  void _done() {
    final tiny = _tiny.text.trim();
    Navigator.of(context).pop(
      PickedHabit(
        emoji: widget.template?.emoji ?? defaultEmoji,
        name: _name.text.trim(),
        tiny: tiny.isEmpty ? null : tiny,
        templateId: widget.template?.id,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ok = _name.text.trim().isNotEmpty;
    return Padding(
      // Clear the keyboard, or else the system navigation bar (3-button
      // navigation sits over the sheet otherwise).
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 +
            (MediaQuery.viewInsetsOf(context).bottom >
                    MediaQuery.viewPaddingOf(context).bottom
                ? MediaQuery.viewInsetsOf(context).bottom
                : MediaQuery.viewPaddingOf(context).bottom),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Make it yours',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 20),
            TextField(
              key: const Key('habit-name'),
              controller: _name,
              autofocus: widget.template == null,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Habit',
                hintText: 'e.g. Walk 20 minutes',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('habit-tiny'),
              controller: _tiny,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Tiny version (for bad days)',
                hintText: 'Just show up for 2 minutes',
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: ok ? _done : null,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(56),
                shape: const StadiumBorder(),
              ),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
