# Stick: Roadmap to Launch

Nov 20, 2026 · @sdd410

App #001 from THE ONE GUY (@th3\_on3guy). Launch is about **5–6 weeks** away. The 14-day closed test is the only fixed step, so everything else is set up so the test can start the day the build is ready.

## 1. Reality check (now, \~1 day)

- [x] Post Reel 3: Reality Check.
- [x] **Start this week:** create the Google Play developer account (one-time $25 fee). Identity verification can take a few days.
- [x] Put the waitlist link in bio now (a Google Form is fine). This is where the 12 testers come from.

## 2. Design (\~2–3 days)

- [ ] Mock up the 4 screens from the spec: setup, home/rescue, Day 4 celebration, settings.
- [x] Settle the open questions first (done 22 Nov 2026, see "Decisions" in `stick-mvp.md` (same folder)). The design is built directly in Flutter, and the two home screen versions are screen-recorded for the Design reel.
- [ ] Reel 4: Design. Ask people to vote between two home screen versions in the comments.

## 3. Build (\~2 weeks)

- [x] Toolchain ready (22 Nov 2026): Flutter 3.50.1, Android platform 36.
- [ ] Flutter, local storage, notifications, voice/video clips with story-style replay, learned quit day, attempt counter, fresh start.
- [ ] **Target Android 16 (API level 36).** Google Play has required this for new apps and updates since August 31, 2026.
- [ ] Day 4 share card moved to after the closed test (22 Nov 2026) to make room for the clips.
- [ ] Reel 5: Build. The clips replay or the attempt counter makes a good real first frame.
- [ ] ⚠️ Scope watch: voice/video clips push the build to about 2.5 weeks. Anything else new waits until after launch.

## 4. Pre-test paperwork (\~1–2 days, alongside the end of the build)

- [ ] Store listing: icon, feature graphic, screenshots, short and full description.
- [ ] Privacy policy URL. Required even with local-only storage; mention microphone and camera use for the clips (stored only on the phone).
- [ ] Data safety form, content rating questionnaire, target audience.
- [ ] Signed release bundle (.aab).

## 5. Closed test (14 days, fixed)

- [ ] Invite testers from the waitlist. Recruit **15–20, not 12**: Google needs at least 12 opted in for 14 days in a row, and some will drop out.
- [ ] Testers get all Pro features free during the test.
- [ ] Track targets: 60% reach day 4, 40% still checking in on day 7.
- [ ] Reel 6: Test, using real tester feedback. Slot a reply reel in here too.

## 6. Production access and launch (\~1 week)

- [ ] Apply for production access in Play Console (it asks about the test and what changed).
- [ ] Fix tester issues, then submit for production review.
- [ ] **Decision needed:** launch free and add the Pro in-app purchase in an update, or add it before production. Adding it first needs a Play payments merchant profile and a few extra days.
- [ ] Reel 7: Launch, with the Day 4 share card as the first frame.

## Reel topics

Seven stage reels and one reply reel take Stick from reality check to launch. Each is 12–15s, asks for the comment in the first 3 seconds, and keeps the COMMENT label on screen.

| Order | Stage | Real first frame | Topics to cover | Comment ask | Status |
| --- | --- | --- | --- | --- | --- |
| 1 | Reality check | Play Store search for "habit tracker" | Hundreds of habit apps exist and some are free and good (Loop Habit Tracker). The gap: none plan for the day you quit. Verdict: passed. | Which habit app did you quit? | Scripted |
| 2 | Design | The 4 screens in Figma | Setup in under 30 seconds, the rescue screen, the paused counter. Show two home screen versions. | A or B? | Not started |
| 3 | Build: clips | Recording a Day 1 video on the phone | Messages to future you, voice or video, replayed story-style when you miss a day. | What would you tell Day 1 you? | Not started |
| 4 | Build: quit day + attempt counter | Home screen showing "Attempt 4 · Day 2" | The app learns the day you quit; a miss pauses the count instead of resetting it; restarting is normal. | What attempt are you on? | Not started |
| 5 | Reply reel | Top idea comment sticker | Verdict on the most-liked idea comment (e.g. "can't decide what to cook" needs 1 more vote). | Comment yours. | Not started |
| 6 | Test: recruiting | Play Console closed test screen | Need 12+ testers for 14 days; testers get Pro free; waitlist in bio. | Comment TEST if you're in. | Not started |
| 7 | Test: results | Real tester numbers | How many testers reached day 4 and day 7, and what got fixed from feedback. | What should I fix next? | Not started |
| 8 | Launch | Day 4 share card / live Play Store listing | Stick is live, free core + one-time Pro, link in bio. | What should I build next? | Not started |

## Critical path

Play account + waitlist (this week) → design → build → closed test → production. With the account and waitlist set up now, nothing waits on paperwork later.
