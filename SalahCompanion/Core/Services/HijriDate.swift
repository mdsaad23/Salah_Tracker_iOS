import Foundation

/// Formats the Hijri (Umm al-Qura) calendar date for display, applying the
/// user's manual ±day adjustment (see `UserSettings.hijriDateOffsetDays`),
/// since computed Hijri dates can be off by a day from local moon-sighting
/// announcements.
enum HijriDate {
    static func formatted(for date: Date, offsetDays: Int, locale: Locale = .current) -> String {
        var calendar = Calendar(identifier: .islamicUmmAlQura)
        calendar.locale = locale
        let adjustedDate = calendar.date(byAdding: .day, value: offsetDays, to: date) ?? date

        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        formatter.setLocalizedDateFormatFromTemplate("d MMMM y")
        return formatter.string(from: adjustedDate)
    }
}
