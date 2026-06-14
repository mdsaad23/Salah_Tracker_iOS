import SwiftUI

/// A single row in today's prayer list: EN/AR name and computed time, with
/// the upcoming prayer highlighted in the gold accent.
struct PrayerRow: View {
    let prayer: Prayer
    let time: Date
    let isNext: Bool

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(prayer.displayName)
                    .font(.body.weight(isNext ? .semibold : .regular))
                    .foregroundStyle(isNext ? Color.appAccent : Color.appTextPrimary)
                Text(prayer.arabicName)
                    .font(.caption)
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Text(time, style: .time)
                .font(.body.monospacedDigit().weight(isNext ? .semibold : .regular))
                .foregroundStyle(isNext ? Color.appAccent : Color.appTextPrimary)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    VStack(spacing: 0) {
        ForEach(Prayer.allCases) { prayer in
            PrayerRow(prayer: prayer, time: .now, isNext: prayer == .asr)
        }
    }
    .padding()
    .background(Color.appBackground)
}
