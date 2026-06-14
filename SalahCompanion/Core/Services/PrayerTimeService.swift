import Foundation
import Adhan

// NOTE: Written without access to Xcode/the Adhan-swift package (Windows
// dev environment). Once the SPM dependency is added (see XCODE_SETUP.md),
// verify against the actual Adhan-swift API surface:
//   - `Adhan.CalculationMethod.params -> CalculationParameters`
//   - `CalculationParameters.madhab` / `.highLatitudeRule`
//   - `Adhan.HighLatitudeRule` case names (`.seventhOfTheNight` etc.)
//   - `Adhan.PrayerTimes.init(coordinates:date:calculationParameters:)`

/// Computes prayer times entirely offline via Adhan-swift. Always pass the
/// *location's* timezone (not `.current`) so calendar-day boundaries line up
/// with the location being tracked.
struct PrayerTimeService {
    enum ServiceError: Error {
        /// Adhan could not compute times for the given date/coordinates.
        case calculationFailed
    }

    /// Latitude magnitude beyond which a high-latitude rule is applied to
    /// Fajr/Isha, since twilight-angle calculations become unreliable.
    private let highLatitudeThreshold: Double = 48

    /// Computes the 6 prayer times for a single calendar date at a location,
    /// expressed in the location's own timezone.
    func dailyPrayerTimes(
        for date: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone,
        calculationMethod: CalculationMethod,
        madhab: Madhab
    ) throws -> DailyPrayerTimes {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let components = calendar.dateComponents([.year, .month, .day], from: date)

        var parameters = calculationMethod.adhanMethod.params
        parameters.madhab = madhab.adhanMadhab
        if abs(latitude) >= highLatitudeThreshold {
            parameters.highLatitudeRule = .seventhOfTheNight
        }

        let coordinates = Adhan.Coordinates(latitude: latitude, longitude: longitude)
        guard let times = Adhan.PrayerTimes(
            coordinates: coordinates,
            date: components,
            calculationParameters: parameters
        ) else {
            throw ServiceError.calculationFailed
        }

        return DailyPrayerTimes(
            date: calendar.startOfDay(for: date),
            locationName: locationName,
            latitude: latitude,
            longitude: longitude,
            timeZoneIdentifier: timeZone.identifier,
            fajr: times.fajr,
            sunrise: times.sunrise,
            dhuhr: times.dhuhr,
            asr: times.asr,
            maghrib: times.maghrib,
            isha: times.isha
        )
    }

    /// Computes both today's and tomorrow's prayer times. Needed so the
    /// "next prayer" countdown wraps correctly overnight (e.g. counting down
    /// to tomorrow's Fajr after today's Isha has passed).
    func schedule(
        around date: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timeZone: TimeZone,
        calculationMethod: CalculationMethod,
        madhab: Madhab
    ) throws -> (today: DailyPrayerTimes, tomorrow: DailyPrayerTimes) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let tomorrowDate = calendar.date(byAdding: .day, value: 1, to: date) ?? date

        let today = try dailyPrayerTimes(
            for: date, locationName: locationName, latitude: latitude, longitude: longitude,
            timeZone: timeZone, calculationMethod: calculationMethod, madhab: madhab
        )
        let tomorrow = try dailyPrayerTimes(
            for: tomorrowDate, locationName: locationName, latitude: latitude, longitude: longitude,
            timeZone: timeZone, calculationMethod: calculationMethod, madhab: madhab
        )
        return (today, tomorrow)
    }

    /// The next upcoming tracked prayer at or after `now`, looking ahead to
    /// `tomorrow` if every tracked prayer for `today` has already passed.
    func nextPrayer(
        after now: Date,
        today: DailyPrayerTimes,
        tomorrow: DailyPrayerTimes,
        trackedPrayers: [Prayer]
    ) -> (prayer: Prayer, time: Date)? {
        let upcomingToday = trackedPrayers
            .map { ($0, today.time(for: $0)) }
            .filter { $0.1 > now }
            .min { $0.1 < $1.1 }

        if let upcomingToday {
            return upcomingToday
        }

        return trackedPrayers
            .map { ($0, tomorrow.time(for: $0)) }
            .min { $0.1 < $1.1 }
    }
}

private extension CalculationMethod {
    var adhanMethod: Adhan.CalculationMethod {
        switch self {
        case .muslimWorldLeague: .muslimWorldLeague
        case .egyptian: .egyptian
        case .karachi: .karachi
        case .ummAlQura: .ummAlQura
        case .dubai: .dubai
        case .moonsightingCommittee: .moonsightingCommittee
        case .northAmerica: .northAmerica
        case .kuwait: .kuwait
        case .qatar: .qatar
        case .singapore: .singapore
        case .tehran: .tehran
        case .turkey: .turkey
        }
    }
}

private extension Madhab {
    var adhanMadhab: Adhan.Madhab {
        switch self {
        case .shafi: .shafi
        case .hanafi: .hanafi
        }
    }
}
