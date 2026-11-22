# Habit name on screen + clearer Progress (short design)

Approved by the user on 22 Nov 2026.

## Why

On the emulator, Stick felt like "just a counter". Home and Progress never say what is being counted; the habit name shows only in Settings. Progress also confuses: "6 days you showed up" next to "Day 7", an unlabeled bar with an unexplained ★, a "Beat your quit day: 1" stat that reads like a score, and a "Get past Day 3 this time" button shown on Day 7.

## Goals

- The habit name is visible on Home (both styles) and on Progress.
- Every number on Progress reads clearly and agrees with the others.
- The way into Progress looks tappable.

## Non-goals

- No change to the engine rules (day numbers, pause, quit day, rescue).
- The why stays where it is now: rescue days only, when there are no clips (user agreed).
- No new navigation (no tabs, no extra screens).

## Approaches considered

- **Name only, every day; why on rescue days only (picked).** Fixes the counter feel and keeps the why rare, so it still hits on the quit day.
- Name + why every day: always reminds, but the why becomes wallpaper.
- Name only inside the counter line ("Gym · Attempt 1 · Day 7"): smallest change, but still easy to miss.

## Design

### Home (both styles)

- The habit name sits as a headline above the big number / road, centered, in the headline font. Long names wrap to at most 2 lines, then ellipsize.
- The counter "Attempt N · Day N" becomes an outlined pill button with a small lime chart icon and a trailing ›, so it clearly looks tappable (user asked for this on 22 Nov). It still opens Progress.
- Everything else stays the same.

```
Attempt 1 · Day 7 ›          ⚙
           Gym
            7
        [ Done today ]
```

### Progress

```
←  Gym

           6
   days you showed up

Your attempts
 Attempt 1 · now   ██████░░░░  6 days ★
 ★ = got past your quit day

Tiny days                     1
  They count.
Messages to future you        2 ›

     [ Back to Day 7 ]
```

- **Title:** the app bar title is the habit name, not "Progress". It is 1 line with an ellipsis (2 lines at 1.3x text scale do not fit the 56px toolbar). Home keeps 2 lines.
- **Section label** "Your attempts" above the bars.
- **Each bar row** is labeled "Attempt N" (current one: "Attempt N · now") and shows "N days" (or "1 day").
- **Bar length** is days done in that attempt (its check-ins), not the day number reached. So the current bar shows 6 when the big number shows 6.
- **Bar track:** each bar has a faint full-width track behind it (muted, about 0.2 alpha), so a 0-day bar still shows and the scale is visible.
- **Bar scale:** the longest bar or 14 days, whichever is larger, so a single attempt is not always full.
- **★** keeps its rule (that attempt got past its quit target). A legend line "★ = got past your quit day" shows only when a ★ is on screen. Changed after the final review: each ★ is judged against that attempt's own quit target, so the legend no longer prints the current target.
- **The "Beat your quit day" stat is removed.** The ★ covers it.
- **Button:** "Get past Day X this time" while today's day number ≤ quit target. After that it reads "Back to Day N" (N = today's day number). It still just goes back to Home.

## Constraints

- Phone width with a 16–24px gutter: names and bar labels must not overflow (wrap or ellipsize).
- Update the existing widget, e2e and progress tests that look for the old strings ("Beat your quit day", the "Get past…" button on later days, "Attempt N · Day N" without "›").

## Left to the builder

- Exact typography sizes and the bar row layout (label above the bar, or beside it), as long as nothing overflows at 360dp wide.
- Whether "›" is part of the counter text or a separate icon (tests should find the counter either way).
