# Friendlier Home, Timer and Logo Intro (rest of 1.1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Finish version 1.1: new Home (week strip, emoji habit card, slide to check in, rescue chips), bottom tabs (Home · Progress · Messages · Settings), one-time tips, the 2-minute tiny timer, and a startup logo animation.

**Architecture:** Pure week-strip logic in the domain. Two new flags (check-in mode, tips seen) folded into schema 1 (no migration; the reset guard is generalised to any missing column). New widgets: `SlideToCheckIn`, `WeekStrip`, `TinyTimerScreen`, `LogoIntro`, `HomeShell` (tabs). Existing Progress, clip list and Settings screens become tab bodies.

**Tech Stack:** Flutter 3.50.1, drift, flutter_test. No new packages.

**Spec:** `docs/superpowers/specs/2026-11-25-friendly-update-design.md` (sections "Update 1.2", "Update 1.3", "Startup logo animation", "Rollout"). Mockups: `docs/superpowers/specs/mockups/friendly-update.png` screens 5–6. Continues `docs/superpowers/plans/2026-11-25-friendly-start.md` on branch `feat/friendly-start`.

## Global Constraints
- Same as the 1.1 onboarding plan: theme colours/fonts only, no new packages/permissions/network, PR checks green, `SafeArea`, scroll at 2× font.
- **No release builds** (`--release`) unless the user asks; verify with `flutter build apk --debug`.
- Version stays `1.1.0+2`; release notes rewritten once for everything.
- Missed days never look different from future days (no red), per the Progress rule.
- Check-in default is **slide**; **tap** available in Settings ("Check-in: Slide / Tap").
- Back from a non-Home tab returns to Home; back on Home leaves the app.
- Animations respect `MediaQuery.disableAnimationsOf(context)`.

## Review Focus
1. **Double check-in:** a slide that completes while a check-in is running, or slide + timer finishing at once, must check in once. Test in Task 3 (slide) and Task 6 (timer → already checked in is a no-op).
2. **Paused / already done states:** paused shows "Pick it back up" (button, not slide); done shows a disabled "Done for today ✓". Test in Task 3.
3. **TalkBack:** the slide must be operable without a drag (`Semantics(onTap)` labelled "Done today"). Test in Task 2.
4. **Tabs + existing pushes:** fresh start in Settings (`popUntil(isFirst)`) and the day-4 / weekly replay pushes still work inside the shell. Test in Task 4.
5. **Restored old database:** a database with `habits.emoji` but without the new flag columns must also reset, not crash. Test in Task 1.

---

### Task 1: Week strip logic, new flags, reset guard

**Files:** Create `lib/domain/week_strip.dart`; modify `lib/domain/models.dart` (`Flags`, new `enum CheckInMode { slide, tap }`), `lib/data/database.dart` (`Flags` table columns `checkInMode` textEnum default `'slide'`, `tipsSeen` bool default false; generalised `beforeOpen`), `lib/data/repository.dart` (map both), `lib/controller/stick_controller.dart`; regenerate `database.g.dart`, re-dump `drift_schemas/drift_schema_v1.json`. Tests: `test/domain/week_strip_test.dart`, `test/data/repository_test.dart`, `test/controller/stick_controller_test.dart`.

**Interfaces (produces):**
- `enum WeekDayState { done, today, todayDone, other }`
- `class WeekDay { final DayKey day; final String letter; final WeekDayState state; }` (letters `M T W T F S S`)
- `List<WeekDay> weekStrip(DayKey today, Iterable<DayKey> checkInDays)` — Monday-to-Sunday week containing `today`.
- `Flags` gains `checkInMode` (default `CheckInMode.slide`) and `tipsSeen` (default `false`), in `copyWith`/`==`/`hashCode`.
- `StickController.setCheckInMode(CheckInMode m)`, `StickController.markTipsSeen()` — both through the op queue, like `setHomeStyle`.
- `beforeOpen` guard: for every table in `allTables` that exists, if any declared column is missing from `PRAGMA table_info`, drop all tables and `createAll()`.

- [ ] **Step 1: Failing tests**
  - `weekStrip('2026-11-25' /*Wed*/, ['2026-11-23','2026-11-24','2026-11-17'])` → letters `MTWTFSS`, days `2026-11-23..29`, states `[done, done, today, other, other, other, other]`.
  - same with `'2026-11-25'` in the check-ins → index 2 is `todayDone`.
  - Sunday `'2026-11-29'` → week still starts `2026-11-23`.
  - repository: `setFlags(flags.copyWith(checkInMode: CheckInMode.tap, tipsSeen: true))` round-trips; a fresh habit has `slide` / `false`.
  - repository: old DB with full v1.1-onboarding `habits` (has `emoji`) but a `flags` table without `check_in_mode` → `load()` returns null (reset), no throw.
  - controller: `setCheckInMode(CheckInMode.tap)` → `snapshot!.flags.checkInMode == tap`; `markTipsSeen()` → `tipsSeen == true`.
- [ ] **Step 2: Run** `flutter test test/domain/week_strip_test.dart test/data test/controller` → FAIL.
- [ ] **Step 3: Implement**; `dart run build_runner build --delete-conflicting-outputs`; `dart run drift_dev schema dump lib/data/database.dart drift_schemas/`.
- [ ] **Step 4: Run** `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(data): week strip, check-in mode and tips flags`.

---

### Task 2: SlideToCheckIn widget

**Files:** Create `lib/ui/home/slide_to_check_in.dart`; test `test/ui/slide_to_check_in_test.dart`.

**Interfaces (produces):** `SlideToCheckIn({required VoidCallback? onDone, VoidCallback? onLongPress, String label = 'Slide when done'})` — 64-high stadium track (`#1B1B25`), 52 px lime knob with `→` at the left; the track fills lime behind the knob while dragging; `HapticFeedback.selectionClick` once each time the knob first passes 25 %, 50 % and 75 %; dragging past 80 % locks: knob snaps to the end, `→` becomes `✓`, `HapticFeedback.mediumImpact`, a soft lime glow pulse (200 ms), and `onDone` is called once; releasing earlier springs the knob back with no haptic. With animations disabled: no glow, instant snap. `onDone == null` → disabled look, no drag. Key `Key('slide-knob')`. `Semantics(button: true, label: 'Done today', onTap: onDone)`.

- [ ] **Step 1: Failing tests** — haptics: record `SystemChannels.platform` `HapticFeedback.vibrate` calls with `t.binding.defaultBinaryMessenger.setMockMethodCallHandler`; a full drag gives 3 `HapticFeedbackType.selectionClick` then 1 `HapticFeedbackType.mediumImpact`; a 40 % drag gives 1 selection click and no impact; drag knob by 90 % of track width → `onDone` called once; drag 40 % → not called and knob returns to start after settle; second full drag in the same widget before rebuild still calls once (guard until `onDone` is replaced); `onDone: null` → drag does nothing; semantics tap (`t.semantics.tap(find.bySemanticsLabel('Done today'))` or `SemanticsAction.tap` via `tester.binding.pipelineOwner.semanticsOwner`) calls `onDone`; long-press calls `onLongPress`.
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** → PASS.
- [ ] **Step 5: Commit** `feat(home): slide to check in`.

---

### Task 3: New Home layout

**Files:** Modify `lib/ui/home/home_screen.dart`; create `lib/ui/home/week_strip_view.dart`; tests `test/ui/home_screen_test.dart` (update), `test/ui/day4_screen_test.dart`, `test/e2e_test.dart` (check-in helper), plus any test using `find.text('Done today')`.

**Interfaces:**
- Consumes: `weekStrip`, `Flags.checkInMode`, `SlideToCheckIn`.
- `HomeScreen({VoidCallback? onPlayReplay, VoidCallback? onOpenTimer})` — the progress pill, settings icon, "See all" and "Add a message" are **removed** (tabs replace them). Keep `onOpenProgress` tap on the attempt line (it switches to the Progress tab).
- `WeekStripView({required List<WeekDay> days})` — 7 columns: letter above a 34 px circle; `done`/`todayDone` lime with ✓, `today` dashed lime ring with the day number, `other` grey ring empty.

Layout (top → bottom): row `Attempt N` (tappable → Progress) ; `WeekStripView`; card (`#16161F`, radius 24) with `${emoji} ${name}`, the number (Big number or Road, unchanged), and in rescue: "Just do this. Get to day N+1.", `tinyLine`, the quiz hint, then chips `⏱ 2-min timer` (→ `onOpenTimer`) and `▶ Your message` (→ `onPlayReplay`, only with clips; otherwise the why text as today); "Last time you stopped on Day N" stays above the card. Bottom: by `checkInMode` — slide (`SlideToCheckIn`, long-press → `onOpenTimer`) or the existing tap button; paused → "Pick it back up" button; checked in → disabled "Done for today ✓". The "Record one for future you." banner stays.

**Check-in moment (about 0.9 s, after `checkIn()` succeeds):** the number rolls up like an odometer from N to N+1 (`AnimatedSwitcher` slide-up + fade, 400 ms; Road style moves the "Today" dot up one step), with `HapticFeedback.lightImpact` as it rolls; today's week-strip circle fills lime with a 1.0→1.15→1.0 pop (400 ms, starts 100 ms after the roll); 6 small lime sparks drift up from the number and fade (500 ms); the slide bar settles into "Done for today ✓". On day 4 (`showDay4`): `HapticFeedback.heavyImpact` twice 120 ms apart, then the existing Day 4 screen opens after the moment finishes. With animations disabled: number and circle change instantly, no sparks, haptics stay.

- [ ] **Step 1: Update tests first**: add `Future<void> slide(WidgetTester t)` helper (drag `Key('slide-knob')` by 400 px, settle) in a shared `test/support/home_helpers.dart`; switch existing `tap('Done today')` uses to `slide(t)` where mode is slide; add tests: week strip renders today dashed and 2 done checks; emoji + name in the card; tap mode shows the `Done today` button; paused shows `Pick it back up` (no knob); done shows `Done for today ✓` and no knob; rescue shows both chips (with clips) and the timer chip calls `onOpenTimer`; no "See all"/"Add a message" on Home; after a slide the number shows N+1 only once the roll has finished (`pump(200ms)` still shows N in the incoming/outgoing pair, `pumpAndSettle` shows only N+1); sparks present at 300 ms and gone after settle; with `MediaQuery(disableAnimations: true)` the number is N+1 after one pump and no sparks; on day 3→4 two heavy impacts are recorded before the Day 4 screen appears.
- [ ] **Step 2: Run** `flutter test test/ui test/e2e_test.dart` → FAIL.
- [ ] **Step 3: Implement.**
- [ ] **Step 4: Run** `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(home): week strip, habit card, slide check-in, rescue chips`.

---

### Task 4: Tabs (HomeShell)

**Files:** Create `lib/ui/shell/home_shell.dart`, `lib/ui/replay/messages_tab.dart`; modify `lib/app.dart`, `lib/ui/progress/progress_screen.dart`, `lib/ui/replay/clip_list_screen.dart`, `lib/ui/settings/settings_screen.dart` (add "Check-in" Slide/Tap `SegmentedButton` under Home style; hide AppBar back when used as a tab); tests `test/ui/home_shell_test.dart`, `test/ui/navigation_guard_test.dart` (update), `test/ui/settings_screen_test.dart` (check-in setting).

**Interfaces:**
- `HomeShell({required Widget home, required Widget progress, required Widget messages, required Widget settings, ValueNotifier<int>? tab})` — `NavigationBar` (Material 3, dark, lime indicator) with Home (`Icons.home_rounded`), Progress (`Icons.bar_chart_rounded`), Messages (`Icons.play_circle_outline`), Settings (`Icons.settings_outlined`); `IndexedStack` bodies; `PopScope(canPop: tab == 0)`, back on other tabs → tab 0.
- `MessagesTab({VoidCallback? onAddMessage, VoidCallback? onPlayAll, ...})` — the clip list plus a lime `+ Add a message` button and `▶ Play` (when clips exist).
- `_Root` builds `HomeShell` instead of `HomeScreen`; Home's attempt line sets `tab.value = 1`.

- [ ] **Step 1: Failing tests**: four tab labels visible; tapping Messages shows `Your messages` and `+ Add a message`; system back on Messages returns to Home; back on Home leaves (`canPop` true); Settings → Check-in Tap → Home shows `Done today` button; fresh start from the Settings tab ends on setup (`Built for the day you quit.`).
- [ ] **Step 2: Run** → FAIL. **Step 3: Implement.** **Step 4: Run** `flutter test` → PASS.
- [ ] **Step 5: Commit** `feat(app): bottom tabs for Home, Progress, Messages, Settings`.

---

### Task 5: One-time tips

**Files:** Create `lib/ui/home/tip_bubble.dart`; modify `lib/ui/home/home_screen.dart`/`home_shell.dart`; test `test/ui/tips_test.dart`.

**Interfaces:** `TipBubble({required String text, required VoidCallback onOk})` — white rounded bubble, dark text, lime-dark `OK`, small arrow down. Shown on Home when `!flags.tipsSeen` and not paused: tip 1 above the slide bar `Slide the lime circle right when you've done it.` (tap mode: `Tap Done today when you've done it.`), after OK tip 2 above the Messages tab `Your messages to future you live here.`; OK on tip 2 calls `markTipsSeen()`.

- [ ] **Step 1: Failing tests**: first Home shows tip 1; OK → tip 2; OK → no tips and `tipsSeen` true; with `tipsSeen` true no tip.
- [ ] **Step 2–4:** FAIL → implement → `flutter test` PASS.
- [ ] **Step 5: Commit** `feat(home): one-time tips`.

---

### Task 6: Tiny timer

**Files:** Create `lib/ui/timer/tiny_timer_screen.dart`; modify `lib/app.dart` (wire `onOpenTimer`); test `test/ui/tiny_timer_test.dart`.

**Interfaces:** `TinyTimerScreen({required String emoji, required String name, required String tinyText, required Future<void> Function() onComplete, Duration length = const Duration(minutes: 2)})` — title `Just 2 minutes.` (`2 minutes` lime), ring countdown `m:ss` driven by a `Ticker` (fake-time friendly), line `${tinyText}` + `If you keep going, great. If not, it still counts.`, buttons `Pause`/`Resume` and `Done ✓`. Reaching 0 or `Done ✓` calls `onComplete` once, then pops. `onComplete` in app = `controller.checkIn()` (a no-op if already checked in — verify `checkIn` guards; if not, guard with `home.checkedInToday`). Keeps the screen on? No (no wakelock package); acceptable.

- [ ] **Step 1: Failing tests**: shows `2:00`, after `pump(Duration(seconds: 30))` shows `1:30`; Pause then 30 s still `1:30`; Resume; reaching 0 calls `onComplete` once and pops; `Done ✓` early calls once; double tap `Done ✓` calls once; app-level: rescue chip → timer → Done → Home shows `Done for today ✓`.
- [ ] **Step 2–4:** FAIL → implement → `flutter test` PASS.
- [ ] **Step 5: Commit** `feat(timer): 2-minute tiny-version timer`.

---

### Task 7: Startup logo animation

**Files:** Create `lib/ui/intro/logo_intro.dart`; modify `lib/app.dart` (`StickApp({bool showIntro = false})`), `lib/lifecycle.dart` (passes `showIntro: true`); test `test/ui/logo_intro_test.dart`.

**Interfaces:** `LogoIntro({required VoidCallback onDone})` — 800 ms `AnimationController`: 0–300 ms lime tile (140 px, radius 32) scales 0.9→1.05→1 with `S` in ArchivoBlack; 250–550 ms the dot drops from above with `Curves.bounceOut`; 450–750 ms `STICK` (ArchivoBlack, lime) slides in from the right and fades in; 700–800 ms whole intro fades out; then `onDone`. Tap anywhere → `onDone` immediately. `MediaQuery.disableAnimationsOf` → `onDone` on the first frame. Background `#0B0B12`. `_Root` shows it once per process (static flag) when `showIntro`.

- [ ] **Step 1: Failing tests**: `STICK` text appears by 600 ms; after 800 ms `onDone` called once; tap at 100 ms → `onDone` once; disabled animations → `onDone` after first pump; `StickApp(showIntro: true)` shows the intro then setup.
- [ ] **Step 2–4:** FAIL → implement → `flutter test` PASS.
- [ ] **Step 5: Commit** `feat(app): startup logo animation`.

---

### Task 8: Release notes, checklist, docs, local checks

**Files:** `docs/release-notes/1.1.0.txt`, `TESTING.md` (rows 34+ for Home/tabs/slide/timer/intro), `CLAUDE.md` status, `stick-mvp.md` (check-in decided as slide).

- [ ] **Step 1:** Release notes (≤ 500 chars):
  ```
  <en-US>
  Stick 1.1: a friendlier app.
  • New start: pick a habit from a list, answer 2 quick questions, make a promise
  • Home shows your week at a glance
  • Slide to check in (tap is in Settings)
  • Day 3 rescue: a 2-minute timer and a hint for why you usually stop
  • Tabs for Progress, Messages and Settings
  Tell me what feels confusing: @th3_on3guy on Instagram.
  </en-US>
  ```
- [ ] **Step 2:** `dart format --output=none --set-exit-if-changed lib test`, generated code fresh, `flutter analyze --no-fatal-infos` (0 warnings), `flutter test`, `flutter build apk --debug`. **No release build.**
- [ ] **Step 3: Commit** `chore: 1.1 release notes, checklist and docs`.
