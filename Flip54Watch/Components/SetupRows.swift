import SwiftUI
import Flip54DesignSystem

/// Gold caps title at the top of a page, with an optional back button.
struct WatchScreenHeader: View {
    let title: String
    var onBack: (() -> Void)?

    var body: some View {
        HStack(spacing: 7) {
            if let onBack {
                Button(action: onBack) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(DS.Colors.textPrimary)
                        .frame(width: 26, height: 26)
                        .background(Circle().fill(DS.Colors.bgCard))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Back")
            }
            Text(title.uppercased())
                .font(WatchType.sub(14))
                .tracking(0.75)
                .foregroundStyle(DS.Colors.gold)
                .lineLimit(1)
            Spacer(minLength: 0)
        }
    }
}

/// Label on the left, value on the right, on a dark rounded row
/// (Progress "Deck", summary "Avg per card", etc.).
struct WatchInfoRow<Value: View>: View {
    let label: String
    @ViewBuilder let value: () -> Value

    var body: some View {
        HStack {
            Text(label)
                .font(WatchType.body(11.5))
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer(minLength: 6)
            value()
                .font(WatchType.body(11.5))
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 11)
        .frame(height: 36)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(DS.Colors.bgCard))
        .accessibilityElement(children: .combine)
    }
}

extension WatchInfoRow where Value == Text {
    init(_ label: String, value: String) {
        self.label = label
        self.value = { Text(value) }
    }
}

/// A Setup row: small label over the current choice, with a chevron.
struct SetupRow: View {
    let label: String
    let value: String
    var detail: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SetupRowLabel(label: label, value: value, detail: detail)
        }
        .buttonStyle(.plain)
    }
}

/// The look of a `SetupRow`, for use as a `NavigationLink` label.
struct SetupRowLabel: View {
    let label: String
    let value: String
    var detail: String?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2.5) {
                Text(label.uppercased())
                    .font(WatchType.sub(9))
                    .tracking(1.2)
                    .foregroundStyle(DS.Colors.textSecondary)
                HStack(alignment: .firstTextBaseline, spacing: 5) {
                    Text(value.uppercased())
                        .font(WatchType.sub(13))
                        .tracking(0.5)
                        .foregroundStyle(DS.Colors.textPrimary)
                    if let detail {
                        Text(detail)
                            .font(WatchType.mono(10))
                            .foregroundStyle(DS.Colors.gold)
                    }
                }
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(DS.Colors.textSecondary)
        }
        .padding(.leading, 12)
        .padding(.trailing, 9)
        .frame(height: 44)
        .background(RoundedRectangle(cornerRadius: WatchLayout.rowRadius, style: .continuous).fill(DS.Colors.bgCard))
        .contentShape(Rectangle())
    }
}

/// A selectable option (Difficulty, Deck, Card style). The chosen one gets a
/// gold border and gold title. `leading` holds an optional illustration.
/// Casing follows the matching iPhone screen: `uppercasesTitle` for caps
/// titles (Difficulty), `capsSubtitle` for small caps hints (Card style).
struct WatchOptionRow<Leading: View>: View {
    let title: String
    let subtitle: String
    var trailing: String?
    let isSelected: Bool
    var isEnabled = true
    var uppercasesTitle = true
    var capsSubtitle = false
    @ViewBuilder var leading: () -> Leading
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                leading()
                VStack(alignment: .leading, spacing: 3) {
                    Text(uppercasesTitle ? title.uppercased() : title)
                        .font(uppercasesTitle ? WatchType.sub(13.5) : WatchType.display(16))
                        .tracking(uppercasesTitle ? 0.75 : 0.25)
                        .foregroundStyle(isSelected ? DS.Colors.gold : DS.Colors.textPrimary)
                    if !subtitle.isEmpty {
                        if capsSubtitle {
                            Text(subtitle.uppercased())
                                .font(WatchType.sub(9))
                                .tracking(1)
                                .foregroundStyle(isSelected ? DS.Colors.gold : DS.Colors.textSecondary)
                        } else {
                            Text(subtitle)
                                .font(WatchType.body(9.5))
                                .foregroundStyle(DS.Colors.textSecondary)
                                .lineLimit(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                if let trailing {
                    Text(trailing)
                        .font(WatchType.mono(14))
                        .foregroundStyle(isSelected ? DS.Colors.gold : DS.Colors.textSecondary)
                } else if !isEnabled {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(minHeight: 50)
            .background(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(isSelected ? DS.Colors.goldSoft : DS.Colors.bgCard)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .strokeBorder(isSelected ? DS.Colors.gold : DS.Colors.bgCard, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

extension WatchOptionRow where Leading == EmptyView {
    init(title: String, subtitle: String, trailing: String? = nil, isSelected: Bool,
         isEnabled: Bool = true, uppercasesTitle: Bool = true, capsSubtitle: Bool = false,
         action: @escaping () -> Void) {
        self.init(title: title, subtitle: subtitle, trailing: trailing, isSelected: isSelected,
                  isEnabled: isEnabled, uppercasesTitle: uppercasesTitle, capsSubtitle: capsSubtitle,
                  leading: { EmptyView() }, action: action)
    }
}

/// An equipment on/off row with a gold switch.
struct EquipmentToggleRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(DS.Colors.gold)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(WatchType.body(13))
                        .foregroundStyle(DS.Colors.textPrimary)
                    Text(subtitle)
                        .font(WatchType.body(9))
                        .foregroundStyle(DS.Colors.textSecondary)
                }
            }
        }
        .tint(DS.Colors.gold)
        .padding(.horizontal, 10)
        .frame(minHeight: 52)
        .background(RoundedRectangle(cornerRadius: 15, style: .continuous).fill(DS.Colors.bgCard))
    }
}

#Preview("Setup") {
    ScrollView {
        VStack(spacing: 4) {
            WatchScreenHeader(title: "Setup", onBack: {})
            SetupRow(label: "Difficulty", value: "Standard", detail: "×1.0") {}
            SetupRow(label: "Deck", value: "Full Deck") {}
            SetupRow(label: "Equipment", value: "Bodyweight") {}
            SetupRow(label: "Card style", value: "Standard") {}
        }
        .padding(.horizontal, WatchLayout.edge)
    }
    .background(Color.black)
}

#Preview("Difficulty options") {
    ScrollView {
        VStack(spacing: 4) {
            WatchScreenHeader(title: "Difficulty", onBack: {})
            WatchOptionRow(title: "Beginner", subtitle: Copy.description(.beginner), isSelected: false) {}
            WatchOptionRow(title: "Standard", subtitle: Copy.description(.standard), isSelected: true) {}
            WatchOptionRow(title: "Advanced", subtitle: Copy.description(.advanced), isSelected: false) {}
            WatchOptionRow(title: "Midas", subtitle: Copy.unlockHint(workoutsLeft: 1), isSelected: false,
                           isEnabled: false, uppercasesTitle: false, capsSubtitle: true) {}
        }
        .padding(.horizontal, WatchLayout.edge)
    }
    .background(Color.black)
}

#Preview("Equipment + info rows") {
    @Previewable @State var weights = true
    @Previewable @State var bar = false
    ScrollView {
        VStack(spacing: 4) {
            EquipmentToggleRow(title: Copy.weights, subtitle: Copy.weightsDetail,
                               systemImage: "dumbbell.fill", isOn: $weights)
            EquipmentToggleRow(title: Copy.pullUpBar, subtitle: Copy.pullUpBarDetail,
                               systemImage: "figure.climbing", isOn: $bar)
            WatchInfoRow("Deck", value: "Standard · Full Deck")
            WatchInfoRow(label: "History") {
                Label("Saved", systemImage: "checkmark").foregroundStyle(DS.Colors.success)
            }
        }
        .padding(.horizontal, WatchLayout.edge)
    }
    .background(Color.black)
}
