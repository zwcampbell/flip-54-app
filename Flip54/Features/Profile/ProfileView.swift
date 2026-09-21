import SwiftUI
import Flip54Core
import Flip54Storage

struct ProfileView: View {
    let history: [WorkoutHistory]

    @State private var expandedSuits: Set<Suit> = []

    private var stats: LifetimeStats { LifetimeStats(history: history) }

    private var allExpanded: Bool {
        Suit.allCases.allSatisfy { expandedSuits.contains($0) }
    }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                headerBar
                ScrollView {
                    VStack(spacing: 0) {
                        statsSection
                        suitsSection
                        Spacer(minLength: 60)
                    }
                }
            }
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("PROFILE")
                .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
        .background(DS.Colors.bg)
    }

    // MARK: - Main stats

    private var statsSection: some View {
        VStack(spacing: 0) {
            SectionHeader(title: "LIFETIME STATS")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
                statTile(value: "\(stats.totalWorkouts)", label: "Workouts")
                statTile(value: "\(stats.totalReps)", label: "Total Reps")
                statTile(value: "\(stats.totalCards)", label: "Cards Flipped")
                statTile(value: stats.totalTimeString, label: "Total Time")
                statTile(value: "\(stats.currentStreak)", label: "Current Streak")
                statTile(value: "\(stats.longestStreak)", label: "Best Streak")
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    private func statTile(value: String, label: String) -> some View {
        StatCell(value: value, label: label, valueSize: 36, spacing: 4)
            .padding(.vertical, 20)
            .background(DS.Colors.bgCard)
    }

    // MARK: - Per-suit breakdown

    private var suitsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("REPS BY BODY FOCUS")
                    .font(.custom("Oswald-SemiBold", size: 11))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .tracking(1.4)
                Spacer()
                Text(allExpanded ? "Collapse All" : "Expand All")
                    .font(.custom("Oswald-SemiBold", size: 11))
                    .foregroundStyle(DS.Colors.gold)
                    .tracking(1.2)
                    .onTapGesture {
                        HapticEngine.shared.play(.tap)
                        withAnimation(.easeInOut(duration: 0.2)) {
                            expandedSuits = allExpanded ? [] : Set(Suit.allCases)
                        }
                    }
            }
            .padding(.horizontal, 24)
            .padding(.top, 24)
            .padding(.bottom, 8)

            VStack(spacing: 0) {
                expandableSuitBar(.hearts,   label: "Lower Body",  reps: stats.repsByHeart)
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                expandableSuitBar(.spades,   label: "Upper Body",  reps: stats.repsBySpade)
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                expandableSuitBar(.clubs,    label: "Total Body",  reps: stats.repsByClub)
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                expandableSuitBar(.diamonds, label: "Core",        reps: stats.repsByDiamond)
                if stats.jumpingJacks > 0 {
                    Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                    suitBarNeutral("★", label: "Jumping Jacks", reps: stats.jumpingJacks, color: DS.Colors.gold)
                }
            }
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
            .padding(.horizontal, 20)
        }
    }

    @ViewBuilder
    private func expandableSuitBar(_ suit: Suit, label: String, reps: Int) -> some View {
        let color: Color = suit.color == .red ? DS.Colors.red : DS.Colors.textPrimary
        let glyph = suit.suitCharacter
        let isExpanded = expandedSuits.contains(suit)
        let exReps = stats.repsByExercise
            .filter { $0.key.bodyFocus == suit }
            .sorted { $0.value > $1.value }
        let maxReps = max(1, [stats.repsByHeart, stats.repsBySpade, stats.repsByClub, stats.repsByDiamond].max() ?? 1)
        let pct = Double(reps) / Double(maxReps)

        VStack(spacing: 0) {
            Button {
                HapticEngine.shared.play(.tap)
                withAnimation(.easeInOut(duration: 0.2)) {
                    if expandedSuits.contains(suit) {
                        expandedSuits.remove(suit)
                    } else {
                        expandedSuits.insert(suit)
                    }
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 14) {
                    Text(glyph)
                        .font(.system(size: 16))
                        .foregroundStyle(color)
                        .frame(width: 20, alignment: .leading)
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(label)
                                .font(.system(size: 13))
                                .foregroundStyle(DS.Colors.textSecondary)
                            Spacer()
                            Text("\(reps)")
                                .font(.custom("IBMPlexMono-Medium", size: 13))
                                .foregroundStyle(DS.Colors.textPrimary)
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(DS.Colors.textTertiary)
                        }
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule().fill(DS.Colors.bgRaised).frame(height: 4)
                                Capsule().fill(color.opacity(0.7))
                                    .frame(width: geo.size.width * pct, height: 4)
                                    .animation(.easeOut(duration: 0.6), value: pct)
                            }
                        }
                        .frame(height: 4)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ForEach(exReps, id: \.key) { exercise, count in
                    HStack {
                        Text(exercise.displayName)
                            .font(.system(size: 12))
                            .foregroundStyle(DS.Colors.textTertiary)
                        Spacer()
                        Text("\(count)")
                            .font(.custom("IBMPlexMono-Medium", size: 13))
                            .foregroundStyle(DS.Colors.textTertiary)
                    }
                    .padding(.leading, 52)
                    .padding(.trailing, 18)
                    .padding(.vertical, 9)
                    .background(DS.Colors.bgRaised.opacity(0.5))
                }
            }
        }
    }

    private func suitBarNeutral(_ glyph: String, label: String, reps: Int, color: Color) -> some View {
        let maxReps = max(1, [stats.repsByHeart, stats.repsBySpade, stats.repsByClub, stats.repsByDiamond, stats.jumpingJacks].max() ?? 1)
        let pct = Double(reps) / Double(maxReps)

        return HStack(alignment: .firstTextBaseline, spacing: 14) {
            Text(glyph)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 20, alignment: .leading)
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(label)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textSecondary)
                    Spacer()
                    Text("\(reps)")
                        .font(.custom("IBMPlexMono-Medium", size: 13))
                        .foregroundStyle(DS.Colors.textPrimary)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(DS.Colors.bgRaised).frame(height: 4)
                        Capsule().fill(color.opacity(0.7))
                            .frame(width: geo.size.width * pct, height: 4)
                            .animation(.easeOut(duration: 0.6), value: pct)
                    }
                }
                .frame(height: 4)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
    }
}

// MARK: - Lifetime stats model

struct LifetimeStats {
    let totalWorkouts: Int
    let totalReps: Int
    let totalCards: Int
    let totalTime: TimeInterval
    let currentStreak: Int
    let longestStreak: Int
    let repsByHeart: Int
    let repsBySpade: Int
    let repsByClub: Int
    let repsByDiamond: Int
    let jumpingJacks: Int
    let repsByExercise: [Exercise: Int]

    init(history: [WorkoutHistory]) {
        totalWorkouts = history.count
        totalReps     = history.reduce(0) { $0 + $1.totalReps }
        totalCards    = history.reduce(0) { $0 + $1.cardCount }
        totalTime     = history.reduce(0) { $0 + $1.duration }
        repsByHeart   = history.reduce(0) { $0 + $1.heartsReps }
        repsBySpade   = history.reduce(0) { $0 + $1.spadesReps }
        repsByClub    = history.reduce(0) { $0 + $1.clubsReps }
        repsByDiamond = history.reduce(0) { $0 + $1.diamondsReps }
        jumpingJacks  = history.reduce(0) { $0 + $1.jumpingJacks }
        var exDict: [Exercise: Int] = [:]
        for w in history {
            for (ex, count) in w.repsByExercise {
                exDict[ex, default: 0] += count
            }
        }
        repsByExercise = exDict

        // Streak calculation — consecutive days with at least one workout.
        let cal = Calendar.current
        let workoutDaySet = Set(history.map { cal.startOfDay(for: $0.completedAt) })
        let today = cal.startOfDay(for: Date())

        // Current streak: walk backward from today. If today has no workout
        // yet, start from yesterday instead of resetting to zero — the
        // streak should survive until the current day actually ends without
        // a workout, not the instant midnight passes.
        var cur = 0
        var cursor = workoutDaySet.contains(today)
            ? today
            : (cal.date(byAdding: .day, value: -1, to: today) ?? today)
        while workoutDaySet.contains(cursor) {
            cur += 1
            cursor = cal.date(byAdding: .day, value: -1, to: cursor) ?? cursor
        }
        currentStreak = cur

        // Longest streak ever: single forward pass over consecutive-day runs.
        // This already covers the trailing run current streak measures, so
        // no separate reconciliation is needed.
        var longest = 0
        var streak = 0
        var prevDay: Date? = nil
        for day in workoutDaySet.sorted() {
            if let prev = prevDay, cal.dateComponents([.day], from: prev, to: day).day == 1 {
                streak += 1
            } else {
                streak = 1
            }
            longest = max(longest, streak)
            prevDay = day
        }
        longestStreak = longest
    }

    var totalTimeString: String {
        let hrs = Int(totalTime) / 3600
        let mins = (Int(totalTime) % 3600) / 60
        if hrs > 0 { return "\(hrs)h \(mins)m" }
        return "\(mins)m"
    }
}
