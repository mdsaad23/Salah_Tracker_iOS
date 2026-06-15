import SwiftData
import SwiftUI

/// Home quick-link card for Habit Consistency: icon + title, plus a row of
/// gradient dots previewing this week's daily completion — grey for no
/// prayers logged, darkening toward emerald as more of the day's tracked
/// prayers are logged.
struct ConsistencyPreviewCard: View {
    @Query private var logs: [PrayerLog]
    @Query private var settingsList: [UserSettings]

    private let calendar = Calendar.current

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.appPrimary.opacity(0.1))
                Image(systemName: "chart.bar.fill")
                    .font(.title3)
                    .foregroundStyle(Color.appPrimary)
            }
            .frame(width: 40, height: 40)

            VStack(alignment: .leading, spacing: 2) {
                Text("Streak & calendar")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.8)
                Text("Habit Consistency")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            HStack(spacing: 6) {
                ForEach(thisWeek, id: \.self) { day in
                    Circle()
                        .fill(color(forPrayed: prayedCount(on: day)))
                        .frame(maxWidth: .infinity)
                        .aspectRatio(1, contentMode: .fit)
                }
            }
        }
        .frame(maxWidth: .infinity, minHeight: 128, alignment: .leading)
        .padding(16)
        .background(Color.appCardSurface)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.appPrimary.opacity(0.06), radius: 10, y: 4)
    }

    private var today: Date { calendar.startOfDay(for: .now) }

    /// Number of tracked obligatory prayers — the denominator for a "full" day.
    private var denominator: Int {
        let tracked = settingsList.first?.trackedPrayers.filter(\.isObligatory).count ?? 5
        return max(tracked, 1)
    }

    /// The current week's days (Sun–Sat or aligned to the calendar's first
    /// weekday), oldest first.
    private var thisWeek: [Date] {
        let weekday = calendar.component(.weekday, from: today)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let weekStart = calendar.date(byAdding: .day, value: -offset, to: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private func prayedCount(on day: Date) -> Int {
        logs.count {
            ($0.status == .prayedOnTime || $0.status == .prayedLate) && calendar.isDate($0.date, inSameDayAs: day)
        }
    }

    /// Grey for no prayers logged, scaling up to a solid emerald fill once
    /// all tracked prayers are logged.
    private func color(forPrayed count: Int) -> Color {
        guard count > 0 else { return Color.appTextSecondary.opacity(0.15) }
        let fraction = min(Double(count) / Double(denominator), 1)
        return Color.appPrimary.opacity(0.3 + 0.7 * fraction)
    }
}

#Preview {
    ConsistencyPreviewCard()
        .padding()
        .background(Color.appBackground)
        .modelContainer(for: [UserSettings.self, DailyPrayerTimes.self, PrayerLog.self], inMemory: true)
}
