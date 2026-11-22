# Habit Name + Clearer Progress Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show the habit name on Home and Progress, and make every number on Progress clear and consistent.

**Architecture:** A UI-only change, plus one new field on the pure `AttemptBar` model (`daysDone`). Home gets a name headline and a chevron on the counter. Progress gets a habit-name title, labeled bars measured in days done, a ★ legend and a button whose label depends on the day. Engine rules stay unchanged.

**Tech Stack:** Flutter 3.50.1 / Dart 3.14, flutter_test. Run everything from `apps/stick` with `~/development/flutter/bin/flutter`.

**Spec:** `docs/superpowers/specs/2026-11-22-habit-name-and-progress-clarity-design.md`

## Global Constraints

- No change to engine rules (day numbers, pause, quit day, rescue) or to when the why shows.
- No new navigation; the counter still opens Progress, and the Progress button still just pops.
- Nothing may overflow at 360dp wide (habit names wrap to max 2 lines, then ellipsize).
- Copy (exact):
  - `Your attempts`
  - `Attempt N`
  - `Attempt N · now`
  - `N days` / `1 day`
  - `★ = got past your quit day (Day X)`
  - `Back to Day N`
  - `Get past Day X this time`
- `flutter analyze --no-fatal-infos` stays clean, `dart format` leaves no changes, and all tests pass (the PR checks on `main` enforce these).

## Review Focus

1. **A 40-character habit name on a 360×640 screen at text scale 1.3:** no RenderFlex overflow on Home or Progress. Tests are in Tasks 1 and 2.
2. **A current attempt with 0 check-ins (Day 1):** the row reads "0 days" with a zero-width bar and no crash. Test in Task 1.
3. **The quit-day boundary:** on Day 3 with target 3, the button reads "Get past Day 3 this time"; on Day 4 it reads "Back to Day 4". Test in Task 1.
4. **No ★ on screen:** the legend is absent. Test in Task 1.
5. **Counter without a Progress callback:** no chevron shows, because it wouldn't be tappable. Test in Task 2.

---

### Task 1: Progress screen

**Files:**
- Modify: `lib/domain/progress.dart` (add `AttemptBar.daysDone`)
- Modify: `lib/ui/progress/progress_screen.dart`
- Test: `test/domain/progress_test.dart`, `test/ui/progress_screen_test.dart`

**Interfaces:**
- Produces: `AttemptBar.daysDone` (`int`), the number of check-ins in that attempt; for the current attempt that's `s.currentCheckIns.length`. `length` (the day reached) and `beatQuitDay` keep their meaning.

- [ ] **Step 1: Write failing domain tests** in `progress_test.dart`, using the existing helpers there:
  - `'daysDone counts check-ins per attempt'`: ended attempt 1 with 4 check-ins and current attempt 2 with 2 check-ins → `bars[0].daysDone == 4`, `bars[1].daysDone == 2`.
  - `'current attempt with no check-ins has daysDone 0'` → `bars.last.daysDone == 0`.
- [ ] **Step 2: Write failing widget tests** in `progress_screen_test.dart`. First extend `pump` with optional `int day = 2` and `int target = 6`, which feed `HomeState.dayNumber` / `quitTarget` and `current.quitTarget`, plus an optional `String name = 'Walk'`. With the existing fixture (attempt 1: 5 check-ins, ★; attempt 2: 1 check-in), update `'shows the numbers from stored data'` to expect:
  - `find.text('Walk')` (app bar title)
  - `find.text('Progress')` finds nothing
  - `'Your attempts'`
  - `'Attempt 1'`
  - `'Attempt 2 · now'`
  - `'5 days'`
  - `'1 day'`
  - `find.textContaining('★')` finds at least one widget
  - `'★ = got past your quit day (Day 6)'`
  - `'Beat your quit day'` finds nothing
  - `'Days you showed up'` (still present)

  New tests:
  - `'button says Back to Day N once past the quit day'`: `day: 4, target: 3` → `'Back to Day 4'`, and no text containing `'Get past'`. Tapping it pops.
  - `'button keeps Get past on the quit day'`: `day: 3, target: 3` → `'Get past Day 3 this time'`.
  - `'no legend without a star'`: a fixture whose ended attempt has `finalDay` ≤ its `quitTarget` (add a `bool star = true` pump flag that sets attempt 1's `quitTarget` to 9) → no text containing `'★ ='`.
  - `'long name does not overflow'`: `t.view.physicalSize = Size(360, 640)`, `devicePixelRatio = 1`, `MediaQuery` text scale 1.3 (`tester.platformDispatcher.textScaleFactorTestValue = 1.3`), name `'Read twenty pages of a book every single night'` → `t.takeException()` is null. Reset the view in `addTearDown`.
- [ ] **Step 3: Run and see them fail:** `flutter test test/domain/progress_test.dart test/ui/progress_screen_test.dart`. Expected: compile error on `daysDone`, or failures on the new copy.
- [ ] **Step 4: Implement.**
  - In `computeProgress`, set `daysDone` from `s.allCheckIns.where((c) => c.attempt == a.number).length` for ended attempts and `s.currentCheckIns.length` for the current one.
  - In `ProgressScreen`:
    - The AppBar title is `Text(snap.habit.name, maxLines: 2, overflow: TextOverflow.ellipsis)`.
    - Add a `Your attempts` label above the bars.
    - Each row shows `Attempt N` or `Attempt N · now`, the bar, `N days` / `1 day`, and ` ★` when `beatQuitDay`.
    - Bar width is `box.maxWidth * daysDone / max(14, longest daysDone)`.
    - The legend line appears only if any bar has `beatQuitDay`, using `p.nextQuitTarget`.
    - Remove the `Beat your quit day` stat.
    - Button label: `home.dayNumber > p.nextQuitTarget ? 'Back to Day ${home.dayNumber}' : 'Get past Day ${p.nextQuitTarget} this time'`.
    - Row layout is your call, but it must not overflow at 360dp. Putting the label line above the bar is the safe choice.
  - Remove `quitDaysBeaten` from `Progress` if nothing else reads it, and adjust its domain test.
- [ ] **Step 5: Run and see them pass:** the same command, all PASS.
- [ ] **Step 6: Format, analyze and commit**
```bash
dart format lib test && flutter analyze --no-fatal-infos
git add lib/domain/progress.dart lib/ui/progress/progress_screen.dart test/domain/progress_test.dart test/ui/progress_screen_test.dart
git commit -m "feat: clearer Progress screen with habit name, labeled attempts and days done"
```

### Task 2: Home — habit name and tappable counter

**Files:**
- Modify: `lib/ui/home/home_screen.dart`
- Test: `test/ui/home_screen_test.dart`

**Interfaces:**
- Consumes: `snap.habit.name`. Counter text stays exactly `Attempt N · Day N`, so existing e2e, road and navigation tests keep finding it.

- [ ] **Step 1: Write failing tests** in `home_screen_test.dart`, using its existing `pump` / `state` / `snap` helpers:
  - `'shows the habit name'` → `find.text('Walk')` finds one widget, both with `HomeStyle.bigNumber` and with `HomeStyle.road`. Use `snap(...)` with `flags.homeStyle` if the helper allows; otherwise add a `homeStyle` parameter to the helper.
  - `'counter shows a chevron when progress can open'`: with `onOpenProgress` set → `find.byIcon(Icons.chevron_right)` finds one widget. Tapping `'Attempt 4 · Day 2'` still opens Progress (keep the existing test).
  - `'no chevron without progress callback'` → `find.byIcon(Icons.chevron_right)` finds nothing.
  - `'long name does not overflow'`: same 360×640 + text scale 1.3 setup as in Task 1, a 46-char name, day 3 rescue state (`RescueReason.quitDay`, `attempt: 2`, `lastQuitDay: 3`) for the tallest layout → `t.takeException()` is null.
- [ ] **Step 2: Run and see them fail:** `flutter test test/ui/home_screen_test.dart`.
- [ ] **Step 3: Implement.**
  - Name headline: `Text(snap.habit.name, textAlign: center, maxLines: 2, overflow: ellipsis, style: textTheme.headlineSmall)`, followed by `SizedBox(height: 16)`.
  - Placement: directly above `number` in the centered column, after the "Last time you stopped…" line.
  - Counter: in the tappable branch only, make it an outlined pill that reads as a button: `Material` + `InkWell` with a `StadiumBorder` (1px `StickColors.muted` at ~50% alpha), padding `EdgeInsets.symmetric(horizontal: 14, vertical: 8)`, min height 48 tap target, content `Row(mainAxisSize: min, children: [Icon(Icons.bar_chart_rounded, size: 16, color: StickColors.lime), SizedBox(width: 6), counter, Icon(Icons.chevron_right, size: 18, color: StickColors.muted)])`. Counter text brightened from `StickColors.muted` to the normal text color inside the pill. The non-tappable branch stays plain text.
- [ ] **Step 4: Run the whole suite:** `flutter test`. Expected: all pass. Fix any existing test that breaks because `'Walk'` now appears twice. None is expected.
- [ ] **Step 5: Format, analyze and commit**
```bash
dart format lib test && flutter analyze --no-fatal-infos
git add lib/ui/home/home_screen.dart test/ui/home_screen_test.dart
git commit -m "feat: show habit name on home and a chevron on the progress counter"
```

### Task 3: Check on the emulator

- [ ] `flutter run -d emulator-5554`. On Home (both styles via Settings → Home style) the habit name shows and the counter has a ›. Progress matches the spec sketch (title = name, "6 days" next to the big 6, legend, "Back to Day 7").
- [ ] Take a screenshot of each with `adb exec-out screencap -p > <scratchpad>/home.png` (and progress.png), and show them to the user.
