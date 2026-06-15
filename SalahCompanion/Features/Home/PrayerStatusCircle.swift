import SwiftUI

/// One prayer in the Home tracker: a tappable status circle above its English
/// name and computed time. The circle's appearance encodes the prayer's state.
struct PrayerStatusCircle: View {
    /// Visual state of a prayer in today's tracker, derived from its log status
    /// and how its time relates to "now".
    enum State {
        /// Marked prayed (on time or late) — solid emerald fill with a check.
        case prayed
        /// Marked missed — clay-rose fill with a cross.
        case missed
        /// The upcoming/active prayer — soft glowing ring with a center dot.
        case next
        /// Time has passed but it's unlogged — a hollow ring inviting a tap.
        case past
        /// Still in the future and not the next prayer — a quiet outline.
        case upcoming
    }

    let prayer: Prayer
    let time: Date
    let state: State

    private let diameter: CGFloat = 50

    var body: some View {
        VStack(spacing: 6) {
            circle
            Text(prayer.displayName)
                .font(.caption.weight(state == .next ? .semibold : .regular))
                .foregroundStyle(labelColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(time, style: .time)
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Color.appTextSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(width: 56)
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var circle: some View {
        ZStack {
            switch state {
            case .prayed:
                Circle().fill(Color.appPrimary)
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(Color.appTextOnPrimary)

            case .missed:
                Circle().fill(Color.appMissed)
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.appTextOnPrimary)

            case .next:
                Circle().fill(Color.appUpcoming.opacity(0.12))
                Circle().strokeBorder(Color.appUpcoming, lineWidth: 3)
                Circle()
                    .fill(Color.appUpcoming)
                    .frame(width: 12, height: 12)
                    .shadow(color: Color.appUpcoming.opacity(0.6), radius: 4)

            case .past:
                Circle().strokeBorder(Color.appTextSecondary.opacity(0.5), lineWidth: 2)

            case .upcoming:
                Circle().strokeBorder(Color.appTextSecondary.opacity(0.25), lineWidth: 2)
            }
        }
        .frame(width: diameter, height: diameter)
        .shadow(color: glowColor, radius: state == .next || state == .prayed ? 8 : 0, y: 2)
    }

    /// Soft glow beneath the active and completed circles; other states cast
    /// no shadow.
    private var glowColor: Color {
        switch state {
        case .prayed: Color.appPrimary.opacity(0.25)
        case .next: Color.appUpcoming.opacity(0.35)
        case .missed, .past, .upcoming: .clear
        }
    }

    private var labelColor: Color {
        switch state {
        case .prayed: Color.appPrimary
        case .missed: Color.appMissed
        case .next: Color.appUpcoming
        case .past, .upcoming: Color.appTextPrimary
        }
    }
}

#Preview {
    HStack(spacing: 0) {
        PrayerStatusCircle(prayer: .fajr, time: .now, state: .prayed)
        PrayerStatusCircle(prayer: .dhuhr, time: .now, state: .missed)
        PrayerStatusCircle(prayer: .asr, time: .now, state: .next)
        PrayerStatusCircle(prayer: .maghrib, time: .now, state: .past)
        PrayerStatusCircle(prayer: .isha, time: .now, state: .upcoming)
    }
    .padding()
    .background(Color.appBackground)
}
