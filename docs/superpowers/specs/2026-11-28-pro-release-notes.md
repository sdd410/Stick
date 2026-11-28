# Pro release: decisions so far

Date: 28 Nov 2026. Status: **notes from the brainstorm, not yet a design doc.** The full design (with approaches) comes next; nothing is built yet.

## Why
More income, and a lower entry price for people who don't want to pay the full amount upfront. Pro restrictions ship **before the public (production) launch**; closed testers keep everything unlocked (`ALL_PRO=true`).

## Money (decided by Sidharth, 28 Nov 2026)
Replaces "one-time unlock, no subscription" in `stick-mvp.md`.

| Plan | India | US / elsewhere (Play converts the rest) |
|---|---|---|
| Monthly subscription | ₹49 | $1.99 |
| Yearly subscription | ₹299 | $9.99 |
| Lifetime (one-time purchase) | ₹699 | $19.99 |

- **One Pro tier**: all three plans unlock exactly the same features.
- **7-day free trial on yearly only**, shown plainly ("7 days free, then ₹299/year, cancel anytime"). No countdowns, fake discounts or pressure.
- Free core stays as today: rescue, slide check-in, messages to future you, progress, 2-minute timer, reminders.
- Rough take-home (India, after 18% GST and Google's 15%): monthly ≈ ₹35, yearly ≈ ₹215, lifetime ≈ ₹500. Exact figures in Play Console.
- To do in Play Console before billing works: **payments profile** (bank + tax details; verification can take days), the subscription with monthly and yearly base plans + the trial offer, and the lifetime one-time product.

## Pro features at launch (decided)
1. **Home-screen widget** (day count on the home screen).
2. **More than one habit + goal-hopping lock** (a second habit unlocks only after the current one reaches day 14).
3. **History calendar.**

Later Pro updates (keep renewing worth it): themes, custom reminder text, "I can't today" button with patterns.

## Talk to the developer (decided)
In **Settings → "Talk to the developer"**, also linked at the bottom of the Pro screen; Instagram also on the Day 4 celebration screen.
- **💡 Suggest a feature:** a text box; **Send** opens the user's own email app with To `oneguyatwork@gmail.com`, Subject "Stick idea", their text, and "Stick <version> · Android <version>". No email app → show the address with a Copy button. Stick itself sends nothing (no internet permission).
- **📸 Instagram @th3_on3guy:** opens Instagram (app or browser) to follow or DM.

## Things that must change with it
- Privacy policy: purchases via Google Play (Google keeps purchase records); feedback emails are user-sent and include their address; Instagram links leave the app.
- Terms of service: subscription terms (renewal, trial, cancel in Google Play, refunds via Google Play).
- Play Console: **Sign-in details → "Yes"** with reviewer access to Pro (license testers); Data safety review; store listing gets "Free core, Pro by subscription or one-time".
- Check whether the Play Billing library adds the `INTERNET` permission. If it does, the privacy promise, PR checks and the release workflow's permission check must be updated deliberately.
- Docs: `stick-mvp.md` (monetization + Pro), `apps/stick/CLAUDE.md` (Free vs Pro), series `CLAUDE.md` objective 3.
