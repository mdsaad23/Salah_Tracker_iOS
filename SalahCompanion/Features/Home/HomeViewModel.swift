import Foundation
import Observation

/// Drives the Home screen: resolves the user's location, computes today's
/// and tomorrow's prayer times, and exposes the next upcoming prayer for the
/// countdown hero card.
@MainActor
@Observable
final class HomeViewModel {
    enum LoadState: Equatable {
        case loading
        case loaded
        /// Location permission was denied/restricted; the view should direct
        /// the user to Settings.
        case needsLocationPermission
        /// Resolving the location or computing prayer times failed.
        case failed
    }

    private let locationService = LocationService()
    private let prayerTimeService = PrayerTimeService()

    private(set) var today: DailyPrayerTimes?
    private(set) var tomorrow: DailyPrayerTimes?
    private(set) var resolvedLocationName: String?
    private(set) var loadState: LoadState = .loading

    /// Resolves the location from `settings` and recomputes today's and
    /// tomorrow's prayer times.
    func refresh(using settings: UserSettings) async {
        loadState = .loading
        do {
            let resolved = try await resolveLocation(using: settings)
            resolvedLocationName = resolved.name
            persistResolvedLocation(resolved, into: settings)

            let (today, tomorrow) = try prayerTimeService.schedule(
                around: .now,
                locationName: resolved.name,
                latitude: resolved.latitude,
                longitude: resolved.longitude,
                timeZone: resolved.timeZone,
                calculationMethod: settings.calculationMethod,
                madhab: settings.madhab
            )
            self.today = today
            self.tomorrow = tomorrow
            loadState = .loaded
        } catch LocationService.LocationError.authorizationDenied {
            loadState = .needsLocationPermission
        } catch {
            loadState = .failed
        }
    }

    /// The next tracked prayer at or after `date`, wrapping into tomorrow if
    /// every tracked prayer for today has already passed.
    func nextPrayer(after date: Date, trackedPrayers: [Prayer]) -> (prayer: Prayer, time: Date)? {
        guard let today, let tomorrow else { return nil }
        return prayerTimeService.nextPrayer(
            after: date, today: today, tomorrow: tomorrow, trackedPrayers: trackedPrayers
        )
    }

    /// Captures the last-resolved automatic location back into `UserSettings`
    /// so it persists (and is available to the widget/App Intents extensions)
    /// even when GPS is later unavailable. Manual locations are already stored.
    private func persistResolvedLocation(_ resolved: ResolvedLocation, into settings: UserSettings) {
        guard settings.locationMode == .automatic else { return }
        settings.latitude = resolved.latitude
        settings.longitude = resolved.longitude
        settings.timeZoneIdentifier = resolved.timeZone.identifier
        if !resolved.name.isEmpty {
            settings.locationName = resolved.name
        }
    }

    private func resolveLocation(using settings: UserSettings) async throws -> ResolvedLocation {
        switch settings.locationMode {
        case .automatic:
            let status = locationService.authorizationStatus
            if status == .notDetermined {
                locationService.requestAuthorization()
            } else if status == .denied || status == .restricted {
                throw LocationService.LocationError.authorizationDenied
            }
            return try await locationService.currentLocation()

        case .manual:
            guard let timeZone = TimeZone(identifier: settings.timeZoneIdentifier) else {
                throw LocationService.LocationError.timeZoneUnavailable
            }
            return ResolvedLocation(
                name: settings.locationName,
                latitude: settings.latitude,
                longitude: settings.longitude,
                timeZone: timeZone
            )
        }
    }
}
