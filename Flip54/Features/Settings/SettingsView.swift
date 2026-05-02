import SwiftUI
import SwiftData
import Flip54Core
import Flip54Storage

struct SettingsView: View {
    @Bindable var settings: UserSettings

    // Sound + haptic controls backed by UserDefaults
    @AppStorage(UserDefaultsKeys.sfxEnabled)      private var sfxEnabled: Bool  = true
    @AppStorage(UserDefaultsKeys.hapticsEnabled)  private var hapticsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.sfxVolume)       private var sfxVolume: Double = 1.0

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    header
                    equipmentSection
                    deckSection
                    difficultySection
                    audioSection
                    Spacer(minLength: 60)
                }
            }
        }
        // Toggle haptics — light impact when any toggle flips.
        .sensoryFeedback(.impact(weight: .light), trigger: settings.hasWeights)
        .sensoryFeedback(.impact(weight: .light), trigger: settings.hasPullUpBar)
        .sensoryFeedback(.impact(weight: .light), trigger: settings.useHalfDeck)
        .sensoryFeedback(.impact(weight: .light), trigger: sfxEnabled)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticsEnabled)
        // Difficulty selection — selection feedback on each row tap.
        .sensoryFeedback(.selection, trigger: settings.difficultyRaw)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("SETTINGS")
                .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Equipment

    private var equipmentSection: some View {
        VStack(spacing: 0) {
            sectionHeader("EQUIPMENT")
            VStack(spacing: 0) {
                equipmentRow(
                    icon: "dumbbell.fill",
                    title: "Weights",
                    subtitle: "Adds curls/press/triceps, goblet squats, weighted sit-ups, thrusters",
                    isOn: $settings.hasWeights
                )
                divider
                equipmentRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Pull-up Bar",
                    subtitle: "Adds pull-ups to upper body workouts and dead-hang holds",
                    isOn: $settings.hasPullUpBar
                )
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    private func equipmentRow(icon: String, title: String, subtitle: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(DS.Colors.gold)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(subtitle)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DS.Colors.gold)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Deck

    private var deckSection: some View {
        VStack(spacing: 0) {
            sectionHeader("DECK")
            VStack(spacing: 0) {
                equipmentRow(
                    icon: "rectangle.stack.fill",
                    title: "Half Deck",
                    subtitle: "27 cards · A/K/Q/J/10/9 every suit + 1 joker",
                    isOn: $settings.useHalfDeck
                )
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Difficulty

    private var difficultySection: some View {
        VStack(spacing: 0) {
            sectionHeader("DIFFICULTY")
            VStack(spacing: 0) {
                ForEach(Difficulty.allCases, id: \.self) { level in
                    difficultyRow(level)
                    if level != Difficulty.allCases.last {
                        divider
                    }
                }
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    private func difficultyRow(_ level: Difficulty) -> some View {
        let isSelected = settings.difficulty == level
        return Button {
            settings.difficultyRaw = level.rawValue
        } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(level.displayName.uppercased())
                        .font(.custom("BarlowCondensed-ExtraBold", size: 18))
                        .foregroundStyle(isSelected ? DS.Colors.gold : DS.Colors.textPrimary)
                    Text(level.description)
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(DS.Colors.gold)
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
        }
    }

    // MARK: - Audio

    private var audioSection: some View {
        VStack(spacing: 0) {
            sectionHeader("AUDIO & HAPTICS")
            VStack(spacing: 0) {
                equipmentRow(
                    icon: "speaker.wave.2.fill",
                    title: "Sound Effects",
                    subtitle: "Card flip, hold timer, completion sounds",
                    isOn: $sfxEnabled
                )
                divider
                equipmentRow(
                    icon: "hand.tap.fill",
                    title: "Haptic Feedback",
                    subtitle: "Vibration on flip, done, and skip",
                    isOn: $hapticsEnabled
                )
                if sfxEnabled {
                    divider
                    HStack(spacing: 14) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.Colors.gold)
                            .frame(width: 28)
                        Text("Volume")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(DS.Colors.textPrimary)
                        Slider(value: $sfxVolume, in: 0...1, step: 0.1)
                            .tint(DS.Colors.gold)
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.Colors.gold)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 14)
                }
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.custom("Oswald-SemiBold", size: 11))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1.4)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }

    private var divider: some View {
        Rectangle()
            .fill(DS.Colors.borderSub)
            .frame(height: 1)
            .padding(.leading, 60)
    }
}

// MARK: - Difficulty helpers

extension Difficulty: CaseIterable {
    public static let allCases: [Difficulty] = [.beginner, .standard, .advanced]

    var displayName: String {
        switch self {
        case .beginner:  return "Beginner"
        case .standard:  return "Standard"
        case .advanced:  return "Advanced"
        }
    }

    var description: String {
        switch self {
        case .beginner:  return "×0.75 reps — great for starting out"
        case .standard:  return "×1.0 reps — the full deck challenge"
        case .advanced:  return "×1.25 reps — for seasoned athletes"
        }
    }
}
