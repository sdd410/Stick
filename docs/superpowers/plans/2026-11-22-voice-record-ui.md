# Voice Record UI Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Live voice bars + pulsing ring around a smaller mic, and a small stop square inside the record button.

**Architecture:** UI only, in `lib/ui/record/record_screen.dart`. A new small widget file `lib/ui/record/voice_level_view.dart` owns the bars + ring and listens to `Stream<double> level`. The record button change stays in `record_screen.dart`.

**Tech Stack:** Flutter 3.50.1, flutter_test. Run from `apps/stick` with `~/development/flutter/bin/flutter`.

**Spec:** `docs/superpowers/specs/2026-11-22-voice-record-ui-design.md`

## Global Constraints
- Sizes (exact): mic circle 72dp, mic icon 32, ring box 110dp, ring 2px; 30 bars, 4dp wide, 3dp gap, min 4dp, max 56dp; stop square 28dp, radius 6, color `StickColors.bg`, inside the 72dp lime circle.
- Reduced motion (`MediaQuery.of(context).disableAnimations`): no ring.
- No change to recording logic or `ClipRecorder`.
- `flutter analyze --no-fatal-infos` no errors/warnings; `dart format lib test` no changes; full `flutter test` passes.

## Review Focus
1. Subscribing to `level` is cancelled on dispose (no setState after dispose when leaving mid-recording).
2. Level values outside 0..1 (defensive clamp) don't break bar heights.
3. Bars reset when a new recording starts (no stale bars from a discarded take).
4. 360dp-wide screen at text scale 1.3: no overflow.
5. Reduced motion hides the ring.

---

### Task 1: Voice level view + small stop square

**Files:**
- Create: `lib/ui/record/voice_level_view.dart`
- Modify: `lib/ui/record/record_screen.dart` (replace `_levelMeter()`; record button child while recording)
- Test: `test/ui/voice_level_view_test.dart`, `test/ui/record_screen_test.dart`

**Interfaces:**
- Produces: `class VoiceLevelView extends StatefulWidget { const VoiceLevelView({super.key, required this.level}); final Stream<double> level; }` — keeps the last 30 readings (clamped 0..1), newest on the right; bars have `Key('voice-bar-$i')` (i = 0 oldest … 29 newest); the ring has `Key('voice-ring')`.

- [ ] **Step 1: Failing tests** in `voice_level_view_test.dart` (feed a `StreamController<double>.broadcast()`):
  - `'starts with 30 flat bars'`: 30 widgets with keys `voice-bar-0..29`, each height 4.
  - `'newest reading appears on the right'`: add 1.0, pump → `voice-bar-29` height 56, `voice-bar-28` height 4.
  - `'readings scroll left'`: add 1.0 then 0.0 → bar-28 height 56, bar-29 height 4.
  - `'clamps out-of-range levels'`: add 2.0 → bar-29 height 56; add -1 → height 4.
  - `'ring hidden with reduced motion'`: wrap in `MediaQuery(data: MediaQueryData(disableAnimations: true))` → `find.byKey(Key('voice-ring'))` findsNothing; without it → findsOneWidget.
  - `'cancels subscription on dispose'`: pump, then replace with `SizedBox()`, then add a level → no exception (`t.takeException()` null) and `controller.hasListener` false.
  In `record_screen_test.dart` (existing FakeRecorder):
  - `'recording shows a small stop square inside the button'`: start voice recording → a `Container`/`DecoratedBox` with `Key('stop-square')` of size 28x28 exists inside `Key('record-button')`; the button itself is 72x72 and circular.
  - `'voice recording shows the level view'` → `find.byType(VoiceLevelView)` findsOneWidget.
  - `'no overflow at 360dp, text scale 1.3'` while recording voice → `t.takeException()` null.
- [ ] **Step 2: Run, see them fail:** `flutter test test/ui/voice_level_view_test.dart test/ui/record_screen_test.dart`.
- [ ] **Step 3: Implement** `VoiceLevelView` (State holds a fixed-length list; `StreamSubscription` set up in `initState`, cancelled in `dispose`; each event → `setState`). Layout: Column(mainAxisSize: min) of [ring Stack (110 box: ring `AnimatedContainer`/`Transform.scale` + 72dp disc with `Icons.mic` 32), SizedBox(24), bars Row (end-aligned, height 56 box, bars `AnimatedContainer` 90ms)]. Older third of bars at ~0.55 opacity. In `RecordScreen`, voice branch uses `VoiceLevelView(key: ValueKey(<take id or start time>), level: _rec.level)` so a new take resets bars; record button: always a 72dp lime circle, child `Container(key: Key('stop-square'), 28x28, radius 6, StickColors.bg)` only while recording.
- [ ] **Step 4: Run, see them pass;** then full `flutter test`, `flutter analyze --no-fatal-infos`, `dart format lib test`.
- [ ] **Step 5: Commit** `feat: live voice bars and pulsing ring, smaller stop square` (with the Co-Authored-By line).
