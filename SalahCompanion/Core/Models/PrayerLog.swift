import Foundation
import SwiftData

/// Whether a tracked prayer was prayed on time, prayed late, missed, or not
/// tracked at all (for prayers the user opted out of in Settings).
enum PrayerStatus: String, Codable, Sendable {
    case prayedOnTime
    case prayedLate
    case missed
    case notTracked
}

/// A single day's record for a single prayer, created once that prayer's
/// time has passed and the user marks (or the system records) its status.
@Model
final class PrayerLog {
    var date: Date
    var prayer: Prayer
    var status: PrayerStatus
    var markedAt: Date?

    init(
        date: Date,
        prayer: Prayer,
        status: PrayerStatus = .notTracked,
        markedAt: Date? = nil
    ) {
        self.date = date
        self.prayer = prayer
        self.status = status
        self.markedAt = markedAt
    }
}
