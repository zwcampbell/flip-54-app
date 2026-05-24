import SwiftUI
import Flip54Core

struct FormGuideView: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    private var guide: FormGuide { FormGuideData.guide(for: exercise) }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                header
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        figureStage
                        tempoLine
                        executionSection
                        watchForSection
                        Spacer(minLength: 100)
                    }
                }
                .scrollIndicators(.hidden)
            }
            // Sticky CTA
            VStack {
                Spacer()
                ctaBar
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            closeButton
            Spacer()
            VStack(spacing: 3) {
                Text("FORM GUIDE")
                    .font(.custom("Oswald-SemiBold", size: 10))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .tracking(1.8)
                Text(exercise.displayName.uppercased())
                    .font(.custom("BarlowCondensed-ExtraBold", size: 26))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tracking(0.5)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer()
            Color.clear.frame(width: 40, height: 40)  // balance the close button
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(DS.Colors.borderSub)
                .frame(height: 1)
        }
    }

    private var closeButton: some View {
        Button {
            HapticEngine.shared.play(.tap)
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(DS.Colors.textSecondary)
                .frame(width: 40, height: 40)
                .background(DS.Colors.bgRaised)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(DS.Colors.border, lineWidth: 1.5)
                )
        }
    }

    // MARK: - Figure stage (placeholder)

    private var figureStage: some View {
        ZStack(alignment: .topLeading) {
            // Striped background pattern
            Canvas { ctx, size in
                let stripe: CGFloat = 14
                var x: CGFloat = -size.height
                while x < size.width + size.height {
                    var path = Path()
                    path.move(to: CGPoint(x: x, y: 0))
                    path.addLine(to: CGPoint(x: x + stripe, y: 0))
                    path.addLine(to: CGPoint(x: x + stripe + size.height, y: size.height))
                    path.addLine(to: CGPoint(x: x + size.height, y: size.height))
                    path.closeSubpath()
                    ctx.fill(path, with: .color(DS.Colors.bgRaised))
                    x += stripe * 2
                }
            }
            .frame(height: 200)

            ExerciseFigureView(exercise: exercise)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .frame(height: 200)

            // Category chip
            Text(guide.category)
                .font(.custom("IBMPlexMono-Medium", size: 10))
                .foregroundStyle(DS.Colors.textTertiary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.black.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .padding(12)

            // Tempo pip (top-right)
            HStack(spacing: 6) {
                Circle()
                    .fill(DS.Colors.gold)
                    .frame(width: 8, height: 8)
                Text("LOOP")
                    .font(.custom("IBMPlexMono-Medium", size: 10))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tracking(0.5)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(.black.opacity(0.75))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .frame(height: 200)
        .background(DS.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(DS.Colors.border, lineWidth: 1)
        )
        .padding(.horizontal, 18)
        .padding(.top, 16)
    }

    // MARK: - Tempo line

    private var tempoLine: some View {
        Text("// \(guide.tempoLabel)")
            .font(.custom("IBMPlexMono-Medium", size: 10))
            .foregroundStyle(DS.Colors.textTertiary)
            .tracking(0.5)
            .padding(.horizontal, 22)
            .padding(.top, 10)
    }

    // MARK: - Execution cues

    private var executionSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("EXECUTION")
            VStack(spacing: 12) {
                ForEach(guide.cues.indices, id: \.self) { i in
                    cueRow(number: i + 1, text: guide.cues[i])
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
    }

    private func cueRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text(String(format: "%02d", number))
                .font(.custom("IBMPlexMono-Medium", size: 13))
                .foregroundStyle(DS.Colors.gold)
                .frame(width: 26, alignment: .leading)
                .padding(.top, 1)
            Text(text)
                .font(.system(size: 14))
                .foregroundStyle(DS.Colors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Watch For

    private var watchForSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("WATCH FOR")
            VStack(spacing: 8) {
                ForEach(guide.watch.indices, id: \.self) { i in
                    watchRow(text: guide.watch[i])
                }
            }
        }
        .padding(.horizontal, 18)
        .padding(.top, 22)
    }

    private func watchRow(text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 12))
                .foregroundStyle(DS.Colors.red)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textSecondary)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(DS.Colors.redSoft)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(DS.Colors.red.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - CTA

    private var ctaBar: some View {
        VStack(spacing: 0) {
            LinearGradient(
                colors: [DS.Colors.bg.opacity(0), DS.Colors.bg],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 40)
            .allowsHitTesting(false)

            Button {
                HapticEngine.shared.play(.tap)
                dismiss()
            } label: {
                Text("BACK TO WORKOUT")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 22))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tracking(0.8)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(DS.Colors.bgRaised)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(DS.Colors.border, lineWidth: 1.5))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 36)
            .background(DS.Colors.bg)
        }
    }

    // MARK: - Helpers

    private func sectionLabel(_ text: String) -> some View {
        Text(text)
            .font(.custom("Oswald-SemiBold", size: 11))
            .foregroundStyle(DS.Colors.textTertiary)
            .tracking(1.6)
            .padding(.bottom, 12)
    }
}
