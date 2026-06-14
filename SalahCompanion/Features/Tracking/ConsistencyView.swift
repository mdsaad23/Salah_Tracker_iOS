import SwiftData
import SwiftUI

/// Habit Consistency screen: a dot heatmap of prayer completion (7 dots per
/// row = one week, darker = more prayers prayed that day), plus current streak
/// and this-week summary. Reads `PrayerLog` from the shared store.
struct ConsistencyView: View {
    @Query private var logs: [PrayerLog]
    @Query private var settingsList: [UserSettings]

    /// How many past weeks of dots to display.
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
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: systemImage)
                .font(.title3)
                .foregroundStyle(Color.appAccent)
            Text(value)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
            Text(unit)
                .font(.caption)
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.appPrimaryLight.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Calendar heatmap

    private var calendarCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Last \(weeksToShow) Weeks")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appTextSecondary)

            weekdayHeader

            VStack(spacing: 8) {
                ForEach(weeks, id: \.first) { week in
                    HStack(spacing: 8) {
                        ForEach(week, id: \.self) { day in
                            dot(for: day)
                        }
                    }
                }
            }

            legend
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appPrimaryLight.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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

    @ViewBuilder
    private func dot(for day: Date) -> some View {
        let isFuture = day > today
        Circle()
            .fill(isFuture ? Color.clear : color(forPrayed: prayedCount(on: day)))
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                if calendar.isDate(day, inSameDayAs: today) {
                    Circle().strokeBorder(Color.appAccent, lineWidth: 2)
                }
            }
    }

    private var legend: some View {
        HStack(spacing: 8) {
            Text("Less")
                .font(.caption2)
                .foregroundStyle(Color.appTextSecondary)
            ForEach(0...denominator, id: \.self) { count in
                Circle()
                    .fill(color(forPrayed: count))
                    .frame(width: 12, height: 12)
            }
            Text("More")
                .font(.caption2)
                .foregroundStyle(Color.appTextSecondary)
        }
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

    /// Gradient from a light tint (few) to solid emerald (all prayers prayed).
    private func color(forPrayed count: Int) -> Color {
        guard count > 0 else { return Color.appTextSecondary.opacity(0.15) }
        let fraction = min(Double(count) / Double(denominator), 1)
        return Color.appPrimary.opacity(0.3 + 0.7 * fraction)
    }
}

#Preview {
    NavigationStack {
        ConsistencyView()
    }
    .modelContainer(for: [UserSettings.self, DailyPrayerTimes.self, PrayerLog.self], inMemory: true)
}
