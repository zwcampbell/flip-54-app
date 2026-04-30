import SwiftUI
import SwiftData
import Flip54Core
import Flip54Storage

struct SettingsView: View {
    @Bindable var settings: UserSettings

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    header
                    equipmentSection
                    difficultySection
                    Spacer(minLength: 60)
                }
            }
        }
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
                    subtitle: "Clubs → Goblet Squat (otherwise Body-weight Squats ×2)",
                    isOn: $settings.hasWeights
                )
                divider
                equipmentRow(
                    icon: "figure.strengthtraining.traditional",
                    title: "Pull-up Bar",
                    subtitle: "Spades → Pull-ups (otherwise Hindu Push-ups)",
                    isOn: $settings.hasPullUpBar
                )
                divider
                equipmentRow(
                    icon: "rectangle.fill",
                    title: "Yoga Mat",
                    subtitle: "Improves comfort for hold exercises",
                    isOn: $settings.hasYogaMat
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
