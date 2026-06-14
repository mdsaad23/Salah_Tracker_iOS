import Foundation
import Testing
@testable import SalahCompanion

// NOTE: Add this file to a Unit Test target once the Xcode project exists
// (see XCODE_SETUP.md) — it depends on the Adhan-swift package being linked
// into that target.

@Suite("PrayerTimeService")
struct PrayerTimeServiceTests {
    let service = PrayerTimeService()

    @Test("Prayer times are in chronological order for a typical mid-latitude location")
    func orderedTimes() throws {
        let timeZone = try requireTimeZone("America/New_York")
        let date = makeDate(year: 2026, month: 6, day: 14, timeZone: timeZone)

        let times = try service.dailyPrayerTimes(
            for: date,
            locationName: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            timeZone: timeZone,
            calculationMethod: .northAmerica,
            madhab: .shafi
        )

        #expect(times.fajr < times.sunrise)
        #expect(times.sunrise < times.dhuhr)
        #expect(times.dhuhr < times.asr)
        #expect(times.asr < times.maghrib)
        #expect(times.maghrib < times.isha)
    }

    @Test("Schedule wraps correctly across the DST spring-forward transition")
    func dstSpringForward() throws {
        let timeZone = try requireTimeZone("America/New_York")
        // 2026-03-08: US clocks move forward 1 hour (02:00 -> 03:00), a 23-hour day.
        let date = makeDate(year: 2026, month: 3, day: 8, timeZone: timeZone)

        let (today, tomorrow) = try service.schedule(
            around: date,
            locationName: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            timeZone: timeZone,
            calculationMethod: .northAmerica,
            madhab: .shafi
        )

        #expect(today.fajr < today.isha)
        #expect(tomorrow.fajr < tomorrow.isha)
        #expect(today.isha < tomorrow.fajr)
    }

    @Test("Schedule wraps correctly across the DST fall-back transition")
    func dstFallBack() throws {
        let timeZone = try requireTimeZone("America/New_York")
        // 2026-11-01: US clocks move back 1 hour (02:00 -> 01:00), a 25-hour day.
        let date = makeDate(year: 2026, month: 11, day: 1, timeZone: timeZone)

        let (today, tomorrow) = try service.schedule(
            around: date,
            locationName: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            timeZone: timeZone,
            calculationMethod: .northAmerica,
            madhab: .shafi
        )

        #expect(today.fajr < today.isha)
        #expect(tomorrow.fajr < tomorrow.isha)
        #expect(today.isha < tomorrow.fajr)
    }

    @Test("nextPrayer rolls over to tomorrow's Fajr after today's Isha has passed")
    func midnightRollover() throws {
        let timeZone = try requireTimeZone("America/New_York")
        let date = makeDate(year: 2026, month: 6, day: 14, timeZone: timeZone)

        let (today, tomorrow) = try service.schedule(
            around: date,
            locationName: "New York",
            latitude: 40.7128,
            longitude: -74.0060,
            timeZone: timeZone,
            calculationMethod: .northAmerica,
            madhab: .shafi
        )

        let afterIsha = today.isha.addingTimeInterval(60)
        let next = service.nextPrayer(
            after: afterIsha,
            today: today,
            tomorrow: tomorrow,
            trackedPrayers: Prayer.allCases.filter(\.isObligatory)
        )

        #expect(next?.prayer == .fajr)
        #expect(next?.time == tomorrow.fajr)
    }

    @Test("High-latitude locations produce valid, ordered times near the summer solstice")
    func highLatitudeSummer() throws {
        let timeZone = try requireTimeZone("Atlantic/Reykjavik")
        // Twilight angles for Fajr/Isha are unreliable this far north without
        // the high-latitude rule applied by PrayerTimeService.
        let date = makeDate(year: 2026, month: 6, day: 21, timeZone: timeZone)

        let times = try service.dailyPrayerTimes(
            for: date,
            locationName: "Reykjavik",
            latitude: 64.1466,
            longitude: -21.9426,
            timeZone: timeZone,
            calculationMethod: .muslimWorldLeague,
            madhab: .shafi
        )

        #expect(times.fajr < times.sunrise)
        #expect(times.sunrise < times.dhuhr)
        #expect(times.dhuhr < times.asr)
        #expect(times.asr < times.maghrib)
        #expect(times.maghrib < times.isha)
    }
}

private enum TestSetupError: Error {
    case unknownTimeZone(String)
}

private func requireTimeZone(_ identifier: String) throws -> TimeZone {
    guard let timeZone = TimeZone(identifier: identifier) else {
        throw TestSetupError.unknownTimeZone(identifier)
    }
    return timeZone
}

private func makeDate(year: Int, month: Int, day: Int, timeZone: TimeZone) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = timeZone
    let components = DateComponents(year: year, month: month, day: day, hour: 12)
    return calendar.date(from: components) ?? Date()
}
