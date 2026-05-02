import SwiftUI
import SwiftData
import Flip54Core
import Flip54Storage

struct HistoryView: View {
    let history: [WorkoutHistory]

    @State private var displayMonth: Date = Date()
    @State private var selectedWorkout: WorkoutHistory?
    @State private var recentPage: Int = 0

    private let recentPageSize = 5

    private var isOnTodayMonth: Bool {
        calendar.isDate(displayMonth, equalTo: Date(), toGranularity: .month)
    }

    private var recentPageCount: Int {
        max(1, Int(ceil(Double(history.count) / Double(recentPageSize))))
    }

    private var recentPageWorkouts: ArraySlice<WorkoutHistory> {
        let start = recentPage * recentPageSize
        let end = min(start + recentPageSize, history.count)
        guard start < end else { return [] }
        return history[start..<end]
    }

    private var calendar: Calendar { .current }

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    headerBar
                    calendarSection
                    recentSection
                }
            }
        }
        .sheet(item: $selectedWorkout) { workout in
            WorkoutDetailView(workout: workout)
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("HISTORY")
                .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                .foregroundStyle(DS.Colors.textPrimary)
            Spacer()
            Button {
                HapticEngine.shared.play(.tap)
                withAnimation(.easeInOut(duration: 0.2)) {
                    displayMonth = Date()
                }
            } label: {
                Text("TODAY")
                    .font(.custom("Oswald-SemiBold", size: 12))
                    .foregroundStyle(isOnTodayMonth ? DS.Colors.textTertiary : DS.Colors.gold)
                    .tracking(1.2)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(DS.Colors.bgCard)
                    .clipShape(Capsule())
                    .overlay(Capsule().strokeBorder(
                        isOnTodayMonth ? DS.Colors.border : DS.Colors.gold.opacity(0.6),
                        lineWidth: 1)
                    )
            }
            .disabled(isOnTodayMonth)
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }

    // MARK: - Calendar

    private var calendarSection: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button {
                    HapticEngine.shared.play(.tap)
                    displayMonth = calendar.date(byAdding: .month, value: -1, to: displayMonth) ?? displayMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(DS.Colors.bgCard)
                        .clipShape(Circle())
                }

                Spacer()

                Text(monthYearString(displayMonth))
                    .font(.custom("Oswald-SemiBold", size: 16))
                    .foregroundStyle(DS.Colors.textPrimary)
                    .tracking(0.5)

                Spacer()

                Button {
                    let next = calendar.date(byAdding: .month, value: 1, to: displayMonth) ?? displayMonth
                    if !calendar.isDate(next, equalTo: Date(), toGranularity: .month) ||
                       next <= Date() {
                        HapticEngine.shared.play(.tap)
                        displayMonth = next
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(DS.Colors.textSecondary)
                        .frame(width: 36, height: 36)
                        .background(DS.Colors.bgCard)
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            // Day-of-week headers
            HStack(spacing: 0) {
                ForEach(["Su","Mo","Tu","We","Th","Fr","Sa"], id: \.self) { d in
                    Text(d)
                        .font(.custom("Oswald-SemiBold", size: 11))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .tracking(0.5)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 8)

            // Calendar grid
            let days = monthDays(for: displayMonth)
            let workoutDays = Set(history.map { calendar.startOfDay(for: $0.completedAt) })

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(days.indices, id: \.self) { i in
                    let day = days[i]
                    calendarCell(day: day, workoutDays: workoutDays)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(DS.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(DS.Colors.border, lineWidth: 1))
        .padding(.horizontal, 20)
    }

    @ViewBuilder
    private func calendarCell(day: Date?, workoutDays: Set<Date>) -> some View {
        if let day {
            let isToday = calendar.isDateInToday(day)
            let hasWorkout = workoutDays.contains(calendar.startOfDay(for: day))
            let workoutsOnDay = history.filter { calendar.isDate($0.completedAt, inSameDayAs: day) }
            let dayNum = calendar.component(.day, from: day)

            Button {
                if let first = workoutsOnDay.first {
                    HapticEngine.shared.play(.tap)
                    selectedWorkout = first
                }
            } label: {
                ZStack {
                    if isToday {
                        Circle().fill(DS.Colors.gold.opacity(0.15))
                    }
                    if hasWorkout {
                        Circle().fill(DS.Colors.gold.opacity(0.9))
                    }
                    Text("\(dayNum)")
                        .font(.system(size: 13, weight: isToday ? .bold : .regular))
                        .foregroundStyle(
                            hasWorkout ? Color(hex: "#111111") :
                            isToday    ? DS.Colors.gold          :
                                         DS.Colors.textSecondary
                        )
                }
                .frame(height: 36)
            }
            .disabled(workoutsOnDay.isEmpty)
        } else {
            Color.clear.frame(height: 36)
        }
    }

    // MARK: - Recent workouts

    private var recentSection: some View {
        VStack(spacing: 0) {
            if history.isEmpty {
                emptyState
            } else {
                sectionHeader("RECENT")
                let pageItems = recentPageWorkouts
                let lastID = pageItems.last?.id
                VStack(spacing: 0) {
                    ForEach(pageItems) { workout in
                        Button {
                            HapticEngine.shared.play(.tap)
                            selectedWorkout = workout
                        } label: {
                            workoutRow(workout)
                        }
                        if workout.id != lastID {
                            Divider().background(DS.Colors.borderSub).padding(.leading, 56)
                        }
                    }
                }
                .background(DS.Colors.bgCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(DS.Colors.border, lineWidth: 1))
                .padding(.horizontal, 20)

                if recentPageCount > 1 {
                    paginationBar
                        .padding(.top, 12)
                }
                Color.clear.frame(height: 60)
            }
        }
    }

    private var paginationBar: some View {
        HStack {
            Button {
                if recentPage > 0 {
                    HapticEngine.shared.play(.tap)
                    recentPage -= 1
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(recentPage > 0 ? DS.Colors.textSecondary : DS.Colors.textTertiary.opacity(0.4))
                    .frame(width: 36, height: 36)
                    .background(DS.Colors.bgCard)
                    .clipShape(Circle())
            }
            .disabled(recentPage == 0)

            Spacer()

            Text("PAGE \(recentPage + 1) OF \(recentPageCount)")
                .font(.custom("Oswald-SemiBold", size: 11))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1.2)

            Spacer()

            Button {
                if recentPage < recentPageCount - 1 {
                    HapticEngine.shared.play(.tap)
                    recentPage += 1
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(recentPage < recentPageCount - 1 ? DS.Colors.textSecondary : DS.Colors.textTertiary.opacity(0.4))
                    .frame(width: 36, height: 36)
                    .background(DS.Colors.bgCard)
                    .clipShape(Circle())
            }
            .disabled(recentPage >= recentPageCount - 1)
        }
        .padding(.horizontal, 24)
    }

    private func workoutRow(_ workout: WorkoutHistory) -> some View {
        HStack(spacing: 14) {
            // Date pill
            VStack(spacing: 0) {
                Text(dayOfWeek(workout.completedAt))
                    .font(.custom("Oswald-SemiBold", size: 10))
                    .foregroundStyle(DS.Colors.textTertiary)
                    .tracking(0.5)
                Text("\(calendar.component(.day, from: workout.completedAt))")
                    .font(.custom("BarlowCondensed-ExtraBold", size: 20))
                    .foregroundStyle(DS.Colors.gold)
            }
            .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text("\(workout.totalReps) reps · \(workout.cardCount) cards")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(DS.Colors.textPrimary)
                Text("\(durationString(workout.duration)) · \(workout.difficulty.displayName)")
                    .font(.system(size: 12))
                    .foregroundStyle(DS.Colors.textTertiary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundStyle(DS.Colors.textTertiary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("♣")
                .font(.system(size: 48))
                .foregroundStyle(DS.Colors.textTertiary)
            Text("No workouts yet")
                .font(.custom("BarlowCondensed-ExtraBold", size: 24))
                .foregroundStyle(DS.Colors.textSecondary)
            Text("Complete your first workout to see history here.")
                .font(.system(size: 14))
                .foregroundStyle(DS.Colors.textTertiary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 60)
        .padding(.horizontal, 40)
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

    // MARK: - Calendar helpers

    private func monthDays(for month: Date) -> [Date?] {
        var days: [Date?] = []
        let components = calendar.dateComponents([.year, .month], from: month)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else { return days }

        let startWeekday = (calendar.component(.weekday, from: firstOfMonth) - 1 + 7) % 7
        for _ in 0..<startWeekday { days.append(nil) }

        for day in range {
            var dc = components
            dc.day = day
            if let date = calendar.date(from: dc) { days.append(date) }
        }
        // Pad to complete weeks
        while days.count % 7 != 0 { days.append(nil) }
        return days
    }

    private func monthYearString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "MMMM yyyy"
        return fmt.string(from: date).uppercased()
    }

    private func dayOfWeek(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEE"
        return fmt.string(from: date).uppercased()
    }

    private func durationString(_ ti: TimeInterval) -> String {
        let total = Int(ti)
        let m = total / 60
        let s = total % 60
        let sStr = s < 10 ? "0\(s)" : "\(s)"
        return "\(m):\(sStr)"
    }
}

// MARK: - Workout detail sheet

struct WorkoutDetailView: View {
    let workout: WorkoutHistory
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            DS.Colors.bg.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 0) {
                    // Handle bar
                    Capsule()
                        .fill(DS.Colors.border)
                        .frame(width: 40, height: 4)
                        .padding(.top, 14)
                        .padding(.bottom, 20)

                    // Date headline
                    Text(dateString(workout.completedAt).uppercased())
                        .font(.custom("BarlowCondensed-ExtraBold", size: 28))
                        .foregroundStyle(DS.Colors.textPrimary)
                        .padding(.bottom, 4)
                    Text("\(workout.difficulty.displayName) · \(workout.deckId.capitalized) Deck")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textTertiary)
                        .padding(.bottom, 24)

                    // Stats
                    statsCard

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private var statsCard: some View {
        VStack(spacing: 0) {
            // Top row
            HStack {
                statCell(value: "\(workout.totalReps)", label: "Total Reps")
                Divider().frame(height: 44).background(DS.Colors.border)
                statCell(value: "\(workout.cardCount)", label: "Cards")
                Divider().frame(height: 44).background(DS.Colors.border)
                statCell(value: durationString(workout.duration), label: "Time")
            }
            .padding(.vertical, 16)

            Divider().background(DS.Colors.border)

            suitRow(.hearts,   label: "Lower Body", reps: workout.heartsReps)
            Divider().background(DS.Colors.borderSub).padding(.leading, 50)
            suitRow(.spades,   label: "Upper Body", reps: workout.spadesReps)
            Divider().background(DS.Colors.borderSub).padding(.leading, 50)
            suitRow(.clubs,    label: "Total Body", reps: workout.clubsReps)
            Divider().background(DS.Colors.borderSub).padding(.leading, 50)
            suitRow(.diamonds, label: "Core",       reps: workout.diamondsReps)

            if workout.jumpingJacks > 0 {
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                suitRow(nil, label: "Jumping Jacks", reps: workout.jumpingJacks)
            }

            if workout.skipCount > 0 {
                Divider().background(DS.Colors.borderSub).padding(.leading, 50)
                HStack {
                    Text("Skipped")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.Colors.textTertiary)
                    Spacer()
                    Text("\(workout.skipCount)")
                        .font(.custom("IBMPlexMono-Medium", size: 14))
                        .foregroundStyle(DS.Colors.textTertiary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 13)
            }
        }
        .background(DS.Colors.bgCard)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).strokeBorder(DS.Colors.border, lineWidth: 1))
    }

    private func suitRow(_ suit: Suit?, label: String, reps: Int) -> some View {
        let isRed = suit == .hearts || suit == .diamonds
        let glyph: String
        switch suit {
        case .hearts:   glyph = "♥"
        case .spades:   glyph = "♠"
        case .clubs:    glyph = "♣"
        case .diamonds: glyph = "♦"
        case .none:     glyph = "★"
        }

        return HStack(spacing: 14) {
            Text(glyph)
                .font(.system(size: 16))
                .foregroundStyle(isRed ? DS.Colors.red : suit == nil ? DS.Colors.gold : DS.Colors.textPrimary)
                .frame(width: 20)
            Text(label)
                .font(.system(size: 13))
                .foregroundStyle(DS.Colors.textSecondary)
            Spacer()
            Text("\(reps)")
                .font(.custom("IBMPlexMono-Medium", size: 14))
                .foregroundStyle(DS.Colors.textPrimary)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 13)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.custom("BarlowCondensed-ExtraBold", size: 32))
                .foregroundStyle(DS.Colors.textPrimary)
            Text(label.uppercased())
                .font(.custom("Oswald-SemiBold", size: 10))
                .foregroundStyle(DS.Colors.textTertiary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }

    private func dateString(_ date: Date) -> String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMM d"
        return fmt.string(from: date)
    }

    private func durationString(_ ti: TimeInterval) -> String {
        let total = Int(ti)
        let m = total / 60
        let s = total % 60
        let sStr = s < 10 ? "0\(s)" : "\(s)"
        return "\(m):\(sStr)"
    }
}
