import SwiftUI
import Flip54Core
import Flip54DesignSystem

/// The flipped card beside what to do with it ("7 REPS" or "HOLD 1:00"),
/// with the exercise name underneath.
///
/// While a card is being flipped it sits alone in the centre (`showsTarget`
/// false); turning `showsTarget` on inside an animation glides it left and
/// fades the reps in behind it.
struct PrescriptionView: View {
    let card: Card
    let prescription: Prescription
    var showsTarget = true
    /// Horizontal scale of the card, for the flip's squash (1 = flat on).
    var cardSquash: CGFloat = 1

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 13) {
                WatchCardFace(card: card)
                    .scaleEffect(x: cardSquash, y: 1)
                if showsTarget {
                    target
                        .frame(minWidth: 48, alignment: .leading)
                        .transition(.opacity.animation(.easeOut(duration: 0.2).delay(0.12)))
                }
            }
            Text(prescription.exercise.displayName.uppercased())
                .font(WatchType.sub(15))
                .tracking(0.5)
                .foregroundStyle(DS.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.75)
                .opacity(showsTarget ? 1 : 0)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder private var target: some View {
        switch prescription {
        case .reps(_, let count):
            VStack(alignment: .leading, spacing: 5) {
                Text("\(count)")
                    .font(WatchType.display(68))
                    .foregroundStyle(card.accentColor)
                    .frame(height: 56)
                    .minimumScaleFactor(0.6)
                Text("REPS")
                    .font(WatchType.sub(13))
                    .tracking(1.5)
                    .foregroundStyle(DS.Colors.textPrimary)
            }
        case .hold(_, let seconds):
            VStack(alignment: .leading, spacing: 6) {
                Text("HOLD")
                    .font(WatchType.display(40))
                    .tracking(0.5)
                    .foregroundStyle(DS.Colors.gold)
                    .frame(height: 33)
                Text(watchClock(seconds))
                    .font(WatchType.mono(17))
                    .foregroundStyle(DS.Colors.textPrimary)
            }
        }
    }
}

#Preview("Number card") {
    PrescriptionView(
        card: .standard(suit: .hearts, rank: .seven),
        prescription: .reps(exercise: .jumpingSquat, count: 7)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Face card") {
    PrescriptionView(
        card: .standard(suit: .spades, rank: .king),
        prescription: .reps(exercise: .hinduPushUp, count: 10)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Ace (hold)") {
    PrescriptionView(
        card: .standard(suit: .diamonds, rank: .ace),
        prescription: .hold(exercise: .hollowBodyHold, seconds: 60)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}

#Preview("Joker") {
    PrescriptionView(
        card: .joker(variant: .black),
        prescription: .reps(exercise: .jumpingJacks, count: 40)
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
}
