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
                WatchDeckFan()
                    .frame(height: 78)
                NavigationLink {
                    SetupScreen()
                } label: {
                    VStack(spacing: 3) {
                        HStack(spacing: 3) {
                            Text("\(settings.difficulty.displayName.uppercased()) · \(multiplier(settings.difficulty))")
                                .font(WatchType.sub(15))
                                .tracking(0.75)
                                .foregroundStyle(DS.Colors.textPrimary)
                            Image(systemName: "chevron.right")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DS.Colors.textSecondary)
                        }
                        Text("\(settings.deckName) deck · \(settings.equipmentName)")
                            .font(WatchType.body(11))
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
    String(format: "%.1f×", difficulty.multiplier)
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
                    SetupRowLabel(label: "Deck", value: settings.deckName, detail: "\(settings.deckSize)")
                }
                NavigationLink { EquipmentScreen() } label: {
                    SetupRowLabel(label: "Equipment", value: settings.equipmentName)
                }
                NavigationLink { CardStyleScreen() } label: {
                    SetupRowLabel(label: "Card style", value: "Standard")
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

    private static let blurbs: [Difficulty: String] = [
        .beginner: "Build the habit.",
        .standard: "As prescribed.",
        .advanced: "Push it.",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(Difficulty.allCases, id: \.self) { level in
                    WatchOptionRow(title: level.displayName, subtitle: Self.blurbs[level] ?? "",
                                   trailing: multiplier(level),
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
                option(half: false, name: "Full", count: 54, blurb: "Every card, both jokers")
                option(half: true, name: "Half", count: 27, blurb: "Aces, faces, 10s, 9s, two 8s, 1 joker")
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
        .navigationTitle {
            Text("DECK").font(WatchType.sub(14)).foregroundStyle(DS.Colors.gold)
        }
    }

    private func option(half: Bool, name: String, count: Int, blurb: String) -> some View {
        WatchOptionRow(title: name, subtitle: blurb, trailing: "\(count)",
                       isSelected: model.settings.useHalfDeck == half) {
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
                EquipmentToggleRow(title: "Weights", subtitle: "Dumbbells or kettlebells",
                                   systemImage: "dumbbell.fill", isOn: $settings.hasWeights)
                EquipmentToggleRow(title: "Pull-up bar", subtitle: "Fixed or doorframe bar",
                                   systemImage: "figure.climbing", isOn: $settings.hasPullUpBar)
                Text(settings.hasWeights || settings.hasPullUpBar
                     ? "Body-weight moves stay in the mix."
                     : "Body-weight only. No problem, we’ve got you.")
                    .font(WatchType.body(10))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 6)
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
        .navigationTitle {
            Text("EQUIPMENT").font(WatchType.sub(14)).foregroundStyle(DS.Colors.gold)
        }
    }
}

/// Only the standard deck is available on the watch for now; Midas unlocks
/// with workout history, which the watch doesn't have until history sync.
struct CardStyleScreen: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                WatchOptionRow(title: "Standard", subtitle: "Selected", isSelected: true) {}
                WatchOptionRow(title: "Midas", subtitle: "Unlock on iPhone", isSelected: false, isEnabled: false) {}
                WatchOptionRow(title: "Masonic", subtitle: "Coming soon", isSelected: false, isEnabled: false) {}
            }
            .padding(.horizontal, WatchLayout.edge)
        }
        .background(Color.black)
        .navigationTitle {
            Text("CARD STYLE").font(WatchType.sub(14)).foregroundStyle(DS.Colors.gold)
        }
    }
}
