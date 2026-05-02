import SwiftUI
import SwiftData
import Flip54Core
import Flip54Storage

struct ProfileView: View {
    let history: [WorkoutHistory]
    let settings: UserSettings

    @State private var showSettings = false

    private var stats: LifetimeStats { LifetimeStats(history: history) }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    headerBar
                    statsSection
                    suitsSection
                    settingsButton
                    Spacer(minLength: 60)
                }
            }
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheet(settings: settings)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("PROFILE")
                .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(DS.Colors.textSecondary)
                    .frame(width: 40, height: 40)
                    .background(DS.Colors.bgCard)
                    .clipShape(Circle())
                    .overlay(Circle().strokeBorder(DS.Colors.border, lineWidth: 1))
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 16)
    }

    // MARK: - Main stats

    private var statsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("LIFETIME STATS")
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
        VStack(spacing: 4) {
            Text(value)
                .font(.custom("BarlowCondensed-ExtraBold", size: 36))
                .foregroundStyle(DS.Colors.textPrimary)
            Text(label.uppercased())
                .font(.custom("Oswald-SemiBold", size: 10))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(DS.Colors.bgCard)
    }

    // MARK: - Per-suit breakdown

    private var suitsSection: some View {
        VStack(spacing: 0) {
            sectionHeader("REPS BY SUIT")
            VStack(spacing: 0) {
                suitBar(.hearts,   label: "Push-ups",    reps: stats.repsByHeart)
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                suitBar(.spades,   label: "Pull-ups",    reps: stats.repsBySpade)
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                suitBar(.clubs,    label: "Total Body",  reps: stats.repsByClub)
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                suitBar(.diamonds, label: "Core",        reps: stats.repsByDiamond)
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

    private func suitBar(_ suit: Suit, label: String, reps: Int) -> some View {
        let isRed = suit == .hearts || suit == .diamonds
        let color: Color = isRed ? DS.Colors.red : DS.Colors.textPrimary
        let glyph: String
        switch suit {
        case .hearts:   glyph = "♥"
        case .spades:   glyph = "♠"
        case .clubs:    glyph = "♣"
        case .diamonds: glyph = "♦"
        }
        return suitBarNeutral(glyph, label: label, reps: reps, color: color)
    }

    private func suitBarNeutral(_ glyph: String, label: String, reps: Int, color: Color) -> some View {
        let maxReps = max(1, [stats.repsByHeart, stats.repsBySpade, stats.repsByClub, stats.repsByDiamond, stats.jumpingJacks].max() ?? 1)
        let pct = Double(reps) / Double(maxReps)

        return HStack(spacing: 14) {
            Text(glyph)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 20)
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

    // MARK: - Settings button

    private var settingsButton: some View {
        Button {
            showSettings = true
        } label: {
            HStack {
                Image(systemName: "gearshape")
                    .foregroundStyle(DS.Colors.textSecondary)
                Text("Settings")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.Colors.textSecondary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .background(DS.Colors.bgCard)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.Colors.border, lineWidth: 1))
            .padding(.horizontal, 20)
            .padding(.top, 16)
        }
    }

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
}

// MARK: - Settings sheet wrapper

private struct SettingsSheet: View {
    @Bindable var settings: UserSettings
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Done") { dismiss() }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(DS.Colors.gold)
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                }
                SettingsView(settings: settings)
            }
        }
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

        // Streak calculation — consecutive days with at least one workout
        let cal = Calendar.current
        let workoutDays = Set(history.map { cal.startOfDay(for: $0.completedAt) }).sorted(by: >)
        var cur = 0, best = 0
        var check = cal.startOfDay(for: Date())
        for day in workoutDays {
            if cal.isDate(day, equalTo: check, toGranularity: .day) {
                cur += 1
                best = max(best, cur)
                check = cal.date(byAdding: .day, value: -1, to: check) ?? check
            } else if day < check {
                break
            }
        }
        currentStreak = cur
        // Longest streak (full pass)
        var longestPass = 0, streak = 0
        var prev: Date? = nil
        for day in workoutDays.sorted() {
            if let p = prev, cal.dateComponents([.day], from: p, to: day).day == 1 {
                streak += 1
            } else {
                streak = 1
            }
            longestPass = max(longestPass, streak)
            prev = day
        }
        longestStreak = max(longestPass, best)
    }

    var totalTimeString: String {
        let hrs = Int(totalTime) / 3600
        let mins = (Int(totalTime) % 3600) / 60
        if hrs > 0 { return "\(hrs)h \(mins)m" }
        return "\(mins)m"
    }
}
