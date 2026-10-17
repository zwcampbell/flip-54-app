# Claude Design prompt — Flip 54 App Store screenshots

Attach before sending: the raw simulator captures listed under "Inputs" (one per screen), the three existing
finished screens (`01-hook.png`, `02-mechanic.png`, `03-versatility.png`) as the style reference, the
`Flip-54-Logo.png` wordmark, and the hero photos (`man-front-raising.jpg`, `man-high-knees.jpg`,
`woman-crunching.jpg`).

---

## Prompt

Design a set of six App Store preview screenshots for **Flip 54**, an iPhone workout app that turns a
54-card deck into a randomized workout. Flip a card, do the reps, flip again. One deck = one workout.

**Output spec**
- Six PNGs, exactly **1320 × 2868 px** (iPhone 6.9" portrait), sRGB, no transparency, no alpha.
- Deliver them numbered `01`–`06` in the order below, each as its own frame so I can export individually.
- Keep the look consistent with the three attached reference screens (`01-hook`, `02-mechanic`,
  `03-versatility`). Treat those as the house style and extend it. Do not restyle them.

**Brand and style (match the reference screens)**
- Dark, gritty, athletic. Nike-training-club energy, not wellness-app softness.
- Headline: **Barlow Condensed ExtraBold**, ALL CAPS, white `#FEFEFE`, tight leading, hard drop shadow for
  legibility, left-aligned at ~60 px side margin, 2–3 lines max.
- Subhead: **Barlow Condensed Light Italic**, cream `#F0EAE0`, sitting on a solid near-black `#0F0F0F` bar
  flush-left under the headline. One short sentence, one line if possible.
- Thin brand-red accent `#C8262C` between headline and subhead.
- Palette from the app: background `#111111`, raised surfaces `#191919`/`#1A1A1A`, borders `#2A2A2A`,
  gold/cream `#D1C4B1`, red `#C8262C`, success green `#4CAF6E` only for completion states.
- Hero photography sits behind the UI, darkened with a top gradient so the headline stays readable.
  Photos are warm, high-contrast, shallow depth of field, real people mid-exercise.
- The phone UI is the product. Show the **real app screens** (attached captures) inside a floating iPhone
  frame, tilted 6–10°, rounded corners, thin white border ring, soft shadow. Do not redraw, restyle, or
  invent UI. Use the captures pixel-for-pixel; only crop or scale them.
- Vary composition across the set: some screens tilt the phone left, some right, one shows two overlapping
  phones. No two consecutive screens should have the phone in the same position.

**The six screens**

1. **Hook** — reuse `01-hook.png` as is (dumbbell photo, wordmark at the bottom). No phone UI.
   Headline: FIFTY-FOUR CARDS. ONE WORKOUT. Subhead: Never the same twice.

2. **Mechanic** — reuse `02-mechanic.png` as is (onboarding card-to-exercise screen).
   Headline: FOUR SUITS. EVERY AREA. Subhead: Each suit is a body target. Match it to whatever exercise
   fits your space and gear.

3. **The flip** — hero screen. Capture: active workout, a face-up card with the exercise name and rep
   count, "FLIP CARD" / "DONE" button visible. Make the card the visual focus, large and slightly
   oversized beyond the phone frame if it helps.
   Headline: FLIP. DO THE REPS. FLIP AGAIN. Subhead: The card decides. You just show up.

4. **Holds and form** — Capture: an Ace (timed hold) with the hold timer running and the animated form
   guide line-art figure visible.
   Headline: EVERY MOVE SHOWN. Subhead: Line-drawn form guides for every exercise, so you never have to
   guess.

5. **Make it yours** — Capture: the pre-workout screen showing difficulty (Beginner / Standard /
   Advanced), equipment (Bodyweight, Weights, Pull-up bar) and the Full Deck / Half Deck choice.
   Headline: YOUR GEAR. YOUR PACE. Subhead: Bodyweight is always on the menu. Add weights or a pull-up bar
   when you have them.

6. **Cleared** — Show two phones overlapping: the **completion screen ("CLEARED.")** in front and the
   **History calendar** or **Profile streak stats** behind it. Use green `#4CAF6E` sparingly.
   Headline: CLEAR THE DECK. Subhead: Track your streak and watch the workouts stack up.

**Copy rules**
- Use the headlines and subheads above verbatim unless something doesn't fit; if so, shorten, don't add
  words or claims.
- No claims about health outcomes, calories burned, weight loss, or before/after results.
- No mention of Apple Health, Watch, widgets, iCloud, accounts, social features, or subscriptions. The app
  doesn't have them.
- No third-party logos or brand marks (no Apple logo, no App Store badge). The device frame should be a
  generic iPhone.
- No suit symbols in text (♠♣♥♦) — use words. Suit pips on the cards in the UI are fine.

**Deliverables**
- Six 1320 × 2868 PNGs, plus one contact sheet showing all six side by side for review.
- Note any screen where the capture was cropped or scaled so I can retake it.

---

## Inputs to capture (iPhone 17 Pro simulator, dark mode, 9:41 status bar)

| Screen | Raw capture name | How to reach it |
|--------|------------------|-----------------|
| 2 | `onboarding-cards.png` | Fresh install, onboarding page 2 (existing) |
| 3 | `active-card.png` | Start workout, flip one card (a numbered card, e.g. 9 of hearts) |
| 4 | `active-hold.png` | Tutorial or flip to an Ace, tap START HOLD, capture mid-timer |
| 5 | `pre-workout.png` | Workout tab, before starting |
| 6a | `completion.png` | Finish a deck (or a half deck) |
| 6b | `history.png` / `profile.png` | History tab with a few days logged; Profile tab with streaks |

## Notes for whoever uploads

- Upload in App Store Connect under iPhone 6.9" Display, in order 01 to 06.
- The hero photos are stock/licensed marketing assets, not bundled in the app. Confirm you hold the license
  before shipping them in screenshots.
