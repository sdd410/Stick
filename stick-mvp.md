# Stick: MVP

App #001 from THE ONE GUY (@th3_on3guy). Picked from a real comment: "I start things and quit by day 3".

## Problem
People start a new habit with energy, then quit around day 3. Most habit apps reward perfect streaks, so one missed day resets the streak to zero and the user gives up.

## Who it's for
Anyone who keeps restarting the same habit (gym, reading, studying, a side project) and also people who jump between goals after seeing others do something new.

## Core idea
A habit app built for the day-3 drop-off, not for perfect streaks. Its one job: **get you to day 4.**

## MVP features

### 1. One habit, set up in under 30 seconds
- Habit name (for example "Gym").
- Daily reminder time.
- A "tiny version" of the habit for hard days (for example "Put on gym shoes"). Optional: if skipped, the app uses "Just show up for 2 minutes".
- One line: "Why are you starting?" (shown on the rescue screen when there are no clips).
- **Done when:** a new user can create a habit in 3 short steps or fewer.

### 2. Daily check-in
- One big button: "Done today".
- A day counter ("Day 2"). Day N = completed check-ins in this attempt + 1 (days you showed up, not calendar days).
- A day ends at **3 am** local time, so a check-in at 12:40 am still counts for "today".
- **Done when:** checking in takes one tap and the counter updates right away.

### 3. Day 3 rescue
- On day 3 (or the user's learned quit day, see feature 8), or the day after a miss, the home screen switches to the tiny version: "Just do this. Get to day 4."
- Doing the tiny version counts as a full check-in.
- **Done when:** day 3 and the day after a miss show the rescue screen, and other days show the normal one.

### 4. No broken streaks
- A missed day **pauses** the counter instead of resetting it. The number turns grey: "Day 3 · paused".
- One tap to continue: "Pick it back up". It continues from the same day number.
- **Done when:** after a miss, the counter keeps its value and the user can continue in one tap.

### 5. Reminder notification
- Sent daily at the chosen time.
- Different wording on day 3 and after a miss (for example "Day 3. This is where most people quit. Not you.").
- **Done when:** reminders fire at the set time, even after the phone restarts.

### 6. Local storage only
- No account, no login, no backend. Data stays on the phone.
- **Done when:** the app works fully offline and keeps its data after it closes.

### 7. Messages to future you (voice or video)
- During setup, the user can record a first clip: voice **or** video, their choice, up to 15 seconds, about why they're starting. Optional, so it never blocks the 30-second setup. Video is recorded at 720p to save storage.
- **Add more any time:** an "Add a message" button, plus a prompt on day 7, 14 and 21: "Record one for future you."
- **Replay** plays the clips one after another, like Instagram stories (not merged into one file): the Day 1 clip plus the latest 3-4, about a minute at most, with "See all" for the rest.
- Replay opens full screen but waits for one tap ("▶ You have something to say"), so it never blasts sound in public.
- **When replay shows up:**
  - Every 7 days (day 7, 14, 21...) when the user opens the app.
  - On the rescue screen (quit day or after a miss).
  - After missed days, a notification ("You left yourself a message") opens the replay when tapped.
- With no clips, the rescue screen shows the "Why are you starting?" text instead.
- **Done when:** a user can record voice or video clips at setup and later, the replay plays them story-style on the weekly day, the rescue screen and from the missed-day notification, and clips stay saved on the device.

### 8. The app learns your quit day
- No setup question (people don't know their quit day).
- First attempt: rescue mode starts on day 3.
- The **first missed day** of each attempt is saved as that attempt's quit day. The count still pauses as normal (feature 4).
- From attempt 2, rescue moves to the quit day of the **most recent** attempt: "Last time you stopped on Day 5. Today is Day 5."
- Rescue also shows on any paused day.
- **Done when:** if the first miss of an attempt is on day N, the next attempt shows the rescue screen on day N.

### 9. Attempt counter
- Show restarts openly: "Attempt 4 · Day 2".
- Restarting is treated as normal, not as failure.
- **Done when:** a reset from settings increases the attempt number and the home screen shows both numbers.

### 10. Fresh start (new habit)
- In settings: "Fresh start" first plays the replay ("Day 1 you said this. Still switching?") and asks to confirm, so switching goals always gets a pause to think (this keeps the Pro goal-hopping lock meaningful). Then it clears the habit, check-ins, attempts and the learned quit day, so a new habit starts clean at Attempt 1, rescue on day 3.
- Asks whether to keep or delete the saved clips (default: delete).
- Different from "reset" (feature 9), which keeps the same habit and starts a new attempt.
- **Done when:** after a fresh start, the app shows setup again with no old data (and clips kept only if chosen).

### 11. Progress screen (free)
- Opened by tapping the "Attempt 4 · Day 2" counter on the home screen (no extra tab).
- Built around what never goes down. No calendar of missed days in the free app.
- Shows:
  - **Days you showed up:** the total across all attempts, big. Restarting never lowers it.
  - **Attempt bars:** one bar per attempt with its length ("Day 9"), a ★ when that attempt got past the quit day, and the current one marked "now".
  - **Beat your quit day:** how many times.
  - **Tiny days:** how many check-ins used the tiny version ("they count").
  - **Messages to future you:** the number of clips, tap to open the replay.
  - **One next step:** a button tied to the learned quit day ("Get past Day 5 this time"), which goes back to home.
- Uses only data already stored (check-ins, attempts, clips).
- **Done when:** the numbers match the stored data, the attempt bars update after a check-in or reset, and the screen never shows missed days.

## Screens
1. **Welcome / setup:** name the habit, tiny version (optional), "why are you starting", reminder time (asks for notification permission), and (optional) record a first voice or video clip.
2. **Home:** attempt and day counter, "Done today" button, "Add a message" button, rescue mode on the quit day or after a miss.
3. **Progress:** days showed up, attempt bars, quit days beaten, tiny days, clips, next step (feature 11).
4. **Replay:** full-screen story player for the clips (tap to start, tap to skip, "See all").
5. **Day 4 celebration:** a one-time screen when the user reaches day 4.
6. **Settings:** edit the habit, change the reminder time, manage clips, reset (new attempt), fresh start (new habit).

## Data (stored on the device)
- Habit: name, tiny version, why text, reminder time, created date.
- Clips: list of voice/video files in app storage, each with type, date and the day number it was recorded on.
- Check-ins: list of dates, each marked full or tiny.
- Attempts: list of attempts with their final day count and the day of their first miss (used to learn the quit day and for the progress screen).
- State: current day count, attempt number, paused or active.

## Pro (one-time unlock, after closed testing)
- More than one habit.
- History calendar (the free app has the progress screen instead, feature 11).
- Themes.
- Custom reminder text.
- **Goal-hopping lock:** a second habit unlocks only after the current one reaches day 14 ("Finish this one first. You're on day 6.").
- **Home screen widget:** the day count on the home screen, seen on every unlock.
- **"I can't today" button:** pick a reason (tired, no time, don't feel like it), get an even smaller version, and see patterns over time ("You always skip Mondays").

Testers get everything free during the closed test. The in-app purchase gets added after it.

## After the closed test
- **Day 4 share card:** when the user reaches day 4, generate an Instagram Stories image in the dark and lime style, tagged @th3_on3guy. It's only an image, not a social feature, and it's the cheapest growth loop. Moved from "before the test" on 22 Nov 2026 to make room for voice/video clips.

## Out of scope for the MVP
- Accounts, cloud sync, backend.
- Social features (the Day 4 share card, after the test, is the only exception).
- iOS (Flutter keeps it possible later).
- In-app purchase (added after testing).

## Tech
- **Framework:** Flutter, Android first.
- **Storage:** local on the device (for example `shared_preferences` or a small local database).
- **Notifications:** local scheduled notifications (inexact daily, no exact-alarm permission), rescheduled on app open and after reboot.
- **Android:** target API 36 (Android 16), min API 24. Handle notification permission (13+), edge-to-edge (15+), predictive back (16), OEM battery savers (Xiaomi, Samsung, Oppo, Vivo, Realme).
- **Permissions:** notifications, microphone, camera (asked only when used).
- **Design:** background #0b0b12, accent lime #c6ff3d, headings in Archivo Black, body in Inter (matches the reels).

## Monetization
Free core app plus a one-time Pro unlock (about $2–4). No ads, no subscription.

## Testing and launch
- Google Play closed test: **12 testers for 14 days**, recruited from followers.
- Add a waitlist link to the reels before the build is ready.
- Collect feedback through comments, Reddit and X.

## How we'll know it works
- Testers who reach **day 4**: at least 60%.
- Testers still checking in on **day 7**: at least 40%.
- Use the rescue screen on day 3: tracked by hand from tester feedback (no analytics in the MVP).

## Rough timeline (about 2.5 weeks + 1 day)
| Days | Work |
|---|---|
| 1–2 | Project setup, theme, data storage |
| 3–4 | Setup flow and home screen with check-in, attempt counter, pause |
| 5–6 | Rescue mode, learned quit day, reset and fresh start |
| 7–10 | Voice and video recording, clip storage, story-style replay (weekly, rescue, notification) |
| 11–12 | Reminders, day-3 and missed-day wording, notification → replay |
| 13–15 | Progress screen, Day 4 celebration, settings, polish |
| 16–18 | Testing on Android 16 and Android 8 emulators and a real phone, Play Store listing, closed test upload |

## Reels along the way
The clips replay, the learned quit day and the attempt counter can each be their own reel moment.

Pick (done) → Reality check → Design → Build → Test → Launch. One reel for each stage.

## Decisions (22 Nov 2026)
- Tiny version: optional, fallback "Just show up for 2 minutes".
- Paused day: grey "Day 3 · paused" + "Pick it back up".
- No clips: rescue screen shows the "why" text.
- Quit day: learned from attempts, not asked (default day 3). Quit day = first missed day of an attempt; rescue uses the most recent attempt's.
- Day count = check-ins + 1; a day ends at 3 am.
- Clips: voice or video, user's choice; add more over time; story-style replay of Day 1 + latest 3-4, tap to start.
- Fresh start plays the replay first, then clears everything for a new habit (clips optional).
- Progress screen: free, opened from the counter, never shows missed days.
- Waitlist: the Google Form in bio.
- Day 4 share card: after the closed test.

## Decisions (25 Nov 2026, friendlier app, see `docs/superpowers/specs/2026-11-25-friendly-update-design.md`)
- Onboarding quiz: "When do you usually quit?" sets the first attempt's quit day (Day 1/2/3 → 1/2/3, a week or two → 7, not sure → 3) for the rescue and "Get past Day N"; after the first miss the learned day takes over. "Why do you usually stop?" picks the rescue hint.
- Check-in is a slide by default, with tap available in Settings (Check-in: Slide / Tap).
- "See all" and "Add a message" moved into a Messages tab. Everything ships together as 1.1.
