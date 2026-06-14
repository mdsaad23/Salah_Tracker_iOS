import Foundation

/// The 6 daily prayer/time markers tracked by the app.
enum Prayer: String, CaseIterable, Codable, Identifiable, Sendable {
    case fajr
    case sunrise
    case dhuhr
    case asr
    case maghrib
    case isha

    var id: String { rawValue }

    /// English display name, e.g. "Fajr".
    var displayName: String {
        switch self {
        case .fajr: "Fajr"
        case .sunrise: "Sunrise"
        case .dhuhr: "Dhuhr"
        case .asr: "Asr"
        case .maghrib: "Maghrib"
        case .isha: "Isha"
        }
    }

    /// Arabic display name, shown alongside the English name per design tokens.
    var arabicName: String {
        switch self {
        case .fajr: "الفجر"
        case .sunrise: "الشروق"
        case .dhuhr: "الظهر"
        case .asr: "العصر"
        case .maghrib: "المغرب"
        case .isha: "العشاء"
        }
    }

    /// True for the 5 obligatory prayers (excludes sunrise).
    var isObligatory: Bool { self != .sunrise }
}
