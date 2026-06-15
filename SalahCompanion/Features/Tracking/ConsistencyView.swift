import SwiftData
import SwiftUI

/// Habit Consistency screen: a month-at-a-time calendar of day cells, each
/// ringed in proportion to how many tracked prayers were completed that day,
/// plus current streak and this-week summary. Swipe left/right on the
/// calendar to change months, or tap the month label to jump via a date
/// picker. Reads `PrayerLog` from the shared store.
struct ConsistencyView: View {
    @Query private var logs: [PrayerLog]
    @Query private var settingsList: [UserSettings]

    @State private var displayedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var showMonthPicker = false
    @State private var pickerDate = Date.now

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
        .sheet(isPresented: $showMonthPicker) {
            monthPickerSheet
        }
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
            monthHeader
            weekdayHeader

            VStack(spacing: 10) {
                ForEach(monthWeeks.indices, id: \.self) { weekIndex in
                    HStack(spacing: 8) {
                        ForEach(monthWeeks[weekIndex].indices, id: \.self) { dayIndex in
                            dayCell(for: monthWeeks[weekIndex][dayIndex])
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
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    if value.translation.width <= -50 {
                        changeMonth(by: 1)
                    } else if value.translation.width >= 50 {
                        changeMonth(by: -1)
                    }
                }
        )
    }

    private var monthHeader: some View {
        HStack {
            monthStepButton(systemImage: "chevron.left") { changeMonth(by: -1) }

            Spacer()

            Button {
                pickerDate = displayedMonth
                showMonthPicker = true
            } label: {
                Text(displayedMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.appTextPrimary)
            }

            Spacer()

            monthStepButton(systemImage: "chevron.right") { changeMonth(by: 1) }
        }
    }

    private func monthStepButton(systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 32, height: 32)
                .background(Color.appBackground)
                .clipShape(Circle())
        }
    }

    private var monthPickerSheet: some View {
        NavigationStack {
            DatePicker(
                "Select Month",
                selection: $pickerDate,
                displayedComponents: [.date]
            )
            .datePickerStyle(.graphical)
            .padding()
            .navigationTitle("Select Month")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        displayedMonth = calendar.dateInterval(of: .month, for: pickerDate)?.start ?? pickerDate
                        showMonthPicker = false
                    }
                }
            }
        }
        .presentationDetents([.medium])
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
    /// `nil` renders an empty cell, used to pad the grid to full weeks.
    @ViewBuilder
    private func dayCell(for day: Date?) -> some View {
        if let day {
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
        } else {
            Color.clear
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
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

    /// The days of `displayedMonth`, padded with leading/trailing `nil`s so
    /// the grid aligns to the calendar's first weekday and forms full weeks.
    private var monthDays: [Date?] {
        guard
            let monthInterval = calendar.dateInterval(of: .month, for: displayedMonth),
            let dayRange = calendar.range(of: .day, in: .month, for: displayedMonth)
        else { return [] }

        let firstOfMonth = monthInterval.start
        let weekday = calendar.component(.weekday, from: firstOfMonth)
        let leadingEmpty = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmpty)
        days += dayRange.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: firstOfMonth) }
        while days.count % 7 != 0 {
            days.append(nil)
        }
        return days
    }

    private var monthWeeks: [[Date?]] {
        stride(from: 0, to: monthDays.count, by: 7).map {
            Array(monthDays[$0..<min($0 + 7, monthDays.count)])
        }
    }

    private func changeMonth(by offset: Int) {
        guard let newMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth) else { return }
        withAnimation(.easeInOut(duration: 0.3)) {
            displayedMonth = calendar.dateInterval(of: .month, for: newMonth)?.start ?? newMonth
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

    /// The current real-world week's days (oldest first) — independent of
    /// whichever month is currently displayed in the calendar.
    private var currentWeek: [Date] {
        let weekday = calendar.component(.weekday, from: today)
        let offset = (weekday - calendar.firstWeekday + 7) % 7
        guard let weekStart = calendar.date(byAdding: .day, value: -offset, to: today) else { return [] }
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: weekStart) }
    }

    private var prayedThisWeek: Int {
        currentWeek.reduce(0) { $0 + prayedCount(on: $1) }
    }
}

#Preview {
    NavigationStack {
        ConsistencyView()
    }
    .modelContainer(for: [UserSettings.self, DailyPrayerTimes.self, PrayerLog.self], inMemory: true)
}
