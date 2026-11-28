# Stick 1.2: Pro (subscription or one-time) and "Talk to the developer"

Date: 28 Nov 2026. Status: **draft for Sidharth's approval** (builder check done; answers folded in, 28 Nov 2026).
Decisions recorded in `2026-11-28-pro-release-notes.md`; this document is the full design built on them.

## Why
More income, and a lower entry price for people who don't want to pay a lot upfront (Sidharth). Pro has to be real and worth renewing, and Stick's promise (private, no account, no internet, no guilt) must survive. Pro ships **before the public production launch**; closed testers keep everything unlocked.

## Goals
- Pro sold three ways, all unlocking the same features: **monthly ₹49 / $1.99**, **yearly ₹299 / $9.99 with a 7-day free trial**, **lifetime ₹699 / $19.99** (one-time).
- Three Pro features at launch: **home-screen widget**, **more than one habit + goal-hopping lock**, **history calendar**.
- **Talk to the developer**: "Suggest a feature" (email) and "Instagram @th3_on3guy" links.
- Closed testers' data survives the update (real database upgrade).
- Website policy, terms and Play Console updated to match.

## Non-goals
- Themes, custom reminder text, "I can't today" (later Pro updates).
- Server, account, analytics, receipt backend, ads.
- iOS.

## Anti-goals (a failure even if it works)
- Taking away anything that is free today (rescue, slide check-in, messages to future you, progress, 2-minute timer, reminders, home styles, tips).
- Dark patterns: countdowns, fake discounts, guilt copy, hiding the free plan, hiding how to cancel.
- Losing a tester's or customer's habit data on update.
- A paying user losing Pro when offline, or a refunded user keeping Pro forever.

## Constraints
- Flutter 3.50.1, Android first, minSdk 24, targetSdk 36. No new permission beyond what Play Billing itself requires.
- **No INTERNET permission today** (privacy policy, PR checks, release workflow). The Play Billing library communicates with the Play Store app on the device. After adding the plugin, check the merged manifest. **Decided (Sidharth):** if `android.permission.INTERNET` appears, remove it with `tools:node="remove"` and prove purchases still work with license testers (purchase, restore, trial). Only if billing breaks without it, stop and ask Sidharth.
- Schema 1 is on testers' phones. This release adds **schema 2 with a real, tested upgrade**; the `beforeOpen` "reset if a column is missing" guard must only ever fire for the pre-1.1 developer database, never after a successful upgrade.
- Testing builds keep `ALL_PRO=true` (release workflow default for testing tracks); production builds never: the release workflow already refuses `track=production` with `pro_unlocked=true`.
- **Closed testers lose Pro at launch (decided):** when they move to the production build they become free users; extra habits go read-only until they buy (section 5). No promo codes.
- Website (privacy policy, terms) lives in the separate repo `/Users/sdd410/personal website` (sdd410.github.io, publishes from `main`); same workflow as before: branch, checks, Sidharth's go before merging.

## Approaches considered (purchases)
1. **Official `in_app_purchase` Flutter plugin (picked by Sidharth).** Uses Google Play Billing through the Play Store app; no server, no third party; Play handles restore, trials, renewals and cancellations. We write the entitlement logic.
2. RevenueCat: nicer dashboards, but needs internet and sends purchase data to their servers. Breaks the privacy promise. Ruled out.
3. Native Kotlin Play Billing through a platform channel: full control, more code to maintain, no gain over 1.

## Design

### 1. Plans and products (Play Console)
- One **subscription** product `stick_pro` with base plans `monthly` (₹49 / $1.99, auto-renewing 1 month) and `yearly` (₹299 / $9.99, 1 year); an **offer** `yearly-free-trial` on `yearly`: 7-day free trial, eligibility "new customers" (Play enforces one trial per account).
- One **one-time product** `stick_pro_lifetime` (₹699 / $19.99), non-consumable.
- Prices in INR set explicitly; US price set and Play's template converts the rest.
- Payments profile, products and license testers set up by Sidharth (step-by-step list in the plan).

### 2. Entitlement (who has Pro)
- `Entitlement { free, pro }` with a `source` (`monthly`, `yearly`, `lifetime`, `tester`) and `checkedAt`.
- Pro if any of: an active `stick_pro` subscription purchase (purchased, not pending), the `stick_pro_lifetime` purchase, or `ALL_PRO=true`.
- **"Active" (builder's call, recorded):** Play still lists the subscription purchase. That includes Play's grace period for a failed renewal; account hold and paused subscriptions are not listed and so are not Pro. `in_app_purchase` exposes no expiry date, so "listed" is the rule.
- **"Couldn't reach Play" is not "owns nothing" (builder's call):** Pro is only removed after a *successful* query that no longer lists the purchase. A failed or timed-out query keeps the stored result.
- On app open and after every purchase update: ask Play for owned purchases (`restorePurchases`), recompute, store the result in the database (`flags.proSource`, `flags.proCheckedAt`).
- **Offline:** use the stored result. Keep a subscriber's Pro for up to **7 days counted from the last successful check** (covers no-signal days); after that, fall back to free until Play answers. Lifetime never expires offline.
- **Pending purchases** (UPI and cash payments are common in India): show "Payment pending: Pro unlocks when Google confirms", don't unlock yet.
- Every completed purchase is **acknowledged** (`completePurchase`) so Play doesn't refund it after 3 days.
- Refunds, expiry and cancellation take effect at the next check (Play stops reporting the purchase).
- All of this lives in one service (`ProService`) behind an interface so tests use a fake store.

### 3. Feature gating
- `lib/domain/tiers.dart`: `enum Feature { multipleHabits, homeWidget, historyCalendar }`, a `tiers` map (all three → pro), `bool canUse(Feature f, Entitlement e)`.
- Screens ask `canUse`; a locked feature shows its normal entry point with a small "Pro" chip, and tapping it opens the Pro screen with that feature highlighted.
- Moving a feature between free and Pro is a one-line change in `tiers`.

### 4. Pro screen (paywall)
Opened from locked features and from **Settings → Stick Pro**. Same dark/lime style.
```
 Stick Pro
 ✓ More than one habit (with the goal-hopping lock)
 ✓ Home-screen widget
 ✓ History calendar
 ┌─────────────────────────────────────────────┐
 │ Yearly   ₹299/year  · 7 days free · ₹25/mo   │  ← preselected, "Best value"
 │ Monthly  ₹49/month                           │
 │ Lifetime ₹699 once  · yours forever          │
 └─────────────────────────────────────────────┘
 [ Start 7-day free trial ]   (or "Continue" for the others)
 7 days free, then ₹299/year. Cancel anytime in Google Play.
 Restore purchases · Terms · Privacy
 Want something else? Tell me →  (Talk to the developer)
```
- Prices and trial text come **from Play** (localised), never hard-coded; the "₹25/mo" comparison is computed.
- Shows the user's current plan when they already have Pro, with "Manage subscription" (opens Play's subscription page) for subscribers.
- **Changing plans (builder's call):** monthly → yearly uses Play's subscription replacement (upgrade, prorated by Play). A subscriber buying lifetime gets a clear note after purchase: "You now own Pro forever. Cancel your subscription in Google Play so it stops renewing." with a button to Play's subscription page. Yearly → monthly is done in Play.
- No timers, no strike-through prices.

### 5. Pro feature: more than one habit + goal-hopping lock
- **Data:** schema 2 adds `habitId` to attempts, check-ins and clips; habits get real ids; flags that belong to a habit (weekly replay, day-4 celebrated) move to the habit. Upgrade step: existing data becomes habit 1, nothing else changes.
- **Home:** a habit switcher at the top when there is more than one habit (tap the habit name → list with each habit's day number). Each habit keeps its own attempts, quit day, rescue, clips and reminders.
- **Adding a habit:** Settings → "Add a habit" (Pro) runs the existing setup flow for the new habit.
- **Goal-hopping nudge (decided, replaces the hard lock):** a Pro user can always add a habit. If the newest active habit is **below day 14 right now**, Stick first shows a pause screen: "You're on day 6 of Walk. Day 1 you said: '<their why>'" (or plays their Day 1 message if there is one), with **Keep going with Walk** (primary) and **Add anyway**. Day 14 or more: no nudge. Same idea as the replay before Fresh start.
- **Archive a habit (decided):** "Archive habit" in that habit's settings. It leaves Home, the switcher and the widget picker; its history stays in the calendar (with an "Archived" filter); its reminders stop; it can be restored. Archived habits don't count for the nudge. Free users can archive too (it's how they'd swap which habit is active after Pro ends).
- **Reminders:** one per habit at its own time; notification ids are namespaced per habit (e.g. `habitIndex * 100 + day`).
- **Free users:** one habit, exactly as today.
- **If Pro ends** (cancelled, refunded, or a tester moving to production): all habits and their data stay. **One habit stays fully usable: by default the oldest; the user can switch which one from the habit switcher (builder's call).** The others become read-only ("Pro ended: renew to keep checking in on Reading") and stop their reminders. Nothing is deleted.
- Data for this: `habits.archived` (bool) and `habits.position` (order); the "usable without Pro" habit is a flag (`flags.freeHabitId`).

### 6. Pro feature: home-screen widget
- Android widget (via the `home_widget` plugin, no internet): shows the habit emoji, name and "Day N", lime when checked in today; tapping opens Stick.
- Updated on every check-in, habit change and app open, and once a day after the 3 am day change (inexact, no new permission).
- **Without Pro:** the widget can still be added but shows "Stick Pro: tap to unlock" and opens the Pro screen.
- One widget per habit choice (configure screen picks the habit when there are several).

### 7. Pro feature: history calendar
- From the Progress tab: "History" (Pro chip for free users).
- Month grid per habit; **days you showed up** are lime (tiny days with a small mark); every other day is neutral. **Missed days are never shown as misses** (the no-guilt rule stays).
- Swipe between months; shows the attempt boundaries as a subtle divider.

### 8. Talk to the developer
In **Settings → "Talk to the developer"**, also at the bottom of the Pro screen; the Instagram link also on the Day 4 celebration screen ("Made it to day 4? Tell me on Instagram").
- **💡 Suggest a feature:** a screen with a text box ("What should Stick do next?") and **Send**. Send opens the user's email app (`mailto:` intent) with To `oneguyatwork@gmail.com`, Subject "Stick idea", the text, and a last line "Stick <version> · Android <version>". If no app can handle it: show the address with a **Copy** button. Stick sends nothing itself. Free for everyone.
- **📸 Instagram @th3_on3guy:** opens `https://www.instagram.com/th3_on3guy/` (Instagram app if installed, else browser). Free for everyone.
- Uses `url_launcher` (no permission); manifest `<queries>` entries for `mailto` and `https` so Android 11+ can see the apps.

### 9. Website, policy and Play Console
- **Privacy policy** (`/apps/stick/privacy/`): purchases are processed by Google Play, which keeps purchase records; Stick only stores whether you have Pro and which plan; feedback emails are sent by the user from their own email app and include their address; Instagram links leave the app. New effective date.
- **Terms** (`/apps/stick/terms/`): subscriptions renew until cancelled in Google Play; the 7-day trial converts to yearly unless cancelled before it ends; lifetime is a one-time purchase; refunds via Google Play; what happens to extra habits if Pro ends.
- **Store listing:** add "Free core. Pro: more habits, home-screen widget, history calendar. Monthly, yearly (7 days free) or one-time."
- **Play Console:** Sign-in details → "Yes" (paid content) with reviewer instructions (license tester account or test purchase); in-app products section; Data safety re-checked (purchase history is handled by Google, not collected by Stick).

### 10. Release and testing
- Version **1.2.0**. Closed testers keep `ALL_PRO=true` builds; a separate **internal** build with `ALL_PRO=false` and license testers exercises real purchases (test card "always approves" and "always declines", pending, trial, cancel, refund).
- Device checks added to `TESTING.md`: purchase each plan, restore after reinstall, offline for 3 and 8 days, cancel and expiry, refund, pending UPI, upgrade from 1.1.x with data, widget with and without Pro, two habits with reminders.

## Build order (each one shippable to testers)
1. **Foundations:** schema 2 upgrade (multi-habit-ready data, habit 1 = existing data), `tiers`, `Entitlement`, `ProService` with a fake store, ALL_PRO path. No visible change.
2. **Talk to the developer** (Settings, Day 4 screen). Visible, free.
3. **Pro screen + real purchases** (`in_app_purchase`), Settings → Stick Pro, restore, manage subscription. INTERNET check here.
4. **History calendar.**
5. **More than one habit + goal-hopping lock.**
6. **Home-screen widget.**
7. **Website policy/terms, store listing, Play Console, TESTING.md, release 1.2.0.**

## Left to the builder
- Exact widget layout and refresh mechanics within the rules above.
- Habit switcher visual details (follow the existing Home style).
- Copy polish within the facts above.
- Which `home_widget` / `in_app_purchase` versions (latest stable compatible with Flutter 3.50.1).
