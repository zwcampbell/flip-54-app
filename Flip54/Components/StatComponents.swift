import SwiftUI

/// A single stat value + label, e.g. "42 / TOTAL REPS". Shared across
/// CompletionView, HistoryView's workout detail sheet, and ProfileView,
/// which previously each defined an identical (or near-identical) private
/// `statCell`/`statTile` function.
struct StatCell: View {
    let value: String
    let label: String
    var valueSize: CGFloat = 32
    var spacing: CGFloat = 2

    var body: some View {
        VStack(spacing: spacing) {
            Text(value)
                .font(.custom("BarlowCondensed-ExtraBold", size: valueSize))
                .foregroundStyle(DS.Colors.textPrimary)
            Text(label.uppercased())
                .font(.custom("Oswald-SemiBold", size: 10))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }
}

/// A small uppercase section label (e.g. "RECENT", "LIFETIME STATS") used to
/// head off a card or list. Shared across HistoryView and ProfileView, which
/// previously each defined an identical private `sectionHeader` function.
struct SectionHeader: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.custom("Oswald-SemiBold", size: 11))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1.4)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
}
