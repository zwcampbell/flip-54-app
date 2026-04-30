# Flip 54 — Build Progress

> **Last updated:** Commits 34–35 complete  
> **Current branch:** `feature/milestone-6-polish`  
> **Next action:** Commit 36 — App icon + launch screen (BLOCKED — needs 1024×1024 icon artwork)

---

## How to resume in a new conversation

1. Read this file first.
2. Run `git log --oneline -10` to confirm head commit.
3. Run `git branch` to confirm you're on `feature/milestone-6-polish`.
4. Pick up at the **Next Action** listed above.

---

## Project basics

| Key | Value |
|-----|-------|
| Bundle ID | `com.flip54.app` |
| Team ID | `LP5448PXCB` |
| Min iOS | 17.0 |
| Swift | 6.0, `SWIFT_STRICT_CONCURRENCY: complete` |
| Project gen | XcodeGen (`project.yml`) — run `xcodegen generate` after adding files |
| Simulator | iPhone 17 Pro (booted) |
| Build cmd | `xcodebuild -scheme Flip54 -destination 'platform=iOS Simulator,name=iPhone 17 Pro' build` |

### Package structure
- `Packages/Flip54Core` — pure domain (Card, Suit, Rank, Prescription, Difficulty, Equipment, Exercise)
- `Packages/Flip54Storage` — SwiftData models (UserSettings, WorkoutHistory, OnboardingState, DeckInventory, ActiveSession) + `ActiveSessionStore`
- `Packages/Flip54WorkoutEngine` — WorkoutCoordinator state machine, HoldTimer

### Critical patterns
- `@MainActor @Observable` on `WorkoutCoordinator` — use `@State private var coordinator = WorkoutCoordinator()`
- SwiftData `ModelContainer.flip54Container()` uses `#if targetEnvironment(simulator)` to skip App Group (App Group entitlement not available in simulator)
- `Difficulty: CaseIterable` extension — must use `public static let allCases` (not `var`) to satisfy Swift 6 concurrency
- Always run `xcodegen generate` after adding new source files before building

---

## Commit history & status

### ✅ Milestone 1 — Headless Core (Commits 1–8)
| # | Commit | Status |
|---|--------|--------|
| 1 | Xcode project + package skeleton | ✅ |
| 2 | Domain types (Card, Suit, Rank, etc.) | ✅ |
| 3 | Prescription function + exhaustive tests | ✅ |
| 4 | ActiveSession model + mutations | ✅ |
| 5 | ActiveSessionStore (JSON persistence) | ✅ |
| 6 | WorkoutState + WorkoutEvent types | ✅ |
| 7 | WorkoutCoordinator (full state machine) | ✅ |
| 8 | SwiftData models + ModelContainer | ✅ |

### ✅ Milestone 2 — Playable Prototype (Commits 9–12)
| # | Commit | Status |
|---|--------|--------|
| 9 | PreWorkoutView + ContentView + placeholder card | ✅ |
| 10+11 | ActiveWorkoutView: full game loop | ✅ |
| 12 | CompletionView + WorkoutHistory save + App Group fix | ✅ |

### ✅ Milestone 3 — Full Workout (Commits 13–19)
| # | Commit | Status |
|---|--------|--------|
| 13 | CardPlaceholderView (Joker, Ace, face, standard) | ✅ |
| 14 | Joker/Ace/face-card prescription in engine | ✅ |
| 15+16 | SettingsView: equipment toggles + difficulty picker | ✅ |
| 17 | Mid-session resume + settings wiring + tab bar | ✅ |
| 18 | HistoryView + WorkoutDetailView | ✅ |
| 19 | ProfileView + lifetime stats | ✅ |

### ✅ Milestone 4 — Onboarding (Commits 20–25)
| # | Commit | Status |
|---|--------|--------|
| 20+21 | OnboardingView (7 screens) + ContentView wiring | ✅ |
| 22 | Tutorial Flip mode (5-card, beginner, not logged to history) | ✅ |
| 23 | First-time contextual tooltips (Ace, face, Joker, Skip) | ✅ |
| 24 | Quick Reference modal for (?) button | ✅ |
| 25 | Tutorial banner on PreWorkoutView | ✅ |

### ✅ Milestone 5 — Standard Deck Visuals (Commits 26–31)
| # | Commit | Status |
|---|--------|--------|
| 26 | CardImageProvider + CardView (art pipeline infrastructure) | ✅ |
| 27 | Artwork placeholder directory + README (awaiting SVG delivery) | ✅ |
| 28 | 3D Y-axis card flip + mid-flip haptic + scale pulse | ✅ |
| 29 | 3-phase riffle-shuffle animation (spread→riffle→collapse) | ✅ |
| 30 | Deck stack indicator (0–3 shadow cards, shrinks as deck depletes) | ✅ |
| 31 | Completion screen polish (triangle confetti, animated entry, Share stub) | ✅ |

### 🔄 Milestone 6 — MVP Polish (Commits 32–37) — IN PROGRESS on `feature/milestone-6-polish`
| # | Commit | Status | Notes |
|---|--------|--------|-------|
| 32 | Accessibility: VoiceOver labels, Reduce Motion, hold-timer announcements | ✅ | |
| 33 | Sound effects: SoundPlayer, all events wired, Settings audio controls | ✅ | Assets not yet bundled — no-ops gracefully |
| 34 | Custom haptic patterns (CHHapticPattern completion crescendo) | ✅ | |
| 35 | Performance pass (Instruments, 60fps, memory) | ✅ | Code-only |
| 36 | App icon + launch screen | ⛔ BLOCKED | Needs icon artwork |
| 37 | TestFlight beta build | ⛔ BLOCKED | Needs App Store Connect setup |

---

## Pending work detail

### Commit 34 — Custom haptic patterns
- `CHHapticEngine` wrapper around existing `UIImpactFeedbackGenerator` calls
- Custom `CHHapticPattern` for completion crescendo (rising intensity burst)
- Per-event patterns: card flip (sharp click), hold start (long rumble), hold tick (light tap), skip (double tap), done (medium thud), completion (crescendo)
- Lives in `Flip54/Utilities/HapticEngine.swift`
- Guard all calls behind `UserDefaults.standard.hapticsEnabled`

### Commit 35 — Performance pass
- Profile in Instruments with a full 54-card workout
- Confirm 60fps during card flip animations
- Confirm SwiftData writes <16ms (add `os_signpost` markers around `try? modelContext.save()`)
- Audit for retain cycles in `DispatchQueue.main.asyncAfter` closures in `ActiveWorkoutView`
- Fix any issues found

### Commit 36 — App icon + launch screen ⛔ BLOCKED
- Need: 1024×1024 source icon delivered
- Drop into `Flip54/Assets.xcassets/AppIcon.appiconset/`
- Launch screen: dark bg `#111111` + gold "54" wordmark centered
- No Storyboard — use `Info.plist` `UILaunchScreen` dict

### Commit 37 — TestFlight ⛔ BLOCKED
- Need: Apple Developer account with `com.flip54.app` bundle ID registered
- Create App Store Connect record
- Archive + upload with `xcodebuild archive` then `altool` or Xcode Organizer
- Add internal testers

---

## Key files to know

| File | Purpose |
|------|---------|
| `Flip54/App/ContentView.swift` | Root controller — onboarding gate, tab view, workout flow, completion |
| `Flip54/App/Flip54App.swift` | App entry, ModelContainer inject |
| `Flip54/Features/ActiveWorkout/ActiveWorkoutView.swift` | Full game loop, 3D flip, deck stack, tooltips |
| `Flip54/Features/PreWorkout/PreWorkoutView.swift` | Start screen, deck fan, shuffle animation, tutorial banner |
| `Flip54/Features/Onboarding/OnboardingView.swift` | 7-screen onboarding flow |
| `Flip54/Features/Completion/CompletionView.swift` | Confetti, stats card, share stub |
| `Flip54/Features/Settings/SettingsView.swift` | Equipment, difficulty, audio settings |
| `Flip54/Features/History/HistoryView.swift` | Calendar grid, recent workouts, WorkoutDetailView |
| `Flip54/Features/Profile/ProfileView.swift` | Lifetime stats, per-suit bars, streak |
| `Flip54/Components/CardView.swift` | Production card renderer (falls back to CardPlaceholderView) |
| `Flip54/Components/CardImageProvider.swift` | Maps Card+deckId → bundled Image? |
| `Flip54/Components/CardPlaceholderView.swift` | Code-drawn card face (used until SVG art delivered) |
| `Flip54/Utilities/SoundPlayer.swift` | AVAudioPlayer pool, UserDefaultsKeys, sfx/haptic helpers |
| `Flip54/Utilities/AccessibilityHelpers.swift` | Card a11y labels, ReduceMotionModifier |
| `Flip54/Resources/decks/standard/README.md` | Asset naming convention for card artwork |
| `Packages/Flip54WorkoutEngine/.../WorkoutCoordinator.swift` | State machine, isTutorial flag, configureTutorial() |
| `Packages/Flip54Storage/.../ModelContainer+Setup.swift` | Simulator vs device container config |
| `project.yml` | XcodeGen spec |

---

## Sound assets needed (Commit 33 — no-ops until delivered)
Drop these into `Flip54/Resources/sounds/` and re-run `xcodegen generate`:

| Filename | Event |
|----------|-------|
| `card-flip.mp3` | Card flip mid-point |
| `deck-riffle.mp3` | Shuffle riffle phase |
| `card-skip.mp3` | Skip action |
| `hold-start.mp3` | Ace hold begins |
| `hold-tick.mp3` | Each second during last 10s of hold |
| `hold-end.mp3` | Hold timer expires |
| `completion.mp3` | Workout complete |

## Card artwork assets needed (Commit 27 — no-ops until delivered)
Drop 55 PNGs into `Flip54/Resources/decks/standard/` per naming convention in that folder's README.

---

## Branch strategy
- `main` — always clean, merged at end of each milestone
- `feature/milestone-N-*` — one branch per milestone, squash-merge to main with milestone summary commit
- **Current:** `feature/milestone-6-polish` — commits 32–33 done, 34–35 pending, 36–37 blocked
