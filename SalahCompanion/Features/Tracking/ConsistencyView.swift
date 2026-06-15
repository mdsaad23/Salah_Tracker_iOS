import SwiftData
import SwiftUI

/// Habit Consistency screen: a calendar of day cells, each ringed in
/// proportion to how many tracked prayers were completed that day, plus
/// current streak and this-week summary. Reads `PrayerLog` from the shared
/// store.
struct ConsistencyView: View {
    @Query private var logs: [PrayerLog]
    @Query private var settingsList: [UserSettings]

    /// How many past weeks of cells to display.
    private let weeksToShow = 12
    private let calendar = Calendar.current

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                statsRow
                calendarCard
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color.appBackground)
        .navigationTitle("Habit Consistency")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Stats

    private var statsRow: some View {
        HStack(spacing: 12) {
            statTile(
                value: "\(currentStreak)",
                unit: "day streak",
                systemImage: "flame.fill"
            )
            statTile(
                value: "\(prayedThisWeek)",
                unit: "prayed this week",
                systemImage: "checkmark.seal.fill"
            )
        }
    }

    private func statTile(value: String, unit: LocalizedStringKey, systemImage: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                Circle().fill(Color.appAccent.opacity(0.15))
                Image(systemName: systemImage)
                    .font(.subheadline)
                    .foregroundStyle(Color.appAccent)
            }
            .frame(width: 32, height: 32)

            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
            Text(unit)
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.appCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.appPrimary.opacity(0.06), radius: 10, y: 4)
    }

    // MARK: - Calendar

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last \(weeksToShow) Weeks")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)

            weekdayHeader

            VStack(spacing: 10) {
                ForEach(weeks, id: \.first) { week in
                    HStack(spacing: 8) {
                        ForEach(week, id: \.self) { day in
                            dayCell(for: day)
                        }
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.appPrimary.opacity(0.06), radius: 10, y: 4)
    }

    private var weekdayHeader: some View {
        HStack(spacing: 8) {
            ForEach(orderedWeekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(.caption2)
                    .foregroundStyle(Color.appTextSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    /// One calendar cell: the day's number inside a ring filled in proportion
    /// to that day's completed prayers, with today highlighted by a soft fill.
    @ViewBuilder
    private func dayCell(for day: Date) -> some View {
        let isFuture = day > today
        let isToday = calendar.isDate(day, inSameDayAs: today)
        let progress = isFuture ? 0 : min(Double(prayedCount(on: day)) / Double(denominator), 1)

        ZStack {
            Circle()
                .fill(isToday ? Color.appPrimary.opacity(0.12) : Color.clear)
            Circle()
                .strokeBorder(Color.appTextSecondary.opacity(0.15), lineWidth: 3)
            if progress > 0 {
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(Color.appPrimary, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
            }
            Text("\(calendar.component(.day, from: day))")
                .font(.caption.weight(isToday ? .bold : .regular).monospacedDigit())
                .foregroundStyle(isFuture ? Color.appTextSecondary.opacity(0.4) : Color.appTextPrimary)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .padding(2)
    }

    // MARK: - Derived data

    private var today: Date { calendar.startOfDay(for: .now) }

    /// Number of tracked obligatory prayers — the denominator for a "full" day.
    private var denominator: Int {
        let tracked = settingsList.first?.trackedPrayers.filter(\.isObligatory).count ?? 5
        return max(tracked, 1)
    }

    /// Prayed (on-time or late) counts keyed by start-of-day.
    private var prayedByDay: [Date: Int] {
        var result: [Date: Int] = [:]
        for log in logs where log.status == .prayedOnTime || log.status == .prayedLate {
            let day = calendar.startOfDay(for: log.date)
            result[day, default: 0] += 1
        }
        return result
    }

    private func prayedCount(on day: Date) -> Int {
        prayedByDay[calendar.startOfDay(for: day)] ?? 0
    }

    /// Weeks (oldest first), each an array of 7 days aligned to the calendar's
    /// first weekday, ending with the current week.
    private var weeks: [[Date]] {
        let weekday = calendar.component(.weekday, from: today)
        let offsetIntoWeek = (weekday - calendar.firstWeekday + 7) % 7
        guard
            let currentWeekStart = calendar.date(byAdding: .day, value: -offsetIntoWeek, to: today),
            let firstWeekStart = calendar.date(byAdding: .day, value: -7 * (weeksToShow - 1), to: currentWeekStart)
        else { return [] }

        return (0..<weeksToShow).compactMap { weekIndex in
            guard let weekStart = calendar.date(byAdding: .day, value: 7 * weekIndex, to: firstWeekStart)
            else { return nil }
            return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
        }
    }

    private var orderedWeekdaySymbols: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        let start = calendar.firstWeekday - 1
        return (0..<7).map { symbols[(start + $0) % 7] }
    }

    /// Consecutive days with all tracked prayers prayed, counting back from
    /// today (or yesterday if today isn't complete yet).
    private var currentStreak: Int {
        var streak = 0
        var day = today
        if prayedCount(on: day) < denominator {
            // Today still in progress — start the count from yesterday.
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = yesterday
        }
        while prayedCount(on: day) >= denominator {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = previous
        }
        return streak
    }

    private var prayedThisWeek: Int {
        guard let week = weeks.last else { return 0 }
        return week.reduce(0) { $0 + prayedCount(on: $1) }
    }
}

#Preview {
    NavigationStack {
        ConsistencyView()
    }
    .modelContainer(for: [UserSettings.self, DailyPrayerTimes.self, PrayerLog.self], inMemory: true)
}
