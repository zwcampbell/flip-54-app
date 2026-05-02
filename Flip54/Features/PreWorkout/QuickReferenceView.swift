import SwiftUI
import Flip54Core

/// Compact quick-reference sheet explaining card values, suits, and special cards.
/// Presented from the (?) button on PreWorkoutView.
struct QuickReferenceView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    handleBar
                    header
                    cardValuesSection
                    suitsSection
                    specialCardsSection
                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    // MARK: - Handle bar

    private var handleBar: some View {
        Capsule()
            .fill(DS.Colors.border)
            .frame(width: 40, height: 4)
            .padding(.top, 14)
            .padding(.bottom, 20)
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("QUICK REFERENCE")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("Card values at a glance")
                    .font(.system(size: 14))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            Spacer()
            Button("Done") { dismiss() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(DS.Colors.gold)
        }
        .padding(.bottom, 24)
    }

    // MARK: - Card values

    private var cardValuesSection: some View {
        VStack(spacing: 0) {
            sectionLabel("CARD VALUES")
            VStack(spacing: 0) {
                valueRow(label: "2 – 10",    value: "Face value",  sub: "e.g. 7♣ = 7 reps")
                divider
                valueRow(label: "J, Q, K",   value: "10 reps",    sub: "Face cards always count as 10")
                divider
                valueRow(label: "Ace",       value: "Hold",        sub: "Timed position hold")
                divider
                valueRow(label: "Joker",     value: "Jumping Jacks", sub: "Reps scale with difficulty")
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
        }
    }

    private func valueRow(label: String, value: String, sub: String) -> some View {
        HStack(spacing: 0) {
            Text(label)
                .font(.custom("BarlowCondensed-ExtraBold", size: 20))
                .foregroundStyle(DS.Colors.gold)
                .frame(width: 72, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(sub)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Suits

    private var suitsSection: some View {
        VStack(spacing: 0) {
            sectionLabel("SUITS → EXERCISES")
            VStack(spacing: 0) {
                suitRow("♥", color: DS.Colors.red,         label: "Hearts",   exercise: "Push-ups")
                divider
                suitRow("♠", color: DS.Colors.textPrimary, label: "Spades",   exercise: "Pull-ups / Hindu Push-ups")
                divider
                suitRow("♣", color: DS.Colors.textPrimary, label: "Clubs",    exercise: "Squats / Goblet Squats")
                divider
                suitRow("♦", color: DS.Colors.red,         label: "Diamonds", exercise: "Core (Sit-ups etc.)")
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
        }
    }

    private func suitRow(_ glyph: String, color: Color, label: String, exercise: String) -> some View {
        HStack(spacing: 14) {
            Text(glyph)
                .font(.system(size: 20))
                .foregroundStyle(color)
                .frame(width: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text(exercise)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Special cards

    private var specialCardsSection: some View {
        VStack(spacing: 0) {
            sectionLabel("DIFFICULTY MULTIPLIERS")
            VStack(spacing: 0) {
                multiplierRow(level: "Beginner", mult: "×0.75", desc: "Scaled-down reps")
                divider
                multiplierRow(level: "Standard", mult: "×1.0",  desc: "The full challenge")
                divider
                multiplierRow(level: "Advanced", mult: "×1.25", desc: "Extra reps on every card")
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
        }
    }

    private func multiplierRow(level: String, mult: String, desc: String) -> some View {
        HStack {
            Text(level.uppercased())
                .font(.custom("BarlowCondensed-ExtraBold", size: 18))
                .foregroundStyle(DS.Colors.textPrimary)
                .frame(width: 88, alignment: .leading)
            Text(mult)
                .font(.custom("IBMPlexMono-Medium", size: 14))
                .foregroundStyle(DS.Colors.gold)
                .lineLimit(1)
                .fixedSize()
                .frame(width: 56, alignment: .leading)
            Text(desc)
                .font(.system(size: 12))
                .foregroundStyle(DS.Colors.textTertiary)
            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(.custom("Oswald-SemiBold", size: 11))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1.4)
            Spacer()
        }
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
