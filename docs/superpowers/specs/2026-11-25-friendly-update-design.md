# Stick: Friendlier app (updates 1.1–1.3)

Date: 25 Nov 2026. Status: **approved 25 Nov 2026** (all three decisions below confirmed by the user).
Mockups: `mockups/friendly-update.png` (source `mockups/friendly-update.html`).

## Why
The user recorded a popular App Store habit app and found Stick "not at all user friendly" next to it. Stick works, but it feels like a form: "Step 1 of 3", empty text fields, a small Next button, and a Home screen made of text and buttons. The goal is to make Stick feel as easy and warm as that app while keeping what makes Stick different: one habit, built for the day you quit, private, no internet.

## What the reference app does well (and what we take)
| In the recording | Take it? | Stick version |
|---|---|---|
| One question per screen, big emoji cards, Continue disabled until a pick, progress bar, Skip | Yes | Onboarding quiz (screen 1) |
| Popular habit list with emoji and a "+", plus "Custom Habit" | Yes | Habit templates with a ready tiny version (screen 2) |
| "Habit formation curve" science screen | Yes, honest | "Day 3 is the wall" drawing, no made-up numbers (screen 3) |
| "I promise I will…" commitment screen | Yes | Promise list → record your first message (screen 4) |
| Week strip at the top of Today | Yes | Week strip above the day number (screen 5) |
| Swipe right to check in, coloured bars that fill | Yes | Swipe-to-check-in bar (screen 5), confirmed (see Decisions) |
| One-time coach-mark bubbles ("Tap this add button…") | Yes | One-time tips on first Home visit |
| Bottom tab bar | Yes | Home · Progress · Messages · Settings |
| Countdown timer for timed habits | Yes | 2-minute timer for the tiny version (screen 6) |
| Weekly / monthly / yearly grid | Later | Already on the Pro list as "history calendar" |
| Friends and groups, Apple Health sync | **No** | Need internet; breaks the privacy promise and the PR checks |
| Fake "70% OFF" 24-hour countdown, inflated reviews and user counts | **No** | Hurts trust with the followers who are the testers |
| Mood, stress meter, daily quote | No | Off-topic for a one-habit app |

## Goals
- A new user picks a habit and finishes setup in **under 30 seconds with mostly taps** (the MVP goal, now actually easy).
- Every screen has one clear main action, a big bottom button, and a way back.
- Home answers "how am I doing this week?" without opening Progress.
- Day 3 / rescue feels like help, not a warning.

## Non-goals
- Multiple habits, history calendar, widgets, themes (still Pro, still later).
- Any network feature.
- Changing how Day N, pauses, the learned quit day or clips work under the hood.

## Anti-goals (fail even if it works)
- Onboarding longer than about 8 screens or 60 seconds.
- Anything that guilt-trips a miss (no red X days, no broken streaks; the Progress rule "never show missed days" still holds).
- Dark patterns: fake timers, fake discounts, fake social proof.

## Approaches considered
1. **Three small updates, one theme each (picked).** 1.1 onboarding, 1.2 home, 1.3 timer. Each one is shippable to closed testers on its own, small enough to test on the 3 devices, and gives a "Build" reel per update.
2. One big redesign release. Fewer releases, but a long gap with nothing to show testers or followers, and a much bigger test surface.
3. Only redo onboarding. Fastest, but the daily screen (where users spend their time) stays plain.

Picked 1 (Claude's call, the user handed over the how).

## Update 1.1: Friendlier start (onboarding)
New flow, replacing `lib/ui/setup/setup_flow.dart`:

1. **Welcome**: S. logo, "Built for the day you quit.", "Start".
2. **Quiz, 1 question/screen** (emoji cards, Continue disabled until picked, progress bar, Skip on each):
   - "When do you usually quit?" Day 1 / Day 2 / Day 3 / After a week or two / Not sure.
   - "Why do you usually stop?" Too tired / Too busy / Got bored / Missed one day and gave up / Not sure.
3. **Pick your habit**: templates by category (Popular, Body, Mind, Work) with emoji and a pre-filled tiny version; "My own habit" button for free text. Picking a template goes to an edit card where name and tiny version are editable (prefilled).
4. **Why are you starting?**: kept, but with 3 tappable example chips plus free text, optional.
5. **Remind me at**: big time wheel (not a text button), with Morning / Lunch / Evening quick chips. Asks notification permission here (Android 13+), same as now.
6. **Day 3 is the wall**: the honest curve screen; copy uses the quiz answer ("You said day 3 gets you. Stick will be ready.").
7. **I promise**: 3 lines built from the answers (habit, tiny version, "show up on day N"), "I promise. Record it" → existing record screen, "Skip recording".

Reason text from the quiz ("why do you stop") is used for rescue-screen wording, e.g. "Too tired? The tiny version is enough today."

Data: store `emoji`, `templateId` (nullable), `quizQuitDay` (nullable), `quizReason` (nullable) on the habit. Drift migration + schema dump.

## Update 1.2: Friendlier home
- **Week strip** (Mon–Sun) at the top: lime check for check-ins, dashed ring for today, empty otherwise. **Missed days look the same as future days** (no red), so the "never show missed days" rule holds.
- **Habit card** with emoji + name, then the existing number (Big number or Road style, both kept).
- **Swipe-to-check-in bar** at the bottom with haptic feedback and a short lime burst. Accessibility: TalkBack gets a "Mark done" action; Settings gets "Check-in: Swipe / Tap" (default **Swipe**, confirmed).
- **Rescue state**: chips for "⏱ 2-min timer" and "▶ Your message" inside the card instead of loose buttons.
- **Bottom tabs**: Home, Progress, Messages (replaces "See all" and "Add a message" text buttons), Settings. Predictive back on Android 16 returns to Home from any tab.
- **One-time tips**: first Home visit shows 2 bubbles (swipe bar, Messages tab); stored as a flag so they never repeat.

## Update 1.3: Tiny-version timer
- "⏱ 2-min timer" from the rescue chips and from a long-press on the swipe bar.
- Full screen ring countdown, Pause, Done. When it reaches 0 (or Done is tapped) the day is checked in, same as a normal check-in.
- Runs only while the screen is open, using a start timestamp so it survives rotation and short app switches. No foreground service, no new permissions.

## Rollout
| Update | Contents | Ship to |
|---|---|---|
| 1.1 | Friendlier start | closed testers (Play closed track) |
| 1.2 | Friendlier home | closed testers |
| 1.3 | Tiny timer | closed testers, then production with the Pro unlock |

Each update: `versionCode` +1, Play release notes, test on Android 16 emulator, Android 8 emulator and a real phone (`TESTING.md`), and one "Build" reel showing before/after.

## Decisions (confirmed by the user, 25 Nov 2026)
These touch features already decided in `stick-mvp.md`:
1. **Quit day from the quiz.** Decided rule: the quit day is learned from the first miss, not asked. Proposal: the quiz answer is used **only for wording**; the rescue still triggers on day 3 by default and then on the learned day. (Alternative: use the quiz answer as the rescue day until the first miss.)
2. **Swipe instead of tap.** Decided: check-in takes one tap. Proposal: swipe by default (prevents accidental check-ins, feels better), tap available in Settings.
3. **"See all" and "Add a message" move into a Messages tab.**

## Left to the builder
- Template list content (about 12–16 habits) and tiny versions.
- Exact animation timings, haptic type.
- Widget structure and tests, following existing patterns (`StickController` queue, domain rules stay pure).

## Free vs Pro
Everything in 1.1–1.3 is **free core**. No gating code is added yet (that comes with the first Pro feature, per `CLAUDE.md`).
