import Foundation
import SwiftData

/// DEBUG-only hooks that let CI (and `xcrun simctl launch`) drive the app into a
/// deterministic state and a specific screen for screenshots. Launch arguments
/// of the form `-Key value` populate `UserDefaults`' argument domain, so they
/// can be read here without any extra parsing.
///
/// In release builds every value is inert, so this can never affect real users.
enum UITestConfiguration {
    /// When `true`, seed a fixed location + sample prayer history so screenshots
    /// are reproducible. Passed as `-UITestSeed YES`.
    static var isSeeding: Bool {
        #if DEBUG
        UserDefaults.standard.bool(forKey: "UITestSeed")
        #else
        false
        #endif
    }

    /// Initial screen to open: `"consistency"`, `"qibla"`, or `nil`/`"home"` for
    /// the Home screen. Passed as `-UITestScreen consistency`.
    static var initialScreen: String? {
        #if DEBUG
        UserDefaults.standard.string(forKey: "UITestScreen")
        #else
        nil
        #endif
    }

    /// Seeds a manual Makkah location plus a prayer-log history that exercises
    /// every tracker state (completed / missed) and a varied consistency
    /// heatmap. Only call when `isSeeding` is true and the store is empty.
    static func seed(into context: ModelContext) {
        context.insert(
            UserSettings(
                locationMode: .manual,
                locationName: "Makkah",
                latitude: 21.4225,
                longitude: 39.8262,
                timeZoneIdentifier: "Asia/Riyadh"
            )
        )

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Asia/Riyadh") ?? .current
        let today = calendar.startOfDay(for: .now)
        let obligatory = Prayer.allCases.filter(\.isObligatory)

        // History for the consistency heatmap: a recent full streak, then a
        // varied pattern so the gradient (light → dark) is visible.
        let variedPattern = [3, 5, 4, 2, 5, 4, 1, 5, 3, 4]
        for offset in 1...34 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let count = offset <= 6 ? 5 : variedPattern[offset % variedPattern.count]
            for prayer in obligatory.prefix(count) {
                context.insert(PrayerLog(date: day, prayer: prayer, status: .prayedOnTime, markedAt: day))
            }
        }

        // Today: a mix that shows completed, missed, next, and upcoming circles.
        context.insert(PrayerLog(date: today, prayer: .fajr, status: .prayedOnTime, markedAt: .now))
        context.insert(PrayerLog(date: today, prayer: .dhuhr, status: .prayedOnTime, markedAt: .now))
        context.insert(PrayerLog(date: today, prayer: .asr, status: .missed, markedAt: .now))
    }
}
