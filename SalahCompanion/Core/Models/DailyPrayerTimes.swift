import Foundation
import SwiftData

/// The 6 computed prayer times for a single date at a single location,
/// produced by `PrayerTimeService`. A location snapshot is stored alongside
/// the times so historical entries remain meaningful if the user later
/// changes location.
@Model
final class DailyPrayerTimes {
    var date: Date
    var locationName: String
    var latitude: Double
    var longitude: Double
    var timeZoneIdentifier: String

    var fajr: Date
    var sunrise: Date
    var dhuhr: Date
    var asr: Date
    var maghrib: Date
    var isha: Date

    init(
        date: Date,
        locationName: String,
        latitude: Double,
        longitude: Double,
        timeZoneIdentifier: String,
        fajr: Date,
        sunrise: Date,
        dhuhr: Date,
        asr: Date,
        maghrib: Date,
        isha: Date
    ) {
        self.date = date
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
        self.timeZoneIdentifier = timeZoneIdentifier
        self.fajr = fajr
        self.sunrise = sunrise
        self.dhuhr = dhuhr
        self.asr = asr
        self.maghrib = maghrib
        self.isha = isha
    }

    /// The computed time for a given prayer marker.
    func time(for prayer: Prayer) -> Date {
        switch prayer {
        case .fajr: fajr
        case .sunrise: sunrise
        case .dhuhr: dhuhr
        case .asr: asr
        case .maghrib: maghrib
        case .isha: isha
        }
    }
}
