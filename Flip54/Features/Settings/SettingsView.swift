import SwiftUI
import SwiftData
import Flip54Core
import Flip54Storage

struct SettingsView: View {
    @Bindable var settings: UserSettings

    // Sound + haptic controls backed by UserDefaults
    @AppStorage(UserDefaultsKeys.sfxEnabled)         private var sfxEnabled: Bool   = true
    @AppStorage(UserDefaultsKeys.hapticsEnabled)     private var hapticsEnabled: Bool = true
    @AppStorage(UserDefaultsKeys.sfxVolume)          private var sfxVolume: Double  = 1.0

    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    header
                    equipmentSection
                    deckSection
                    difficultySection
                    workoutsSection
                    audioSection
                    supportSection
                    Spacer(minLength: 60)
                }
            }
        }
        // Toggle haptics — light impact when any toggle flips.
        .sensoryFeedback(.impact(weight: .light), trigger: settings.hasWeights)
        .sensoryFeedback(.impact(weight: .light), trigger: settings.hasPullUpBar)
        .sensoryFeedback(.impact(weight: .light), trigger: settings.useHalfDeck)
        .sensoryFeedback(.impact(weight: .light), trigger: settings.disabledExercisesRaw)
        .sensoryFeedback(.impact(weight: .light), trigger: sfxEnabled)
        .sensoryFeedback(.impact(weight: .light), trigger: hapticsEnabled)
        // Difficulty selection — selection feedback on each row tap.
        .sensoryFeedback(.selection, trigger: settings.difficultyRaw)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            DS.Typography.display("SETTINGS", size: 32)
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
                    subtitle: "Adds curls, goblet squats, thrusters, and more",
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

    // MARK: - Exercises

    private var workoutsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("EXERCISES")
            Text("Choose which exercises appear in your workouts. Disabled exercises are excluded from all flips.")
                .font(.system(size: 12))
                .foregroundStyle(DS.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 8)
            VStack(spacing: 12) {
                ForEach(Suit.allCases, id: \.self) { suit in
                    exerciseGroupCard(for: suit)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func exerciseGroupCard(for suit: Suit) -> some View {
        // Always show the full possible roster so users can see and pre-configure
        // equipment-gated exercises before enabling the equipment.
        let fullPool = exercisePool(for: suit, equipment: .fullKit)
        return VStack(spacing: 0) {
            HStack(spacing: 8) {
                Text(suit.suitCharacter)
                    .font(.system(size: 14))
                    .foregroundStyle(suit.color == .red ? DS.Colors.red : DS.Colors.textPrimary)
                DS.Typography.display(suit.bodyFocusLabel.uppercased(), size: 15)
                    .foregroundStyle(DS.Colors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 18)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Rectangle()
                .fill(DS.Colors.borderSub)
                .frame(height: 1)

            ForEach(fullPool, id: \.self) { exercise in
                exerciseToggleRow(exercise, fullPool: fullPool)
                if exercise != fullPool.last {
                    divider
                }
            }
        }
        .background(DS.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
    }

    private func exerciseToggleRow(_ exercise: Exercise, fullPool: [Exercise]) -> some View {
        let isEnabled = exerciseIsEnabled(exercise)
        let isLast = isLastEnabled(exercise, in: fullPool)
        return HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text(exercise.displayName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(isEnabled ? DS.Colors.textPrimary : DS.Colors.textTertiary)
                if isLast {
                    Text("At least one exercise required")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
            }
            Spacer()
            if isLast {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            Toggle("", isOn: exerciseEnabledBinding(exercise))
                .labelsHidden()
                .tint(DS.Colors.gold)
                .disabled(isLast)
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }

    private func exerciseIsEnabled(_ exercise: Exercise) -> Bool {
        !settings.disabledExercisesRaw.split(separator: ",").contains(Substring(exercise.rawValue))
    }

    private func exerciseEnabledBinding(_ exercise: Exercise) -> Binding<Bool> {
        Binding(
            get: { exerciseIsEnabled(exercise) },
            set: { isOn in
                var disabled = Set(settings.disabledExercisesRaw.split(separator: ",").map(String.init))
                if isOn { disabled.remove(exercise.rawValue) } else { disabled.insert(exercise.rawValue) }
                settings.disabledExercisesRaw = disabled.sorted().joined(separator: ",")
            }
        )
    }

    private func isLastEnabled(_ exercise: Exercise, in fullPool: [Exercise]) -> Bool {
        guard exerciseIsEnabled(exercise) else { return false }
        return fullPool.filter { exerciseIsEnabled($0) }.count == 1
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
                    DS.Typography.display(level.displayName.uppercased(), size: 18)
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
                // If haptics are on but Core Haptics engine isn't running, UIKit
                // fallbacks are used — those respect the system Haptics toggle. Prompt
                // the user to check iOS Settings if they're not feeling anything.
                if hapticsEnabled && !HapticEngine.shared.isCoreHapticsRunning {
                    divider
                    HStack(spacing: 14) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(DS.Colors.textTertiary)
                            .frame(width: 28)
                        Text("If you feel no vibration, check **Settings → Sounds & Haptics → System Haptics**")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Colors.textTertiary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                }
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

    // MARK: - Support

    // App Review 3.2.2(iv): Flip 54 isn't an Apple-approved nonprofit, so donations
    // must be collected outside the app. Both links open in Safari.
    private var supportSection: some View {
        VStack(spacing: 0) {
            sectionHeader("SUPPORT THE ROW")
            VStack(alignment: .leading, spacing: 14) {
                Image("KLCLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 160)
                    .frame(maxWidth: .infinity)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("The Kenneth Lambert Collective")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text("A 501(c)(3) nonprofit")
                        .font(.system(size: 12))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
                Text("In December 2027 Kenneth Lambert rows 3,000 miles solo across the Atlantic to raise $2.5 million for the Masonic Home for Children at Oxford and the Central Children's Home of North Carolina.")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                Button {
                    openURL(Donation.donateURL)
                } label: {
                    HStack(spacing: 6) {
                        DS.Typography.display("DONATE", size: 16)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundStyle(DS.Colors.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(DS.Colors.gold)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityHint("Opens the Collective's GoFundMe donation page in Safari")
                Button {
                    openURL(Donation.websiteURL)
                } label: {
                    HStack(spacing: 6) {
                        Text("Follow the row at iamkennethlambert.com")
                            .font(.system(size: 13, weight: .semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(DS.Colors.gold)
                    .frame(maxWidth: .infinity)
                }
                .accessibilityHint("Opens Kenneth Lambert's website in Safari")
                Text("Donations are tax-deductible and go directly to the Collective through GoFundMe, outside Flip 54.")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(18)
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ text: String) -> some View {
        HStack {
            DS.Typography.sub(text, size: 11)
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

// MARK: - Donation

/// The Kenneth Lambert Collective (EIN 39-4037971), a 501(c)(3) in Charlotte, NC.
enum Donation {
    /// The Collective's verified GoFundMe charity page, straight to the donation form.
    static let donateURL = URL(string: "https://www.gofundme.com/charity/the-kenneth-lambert-collective/donate")!
    static let websiteURL = URL(string: "https://iamkennethlambert.com")!
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
        let m = String(format: "×%.1f", multiplier)
        switch self {
        case .beginner:  return "\(m) reps — great for starting out"
        case .standard:  return "\(m) reps — the full deck challenge"
        case .advanced:  return "\(m) reps — for seasoned athletes"
        }
    }
}
