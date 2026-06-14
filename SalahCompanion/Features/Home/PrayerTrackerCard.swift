import SwiftUI

/// The Home screen's focal card: a "Today's Prayers" header with a completed
/// count, a tappable row of prayer status circles for logging, and the next
/// prayer's name with a live countdown beneath.
struct PrayerTrackerCard: View {
    let trackedPrayers: [Prayer]
    let today: DailyPrayerTimes
    let statuses: [Prayer: PrayerStatus]
    let next: (prayer: Prayer, time: Date)?
    let now: Date
    /// Marks `prayer` with `status`, or clears its log when `status` is `nil`.
    let onLog: (Prayer, PrayerStatus?) -> Void

    @State private var selectedPrayer: Prayer?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            circleRow
            Divider()
            nextPrayer
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appPrimaryLight.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.appPrimary.opacity(0.08), radius: 12, y: 4)
        .confirmationDialog(
            selectedPrayer?.displayName ?? "",
            isPresented: logDialogPresented,
            titleVisibility: .visible
        ) {
            if let prayer = selectedPrayer {
                Button("Prayed on time") { onLog(prayer, .prayedOnTime) }
                Button("Prayed late") { onLog(prayer, .prayedLate) }
                Button("Missed", role: .destructive) { onLog(prayer, .missed) }
                if statuses[prayer] != nil {
                    Button("Clear", role: .cancel) { onLog(prayer, nil) }
                }
            }
        }
    }

    private var header: some View {
        HStack {
            Text("Today's Prayers")
                .font(.headline)
                .foregroundStyle(Color.appTextPrimary)
            Spacer()
            Text("\(completedCount)/\(trackedPrayers.count)")
                .font(.headline.monospacedDigit())
                .foregroundStyle(Color.appPrimary)
        }
    }

    private var circleRow: some View {
        HStack(alignment: .top, spacing: 0) {
            ForEach(Array(trackedPrayers.enumerated()), id: \.element) { index, prayer in
                PrayerStatusCircle(
                    prayer: prayer,
                    time: today.time(for: prayer),
                    state: state(for: prayer)
                )
                .onTapGesture { selectedPrayer = prayer }

                if index < trackedPrayers.count - 1 {
                    connector
                }
            }
        }
    }

    /// A thin track segment between two circles, aligned to their center.
    private var connector: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.appTextSecondary.opacity(0.3))
            .frame(height: 2)
            .frame(maxWidth: .infinity)
            .padding(.top, 22) // ≈ circle radius, so it meets the circle centers
    }

    private var nextPrayer: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let next {
                Text("Next: \(next.prayer.displayName)")
                    .font(.title.weight(.bold))
                    .foregroundStyle(Color.appPrimary)

                HStack(spacing: 8) {
                    Text(next.time, style: .time)
                        .font(.subheadline.monospacedDigit())
                        .foregroundStyle(Color.appTextSecondary)
                    Text("·")
                        .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                    Text(countdown(to: next.time))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(Color.appTextPrimary)
                    Text("remaining")
                        .font(.subheadline)
                        .foregroundStyle(Color.appTextSecondary)
                }
            } else {
                Text("All prayers logged for today")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color.appPrimary)
            }
        }
    }

    // MARK: - Derived values

    private var completedCount: Int {
        trackedPrayers.count { prayer in
            statuses[prayer] == .prayedOnTime || statuses[prayer] == .prayedLate
        }
    }

    private func state(for prayer: Prayer) -> PrayerStatusCircle.State {
        switch statuses[prayer] {
        case .prayedOnTime, .prayedLate: return .prayed
        case .missed: return .missed
        case .notTracked, .none: break
        }
        if next?.prayer == prayer { return .next }
        if today.time(for: prayer) <= now { return .past }
        return .upcoming
    }

    private var logDialogPresented: Binding<Bool> {
        Binding(
            get: { selectedPrayer != nil },
            set: { if !$0 { selectedPrayer = nil } }
        )
    }

    private func countdown(to target: Date) -> String {
        let remaining = max(0, target.timeIntervalSince(now))
        return Duration.seconds(remaining).formatted(.time(pattern: .hourMinute))
    }
}

#Preview {
    let today = DailyPrayerTimes(
        date: .now, locationName: "Dubai", latitude: 25, longitude: 55,
        timeZoneIdentifier: "Asia/Dubai",
        fajr: .now.addingTimeInterval(-3600 * 6),
        sunrise: .now.addingTimeInterval(-3600 * 5),
        dhuhr: .now.addingTimeInterval(-3600 * 2),
        asr: .now.addingTimeInterval(3600),
        maghrib: .now.addingTimeInterval(3600 * 4),
        isha: .now.addingTimeInterval(3600 * 6)
    )
    return PrayerTrackerCard(
        trackedPrayers: Prayer.allCases.filter(\.isObligatory),
        today: today,
        statuses: [.fajr: .prayedOnTime, .dhuhr: .missed],
        next: (.asr, today.asr),
        now: .now,
        onLog: { _, _ in }
    )
    .padding()
    .background(Color.appBackground)
}
