import SwiftUI
import Flip54Core
import Flip54DesignSystem

/// Home: title, deck fan, a summary of the setup that opens Setup, and Start.
struct StartScreen: View {
    @Environment(WatchWorkoutModel.self) private var model

    var body: some View {
        let settings = model.settings
        NavigationStack {
            VStack(spacing: 4) {
                WatchDeckFan(isMidas: settings.deckId == "midas")
                    .frame(height: 78)
                NavigationLink {
                    SetupScreen()
                } label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 3) {
                            Text(Copy.difficultySummary(settings.difficulty, halfDeck: settings.useHalfDeck))
                                .font(WatchType.sub(15))
                                .tracking(0.75)
                                .foregroundStyle(DS.Colors.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                        Text(settings.equipmentName.uppercased())
                            .font(WatchType.sub(11))
                            .tracking(1)
                            .foregroundStyle(DS.Colors.textSecondary)
                    }
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.plain)
                Spacer(minLength: 0)
                WatchActionButton(title: "Start") { model.start() }
                    .handGestureShortcut(.primaryAction)
            }
            .padding(.horizontal, WatchLayout.edge)
            .ignoresSafeArea(edges: .bottom)
            .background(Color.black)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("FLIP 54")
                        .font(WatchType.display(18))
                        .tracking(0.25)
                        .foregroundStyle(DS.Colors.textPrimary)
                }
            }
        }
    }
}

func multiplier(_ difficulty: Difficulty) -> String {
    Copy.multiplier(difficulty)
}

struct SetupScreen: View {
    @Environment(WatchWorkoutModel.self) private var model

    var body: some View {
        let settings = model.settings
        ScrollView {
            VStack(spacing: 4) {
                NavigationLink { DifficultyScreen() } label: {
                    SetupRowLabel(label: "Difficulty", value: settings.difficulty.displayName,
                                  detail: multiplier(settings.difficulty))
                }
                NavigationLink { DeckSizeScreen() } label: {
                    SetupRowLabel(label: "Deck", value: settings.deckName)
                }
                NavigationLink { EquipmentScreen() } label: {
                    SetupRowLabel(label: "Equipment", value: settings.equipmentName)
                }
                NavigationLink { CardStyleScreen() } label: {
                    SetupRowLabel(label: "Card style", value: cardStyleName(settings.deckId))
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
        .navigationTitle {
            Text("SETUP").font(WatchType.sub(14)).foregroundStyle(DS.Colors.gold)
        }
    }
}

struct DifficultyScreen: View {
    @Environment(WatchWorkoutModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(Difficulty.allCases, id: \.self) { level in
                    WatchOptionRow(title: level.displayName, subtitle: Copy.description(level),
                                   isSelected: model.settings.difficulty == level) {
                        model.settings.difficulty = level
                        dismiss()
                    }
                }
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
        .navigationTitle {
            Text("DIFFICULTY").font(WatchType.sub(14)).foregroundStyle(DS.Colors.gold)
        }
    }
}

struct DeckSizeScreen: View {
    @Environment(WatchWorkoutModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                option(half: false, detail: Copy.fullDeckDetail)
                option(half: true, detail: Copy.halfDeckDetail)
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
        .navigationTitle {
            Text("DECK").font(WatchType.sub(14)).foregroundStyle(DS.Colors.gold)
        }
    }

    private func option(half: Bool, detail: String) -> some View {
        WatchOptionRow(title: Copy.deckSizeName(halfDeck: half), subtitle: detail,
                       isSelected: model.settings.useHalfDeck == half, uppercasesTitle: false) {
            model.settings.useHalfDeck = half
            dismiss()
        }
    }
}

struct EquipmentScreen: View {
    @Environment(WatchWorkoutModel.self) private var model

    var body: some View {
        @Bindable var settings = model.settings
        ScrollView {
            VStack(spacing: 4) {
                EquipmentToggleRow(title: Copy.weights, subtitle: Copy.weightsDetail,
                                   systemImage: "dumbbell.fill", isOn: $settings.hasWeights)
                EquipmentToggleRow(title: Copy.pullUpBar, subtitle: Copy.pullUpBarDetail,
                                   systemImage: "figure.climbing", isOn: $settings.hasPullUpBar)
                if !settings.hasWeights && !settings.hasPullUpBar {
                    Text(Copy.bodyweightOnly)
                        .font(WatchType.body(10))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 6)
                }
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
        .navigationTitle {
            Text("EQUIPMENT").font(WatchType.sub(14)).foregroundStyle(DS.Colors.gold)
        }
    }
}

func cardStyleName(_ deckId: String) -> String {
    deckId == "midas" ? "Midas" : "Standard"
}

/// Standard, or Midas once it's unlocked on the iPhone (3 workouts, which
/// now includes workouts done on the watch). The choice syncs to the iPhone.
struct CardStyleScreen: View {
    @Environment(WatchWorkoutModel.self) private var model
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        let settings = model.settings
        ScrollView {
            VStack(spacing: 4) {
                style("standard", name: "Standard")
                style("midas", name: "Midas")
                WatchOptionRow(title: "Masonic", subtitle: Copy.unlockHint(workoutsLeft: nil), isSelected: false,
                               isEnabled: false, uppercasesTitle: false, capsSubtitle: true) {}
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
        .navigationTitle {
            Text("CARD STYLE").font(WatchType.sub(14)).foregroundStyle(DS.Colors.gold)
        }
    }

    /// A deck row as in the iPhone's deck picker: "Equipped" under the
    /// chosen deck, the workouts still needed under a locked one.
    private func style(_ id: String, name: String) -> some View {
        let settings = model.settings
        let unlocked = id == "standard" || settings.isUnlocked(id)
        let isSelected = settings.deckId == id
        let subtitle = unlocked
            ? (isSelected ? Copy.equipped : "")
            // Before the iPhone has synced, the watch doesn't know the count yet.
            : settings.workoutsToUnlock(id).map { Copy.unlockHint(workoutsLeft: $0) } ?? "Unlock on iPhone"
        return WatchOptionRow(title: name, subtitle: subtitle, isSelected: isSelected, isEnabled: unlocked,
                              uppercasesTitle: false, capsSubtitle: true) {
            settings.deckId = id
            dismiss()
        }
    }
}
