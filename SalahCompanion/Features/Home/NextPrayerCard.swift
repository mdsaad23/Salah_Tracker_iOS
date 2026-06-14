import SwiftUI

/// The Home screen's focal element: the upcoming prayer and a live countdown
/// to it, ticking every second via `TimelineView`.
struct NextPrayerCard: View {
    let prayer: Prayer
    let time: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Next Prayer")
                .font(.subheadline)
                .foregroundStyle(Color.appTextOnPrimary.opacity(0.7))

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(prayer.displayName)
                    .font(.largeTitle.weight(.semibold))
                Text(prayer.arabicName)
                    .font(.title2)
            }
            .foregroundStyle(Color.appTextOnPrimary)

            Text(time, style: .time)
                .font(.headline)
                .foregroundStyle(Color.appAccent)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(countdown(to: time, from: context.date))
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(Color.appTextOnPrimary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func countdown(to target: Date, from now: Date) -> String {
        let remaining = max(0, target.timeIntervalSince(now))
        return Duration.seconds(remaining).formatted(.time(pattern: .hourMinuteSecond))
    }
}

#Preview {
    NextPrayerCard(prayer: .asr, time: .now.addingTimeInterval(5_430))
        .padding()
        .background(Color.appBackground)
}
