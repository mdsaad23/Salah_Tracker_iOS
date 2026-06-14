import Foundation
import SwiftData

/// Calculation method for prayer times. Raw values mirror Adhan-swift's
/// `CalculationMethod` case names so `PrayerTimeService` can map 1:1.
enum CalculationMethod: String, CaseIterable, Codable, Sendable {
    case muslimWorldLeague
    case egyptian
    case karachi
    case ummAlQura
    case dubai
    case moonsightingCommittee
    case northAmerica
    case kuwait
    case qatar
    case singapore
    case tehran
    case turkey
}

/// Madhab affects the Asr calculation only.
enum Madhab: String, CaseIterable, Codable, Sendable {
    case shafi
    case hanafi
}

enum LocationMode: String, Codable, Sendable {
    case automatic
    case manual
}

enum TimeFormat: String, Codable, Sendable {
    case twelveHour
    case twentyFourHour
}

/// User-configurable settings: location, calculation preferences, tracked
/// prayers, notification offsets, and display preferences. A single instance
/// is expected per user, stored in the shared App Group container so the
/// widget and App Intents extensions can read it.
@Model
final class UserSettings {
    var locationMode: LocationMode
    var locationName: String
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String

    var calculationMethod: CalculationMethod
    var madhab: Madhab

    /// Subset of `Prayer` the user wants tracked/notified about.
    var trackedPrayers: [Prayer]

    /// Per-prayer notification lead time in minutes, keyed by `Prayer.rawValue`.
    var notificationOffsetMinutes: [String: Int]

    var timeFormat: TimeFormat

    /// Manual adjustment applied to the computed Hijri date, in days (±1 typical).
    var hijriDateOffsetDays: Int

    init(
        locationMode: LocationMode = .automatic,
        locationName: String = "",
        latitude: Double = 0,
        longitude: Double = 0,
        timeZoneIdentifier: String = TimeZone.current.identifier,
        calculationMethod: CalculationMethod = .muslimWorldLeague,
        madhab: Madhab = .shafi,
        trackedPrayers: [Prayer] = Prayer.allCases.filter(\.isObligatory),
        notificationOffsetMinutes: [String: Int] = [:],
        timeFormat: TimeFormat = .twentyFourHour,
        hijriDateOffsetDays: Int = 0
    ) {
        self.locationMode = locationMode
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.calculationMethod = calculationMethod
        self.madhab = madhab
        self.trackedPrayers = trackedPrayers
        self.notificationOffsetMinutes = notificationOffsetMinutes
        self.timeFormat = timeFormat
        self.hijriDateOffsetDays = hijriDateOffsetDays
    }
}
